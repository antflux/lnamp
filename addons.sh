#!/bin/bash
#-------------------------------------------------------------------------
# Author: MaXincai <maxincai AT 126.com>
# Blog: http://www.maxincai.com
#
# Notes: LANMP for CentOS/RadHat 5+ Debian 6+ and Ubuntu 12+
#
# Github: https://github.com/maxincai/lnamp
#-------------------------------------------------------------------------

export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
clear

printf "
#######################################################################
#       lnamp for Linux Server                                        #
#       Install/Uninstall PHP Extensions                              #
#       By:MaXincai http://www.maxincai.com                           #
#######################################################################
"

# get pwd
sed -i "s@^lnamp_dir.*@lnamp_dir=`pwd`@" ./options.conf

. ./versions.txt
. ./options.conf
. ./include/color.sh
. ./include/memory.sh
. ./include/check_os.sh
. ./include/download.sh
. ./include/get_char.sh

. ./include/ImageMagick.sh
. ./include/GraphicsMagick.sh

. ./include/memcached.sh

. ./include/redis.sh

# Check if user is root
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }

# Check PHP
if [ -e "$php_install_dir/bin/phpize" ];then
    PHP_version=`$php_install_dir/bin/php -r 'echo PHP_VERSION;'`
    PHP_main_version=${PHP_version%.*}
fi

# Check PHP Extensions
Check_PHP_Extension() {
[ -e "$php_install_dir/etc/php.d/ext-${PHP_extension}.ini" ] && { echo "${CWARNING}PHP $PHP_extension module already installed! ${CEND}"; exit 1; }
}

# restart PHP
Restart_PHP() {
[ -e "$apache_install_dir/conf/httpd.conf" ] && /etc/init.d/httpd restart || /etc/init.d/php-fpm restart
}

# Check succ
Check_succ() {
[ -f "`$php_install_dir/bin/php-config --extension-dir`/${PHP_extension}.so" ] && { Restart_PHP; echo;echo "${CSUCCESS}PHP $PHP_extension module installed successfully! ${CEND}"; }
}

# Uninstall succ
Uninstall_succ() {
[ -e "$php_install_dir/etc/php.d/ext-${PHP_extension}.ini" ] && { rm -rf $php_install_dir/etc/php.d/ext-${PHP_extension}.ini; Restart_PHP; echo; echo "${CMSG}PHP $PHP_extension module uninstall completed${CEND}"; } || { echo; echo "${CWARNING}$PHP_extension module does not exist! ${CEND}"; }
}

ACTION_FUN() {
while :; do
    echo
    echo 'Please select an action:'
    echo -e "\t${CMSG}1${CEND}. install"
    echo -e "\t${CMSG}2${CEND}. uninstall"
    read -p "Please input a number:(Default 1 press Enter) " ACTION
    [ -z "$ACTION" ] && ACTION=1
    if [[ ! $ACTION =~ ^[1,2]$ ]];then
        echo "${CWARNING}input error! Please only input number 1,2${CEND}"
    else
        break
    fi
done
}

while :;do
    printf "
What Are You Doing?
\t${CMSG}1${CEND}. Install/Uninstall ImageMagick/GraphicsMagick PHP Extension
\t${CMSG}2${CEND}. Install/Uninstall fileinfo PHP Extension
\t${CMSG}3${CEND}. Install/Uninstall memcached/memcache
\t${CMSG}4${CEND}. Install/Uninstall Redis
\t${CMSG}q${CEND}. Exit
"
    read -p "Please input the correct option: " Number
    if [[ ! $Number =~ ^[1-7,q]$ ]];then
        echo "${CFAILURE}input error! Please only input 1 ~ 7 and q${CEND}"
    else
        case "$Number" in
        1)
            ACTION_FUN
            while :; do echo
                echo 'Please select ImageMagick/GraphicsMagick:'
                echo -e "\t${CMSG}1${CEND}. ImageMagick"
                echo -e "\t${CMSG}2${CEND}. GraphicsMagick"
                read -p "Please input a number:(Default 1 press Enter) " Magick
                [ -z "$Magick" ] && Magick=1
                if [[ ! $Magick =~ ^[1,2]$ ]];then
                    echo "${CWARNING}input error! Please only input number 1,2${CEND}"
                else
                    [ $Magick = 1 ] && PHP_extension=imagick
                    [ $Magick = 2 ] && PHP_extension=gmagick
                    break
                fi
            done
            if [ $ACTION = 1 ];then
                Check_PHP_Extension
                if [ $Magick = 1 ];then
                    [ ! -d "/usr/local/imagemagick" ] && Install_ImageMagick
                    Install_php-imagick
                    Check_succ
                elif [ $Magick = 2 ];then
                    [ ! -d "/usr/local/graphicsmagick" ] && Install_GraphicsMagick
                    Install_php-gmagick
                    Check_succ
                fi
            else
                Uninstall_succ
                [ -d "/usr/local/imagemagick" ] && rm -rf /usr/local/imagemagick
                [ -d "/usr/local/graphicsmagick" ] && rm -rf /usr/local/graphicsmagick
            fi
            ;;
        2)
            ACTION_FUN
            PHP_extension=fileinfo
            if [ $ACTION = 1 ];then
                Check_PHP_Extension
                cd $lnamp_dir/src
                src_url=http://www.php.net/distributions/php-$PHP_version.tar.gz && Download_src
                tar xzf php-$PHP_version.tar.gz
                cd php-$PHP_version/ext/fileinfo
                $php_install_dir/bin/phpize
                ./configure --with-php-config=$php_install_dir/bin/php-config
                make -j ${THREAD} && make install
                echo 'extension=fileinfo.so' > $php_install_dir/etc/php.d/ext-fileinfo.ini
                Check_succ
            else
                Uninstall_succ
            fi
            ;;
        3)
            ACTION_FUN
            while :; do echo
                echo 'Please select memcache/memcached PHP Extension:'
                echo -e "\t${CMSG}1${CEND}. memcache PHP Extension"
                echo -e "\t${CMSG}2${CEND}. memcached PHP Extension"
                echo -e "\t${CMSG}3${CEND}. memcache/memcached PHP Extension"
                read -p "Please input a number:(Default 1 press Enter) " Memcache
                [ -z "$Memcache" ] && Memcache=1
                if [[ ! $Memcache =~ ^[1-3]$ ]];then
                    echo "${CWARNING}input error! Please only input number 1,2,3${CEND}"
                else
                    [ $Memcache = 1 ] && PHP_extension=memcache
                    [ $Memcache = 2 ] && PHP_extension=memcached
                    break
                fi
            done
            if [ $ACTION = 1 ];then
                if [ $Memcache = 1 ];then
                    [ ! -d "$memcached_install_dir/include/memcached" ] && Install_memcached
                    Check_PHP_Extension
                    Install_php-memcache
                    Check_succ
                elif [ $Memcache = 2 ];then
                    [ ! -d "$memcached_install_dir/include/memcached" ] && Install_memcached
                    Check_PHP_Extension
                    Install_php-memcached
                    Check_succ
                elif [ $Memcache = 3 ];then
                    [ ! -d "$memcached_install_dir/include/memcached" ] && Install_memcached
                    PHP_extension=memcache && Check_PHP_Extension
                    Install_php-memcache
                    PHP_extension=memcached && Check_PHP_Extension
                    Install_php-memcached
                    [ -f "`$php_install_dir/bin/php-config --extension-dir`/memcache.so" -a "`$php_install_dir/bin/php-config --extension-dir`/memcached.so" ] && { Restart_PHP; echo;echo "${CSUCCESS}PHP memcache/memcached module installed successfully! ${CEND}"; }
                fi
            else
                PHP_extension=memcache && Uninstall_succ
                PHP_extension=memcached && Uninstall_succ
                [ -e "$memcached_install_dir" ] && { service memcached stop > /dev/null 2>&1; rm -rf $memcached_install_dir /etc/init.d/memcached /usr/bin/memcached; }
            fi
            ;;
        4)
            ACTION_FUN
            PHP_extension=redis
            if [ $ACTION = 1 ];then
                [ ! -d "$redis_install_dir" ] && Install_redis-server
                Check_PHP_Extension
                Install_php-redis
            else
                Uninstall_succ
                [ -e "$redis_install_dir" ] && { service redis-server stop > /dev/null 2>&1; rm -rf $redis_install_dir /etc/init.d/redis-server /usr/local/bin/redis-*; }
            fi
            ;;
        q)
            exit
            ;;
        esac
    fi
done
