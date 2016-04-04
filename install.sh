#!/bin/bash

echo ''
echo '--------------------------- URL ДОМЕНА ---------------------------'
AGAIN=yes
while [ "${AGAIN}" = "yes" ]
do
    if [ $1 ]; then
        DOMAIN=${1}
        echo ": ${DOMAIN}"
    else
        read -p ': ' DOMAIN
    fi
    if [ "${DOMAIN}" != "" ]
    then
        AGAIN=no
    else
        echo 'WARNING: URL домена не может быть пустым.'
    fi
done
echo '------------------------- НАЗВАНИЕ ТЕМЫ --------------------------'
AGAIN=yes
while [ "${AGAIN}" = "yes" ]
do
    if [ $2 ]
    then
        THEME=${2}
        echo ": ${THEME}"
    else
        read -p ': ' THEME
    fi
    if [ "${THEME}" = "" ]
    then
        AGAIN=no
        THEME='skeleton'
    else
        if [ "${THEME}" = "ted" ] || [ "${THEME}" = "barney" ] || [ "${THEME}" = "lily" ] || [ "${THEME}" = "marshall" ]
        then
            AGAIN=no
        else
            echo 'WARNING: Нет такой темы.'
        fi
    fi
done
echo '---------------- ВАШ ЛОГИН ОТ АДМИН-ПАНЕЛИ И FTP -----------------'
echo ": ${DOMAIN}"
echo '------------ ПРИДУМАЙТЕ ПАРОЛЬ ОТ АДМИН-ПАНЕЛИ И FTP -------------'
AGAIN=yes
while [ "${AGAIN}" = "yes" ]
do
    if [ $3 ]
    then
        PASSWD=${3}
        echo ": ${PASSWD}"
    else
        read -p ': ' PASSWD
    fi
    if [ "${PASSWD}" != "" ]
    then
        AGAIN=no
    else
        echo 'WARNING: Пароль от админ-панели и FTP не может быть пустым.'
    fi
done
echo '------------------------------------------------------------------'
echo ''
sleep 3
echo '------------------------------------------------------------------'
echo '-----                       ОБНОВЛЕНИЕ                       -----'
echo '------------------------------------------------------------------'
echo ''
apt-get -y -qq update && apt-get -y -qq install debian-keyring debian-archive-keyring wget curl nano htop sudo lsb-release ca-certificates git-core openssl netcat debconf-utils
VER=`lsb_release -cs`
echo "proftpd-basic shared/proftpd/inetd_or_standalone select standalone" | debconf-set-selections
echo ''
echo '------------------------------------------------------------------'
echo '-----                           OK                           -----'
echo '------------------------------------------------------------------'
echo ''
echo '------------------------------------------------------------------'
echo '-----            ПРОПИСЫВАЕМ СПИСОК РЕПОЗИТОРИЕВ             -----'
echo '------------------------------------------------------------------'
echo ''
echo "deb http://httpredir.debian.org/debian ${VER} main contrib non-free \n deb-src http://httpredir.debian.org/debian ${VER} main contrib non-free \n deb http://httpredir.debian.org/debian ${VER}-updates main contrib non-free \n deb-src http://httpredir.debian.org/debian ${VER}-updates main contrib non-free \n deb http://security.debian.org/ ${VER}/updates main contrib non-free \n deb-src http://security.debian.org/ ${VER}/updates main contrib non-free \n deb http://nginx.org/packages/debian/ ${VER} nginx \n deb-src http://nginx.org/packages/debian/ ${VER} nginx \n deb http://mirror.de.leaseweb.net/dotdeb/ ${VER} all \n deb-src http://mirror.de.leaseweb.net/dotdeb/ ${VER} all" > /etc/apt/sources.list
echo ''
echo '------------------------------------------------------------------'
echo '-----                           OK                           -----'
echo '------------------------------------------------------------------'
echo ''
echo '------------------------------------------------------------------'
echo '-----                     ИМПОРТ КЛЮЧЕЙ                      -----'
echo '------------------------------------------------------------------'
echo ''
wget --no-check-certificate http://www.dotdeb.org/dotdeb.gpg; apt-key add dotdeb.gpg; wget --no-check-certificate http://nginx.org/keys/nginx_signing.key; apt-key add nginx_signing.key
rm -rf dotdeb.gpg
rm -rf nginx_signing.key
echo ''
echo '------------------------------------------------------------------'
echo '-----                           OK                           -----'
echo '------------------------------------------------------------------'
echo ''
echo '------------------------------------------------------------------'
echo '-----                        УЛУЧШЕНИЕ                       -----'
echo '------------------------------------------------------------------'
echo ''
apt-get -y -qq update && apt-get -y -qq upgrade
echo ''
echo '------------------------------------------------------------------'
echo '-----                           OK                           -----'
echo '------------------------------------------------------------------'
echo ''
echo '------------------------------------------------------------------'
echo '-----                    УСТАНОВКА ПАКЕТОВ                   -----'
echo '------------------------------------------------------------------'
echo ''
wget -qO- https://deb.nodesource.com/setup_5.x | bash -
apt-get -y install nginx proftpd-basic openssl mysql-client nodejs memcached libltdl7 libodbc1 libpq5 fail2ban
echo ''
echo '------------------------------------------------------------------'
echo '-----                           OK                           -----'
echo '------------------------------------------------------------------'
echo ''
echo '------------------------------------------------------------------'
echo '-----                 ДОБАВЛЕНИЕ ПОЛЬЗОВАТЕЛЯ                -----'
echo '------------------------------------------------------------------'
echo ''
useradd ${DOMAIN} -m -U -s /bin/false
OPENSSL=`echo "${PASSWD}" | openssl passwd -1 -stdin -salt cinemapress`
rm -rf /home/${DOMAIN}/
rm -rf /home/${DOMAIN}/.??*
git clone https://github.com/CinemaPress/CinemaPress-CMS.git /home/${DOMAIN}
chown -R ${DOMAIN}:www-data /home/${DOMAIN}/
echo ''
echo '------------------------------------------------------------------'
echo '-----                           OK                           -----'
echo '------------------------------------------------------------------'
echo ''
echo '------------------------------------------------------------------'
echo '-----                     НАСТРОЙКА NGINX                    -----'
echo '------------------------------------------------------------------'
echo ''
AGAIN=yes
DEFAULT_PORT=33333
BACKUP_PORT=43333
while [ "${AGAIN}" = "yes" ]
do
    DEFAULT_PORT_TEST=`netstat -tunlp | grep ${DEFAULT_PORT}`
    BACKUP_PORT_TEST=`netstat -tunlp | grep ${BACKUP_PORT}`
    if [ "${DEFAULT_PORT_TEST}" = "" ] && [ "${BACKUP_PORT_TEST}" = "" ]
    then
        AGAIN=no
    else
        DEFAULT_PORT=$((DEFAULT_PORT+1))
        BACKUP_PORT=$((BACKUP_PORT+1))
    fi
done
rm -rf /etc/nginx/conf.d/rewrite.conf
mv /home/${DOMAIN}/config/rewrite.conf /etc/nginx/conf.d/rewrite.conf
rm -rf /etc/nginx/conf.d/${DOMAIN}.conf
ln -s /home/${DOMAIN}/config/nginx.conf /etc/nginx/conf.d/${DOMAIN}.conf
sed -i "s/DEFAULT_PORT/${DEFAULT_PORT}/g" /home/${DOMAIN}/config/nginx.conf
sed -i "s/BACKUP_PORT/${BACKUP_PORT}/g" /home/${DOMAIN}/config/nginx.conf
sed -i "s/example\.com/${DOMAIN}/g" /home/${DOMAIN}/config/nginx.conf
sed -i "s/user  nginx;/user  www-data;/g" /etc/nginx/nginx.conf
sed -i "s/server_names_hash_bucket_size 64;//g" /etc/nginx/nginx.conf
sed -i "s/http {/http {\n    server_names_hash_bucket_size 64;/g" /etc/nginx/nginx.conf
sed -i "s/#gzip/gzip/g" /etc/nginx/nginx.conf
echo "${DOMAIN}:$OPENSSL" >> /etc/nginx/nginx_pass
echo ''
echo '------------------------------------------------------------------'
echo '-----                           OK                           -----'
echo '------------------------------------------------------------------'
echo ''
echo '------------------------------------------------------------------'
echo '-----                    НАСТРОЙКА SPHINX                    -----'
echo '------------------------------------------------------------------'
echo ''
I=`dpkg -s sphinxsearch | grep "Status"`
if ! [ -n "${I}" ]
then
    wget --no-check-certificate http://sphinxsearch.com/files/sphinxsearch_2.2.10-release-1~${VER}_amd64.deb -qO s.deb && dpkg -i s.deb && rm -rf s.deb
    rm -rf /etc/sphinxsearch/sphinx.conf
fi
AGAIN=yes
SPHINX_PORT=39312
MYSQL_PORT=29306
while [ "${AGAIN}" = "yes" ]
do
    SPHINX_PORT_TEST=`netstat -tunlp | grep ${SPHINX_PORT}`
    MYSQL_PORT_TEST=`netstat -tunlp | grep ${MYSQL_PORT}`
    if [ "${SPHINX_PORT_TEST}" = "" ] && [ "${MYSQL_PORT_TEST}" = "" ]
    then
        AGAIN=no
    else
        MYSQL_PORT=$((MYSQL_PORT+1))
        SPHINX_PORT=$((SPHINX_PORT+1))
    fi
done
INDEX_DOMAIN=`echo ${DOMAIN} | sed -r "s/[^A-Za-z0-9]/_/g"`
sed -i "s/example\.com/${DOMAIN}/g" /home/${DOMAIN}/config/sphinx.conf
sed -i "s/example_com/${INDEX_DOMAIN}/g" /home/${DOMAIN}/config/sphinx.conf
sed -i "s/:9306/:${MYSQL_PORT}/g" /home/${DOMAIN}/config/sphinx.conf
sed -i "s/:9312/:${SPHINX_PORT}/g" /home/${DOMAIN}/config/sphinx.conf
echo ''
echo '------------------------------------------------------------------'
echo '-----                           OK                           -----'
echo '------------------------------------------------------------------'
echo ''
echo '------------------------------------------------------------------'
echo '-----                    НАСТРОЙКА PROFTPD                   -----'
echo '------------------------------------------------------------------'
echo ''
sed -i "s/AuthUserFile    \/etc\/proftpd\/ftpd\.passwd//g" /etc/proftpd/proftpd.conf
echo 'AuthUserFile    /etc/proftpd/ftpd.passwd' >> /etc/proftpd/proftpd.conf
sed -i "s/\/bin\/false//g" /etc/shells
echo '/bin/false' >> /etc/shells
sed -i "s/# DefaultRoot/DefaultRoot/g" /etc/proftpd/proftpd.conf
USERID=`id -u ${DOMAIN}`
echo ${PASSWD} | ftpasswd --stdin --passwd --file=/etc/proftpd/ftpd.passwd --name=${DOMAIN} --shell=/bin/false --home=/home/${DOMAIN} --uid=${USERID} --gid=${USERID}
echo ''
echo '------------------------------------------------------------------'
echo '-----                           OK                           -----'
echo '------------------------------------------------------------------'
echo ''
echo '------------------------------------------------------------------'
echo '-----                   НАСТРОЙКА MEMCACHED                  -----'
echo '------------------------------------------------------------------'
echo ''
AGAIN=yes
MEMCACHED_PORT=51211
while [ "${AGAIN}" = "yes" ]
do
    MEMCACHED_PORT_TEST=`netstat -tunlp | grep ${MEMCACHED_PORT}`
    if [ "${MEMCACHED_PORT_TEST}" = "" ]
    then
        AGAIN=no
    else
        MEMCACHED_PORT=$((MEMCACHED_PORT+1))
    fi
done
if [ "${VER}" = "jessie" ]
then
    cp /lib/systemd/system/memcached.service /lib/systemd/system/memcached_${DOMAIN}.service
    sed -i "s/memcached\.conf/memcached_${DOMAIN}.conf/g" /lib/systemd/system/memcached_${DOMAIN}.service
    systemctl enable memcached_${DOMAIN}.service
    systemctl start memcached_${DOMAIN}.service
fi
rm -rf /etc/memcached_${DOMAIN}.conf
cp /etc/memcached.conf /etc/memcached_${DOMAIN}.conf
sed -i "s/11211/${MEMCACHED_PORT}/g" /etc/memcached_${DOMAIN}.conf
echo ''
echo '------------------------------------------------------------------'
echo '-----                           OK                           -----'
echo '------------------------------------------------------------------'
echo ''
echo '------------------------------------------------------------------'
echo '-----                  НАСТРОЙКА CINEMAPRESS                 -----'
echo '------------------------------------------------------------------'
echo ''
if [ "${THEME}" != "skeleton" ]
then
    git clone https://github.com/CinemaPress/Theme-${THEME}.git /home/${DOMAIN}/themes/${THEME}
    chown -R ${DOMAIN}:www-data /home/${DOMAIN}/themes
    sed -i "s/\"theme\":\s*\".*\"/\"theme\":\"${THEME}\"/" /home/${DOMAIN}/config/config.js
fi
sed -i "s/example\.com/${DOMAIN}/g" /home/${DOMAIN}/config/config.js
sed -i "s/:11211/:${MEMCACHED_PORT}/" /home/${DOMAIN}/config/config.js
sed -i "s/:9306/:${MYSQL_PORT}/" /home/${DOMAIN}/config/config.js
cp /home/${DOMAIN}/config/config.js /home/${DOMAIN}/config/config.old.js
echo ''
echo '------------------------------------------------------------------'
echo '-----                           OK                           -----'
echo '------------------------------------------------------------------'
echo ''
echo '------------------------------------------------------------------'
echo '-----                  НАСТРОЙКА АВТОЗАПУСКА                 -----'
echo '------------------------------------------------------------------'
echo ''
CRONTAB=`grep ${DOMAIN} /etc/crontab`
if [ "${CRONTAB}" = "" ]
then
    echo "\n" >> /etc/crontab
    echo "# -----" >> /etc/crontab
    echo "# ----- ${DOMAIN} --------------------------------------------" >> /etc/crontab
    echo "# -----" >> /etc/crontab
    echo "@reboot root sleep 20 && searchd --config /home/${DOMAIN}/config/sphinx.conf >> /home/${DOMAIN}/config/autostart.log 2>&1" >> /etc/crontab
    echo "@reboot root sleep 25 && cd /home/${DOMAIN}/ && PORT=${DEFAULT_PORT} forever start --minUptime 1000ms --spinSleepTime 1000ms --append --uid \"${DOMAIN}-default\" --killSignal=SIGTERM -c \"nodemon --delay 2 --exitcrash\" app.js >> /home/${DOMAIN}/config/autostart.log 2>&1" >> /etc/crontab
    echo "@reboot root sleep 30 && cd /home/${DOMAIN}/ && PORT=${BACKUP_PORT} forever start --minUptime 1000ms --spinSleepTime 1000ms --append --uid \"${DOMAIN}-backup\" app.js >> /home/${DOMAIN}/config/autostart.log 2>&1" >> /etc/crontab
    echo "@hourly root forever restart ${DOMAIN}-backup >> /home/${DOMAIN}/config/autostart.log 2>&1" >> /etc/crontab
    echo "# ----- ${DOMAIN} --------------------------------------------" >> /etc/crontab
fi
echo ''
echo '------------------------------------------------------------------'
echo '-----                           OK                           -----'
echo '------------------------------------------------------------------'
echo ''
echo '------------------------------------------------------------------'
echo '-----                    НАСТРОЙКА SYSCTL                    -----'
echo '------------------------------------------------------------------'
echo ''
mv /etc/sysctl.conf /etc/sysctl.old.conf
cp /home/${DOMAIN}/config/sysctl.conf /etc/sysctl.conf
sysctl -p
echo ''
echo '------------------------------------------------------------------'
echo '-----                           OK                           -----'
echo '------------------------------------------------------------------'
echo ''
echo '------------------------------------------------------------------'
echo '-----                   НАСТРОЙКА FAIL2BAN                   -----'
echo '------------------------------------------------------------------'
echo ''
rm -rf /etc/fail2ban/jail.local
cp /home/${DOMAIN}/config/jail.conf /etc/fail2ban/jail.local
echo ''
echo '------------------------------------------------------------------'
echo '-----                           OK                           -----'
echo '------------------------------------------------------------------'
echo ''
echo '------------------------------------------------------------------'
echo '-----                   ПЕРЕЗАПУСК ПАКЕТОВ                   -----'
echo '------------------------------------------------------------------'
echo ''
service nginx restart
service proftpd restart
service memcached restart
echo ''
echo '------------------------------------------------------------------'
echo '-----                           OK                           -----'
echo '------------------------------------------------------------------'
echo ''
echo '------------------------------------------------------------------'
echo '-----                  УСТАНОВКА ЗАВИСИМОСТЕЙ                -----'
echo '------------------------------------------------------------------'
echo ''
cd /home/${DOMAIN}/
npm install --loglevel=silent --parseable
npm install --loglevel=silent --parseable forever -g
npm install --loglevel=silent --parseable nodemon -g
indexer --all --config "/home/${DOMAIN}/config/sphinx.conf" || indexer --all --rotate --config "/home/${DOMAIN}/config/sphinx.conf"
echo ''
echo '------------------------------------------------------------------'
echo '-----                           OK                           -----'
echo '------------------------------------------------------------------'
echo ''
echo '------------------------------------------------------------------'
echo '------------------------------------------------------------------'
echo '-----                                                        -----'
echo '-----          УРА! CinemaPress CMS готова к работе!         -----'
echo '-----      Чтобы все заработало, требуется перезагрузка.     -----'
echo '-----        Сервер будет перезагружен через 10 сек ...      -----'
echo '-----                                                        -----'
echo '------------------------------------------------------------------'
echo '------------------------------------------------------------------'
echo '-----                                                        -----'
echo '!!!!!      Нажмите CTRL+C ^C чтобы отменить перезагрузку     !!!!!'
echo '-----                                                        -----'
echo '------------------------------------------------------------------'
echo '------------------------------------------------------------------'
echo ''
sleep 10
reboot