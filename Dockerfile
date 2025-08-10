FROM php:8.4-fpm AS builder

WORKDIR /var/www

RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY composer.json composer.lock ./

RUN composer install --no-interaction --no-scripts --no-dev --optimize-autoloader

COPY . .

FROM node:20-alpine AS asset_builder

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm install

COPY vite.config.js ./
COPY resources ./resources

RUN npm run build

FROM php:8.4-fpm-alpine

ARG UID=1000
ARG GID=1000

WORKDIR /var/www

RUN deluser www-data && \
    if [ $(getent group $GID) ]; then groupdel $(getent group $GID | cut -d: -f1); fi && \
    addgroup -g $GID www-data && \
    adduser -D -u $UID -G www-data -s /bin/sh www-data

RUN apk add --no-cache --update \
    $PHPIZE_DEPS \
    libzip-dev \
    oniguruma-dev \
    libexif-dev \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath zip \
    && apk del $PHPIZE_DEPS

COPY --from=builder /var/www .

RUN chown -R www-data:www-data storage bootstrap/cache

COPY --from=asset_builder /app/public/build public/build

RUN chown -R www-data:www-data public/build

EXPOSE 9000

CMD ["php-fpm"]
