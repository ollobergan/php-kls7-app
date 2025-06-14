FROM php:8.2-cli

# System dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libaio1 \
    wget \
    alien \
    libaio-dev \
    gnupg \
    supervisor \
    procps \
    libbrotli-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    pkg-config

# Node.js va NPM o'rnatish
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Oracle instantclient
RUN mkdir -p /opt/oracle
WORKDIR /opt/oracle

# Oracle instantclient paketlarini yuklab olish va o'rnatish
RUN wget https://download.oracle.com/otn_software/linux/instantclient/219000/oracle-instantclient-basic-21.9.0.0.0-1.el8.x86_64.rpm && \
    wget https://download.oracle.com/otn_software/linux/instantclient/219000/oracle-instantclient-devel-21.9.0.0.0-1.el8.x86_64.rpm && \
    wget https://download.oracle.com/otn_software/linux/instantclient/219000/oracle-instantclient-sqlplus-21.9.0.0.0-1.el8.x86_64.rpm && \
    alien -i oracle-instantclient-basic-21.9.0.0.0-1.el8.x86_64.rpm && \
    alien -i oracle-instantclient-devel-21.9.0.0.0-1.el8.x86_64.rpm && \
    alien -i oracle-instantclient-sqlplus-21.9.0.0.0-1.el8.x86_64.rpm

# Oracle instantclient konfiguratsiyasi
RUN echo /usr/lib/oracle/21/client64/lib > /etc/ld.so.conf.d/oracle-instantclient.conf && \
    ldconfig

# PHP kengaytmalarini o'rnatish
RUN pecl install redis && \
    docker-php-ext-enable redis

# Oracle kengaytmalarini alohida o'rnatish
RUN docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/usr/lib/oracle/21/client64/lib && \
    docker-php-ext-configure oci8 --with-oci8=instantclient,/usr/lib/oracle/21/client64/lib && \
    docker-php-ext-install pdo_oci oci8

# Boshqa kengaytmalarni o'rnatish
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd sockets

RUN pecl install swoole --enable-brotli=no && docker-php-ext-enable swoole

# PHP optimization - PHP ishlashini tezlashtirish uchun
RUN echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.memory_consumption=256" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.interned_strings_buffer=16" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.max_accelerated_files=16229" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.validate_timestamps=0" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "realpath_cache_size=4096K" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "realpath_cache_ttl=600" >> /usr/local/etc/php/conf.d/opcache.ini

# Composer o'rnatish
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Supervisor configuratsiyasi
RUN mkdir -p /etc/supervisor/conf.d/
RUN mkdir -p /var/log/supervisor/

# Application directory
WORKDIR /var/www/html

# Foydalanuvchi huquqlarini o'zgartirish
RUN chown -R www-data:www-data /var/www/html


EXPOSE 8000

#COPY ./html /var/www/html
#COPY ./supervisord.conf /etc/supervisor/supervisord.conf

#CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"] 