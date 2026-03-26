# ---------- Stage 1: Composer ----------
FROM composer:2 AS composer-deps
WORKDIR /app

# copy only if exists (safe)
COPY composer.json composer.lock* ./

RUN if [ -f composer.json ]; then \
    composer install --no-dev --no-interaction --no-scripts --prefer-dist --optimize-autoloader; \
    fi

# ---------- Stage 2: Frontend ----------
FROM node:20-alpine AS frontend-builder
WORKDIR /app

# copy full project (safe for any structure)
COPY . .

# install dependencies if present
RUN if [ -f package.json ]; then npm install; fi

# build frontend if config exists
RUN if [ -f vite.config.js ] || [ -f vite.config.ts ]; then npm run build; fi

# ---------- Stage 3: Runtime ----------
FROM php:8.3-fpm-alpine AS runtime

RUN apk add --no-cache bash curl icu-dev libpng-dev libjpeg-turbo-dev freetype-dev libzip-dev oniguruma-dev zip unzip shadow \
  && docker-php-ext-configure gd --with-freetype --with-jpeg \
  && docker-php-ext-install -j"$(nproc)" pdo_mysql mbstring intl gd zip opcache \
  && rm -rf /tmp/* /var/cache/apk/*

# create user
RUN addgroup -S laravel && adduser -S laravel -G laravel

WORKDIR /var/www/html

# copy full app
COPY --chown=laravel:laravel . .

# copy vendor if installed
COPY --from=composer-deps --chown=laravel:laravel /app/vendor ./vendor

# copy frontend build if exists
COPY --from=frontend-builder --chown=laravel:laravel /app/public/build ./public/build

# optional configs (ignore if not present)
COPY docker/php/php.ini /usr/local/etc/php/conf.d/zz-app.ini || true
COPY docker/php/entrypoint.sh /usr/local/bin/entrypoint.sh || true

# permissions
RUN chmod +x /usr/local/bin/entrypoint.sh 2>/dev/null || true \
  && mkdir -p storage bootstrap/cache 2>/dev/null || true \
  && chown -R laravel:laravel storage bootstrap/cache 2>/dev/null || true

USER laravel

EXPOSE 9000

ENTRYPOINT ["sh", "-c", "if [ -f /usr/local/bin/entrypoint.sh ]; then entrypoint.sh; else php-fpm -F; fi"]