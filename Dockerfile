FROM ubuntu:latest
MAINTAINER Petter A. Helset <petter@helset.eu>

# setup workdir
RUN mkdir /data
WORKDIR /data

# environment for osticket and apt
ENV OSTICKET_VERSION 1.9.4
ENV DEBIAN_FRONTEND noninteractive
ENV HOME /data

# requirements
RUN apt-get update && apt-get -y install \
  wget \
  unzip \
  supervisor \
  nginx \
  php5-fpm \
  php5-imap \
  php5-gd \
  php5-mysql && \
  rm -rf /var/lib/apt/lists/*

# osticket
RUN wget -O osTicket.zip http://osticket.com/sites/default/files/download/osTicket-v${OSTICKET_VERSION}.zip
RUN unzip osTicket.zip
RUN mv /data/upload/include/ost-sampleconfig.php /data/upload/include/ost-config.php
RUN chown www-data:www-data -R /data/upload/

# nginx config
RUN sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf
RUN sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# php-fpm config
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf
RUN sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php5/fpm/pool.d/www.conf
RUN php5enmod imap

# add nginx virtualhost
ADD virtualhost /etc/nginx/sites-available/default
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 80
CMD ["/usr/bin/supervisord"]
