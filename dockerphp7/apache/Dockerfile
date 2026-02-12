FROM php:7.4-apache

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

# Create SSL certificate directory and self-signed certificate
RUN mkdir -p /etc/apache2/ssl && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout /etc/apache2/ssl/private.key \
      -out /etc/apache2/ssl/certificate.crt \
      -subj "/CN=localhost" 2>/dev/null

# Set Apache DocumentRoot to /var/www/src
RUN mkdir -p /var/www/src \
    && sed -ri 's!DocumentRoot /var/www/html!DocumentRoot /var/www/src/html!g' /etc/apache2/sites-available/000-default.conf \
    && sed -ri "s!<Directory /var/www/>!<Directory /var/www/src/html>!g" /etc/apache2/apache2.conf || true

# Configure HTTP to HTTPS redirect
RUN echo '<VirtualHost *:80>' > /etc/apache2/sites-available/000-default-http.conf && \
    echo '  ServerName localhost' >> /etc/apache2/sites-available/000-default-http.conf && \
    echo '  RewriteEngine On' >> /etc/apache2/sites-available/000-default-http.conf && \
    echo '  RewriteCond %{HTTPS} off' >> /etc/apache2/sites-available/000-default-http.conf && \
    echo '  RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]' >> /etc/apache2/sites-available/000-default-http.conf && \
    echo '</VirtualHost>' >> /etc/apache2/sites-available/000-default-http.conf

# Create SSL VirtualHost
RUN echo '<VirtualHost *:443>' > /etc/apache2/sites-available/000-default-ssl.conf && \
    echo '  ServerName localhost' >> /etc/apache2/sites-available/000-default-ssl.conf && \
    echo '  DocumentRoot /var/www/src/html' >> /etc/apache2/sites-available/000-default-ssl.conf && \
    echo '  SSLEngine on' >> /etc/apache2/sites-available/000-default-ssl.conf && \
    echo '  SSLCertificateFile /etc/apache2/ssl/certificate.crt' >> /etc/apache2/sites-available/000-default-ssl.conf && \
    echo '  SSLCertificateKeyFile /etc/apache2/ssl/private.key' >> /etc/apache2/sites-available/000-default-ssl.conf && \
    echo '  <Directory /var/www/src/html>' >> /etc/apache2/sites-available/000-default-ssl.conf && \
    echo '    AllowOverride All' >> /etc/apache2/sites-available/000-default-ssl.conf && \
    echo '    Require all granted' >> /etc/apache2/sites-available/000-default-ssl.conf && \
    echo '  </Directory>' >> /etc/apache2/sites-available/000-default-ssl.conf && \
    echo '</VirtualHost>' >> /etc/apache2/sites-available/000-default-ssl.conf && \
    a2ensite 000-default-http && \
    a2ensite 000-default-ssl && \
    a2dissite 000-default

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

EXPOSE 80 443

CMD ["apache2-foreground"]
