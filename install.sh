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
#       Automatic compilation(Tengine/nginx)+php+Mysql                #
#       By:MaXincai http://www.maxincai.com                           #
#######################################################################
"

# get pwd
sed -i "s@^lnamp_dir.*@lnamp_dir=`pwd`@" ./options.conf

. ./versions.txt
. ./options.conf
. ./include/color.sh
. ./include/check_os.sh
. ./include/check_dir.sh
. ./include/download.sh
. ./include/get_char.sh

# Check if user is root
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }

mkdir -p $wwwroot_dir/default $wwwlogs_dir
[ -d /data ] && chmod 755 /data

# Use default SSH port 22. If you use another SSH port on your server
if [ -e "/etc/ssh/sshd_config" ];then
    [ -z "`grep ^Port /etc/ssh/sshd_config`" ] && ssh_port=22 || ssh_port=`grep ^Port /etc/ssh/sshd_config | awk '{print $2}'`
    while :; do echo
        read -p "Please input SSH port(Default: $ssh_port): " SSH_PORT
        [ -z "$SSH_PORT" ] && SSH_PORT=$ssh_port
        if [ $SSH_PORT -eq 22 >/dev/null 2>&1 -o $SSH_PORT -gt 1024 >/dev/null 2>&1 -a $SSH_PORT -lt 65535 >/dev/null 2>&1 ];then
            break
        else
            echo "${CWARNING}input error! Input range: 22,1025~65534${CEND}"
        fi
    done

    if [ -z "`grep ^Port /etc/ssh/sshd_config`" -a "$SSH_PORT" != '22' ];then
        sed -i "s@^#Port.*@&\nPort $SSH_PORT@" /etc/ssh/sshd_config
    elif [ -n "`grep ^Port /etc/ssh/sshd_config`" ];then
        sed -i "s@^Port.*@Port $SSH_PORT@" /etc/ssh/sshd_config
    fi
fi

# check Web server
while :; do echo
    read -p "Do you want to install Web server? [y/n]: " Web_yn
    if [[ ! $Web_yn =~ ^[y,n]$ ]];then
        echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
        if [ "$Web_yn" == 'y' ];then
            # Nginx/Tegine/OpenResty
            while :; do echo
                echo 'Please select Nginx server:'
                echo -e "\t${CMSG}1${CEND}. Install Nginx"
                echo -e "\t${CMSG}2${CEND}. Install Tengine"
                echo -e "\t${CMSG}3${CEND}. Install OpenResty"
                echo -e "\t${CMSG}4${CEND}. Do not install"
                read -p "Please input a number:(Default 1 press Enter) " Nginx_version
                [ -z "$Nginx_version" ] && Nginx_version=1
                if [[ ! $Nginx_version =~ ^[1-4]$ ]];then
                    echo "${CWARNING}input error! Please only input number 1,2,3,4${CEND}"
                else
                    [ "$Nginx_version" != '4' -a -e "$nginx_install_dir/sbin/nginx" ] && { echo "${CWARNING}Nginx already installed! ${CEND}"; Nginx_version=Other; }
                    [ "$Nginx_version" != '4' -a -e "$tengine_install_dir/sbin/nginx" ] && { echo "${CWARNING}Tengine already installed! ${CEND}"; Nginx_version=Other; }
                    [ "$Nginx_version" != '4' -a -e "$openresty_install_dir/nginx/sbin/nginx" ] && { echo "${CWARNING}OpenResty already installed! ${CEND}"; Nginx_version=Other; }
                    break
                fi
            done
            # Apache
            while :; do echo
                echo 'Please select Apache server:'
                echo -e "\t${CMSG}1${CEND}. Install Apache-2.4"
                echo -e "\t${CMSG}2${CEND}. Install Apache-2.2"
                echo -e "\t${CMSG}3${CEND}. Do not install"
                read -p "Please input a number:(Default 3 press Enter) " Apache_version
                [ -z "$Apache_version" ] && Apache_version=3
                if [[ ! $Apache_version =~ ^[1-3]$ ]];then
                    echo "${CWARNING}input error! Please only input number 1,2,3${CEND}"
                else
                    [ "$Apache_version" != '3' -a -e "$apache_install_dir/conf/httpd.conf" ] && { echo "${CWARNING}Aapche already installed! ${CEND}"; Apache_version=Other; }
                    break
                fi
            done
        fi
        break
    fi
done

# choice database
while :; do echo
    read -p "Do you want to install Database? [y/n]: " DB_yn
    if [[ ! $DB_yn =~ ^[y,n]$ ]];then
        echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
        if [ "$DB_yn" == 'y' ];then
            [ -d "$db_install_dir/support-files" ] && { echo "${CWARNING}Database already installed! ${CEND}"; DB_yn=Other; break; }
            while :; do echo
                echo 'Please select a version of the Database:'
                echo -e "\t${CMSG}1${CEND}. Install MySQL-5.7"
                echo -e "\t${CMSG}2${CEND}. Install MySQL-5.6"
                echo -e "\t${CMSG}3${CEND}. Install MySQL-5.5"
                read -p "Please input a number:(Default 2 press Enter) " DB_version
                [ -z "$DB_version" ] && DB_version=2
                if [[ ! $DB_version =~ ^[1-3]$ ]];then
                    echo "${CWARNING}input error! Please only input number 1,2,3${CEND}"
                else
                    while :; do
                        read -p "Please input the root password of database: " dbrootpwd
                        [ -n "`echo $dbrootpwd | grep '[+|&]'`" ] && { echo "${CWARNING}input error,not contain a plus sign (+) and & ${CEND}"; continue; }
                        (( ${#dbrootpwd} >= 5 )) && sed -i "s+^dbrootpwd.*+dbrootpwd='$dbrootpwd'+" ./options.conf && break || echo "${CWARNING}database root password least 5 characters! ${CEND}"
                    done
                    break
                fi
            done
        fi
        break
    fi
done

# check PHP
while :; do echo
    read -p "Do you want to install PHP? [y/n]: " PHP_yn
    if [[ ! $PHP_yn =~ ^[y,n]$ ]];then
        echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
        if [ "$PHP_yn" == 'y' ];then
            [ -e "$php_install_dir/bin/phpize" ] && { echo "${CWARNING}PHP already installed! ${CEND}"; PHP_yn=Other; break; }
            while :; do echo
                echo 'Please select a version of the PHP:'
                echo -e "\t${CMSG}1${CEND}. Install php-5.3"
                echo -e "\t${CMSG}2${CEND}. Install php-5.4"
                echo -e "\t${CMSG}3${CEND}. Install php-5.5"
                echo -e "\t${CMSG}4${CEND}. Install php-5.6"
                echo -e "\t${CMSG}5${CEND}. Install php-7"
                read -p "Please input a number:(Default 3 press Enter) " PHP_version
                [ -z "$PHP_version" ] && PHP_version=3
                if [[ ! $PHP_version =~ ^[1-5]$ ]];then
                    echo "${CWARNING}input error! Please only input number 1,2,3,4,5${CEND}"
                else
                    # ImageMagick or GraphicsMagick
                    while :; do echo
                        read -p "Do you want to install ImageMagick or GraphicsMagick? [y/n]: " Magick_yn
                        if [[ ! $Magick_yn =~ ^[y,n]$ ]];then
                            echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
                        else
                            break
                        fi
                    done

                    if [ "$Magick_yn" == 'y' ];then
                        while :; do
                            echo 'Please select ImageMagick or GraphicsMagick:'
                            echo -e "\t${CMSG}1${CEND}. Install ImageMagick"
                            echo -e "\t${CMSG}2${CEND}. Install GraphicsMagick"
                            read -p "Please input a number:(Default 1 press Enter) " Magick
                            [ -z "$Magick" ] && Magick=1
                            if [[ ! $Magick =~ ^[1-2]$ ]];then
                                echo "${CWARNING}input error! Please only input number 1,2${CEND}"
                            else
                                break
                            fi
                        done
                    fi
                    break
                fi
            done
        fi
        break
    fi
done


# check redis
while :; do echo
    read -p "Do you want to install redis? [y/n]: " redis_yn
    if [[ ! $redis_yn =~ ^[y,n]$ ]];then
        echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
        break
    fi
done

# check memcached
while :; do echo
    read -p "Do you want to install memcached? [y/n]: " memcached_yn
    if [[ ! $memcached_yn =~ ^[y,n]$ ]];then
        echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
        break
    fi
done


# get the IP information
chmod +x ./include/get_ipaddr.py
chmod +x ./include/get_public_ipaddr.py
chmod +x ./include/get_ipaddr_state.py
IPADDR=`./include/get_ipaddr.py`
PUBLIC_IPADDR=`./include/get_public_ipaddr.py`
IPADDR_COUNTRY_ISP=`./include/get_ipaddr_state.py $PUBLIC_IPADDR`
IPADDR_COUNTRY=`echo $IPADDR_COUNTRY_ISP | awk '{print $1}'`
[ "`echo $IPADDR_COUNTRY_ISP | awk '{print $2}'`"x == '1000323'x ] && IPADDR_ISP=aliyun

# init
. ./include/memory.sh
if [ "$OS" == 'CentOS' ];then
    . include/init_CentOS.sh 2>&1 | tee $lnamp_dir/install.log
    [ -n "`gcc --version | head -n1 | grep '4\.1\.'`" ] && export CC="gcc44" CXX="g++44"
elif [ "$OS" == 'Debian' ];then
    . include/init_Debian.sh 2>&1 | tee $lnamp_dir/install.log
elif [ "$OS" == 'Ubuntu' ];then
    . include/init_Ubuntu.sh 2>&1 | tee $lnamp_dir/install.log
fi


# Database
if [ "$DB_version" == '1' ];then
    . include/mysql-5.7.sh
    Install_MySQL-5-7 2>&1 | tee -a $lnamp_dir/install.log
elif [ "$DB_version" == '2' ];then
    . include/mysql-5.6.sh
    Install_MySQL-5-6 2>&1 | tee -a $lnamp_dir/install.log
elif [ "$DB_version" == '3' ];then
    . include/mysql-5.5.sh
    Install_MySQL-5-5 2>&1 | tee -a $lnamp_dir/install.log
fi

# Apache
if [ "$Apache_version" == '1' ];then
    . include/apache-2.4.sh
    Install_Apache-2-4 2>&1 | tee -a $lnamp_dir/install.log
elif [ "$Apache_version" == '2' ];then
    . include/apache-2.2.sh
    Install_Apache-2-2 2>&1 | tee -a $lnamp_dir/install.log
fi

# PHP
if [ "$PHP_version" == '1' ];then
    . include/php-5.3.sh
    Install_PHP-5-3 2>&1 | tee -a $lnamp_dir/install.log
elif [ "$PHP_version" == '2' ];then
    . include/php-5.4.sh
    Install_PHP-5-4 2>&1 | tee -a $lnamp_dir/install.log
elif [ "$PHP_version" == '3' ];then
    . include/php-5.5.sh
    Install_PHP-5-5 2>&1 | tee -a $lnamp_dir/install.log
elif [ "$PHP_version" == '4' ];then
    . include/php-5.6.sh
    Install_PHP-5-6 2>&1 | tee -a $lnamp_dir/install.log
elif [ "$PHP_version" == '5' ];then
    . include/php-7.sh
    Install_PHP-7 2>&1 | tee -a $lnamp_dir/install.log
fi

# ImageMagick or GraphicsMagick
if [ "$Magick" == '1' ];then
    . include/ImageMagick.sh
    [ ! -d "/usr/local/imagemagick" ] && Install_ImageMagick 2>&1 | tee -a $lnamp_dir/install.log
    [ ! -e "`$php_install_dir/bin/php-config --extension-dir`/imagick.so" ] && Install_php-imagick 2>&1 | tee -a $lnamp_dir/install.log
elif [ "$Magick" == '2' ];then
    . include/GraphicsMagick.sh
    [ ! -d "/usr/local/graphicsmagick" ] && Install_GraphicsMagick 2>&1 | tee -a $lnamp_dir/install.log
    [ ! -e "`$php_install_dir/bin/php-config --extension-dir`/gmagick.so" ] && Install_php-gmagick 2>&1 | tee -a $lnamp_dir/install.log
fi


# Web server
if [ "$Nginx_version" == '1' ];then
    . include/nginx.sh
    Install_Nginx 2>&1 | tee -a $lnamp_dir/install.log
elif [ "$Nginx_version" == '2' ];then
    . include/tengine.sh
    Install_Tengine 2>&1 | tee -a $lnamp_dir/install.log
elif [ "$Nginx_version" == '3' ];then
    . include/openresty.sh
    Install_OpenResty 2>&1 | tee -a $lnamp_dir/install.log
fi

# redis
if [ "$redis_yn" == 'y' ];then
    . include/redis.sh
    [ ! -d "$redis_install_dir" ] && Install_redis-server 2>&1 | tee -a $lnamp_dir/install.log
    [ -e "$php_install_dir/bin/phpize" ] && [ ! -e "`$php_install_dir/bin/php-config --extension-dir`/redis.so" ] && Install_php-redis 2>&1 | tee -a $lnamp_dir/install.log
fi

# memcached
if [ "$memcached_yn" == 'y' ];then
    . include/memcached.sh
    [ ! -d "$memcached_install_dir/include/memcached" ] && Install_memcached 2>&1 | tee -a $lnamp_dir/install.log
    [ -e "$php_install_dir/bin/phpize" ] && [ ! -e "`$php_install_dir/bin/php-config --extension-dir`/memcache.so" ] && Install_php-memcache 2>&1 | tee -a $lnamp_dir/install.log
    [ -e "$php_install_dir/bin/phpize" ] && [ ! -e "`$php_install_dir/bin/php-config --extension-dir`/memcached.so" ] && Install_php-memcached 2>&1 | tee -a $lnamp_dir/install.log
fi

# index example
if [ ! -e "$wwwroot_dir/default/index.html" -a "$Web_yn" == 'y' ];then
    . include/demo.sh
    DEMO 2>&1 | tee -a $lnamp_dir/install.log
fi

# get web_install_dir and db_install_dir
. include/check_dir.sh

# Starting DB
[ -d "/etc/mysql" ] && /bin/mv /etc/mysql{,_bk}
[ -d "$db_install_dir/support-files" -a -z "`ps -ef | grep -v grep | grep mysql`" ] && /etc/init.d/mysqld start

echo "####################Congratulations########################"
[ "$Web_yn" == 'y' -a "$Nginx_version" != '4' -a "$Apache_version" == '3' ] && echo -e "\n`printf "%-32s" "Nginx install dir":`${CMSG}$web_install_dir${CEND}"
[ "$Web_yn" == 'y' -a "$Nginx_version" != '4' -a "$Apache_version" != '3' ] && echo -e "\n`printf "%-32s" "Nginx install dir":`${CMSG}$web_install_dir${CEND}\n`printf "%-32s" "Apache install  dir":`${CMSG}$apache_install_dir${CEND}"
[ "$Web_yn" == 'y' -a "$Nginx_version" == '4' -a "$Apache_version" != '3' ] && echo -e "\n`printf "%-32s" "Apache install dir":`${CMSG}$apache_install_dir${CEND}"
[ "$DB_yn" == 'y' ] && echo -e "\n`printf "%-32s" "Database install dir:"`${CMSG}$db_install_dir${CEND}"
[ "$DB_yn" == 'y' ] && echo "`printf "%-32s" "Database data dir:"`${CMSG}$db_data_dir${CEND}"
[ "$DB_yn" == 'y' ] && echo "`printf "%-32s" "Database user:"`${CMSG}root${CEND}"
[ "$DB_yn" == 'y' ] && echo "`printf "%-32s" "Database password:"`${CMSG}${dbrootpwd}${CEND}"
[ "$PHP_yn" == 'y' ] && echo -e "\n`printf "%-32s" "PHP install dir:"`${CMSG}$php_install_dir${CEND}"
[ "$redis_yn" == 'y' ] && echo -e "\n`printf "%-32s" "redis install dir:"`${CMSG}$redis_install_dir${CEND}"
[ "$memcached_yn" == 'y' ] && echo -e "\n`printf "%-32s" "memcached install dir:"`${CMSG}$memcached_install_dir${CEND}"
[ "$Web_yn" == 'y' ] && echo -e "\n`printf "%-32s" "index url:"`${CMSG}http://$IPADDR/${CEND}"
while :; do echo
    echo "${CMSG}Please restart the server and see if the services start up fine.${CEND}"
    read -p "Do you want to restart OS ? [y/n]: " restart_yn
    if [[ ! $restart_yn =~ ^[y,n]$ ]];then
        echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
        break
    fi
done
[ "$restart_yn" == 'y' ] && reboot
