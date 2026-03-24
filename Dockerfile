
FROM composer:2 AS composer-deps
WORKDIR /app
COPY laravel/composer.json laravel/composer.lock ./
RUN composer install --no-dev --no-interaction --no-scripts --prefer-dist --optimize-autoloader

FROM node:20-alpine AS frontend-builder
WORKDIR /app
COPY laravel/package*.json ./
RUN if [ -f package.json ]; then npm install; fi
COPY laravel/resources ./resources
COPY laravel/vite.config.* ./
RUN if [ -f package.json ]; then npm run build; fi

FROM php:8.3-fpm-alpine AS runtime
RUN apk add --no-cache bash curl icu-dev libpng-dev libjpeg-turbo-dev freetype-dev libzip-dev oniguruma-dev zip unzip shadow \
  && docker-php-ext-configure gd --with-freetype --with-jpeg \
  && docker-php-ext-install -j"$(nproc)" pdo_mysql mbstring intl gd zip opcache \
  && rm -rf /tmp/* /var/cache/apk/*

RUN addgroup -S laravel && adduser -S laravel -G laravel
WORKDIR /var/www/html

# ✅ FIXED: copy Laravel app correctly
COPY --chown=laravel:laravel laravel/ .

COPY --from=composer-deps --chown=laravel:laravel /app/vendor ./vendor
COPY --from=frontend-builder --chown=laravel:laravel /app/public/build ./public/build

COPY docker/php/php.ini /usr/local/etc/php/conf.d/zz-app.ini
COPY docker/php/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh \
  && mkdir -p storage bootstrap/cache \
  && chown -R laravel:laravel storage bootstrap/cache

USER laravel
EXPOSE 9000
ENTRYPOINT ["entrypoint.sh"]
CMD ["php-fpm", "-F"]