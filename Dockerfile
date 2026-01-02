FROM ubuntu:22.04

# 1. Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# 2. Update and Install Basic Tools
RUN apt-get update && apt-get install -y \
    software-properties-common \
    curl \
    git \
    zip \
    unzip \
    nano

# 3. Add PHP Repository (ppa:ondrej/php) to get PHP 8.2
RUN add-apt-repository ppa:ondrej/php -y && apt-get update

# 4. Install Apache and PHP 8.2 with all required extensions
RUN apt-get install -y \
    apache2 \
    php8.2 \
    php8.2-cli \
    php8.2-common \
    php8.2-mysql \
    php8.2-zip \
    php8.2-gd \
    php8.2-mbstring \
    php8.2-curl \
    php8.2-xml \
    php8.2-bcmath \
    libapache2-mod-php8.2

# 5. Enable Apache Rewrite Module
RUN a2enmod rewrite

# 6. Install Node.js 18.x (Updated from 16)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# 7. Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# 8. Configure Apache DocumentRoot
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/000-default.conf
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf

# 9. Set Working Directory and Copy Code
WORKDIR /var/www/html
COPY . /var/www/html

# 10. Install Project Dependencies
RUN composer install --no-interaction --prefer-dist --optimize-autoloader
RUN npm install && npm run build

# 11. Fix Permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# 12. Expose Port and Start Apache in Foreground
EXPOSE 80
CMD ["apachectl", "-D", "FOREGROUND"]