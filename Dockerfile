FROM php:8.2-apache

# 1. Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev

# 2. Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. Install PHP extensions required by Laravel
RUN docker-php-ext-configure gd --with-freetype --with-jpeg

# 4. Install Extensions in batches to prevent Out-Of-Memory errors
RUN docker-php-ext-install -j\$(nproc) pdo_mysql mbstring exif pcntl bcmath
RUN docker-php-ext-install -j\$(nproc) gd
RUN docker-php-ext-install -j\$(nproc) zip

# 4. Enable Apache Rewrite Module (for Laravel routes)
RUN a2enmod rewrite

# 5. Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 6. Install Node.js (for npm run prod)
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install -y nodejs

# 7. Set Working Directory
WORKDIR /var/www/html

# 8. Configure Apache DocumentRoot to point to /public
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf

# 9. Copy Application Code
COPY . /var/www/html

# 10. Install Dependencies
RUN composer install --no-interaction --prefer-dist --optimize-autoloader
RUN npm install && npm run prod

# 11. Fix Permissions (Make storage writable)
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache