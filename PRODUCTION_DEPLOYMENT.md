# Production Deployment Guide

## 📚 Documentation Menu

- **[README.md](README.md)** - Main documentation and setup guide
- **[SECURITY.md](SECURITY.md)** - Security configuration and best practices
- **[PRODUCTION_DEPLOYMENT.md](PRODUCTION_DEPLOYMENT.md)** - Production deployment guide

---

This guide covers production deployment configurations for the multi-PHP Docker environment.

## 1. SSL Certificate Configuration

### Option A: Let's Encrypt Certificates

1. **Install Certbot:**

   ```bash
   sudo apt update
   sudo apt install certbot
   ```

2. **Generate certificates:**
   ```bash
   sudo certbot certonly --standalone -d legacy.example.com
   sudo certbot certonly --standalone -d api.example.com
   sudo certbot certonly --standalone -d app.example.com
   ```

3. **Create certificate directories:**
   ```bash
   sudo mkdir -p /var/containers/certs/{php5,php7,php8}
   ```

4. **Copy certificates:**
   ```bash
   sudo cp /etc/letsencrypt/live/legacy.example.com/fullchain.pem /var/containers/certs/php5/certificate.crt
   sudo cp /etc/letsencrypt/live/legacy.example.com/privkey.pem /var/containers/certs/php5/private.key
   
   sudo cp /etc/letsencrypt/live/api.example.com/fullchain.pem /var/containers/certs/php7/certificate.crt
   sudo cp /etc/letsencrypt/live/api.example.com/privkey.pem /var/containers/certs/php7/private.key
   
   sudo cp /etc/letsencrypt/live/app.example.com/fullchain.pem /var/containers/certs/php8/certificate.crt
   sudo cp /etc/letsencrypt/live/app.example.com/privkey.pem /var/containers/certs/php8/private.key
   ```

5. **Set permissions:**

   ```bash
   sudo chmod 644 /var/containers/certs/*/certificate.crt
   sudo chmod 600 /var/containers/certs/*/private.key
   sudo chown root:root /var/containers/certs -R
   ```

### Option B: Commercial SSL Provider

1. Request certificate from provider (Comodo, GlobalSign, etc.)
2. Receive `certificate.crt` and `private.key` files
3. Place in `/var/containers/certs/{php5,php7,php8}/`

### Update docker-compose.yml for Production Certs

Modify the docker-compose.yml to mount real certificates:

```yaml
volumes:
  - ./dockerphp5/src:/var/www/src
  - /var/containers/certs/php5:/etc/apache2/ssl:ro  # Add this line
```

Repeat for php7 and php8.

### Auto-Renewal of Let's Encrypt Certificates

Create a renewal cron job:

```bash
sudo crontab -e

# Add this line (renews at 2 AM daily)
0 2 * * * certbot renew && cp /etc/letsencrypt/live/*/fullchain.pem /var/containers/certs/*/certificate.crt && cp /etc/letsencrypt/live/*/privkey.pem /var/containers/certs/*/private.key
```

---

## 2. Database User Permissions

### How It Works

The `db-init` SQL scripts automatically configure restricted database users when containers start:

**Granted Permissions:**

- `SELECT` - Read data
- `INSERT` - Add new records
- `UPDATE` - Modify existing records
- `DELETE` - Remove records

**Denied Permissions:**

- User cannot change their own password
- Cannot create/drop databases
- Cannot modify user permissions
- Cannot view system tables
- Limited to specific database only

### Verification

Verify restricted permissions are applied:

```bash
# Connect to database as root
docker exec -it synaptic_db_webPHP8 mysql -u root -p${MYSQL_ROOT_PASSWORD_PHP8}

# Check user privileges
SHOW GRANTS FOR '${MYSQL_USER_PHP8}'@'%';

# Output should show only:
# GRANT SELECT, INSERT, UPDATE, DELETE ON `appdb_php8`.* TO 'appuser_php8'@'%'
```

---

## 3. Centralized Logging

### Docker Logging Configuration

All containers use JSON file driver with rotation:

```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"         # Rotate after 10MB
    max-file: "3"           # Keep 3 rotated logs
    labels: "service=web"   # Add labels for filtering
```

### Access Container Logs

```bash
# View live logs
docker logs -f synaptic_webPHP8

# View logs with timestamp
docker logs -t synaptic_webPHP8

# View last 100 lines
docker logs --tail 100 synaptic_webPHP8

# View logs from specific time
docker logs --since 2024-01-15T10:00:00 synaptic_webPHP8
```

---

## 4. Monitoring & Health Checks

### Health Check Status

```bash
# Check health of all services
docker ps --format "table {{.Names}}\t{{.Status}}"

# Example output:
# NAME                STATUS
# synaptic_webPHP8    Up 2 hours (healthy)
# synaptic_db_webPHP8 Up 2 hours (healthy)
```

---

## 5. Security Hardening Checklist

- [ ] Use Let's Encrypt or commercial certificates (not self-signed)
- [ ] Enable HSTS header in Apache
- [ ] Set strong passwords (16+ characters, mixed case/numbers)
- [ ] Rotate database passwords regularly
- [ ] Restrict database user to specific IP ranges
- [ ] Enable firewall rules on host
- [ ] Use fail2ban for brute-force protection
- [ ] Enable audit logging
- [ ] Regular security scans with Trivy
- [ ] Keep base images updated

---

## 6. Backup Strategy

### Database Backups

```bash
# Manual backup
docker exec synaptic_db_webPHP8 mysqldump -u root -p${MYSQL_ROOT_PASSWORD_PHP8} --all-databases > backup.sql

# Restore from backup
docker exec -i synaptic_db_webPHP8 mysql -u root -p${MYSQL_ROOT_PASSWORD_PHP8} < backup.sql
```

### Automated Daily Backups

Create backup script:

```bash
#!/bin/bash
BACKUP_DIR="/backups/mysql"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

for VERSION in php5 php7 php8; do
  docker exec synaptic_db_webPHP${VERSION} mysqldump \
    -u root \
    -p${MYSQL_ROOT_PASSWORD_${VERSION}} \
    --all-databases > $BACKUP_DIR/backup_${VERSION}_${DATE}.sql
done

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
```

Add to crontab:

```bash
0 2 * * * /scripts/backup-databases.sh
```

---

## 7. Deployment Checklist

- [ ] Create `.env` file with strong credentials
- [ ] Generate SSL certificates (Let's Encrypt or commercial)
- [ ] Configure firewall rules
- [ ] Set up log aggregation (ELK or similar)
- [ ] Configure monitoring (Prometheus, etc.)
- [ ] Enable database backups
- [ ] Test HTTPS connectivity
- [ ] Verify database permissions
- [ ] Load test the application
- [ ] Set up alerting and monitoring
- [ ] Document access procedures
- [ ] Plan incident response procedures

---

## 8. Troubleshooting

### HTTPS Connection Issues

```bash
# Test SSL certificate
openssl s_client -connect localhost:8443

# Check certificate details
openssl x509 -in /var/containers/certs/php5/certificate.crt -text -noout
```

### Database Connection Issues

```bash
# Test connection from web container
docker exec synaptic_webPHP8 mysql -h db_webPHP8 -u ${MYSQL_USER_PHP8} -p${MYSQL_PASSWORD_PHP8}

# Check container logs
docker logs synaptic_db_webPHP8
```

### Performance Issues

```bash
# Monitor resource usage
docker stats

# Check disk space
df -h

# Monitor database performance
docker exec synaptic_db_webPHP8 mysql -u root -p${MYSQL_ROOT_PASSWORD_PHP8} -e "SHOW PROCESSLIST;"
```

---

## 9. Maintenance

### Regular Updates

```bash
# Update base images
docker-compose pull

# Rebuild containers
docker-compose build --no-cache

# Restart services
docker-compose down && docker-compose up -d
```

### Security Scanning

```bash
# Scan images for vulnerabilities
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image synaptic_webphp8
```

---

## Support & References

- [Apache SSL Documentation](https://httpd.apache.org/docs/2.4/ssl/)
- [MySQL User Privileges](https://dev.mysql.com/doc/refman/8.0/en/grant.html)
- [Docker Logging Drivers](https://docs.docker.com/config/containers/logging/)
- [Let's Encrypt](https://letsencrypt.org/)
- [OWASP Security Best Practices](https://owasp.org/www-project-secure-coding-practices-quick-reference-guide/)