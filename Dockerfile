FROM php:8.2-apache

# FIX 1: Prevent "xz: Failed to enable the sandbox" error on AlmaLinux/Podman
ENV XZ_DEFAULTS="--no-sandbox"

# 2. Install system dependencies
# FIX 2: Added libjpeg62-turbo-dev and libfreetype6-dev (REQUIRED for gd)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev

# 3. Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# 4. Configure GD (Now this will work because libraries are installed)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg

# 5. Install Extensions in batches
RUN docker-php-ext-install -j$(nproc) pdo_mysql mbstring exif pcntl bcmath
RUN docker-php-ext-install -j$(nproc) gd
RUN docker-php-ext-install -j$(nproc) zip

# 6. Enable Apache Rewrite Module
RUN a2enmod rewrite

# 7. Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 8. Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install -y nodejs

# 9. Configure Apache
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf

# 10. Copy Code
WORKDIR /var/www/html
COPY . /var/www/html

# 11. Install Dependencies
RUN composer install --no-interaction --prefer-dist --optimize-autoloader
RUN npm install && npm run prod

# 12. Fix Permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache