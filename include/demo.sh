#!/bin/bash
#-------------------------------------------------------------------------
# Author: MaXincai <maxincai AT 126.com>
# Blog: http://www.maxincai.com
#
# Notes: LANMP for CentOS/RadHat 5+ Debian 6+ and Ubuntu 12+
#
# Github: https://github.com/maxincai/lnamp
#-------------------------------------------------------------------------

DEMO() {
cd $lnamp_dir/src

[ "$IPADDR_COUNTRY"x == "CN"x ] && /bin/cp ../config/index_cn.html $wwwroot_dir/default/index.html || /bin/cp ../config/index.html $wwwroot_dir/default

if [ -e "$php_install_dir/bin/php" ];then
    if [ "$IPADDR_COUNTRY"x == "CN"x ];then
        src_url=http://mirrors.linuxeye.com/oneinstack/src/tz.zip && Download_src
        unzip -q tz.zip -d $wwwroot_dir/default
    else
        src_url=http://mirrors.linuxeye.com/oneinstack/src/tz_e.zip && Download_src
        unzip -q tz_e.zip -d $wwwroot_dir/default;/bin/mv $wwwroot_dir/default/{tz_e.php,proberv.php}
        sed -i 's@https://ajax.googleapis.com/ajax/libs/jquery/1.7.0/jquery.min.js@http://lib.sinaapp.com/js/jquery/1.7/jquery.min.js@' $wwwroot_dir/default/proberv.php
    fi

    echo '<?php phpinfo() ?>' > $wwwroot_dir/default/phpinfo.php
fi
chown -R ${run_user}.$run_user $wwwroot_dir/default
[ -e /usr/bin/systemctl ] && systemctl daemon-reload
cd ..
}
