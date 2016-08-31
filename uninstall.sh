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
#       Uninstall lnamp                                               #
#       By:MaXincai http://www.maxincai.com                           #
#######################################################################
"

. ./options.conf
. ./include/color.sh
. ./include/get_char.sh
. ./include/check_dir.sh

# Check if user is root
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }


Usage(){
printf "
Usage: $0 [  ${CMSG}all${CEND} | ${CMSG}web${CEND} | ${CMSG}db${CEND} | ${CMSG}php${CEND} | ${CMSG}hhvm${CEND} | ${CMSG}pureftpd${CEND} | ${CMSG}redis${CEND} | ${CMSG}memcached${CEND} ]
${CMSG}all${CEND}            --->Uninstall All
${CMSG}web${CEND}            --->Uninstall Nginx/Tengine/Apache
${CMSG}db${CEND}             --->Uninstall MySQL
${CMSG}php${CEND}            --->Uninstall PHP
${CMSG}redis${CEND}          --->Uninstall Redis
${CMSG}memcached${CEND}      --->Uninstall Memcached

"
}

Uninstall_status() {
while :; do echo
    read -p "Do you want to uninstall? [y/n]: " uninstall_yn
    echo
    if [[ ! $uninstall_yn =~ ^[y,n]$ ]];then
        echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
        break
    fi
done
}

Print_Warn() {
echo
echo "${CWARNING}You will uninstall lnamp, Please backup your configure files and DB data! ${CEND}"
}

Print_web() {
[ -d "$nginx_install_dir" ] && echo "$nginx_install_dir"
[ -d "$tengine_install_dir" ] && echo "$tengine_install_dir"
[ -d "$openresty_install_dir" ] && echo "$openresty_install_dir"
[ -e "/etc/init.d/nginx" ] && echo '/etc/init.d/nginx'
[ -e "/etc/logrotate.d/nginx" ] && echo '/etc/logrotate.d/nginx'

[ -d "$apache_install_dir" ] && echo "$apache_install_dir"
[ -e "/etc/init.d/httpd" ] && echo "/etc/init.d/httpd"
[ -e "/etc/logrotate.d/apache" ] && echo "/etc/logrotate.d/apache"
}

Uninstall_Web() {
[ -d "$nginx_install_dir" ] && { killall nginx > /dev/null 2>&1; rm -rf $nginx_install_dir /etc/init.d/nginx /etc/logrotate.d/nginx; sed -i "s@$nginx_install_dir/sbin:@@" /etc/profile; }
[ -d "$tengine_install_dir" ] && { killall nginx > /dev/null 2>&1; rm -rf $tengine_install_dir /etc/init.d/nginx /etc/logrotate.d/nginx; sed -i "s@$tengine_install_dir/sbin:@@" /etc/profile; }
[ -d "$openresty_install_dir" ] && { killall nginx > /dev/null 2>&1; rm -rf $openresty_install_dir /etc/init.d/nginx /etc/logrotate.d/nginx; sed -i "s@$openresty_install_dir/nginx/sbin:@@" /etc/profile; }
[ -d "$apache_install_dir" ] && { service httpd stop > /dev/null 2>&1; rm -rf $apache_install_dir /etc/init.d/httpd /etc/logrotate.d/apache; sed -i "s@$apache_install_dir/bin:@@" /etc/profile; }

[ -e "$wwwroot_dir" ] && /bin/mv ${wwwroot_dir}{,$(date +%Y%m%d%H)}
sed -i 's@^website_name=.*@website_name=@' ./options.conf
sed -i 's@^local_bankup_yn=.*@local_bankup_yn=y@' ./options.conf
sed -i 's@^remote_bankup_yn=.*@remote_bankup_yn=n@' ./options.conf
echo "${CMSG}Web uninstall completed${CEND}"
}

Print_DB() {
[ -e "$db_install_dir" ] && echo "$db_install_dir"
[ -e "/etc/init.d/mysqld" ] && echo "/etc/init.d/mysqld"
[ -e "/etc/my.cnf" ] && echo "/etc/my.cnf"
}

Uninstall_DB() {
[ -e "$db_install_dir" ] && { service mysqld stop > /dev/null 2>&1; rm -rf $db_install_dir /etc/init.d/mysqld /etc/my.cnf /etc/ld.so.conf.d/mysql*.conf; }
id -u mysql >/dev/null 2>&1 ; [ $? -eq 0 ] && userdel mysql
[ -e "$db_data_dir" ] && /bin/mv ${db_data_dir}{,$(date +%Y%m%d%H)}
sed -i 's@^dbrootpwd=.*@dbrootpwd=@' ./options.conf
sed -i "s@$db_install_dir/bin:@@" /etc/profile
echo "${CMSG}DB uninstall completed${CEND}"
}

Print_PHP() {
[ -e "$php_install_dir" ] && echo "$php_install_dir"
[ -e "/etc/init.d/php-fpm" ] && echo "/etc/init.d/php-fpm"
[ -e "/usr/local/imagemagick" ] && echo "/usr/local/imagemagick"
[ -e "/usr/local/graphicsmagick" ] && echo '/usr/local/graphicsmagick'
}

Uninstall_PHP() {
[ -e "$php_install_dir/bin/phpize" -a -e "$php_install_dir/etc/php-fpm.conf" ] && { service php-fpm stop > /dev/null 2>&1; rm -rf $php_install_dir /etc/init.d/php-fpm; }
[ -e "$php_install_dir/bin/phpize" -a ! -e "$php_install_dir/etc/php-fpm.conf" ] && rm -rf $php_install_dir
[ -e "/usr/local/imagemagick" ] && rm -rf /usr/local/imagemagick
[ -e "/usr/local/graphicsmagick" ] && rm -rf /usr/local/graphicsmagick
sed -i "s@$php_install_dir/bin:@@" /etc/profile
echo "${CMSG}PHP uninstall completed${CEND}"
}

Print_Redis() {
[ -e "$redis_install_dir" ] && echo "$redis_install_dir"
[ -e "/etc/init.d/redis-server" ] && echo "/etc/init.d/redis-server"
}

Uninstall_Redis() {
[ -e "$redis_install_dir" ] && { service redis-server stop > /dev/null 2>&1; rm -rf $redis_install_dir /etc/init.d/redis-server /usr/local/bin/redis-*; }
[ -e "$php_install_dir/etc/php.d/ext-redis.ini" ] && rm -rf $php_install_dir/etc/php.d/ext-redis.ini
echo "${CMSG}Redis uninstall completed${CEND}"
}

Print_Memcached() {
[ -e "$memcached_install_dir" ] && echo "$memcached_install_dir"
[ -e "/etc/init.d/memcached" ] && echo "/etc/init.d/memcached"
[ -e "/usr/bin/memcached" ] && echo "/usr/bin/memcached"
}

Uninstall_Memcached() {
[ -e "$memcached_install_dir" ] && { service memcached stop > /dev/null 2>&1; rm -rf $memcached_install_dir /etc/init.d/memcached /usr/bin/memcached; }
[ -e "$php_install_dir/etc/php.d/ext-memcache.ini" ] && rm -rf $php_install_dir/etc/php.d/ext-memcache.ini
[ -e "$php_install_dir/etc/php.d/ext-memcached.ini" ] && rm -rf $php_install_dir/etc/php.d/ext-memcached.ini
echo "${CMSG}Memcached uninstall completed${CEND}"
}

Menu(){
while :; do
    printf "
What Are You Doing?
\t${CMSG}0${CEND}. Uninstall All
\t${CMSG}1${CEND}. Uninstall Nginx/Tengine/Apache
\t${CMSG}2${CEND}. Uninstall MySQL
\t${CMSG}3${CEND}. Uninstall PHP
\t${CMSG}4${CEND}. Uninstall Redis
\t${CMSG}5${CEND}. Uninstall Memcached
\t${CMSG}q${CEND}. Exit
"
    echo
    read -p "Please input the correct option: " Number
    if [[ ! $Number =~ ^[0-7,q]$ ]];then
        echo "${CWARNING}input error! Please only input 0,1,2,3,4,5 and q${CEND}"
    else
        case "$Number" in
        0)
            Print_Warn
            Print_web
            Print_DB
            Print_PHP
            Print_Redis
            Print_Memcached

            Uninstall_status
            if [ "$uninstall_yn" == 'y' ];then
                Uninstall_Web
                Uninstall_DB
                Uninstall_PHP
                Uninstall_Redis
                Uninstall_Memcached
            else
                exit
            fi
            ;;
        1)
            Print_Warn
            Print_web
            Uninstall_status
            [ "$uninstall_yn" == 'y' ] && Uninstall_Web || exit
            ;;
        2)
            Print_Warn
            Print_DB
            Uninstall_status
            [ "$uninstall_yn" == 'y' ] && Uninstall_DB || exit
            ;;
        3)
            Print_PHP
            Uninstall_status
            [ "$uninstall_yn" == 'y' ] && Uninstall_PHP || exit
            ;;
        4)
            Print_Redis
            Uninstall_status
            [ "$uninstall_yn" == 'y' ] && Uninstall_Redis || exit
            ;;
        5)
            Print_Memcached
            Uninstall_status
            [ "$uninstall_yn" == 'y' ] && Uninstall_Memcached || exit
            ;;
        q)
            exit
            ;;
        esac
    fi
done
}

if [ $# == 0 ];then
    Menu
elif [ $# == 1 ];then
    case $1 in
    all)
        Print_Warn
        Print_web
        Print_DB
        Print_PHP
        Print_Redis
        Print_Memcached

        Uninstall_status
        if [ "$uninstall_yn" == 'y' ];then
            Uninstall_Web
            Uninstall_DB
            Uninstall_PHP
            Uninstall_Redis
            Uninstall_Memcached
        else
            exit
        fi
        ;;
    web)
        Print_Warn
        Print_web
        Uninstall_status
        [ "$uninstall_yn" == 'y' ] && Uninstall_Web || exit
        ;;
    db)
        Print_Warn
        Print_DB
        Uninstall_status
        [ "$uninstall_yn" == 'y' ] && Uninstall_DB || exit
        ;;
    php)
        Print_PHP
        Uninstall_status
        [ "$uninstall_yn" == 'y' ] && Uninstall_PHP || exit
        ;;
    redis)
        Print_Redis
        Uninstall_status
        [ "$uninstall_yn" == 'y' ] && Uninstall_Redis || exit
        ;;
    memcached)
        Print_Memcached
        Uninstall_status
        [ "$uninstall_yn" == 'y' ] && Uninstall_Memcached || exit
        ;;
    *)
        Usage
        ;;
    esac
else
    Usage
fi
