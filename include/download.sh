#!/bin/bash
#-------------------------------------------------------------------------
# Author: MaXincai <maxincai AT 126.com>
# Blog: http://www.maxincai.com
#
# Notes: LANMP for CentOS/RadHat 5+ Debian 6+ and Ubuntu 12+
#
# Github: https://github.com/maxincai/lnamp
#-------------------------------------------------------------------------

Download_src() {
    [ -s "${src_url##*/}" ] && echo "[${CMSG}${src_url##*/}${CEND}] found" || { wget --tries=6 -c --no-check-certificate $src_url; sleep 1; }
    if [ ! -e "${src_url##*/}" ];then
        echo "${CFAILURE}${src_url##*/} download failed, Please contact the author! ${CEND}"
        kill -9 $$
    fi
}
