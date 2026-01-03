FROM php:8.4.1

# System deps
RUN apt-get update -y && apt-get install -y \
    openssl zip unzip git curl ca-certificates gnupg

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- \
    --install-dir=/usr/local/bin \
    --filename=composer

# PHP extensions
RUN apt-get update && apt-get install -y libpq-dev
RUN docker-php-ext-install pdo pdo_pgsql

# Install Node.js 24
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs

# Verify installs (optional but useful for debugging)


WORKDIR /app
COPY . .


RUN composer install
RUN npm i && npm run build


EXPOSE 8000
CMD php artisan serve --host=0.0.0.0 --port=8000
