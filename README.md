# LNAMP
Linux,Nginx,Apache,MySql,PHP生产环境一键安装包


## 如何使用

```bash
git clone https://github.com/maxincai/lnamp.git
cd lnamp
./install.sh // 请勿sh install.sh或者bash install.sh这样执行
```

## 如何添加扩展

```bash
cd ~/lnamp    // 必须进入lnamp目录执行 
./addons.sh    // 请勿sh addons.sh或者bash addons.sh这样执行

```


## 如何管理服务

Nginx/Tengine/OpenResty:
```bash
service nginx {start|stop|status|restart|reload|configtest}
```
MySQL:
```bash
service mysqld {start|stop|restart|reload|status}
```
PHP:
```bash
service php-fpm {start|stop|restart|reload|status}
```
Apache:
```bash
service httpd {start|restart|stop}
```
Redis:
```bash
service redis-server {start|stop|status|restart|reload}
```
Memcached:
```bash
service memcached {start|stop|status|restart|reload}
```

## 如何升级

待完善

## 如何卸载

```bash
./uninstall.sh
```

