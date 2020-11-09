FROM ubuntu:18.04

# https://developers.google.com/speed/pagespeed/module/build_ngx_pagespeed_from_source
# PAGESPEED Version
ENV NPS_VERSION 1.13.35.2-stable
# http://nginx.org/en/download.html
# Nginx Version
ENV NGINX_VERSION 1.18.0
#PHP Reposiotry
ENV PHP_VERSION_REPO 'ondrej/php'
# https://github.com/openresty/echo-nginx-module/releases
#Echo Module
ENV ECHO_MODULE 0.62
# https://github.com/openresty/headers-more-nginx-module/releases
#More Headers
ENV MORE_HEADERS 0.33
#https://ftp.pcre.org/pub/pcre/
#target for gz file not version 2
ENV PCRE_VERSION 8.44
#https://www.zlib.net/
# zlib version 1.1.3 - 1.2.11
ENV ZLIB_VERSION 1.2.11
#https://github.com/openssl/openssl/releases
ENV OPENSSL_VERSION 1.1.1

RUN apt-get -y update

RUN apt-get install -y apt-utils
RUN apt-get install -y zlib1g-dev libpcre3 libpcre3-dev unzip libxml2 libgd-dev libgeoip1 libgeoip-dev libperl-dev libxslt1-dev uuid-dev
RUN apt-get install -y libssl-dev libxml2-dev libxslt-dev
RUN apt-get install -y git-core nano curl zsh wget
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

WORKDIR /

# PAGESPEED
RUN wget https://github.com/apache/incubator-pagespeed-ngx/archive/v${NPS_VERSION}.zip && unzip v${NPS_VERSION}.zip && nps_dir=$(find . -name "*pagespeed-ngx-${NPS_VERSION}" -type d) && cd "$nps_dir" && psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz && [ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL) && wget -O- ${psol_url} | tar -xz

# Echo Module
RUN wget https://github.com/openresty/echo-nginx-module/archive/v${ECHO_MODULE}.tar.gz && tar xzvf v${ECHO_MODULE}.tar.gz

# MORE HEADERS
RUN wget https://github.com/openresty/headers-more-nginx-module/archive/v${MORE_HEADERS}.tar.gz && tar xzvf v${MORE_HEADERS}.tar.gz

RUN apt-get install build-essential -y

# pcre
RUN wget https://ftp.pcre.org/pub/pcre/pcre-${PCRE_VERSION}.tar.gz && tar xzvf pcre-${PCRE_VERSION}.tar.gz

# zlib
RUN wget http://www.zlib.net/zlib-${ZLIB_VERSION}.tar.gz && tar xzvf zlib-${ZLIB_VERSION}.tar.gz

# openssl
RUN wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz && tar xzvf openssl-${OPENSSL_VERSION}.tar.gz

RUN mkdir -p /etc/nginx/ && wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && tar -xvzf nginx-${NGINX_VERSION}.tar.gz

RUN nps_dir=$(find . -name "*pagespeed-ngx-${NPS_VERSION}" -type d) && cd nginx-${NGINX_VERSION}/ && ./configure --add-module=/$nps_dir ${PS_NGX_EXTRA_FLAGS} --add-module=/headers-more-nginx-module-${MORE_HEADERS}  --add-module=/echo-nginx-module-${ECHO_MODULE}  --prefix=/usr/share/nginx  --sbin-path=/usr/sbin/nginx  --modules-path=/usr/lib/nginx/modules  --conf-path=/etc/nginx/nginx.conf  --error-log-path=/var/log/nginx/error.log  --http-log-path=/var/log/nginx/access.log  --pid-path=/run/nginx.pid  --lock-path=/var/lock/nginx.lock  --user=www-data  --group=www-data  --build=Ubuntu  --http-client-body-temp-path=/var/lib/nginx/body  --http-fastcgi-temp-path=/var/lib/nginx/fastcgi  --http-proxy-temp-path=/var/lib/nginx/proxy  --http-scgi-temp-path=/var/lib/nginx/scgi  --http-uwsgi-temp-path=/var/lib/nginx/uwsgi  --with-openssl=../openssl-${OPENSSL_VERSION}  --with-openssl-opt=enable-ec_nistp_64_gcc_128  --with-openssl-opt=no-nextprotoneg  --with-openssl-opt=no-weak-ssl-ciphers  --with-openssl-opt=no-ssl3  --with-pcre=../pcre-${PCRE_VERSION}  --with-pcre-jit  --with-zlib=../zlib-${ZLIB_VERSION}  --with-compat  --with-file-aio  --with-threads  --with-http_addition_module  --with-http_auth_request_module  --with-http_dav_module  --with-http_flv_module  --with-http_gunzip_module  --with-http_geoip_module  --with-http_image_filter_module  --with-http_perl_module  --with-http_gzip_static_module  --with-http_mp4_module  --with-http_random_index_module  --with-http_realip_module  --with-http_slice_module  --with-http_ssl_module  --with-http_sub_module  --with-http_xslt_module  --with-http_stub_status_module  --with-http_v2_module  --with-http_secure_link_module  --with-mail  --with-ipv6  --with-mail_ssl_module  --with-stream  --with-stream_realip_module  --with-stream_ssl_module  --with-stream_ssl_preread_module && make && make install

RUN rm -rf *.tar.gz *.zip nginx-*/ openssl-1.1.0f/ pcre-*/ zlib-*/ incubator-pagespeed-ngx-*/ headers-more-nginx-module-*/ echo-nginx-module-*/

RUN mkdir -p /var/lib/nginx && nginx -T

RUN mkdir -p /etc/nginx/sites-available && mkdir -p /etc/nginx/sites-enabled

RUN apt-get install software-properties-common -y && add-apt-repository -y ppa:$PHP_VERSION_REPO && apt-get update

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -y install tzdata

RUN apt-get -y install php7.1 mcrypt php7.1-mcrypt php-mbstring php-pear php7.1-dev php7.1-xml php-mysql imagemagick php-imagick php7.1-fpm php7.1-opcache
RUN apt-get -y install php7.1-bz2 php7.1-curl php7.1-gd php7.1-imap php7.1-intl php7.1-json php7.1-mbstring php7.1-mysql php7.1-pgsql php7.1-sqlite3 php7.1-xmlrpc php7.1-xsl php7.1-zip php7.1-cli php7.1-common php7.1-cgi && sed -i "s/;listen.mode = 0660/listen.mode = 0660/g" /etc/php\/7.1/fpm/pool.d/www.conf
RUN apt-get -y install mysql-server
RUN service mysql start
RUN apt-get install -y libfontenc1 xfonts-75dpi php7.1-mbstring php7.1-dom php-gettext php7.1-tidy php-bcmath php-zip liblcms2-dev libpng-dev gcc make re2c xfonts-base
RUN apt-get install -y xfonts-encodings xfonts-utils openssl beanstalkd libxrender-dev libx11-dev libxext-dev libfontconfig1-dev postfix libsasl2-modules libfreetype6-dev fontconfig autoconf libc-dev pkg-config libyaml-dev mailutils python3-pip libffi-dev python3-dev

RUN wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.bionic_amd64.deb && dpkg -i wkhtmltox_0.12.5-1.bionic_amd64.deb && apt --fix-broken install

RUN git clone https://github.com/jbboehr/php-psr.git && cd php-psr && phpize && ./configure && make && make test && make install && echo 'extension = psr.so' > /etc/php/7.1/mods-available/psr.ini && ln -s /etc/php/7.1/mods-available/psr.ini /etc/php/7.1/fpm/conf.d/20-psr.ini && ln -s /etc/php/7.1/mods-available/psr.ini /etc/php/7.1/cli/conf.d/20-psr.ini && ln -s /etc/php/7.1/mods-available/psr.ini /etc/php/7.1/cgi/conf.d/20-psr.ini

RUN service php7.1-fpm start

RUN service php7.1-fpm restart

#RUN curl -s "https://packagecloud.io/install/repositories/phalcon/stable/script.deb.sh" | bash

#apt-cache policy php7.4-phalcon for latest version
#apt-cache policy php7.3-phalcon for version 3

#RUN apt-get install php7.1-phalcon=3.4.5-1+php7.1 -y

RUN git clone https://github.com/phalcon/cphalcon.git && cd cphalcon && git checkout 3.4.x && curl -o phalcon/mvc/model/query.zep https://gist.githubusercontent.com/Rajeshr34/e933e7c8675c7304eca250b79a105e60/raw/5b57d383f6691ada23955531a2d8292f92815f60/Query.zep && cd build && ./install

RUN echo '[phalcon]\nextension = phalcon.so\nphalcon.orm.cast_on_hydrate = On\nphalcon.orm.column_renaming = On\nphalcon.orm.ignore_unknown_columns = On\nphalcon.orm.update_snapshot_on_save = On' > /etc/php/7.1/mods-available/phalcon.ini

RUN ln -s /etc/php/7.1/mods-available/phalcon.ini /etc/php/7.1/fpm/conf.d/20-phalcon.ini
RUN ln -s /etc/php/7.1/mods-available/phalcon.ini /etc/php/7.1/cli/conf.d/20-phalcon.ini
RUN ln -s /etc/php/7.1/mods-available/phalcon.ini /etc/php/7.1/cgi/conf.d/20-phalcon.ini

RUN /etc/init.d/php7.1-fpm restart && apt-get remove php7.4-cli -y

RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

RUN git clone https://github.com/phalcon/phalcon-devtools.git && cd phalcon-devtools && git checkout 3.4.x && ln -s $(pwd)/phalcon /usr/local/bin/phalcon && chmod ugo+x /usr/local/bin/phalcon && composer install

RUN wget https://files.phpmyadmin.net/phpMyAdmin/4.9.7/phpMyAdmin-4.9.7-english.zip && unzip phpMyAdmin-4.9.7-english.zip

RUN echo "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '123';\nDELETE FROM mysql.user WHERE User='';\nDELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');\nDROP DATABASE IF EXISTS test;\nDELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';\nFLUSH PRIVILEGES;" > mysql.sql && /etc/init.d/mysql restart && mysql -sfu root < mysql.sql

RUN sed -i 's/upload_max_filesize\s*=.*/upload_max_filesize=1024M/g' /etc/php/7.1/fpm/php.ini
RUN sed -i 's/post_max_size\s*=.*/post_max_size=1024M/g' /etc/php/7.1/fpm/php.ini
RUN sed -i 's/max_input_time\s*=.*/max_input_time=24000/g' /etc/php/7.1/fpm/php.ini
RUN sed -i 's/max_execution_time\s*=.*/max_execution_time=24000/g' /etc/php/7.1/fpm/php.ini
RUN sed -i 's/memory_limit\s*=.*/memory_limit=12000M/g' /etc/php/7.1/fpm/php.ini
RUN sed -i 's/display_errors\s*=.*/display_errors=On/g' /etc/php/7.1/fpm/php.ini

RUN echo '[mysqld]\nsql_mode = STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' > /etc/mysql/conf.d/strict.cnf

CMD /etc/init.d/mysql restart && /etc/init.d/php7.1-fpm restart && nginx -g "daemon off;"
