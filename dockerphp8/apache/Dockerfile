FROM php:8.3-apache

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       wget \
       git \
       unzip \
       zip \
       nano \
       libzip-dev \
       libpng-dev \
       libjpeg62-turbo-dev \
       libfreetype6-dev \
       libicu-dev \
       libxml2-dev \
       libonig-dev \
       libcurl4-openssl-dev \
       zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
       pdo pdo_mysql mysqli \
       mbstring \
       zip \
       exif \
       pcntl \
       bcmath \
       intl \
       opcache \
       soap \
       xml \
       curl \
       gd

RUN a2enmod rewrite


# Set Apache DocumentRoot to /var/www/src
RUN mkdir -p /var/www/src \
    && sed -ri 's!DocumentRoot /var/www/html!DocumentRoot /var/www/src/html!g' /etc/apache2/sites-available/000-default.conf \
    && sed -ri "s!<Directory /var/www/>!<Directory /var/www/src/html>!g" /etc/apache2/apache2.conf || true

# Install Composer (from official composer image)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/src

RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

CMD ["apache2-foreground"]
