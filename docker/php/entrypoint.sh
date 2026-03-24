#!/usr/bin/env sh
set -e
if [ ! -f .env ] && [ -f .env.example ]; then cp .env.example .env; fi
php artisan key:generate --force --no-interaction || true
php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true
exec "$@"
