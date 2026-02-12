# SSL/TLS Encryption Configuration

## Overview

This setup enables encrypted communication between web services and MySQL databases using SSL/TLS certificates.

## SSL Certificate Generation

Run the following command to generate SSL certificates:

```bash
./generate-ssl-certs.sh
```

This creates:
- CA certificate and key
- Server certificates for MySQL
- Client certificates for PHP applications

## Configuration

### MySQL SSL Configuration

Each MySQL service is configured with:
- `ssl-ca`: Certificate Authority certificate
- `ssl-cert`: Server certificate
- `ssl-key`: Server private key
- `require_secure_transport=ON`: Forces SSL connections

### PHP Application Configuration

Each web service has access to:
- `DB_SSL_CA`: Path to CA certificate
- `DB_SSL_CERT`: Path to client certificate
- `DB_SSL_KEY`: Path to client private key

## Usage Examples

See the `ssl-connection-example.php` files in each PHP version directory for implementation examples:

- `dockerphp5/src/ssl-connection-example.php` - MySQLi with SSL
- `dockerphp7/src/ssl-connection-example.php` - PDO with SSL
- `dockerphp8/src/ssl-connection-example.php` - PDO with SSL

## Security Notes

- Private keys are excluded from version control
- Certificates are mounted read-only in containers
- All database connections require SSL encryption
- Self-signed certificates are used for development (use proper CA certificates in production)

## Verification

To verify SSL is working:

1. Connect to a web container: `docker exec -it synaptic_webPHP8 bash`
2. Run the SSL example: `php /var/www/src/ssl-connection-example.php`
3. Check for "SSL Cipher" output confirming encryption