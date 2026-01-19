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

RUN a2enmod rewrite headers ssl


# Set Apache DocumentRoot to /var/www/src
RUN mkdir -p /var/www/src \
    && sed -ri 's!DocumentRoot /var/www/html!DocumentRoot /var/www/src/html!g' /etc/apache2/sites-available/000-default.conf \
    && sed -ri "s!<Directory /var/www/>!<Directory /var/www/src/html>!g" /etc/apache2/apache2.conf || true

# Create Apache security headers configuration
RUN echo '<IfModule mod_headers.c>' > /etc/apache2/conf-available/security-headers.conf && \
    echo '  # Prevent MIME type sniffing' >> /etc/apache2/conf-available/security-headers.conf && \
    echo '  Header always set X-Content-Type-Options "nosniff"' >> /etc/apache2/conf-available/security-headers.conf && \
    echo '  # Enable XSS protection' >> /etc/apache2/conf-available/security-headers.conf && \
    echo '  Header always set X-XSS-Protection "1; mode=block"' >> /etc/apache2/conf-available/security-headers.conf && \
    echo '  # Clickjacking protection' >> /etc/apache2/conf-available/security-headers.conf && \
    echo '  Header always set X-Frame-Options "SAMEORIGIN"' >> /etc/apache2/conf-available/security-headers.conf && \
    echo '  # Content Security Policy' >> /etc/apache2/conf-available/security-headers.conf && \
    echo "  Header always set Content-Security-Policy \"default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'\"" >> /etc/apache2/conf-available/security-headers.conf && \
    echo '  # Referrer Policy' >> /etc/apache2/conf-available/security-headers.conf && \
    echo '  Header always set Referrer-Policy "strict-origin-when-cross-origin"' >> /etc/apache2/conf-available/security-headers.conf && \
    echo '  # Feature Policy / Permissions Policy' >> /etc/apache2/conf-available/security-headers.conf && \
    echo '  Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"' >> /etc/apache2/conf-available/security-headers.conf && \
    echo '</IfModule>' >> /etc/apache2/conf-available/security-headers.conf && \
    a2enconf security-headers

# Install Composer (from official composer image)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/src

RUN chown -R www-data:www-data /var/www/src

USER www-data

EXPOSE 80

CMD ["apache2-foreground"]
