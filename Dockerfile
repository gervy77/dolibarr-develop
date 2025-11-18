# Multi-stage build pour optimiser la taille de l'image
# Stage 1: Build stage (si nécessaire pour composer)
FROM php:8.1-fpm-alpine AS builder

# Installer les dépendances nécessaires
RUN apk add --no-cache \
    git \
    unzip \
    curl \
    && rm -rf /var/cache/apk/*

# Installer les extensions PHP nécessaires
RUN apk add --no-cache \
    mysql-client \
    postgresql-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libzip-dev \
    icu-dev \
    libxml2-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    mysqli \
    pgsql \
    pdo_mysql \
    pdo_pgsql \
    gd \
    zip \
    intl \
    soap \
    opcache \
    && rm -rf /var/cache/apk/*

# Stage 2: Production stage
FROM php:8.1-fpm-alpine

# Installer les dépendances système minimales
RUN apk add --no-cache \
    mysql-client \
    postgresql-libs \
    libpng \
    libjpeg-turbo \
    freetype \
    libzip \
    icu-libs \
    libxml2 \
    nginx \
    supervisor \
    tzdata \
    wget \
    && rm -rf /var/cache/apk/*

# Installer les extensions PHP (copiées depuis le stage builder ou réinstallées)
RUN apk add --no-cache --virtual .build-deps \
    postgresql-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libzip-dev \
    icu-dev \
    libxml2-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    mysqli \
    pgsql \
    pdo_mysql \
    pdo_pgsql \
    gd \
    zip \
    intl \
    soap \
    opcache \
    && apk del .build-deps \
    && rm -rf /var/cache/apk/*

# Configuration OPcache pour la production
RUN echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
    && echo "opcache.memory_consumption=128" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
    && echo "opcache.interned_strings_buffer=8" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
    && echo "opcache.max_accelerated_files=4000" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
    && echo "opcache.revalidate_freq=60" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
    && echo "opcache.fast_shutdown=1" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini

# Configuration PHP sécurisée
RUN echo "upload_max_filesize=20M" >> /usr/local/etc/php/conf.d/dolibarr.ini \
    && echo "post_max_size=20M" >> /usr/local/etc/php/conf.d/dolibarr.ini \
    && echo "memory_limit=256M" >> /usr/local/etc/php/conf.d/dolibarr.ini \
    && echo "expose_php=Off" >> /usr/local/etc/php/conf.d/dolibarr.ini \
    && echo "display_errors=Off" >> /usr/local/etc/php/conf.d/dolibarr.ini \
    && echo "display_startup_errors=Off" >> /usr/local/etc/php/conf.d/dolibarr.ini \
    && echo "log_errors=On" >> /usr/local/etc/php/conf.d/dolibarr.ini \
    && echo "error_log=/var/log/php_errors.log" >> /usr/local/etc/php/conf.d/dolibarr.ini

# Créer un utilisateur non-root pour exécuter PHP-FPM
RUN addgroup -g 1000 dolibarr \
    && adduser -D -u 1000 -G dolibarr dolibarr

# Créer les répertoires nécessaires
RUN mkdir -p /var/www/html \
    /var/www/documents \
    /var/log/nginx \
    /var/log/php \
    /run/nginx \
    && chown -R dolibarr:dolibarr /var/www/html \
    /var/www/documents \
    /var/log/nginx \
    /var/log/php

# Copier l'application
COPY --chown=dolibarr:dolibarr htdocs/ /var/www/html/

# Configuration Nginx
COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY docker/nginx/default.conf /etc/nginx/http.d/default.conf
RUN mkdir -p /run/nginx /var/lib/nginx/tmp/client_body /var/lib/nginx/tmp/proxy /var/lib/nginx/tmp/fastcgi /var/lib/nginx/tmp/uwsgi /var/lib/nginx/tmp/scgi && \
    chown -R dolibarr:dolibarr /run/nginx /var/log/nginx /var/lib/nginx

# Configuration PHP-FPM pour écouter sur TCP (plus simple pour les permissions)
RUN sed -i 's/user = www-data/user = dolibarr/' /usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's/group = www-data/group = dolibarr/' /usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's/listen = 127.0.0.1:9000/listen = 127.0.0.1:9000/' /usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's|^error_log = .*|error_log = /proc/self/fd/2|' /usr/local/etc/php-fpm.d/www.conf \
    && echo "php_admin_flag[log_errors] = on" >> /usr/local/etc/php-fpm.d/www.conf

# Configuration Supervisor pour gérer Nginx et PHP-FPM
COPY docker/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Script d'entrypoint
COPY docker/scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Définir les permissions appropriées pour les fichiers sensibles
RUN chmod 755 /var/www/html \
    && chmod 755 /var/www/documents

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

# Exposer le port 80
EXPOSE 80

# Définir le répertoire de travail
WORKDIR /var/www/html

# Point d'entrée (supervisord doit être exécuté en root)
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

