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

RUN php artisan route:cache && \
    php artisan view:cache

FROM node:20-alpine AS asset_builder

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm install

COPY vite.config.js ./
COPY resources ./resources

RUN npm run build

FROM php:8.4-fpm-alpine

WORKDIR /var/www

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
