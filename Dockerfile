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
RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true

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

RUN apt-get -y install php7.4 mcrypt php7.1-mcrypt php-mbstring php-pear php7.4-dev php7.4-xml php-mysql imagemagick php-imagick php7.4-fpm php7.4-opcache
RUN apt-get -y install php7.4-bz2 php7.4-curl php7.4-gd php7.4-imap php7.4-intl php7.4-json php7.4-mbstring php7.4-mysql php7.4-pgsql php7.4-sqlite3 php7.4-xmlrpc php7.4-xsl php7.4-zip php7.4-cli php7.4-common php7.4-cgi && sed -i "s/;listen.mode = 0660/listen.mode = 0660/g" /etc/php\/7.4/fpm/pool.d/www.conf
RUN apt-get -y install mysql-server
RUN service mysql start
RUN apt-get install -y libfontenc1 xfonts-75dpi php7.4-mbstring php7.4-dom php-gettext php7.4-tidy php-bcmath php-zip liblcms2-dev libpng-dev gcc make re2c xfonts-base
RUN apt-get install -y xfonts-encodings xfonts-utils openssl beanstalkd libxrender-dev libx11-dev libxext-dev libfontconfig1-dev postfix libsasl2-modules libfreetype6-dev fontconfig autoconf libc-dev pkg-config libyaml-dev mailutils python3-pip libffi-dev python3-dev

RUN wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.bionic_amd64.deb && dpkg -i wkhtmltox_0.12.5-1.bionic_amd64.deb && apt --fix-broken install

RUN git clone https://github.com/jbboehr/php-psr.git && cd php-psr && phpize && ./configure && make && make test && make install && echo 'extension = psr.so' > /etc/php/7.4/mods-available/psr.ini && ln -s /etc/php/7.4/mods-available/psr.ini /etc/php/7.4/fpm/conf.d/20-psr.ini && ln -s /etc/php/7.4/mods-available/psr.ini /etc/php/7.4/cli/conf.d/20-psr.ini && ln -s /etc/php/7.4/mods-available/psr.ini /etc/php/7.4/cgi/conf.d/20-psr.ini

RUN service php7.4-fpm start

RUN service php7.4-fpm restart

RUN curl -s "https://packagecloud.io/install/repositories/phalcon/stable/script.deb.sh" | bash

RUN apt-get install php7.4-phalcon -y

RUN wget https://github.com/phalcon/phalcon-devtools/releases/download/v4.0.3/phalcon.phar && chmod +x phalcon.phar && mv phalcon.phar /usr/local/bin/phalcon

CMD /etc/init.d/mysql restart && /etc/init.d/php7.4-fpm restart && nginx -g "daemon off;"
