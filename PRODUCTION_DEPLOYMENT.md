# Production Deployment Guide

## Overview

This guide covers deploying the Docker containers to a production environment with:
- HTTPS/SSL with real certificates
- Database user permission restrictions
- Centralized logging and monitoring
- Security best practices

---

## 1. HTTPS/SSL Configuration

### Self-Signed Certificates (Development)

Containers include self-signed certificates by default. To verify:

```bash
# Test HTTPS with self-signed cert (ignore cert warnings)
curl -k https://localhost:8443
curl -k https://localhost:8444
curl -k https://localhost:8445
```

### Production Certificates (Let's Encrypt)

#### Option A: Using Let's Encrypt with Certbot

1. **Install Certbot on host machine:**
   ```bash
   sudo apt-get install certbot
   ```

2. **Generate certificates:**
   ```bash
   # For PHP 5.6 (example.com)
   sudo certbot certonly --standalone -d example.com -d www.example.com
   
   # For PHP 7.4
   sudo certbot certonly --standalone -d api.example.com
   
   # For PHP 8.3
   sudo certbot certonly --standalone -d app.example.com
   ```

3. **Create certificate volumes directory:**
   ```bash
   mkdir -p /var/containers/certs/php5
   mkdir -p /var/containers/certs/php7
   mkdir -p /var/containers/certs/php8
   ```

4. **Copy certificates:**
   ```bash
   sudo cp /etc/letsencrypt/live/example.com/fullchain.pem /var/containers/certs/php5/certificate.crt
   sudo cp /etc/letsencrypt/live/example.com/privkey.pem /var/containers/certs/php5/private.key
   
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

#### Option B: Using Commercial SSL Provider

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

### Additional Permission Restrictions

For even stricter security, modify `db-init/01-restricted-user.sql`:

```sql
-- Restrict to specific tables only
GRANT SELECT, INSERT, UPDATE ON `appdb_php8`.`users` TO 'appuser_php8'@'%';
GRANT SELECT ON `appdb_php8`.`products` TO 'appuser_php8'@'%';

-- Restrict to specific columns
GRANT SELECT(id, name, email) ON `appdb_php8`.`users` TO 'appuser_php8'@'%';
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

### Log File Locations

```
/var/lib/docker/containers/[container-id]/[container-id]-json.log
```

Find container ID:
```bash
docker inspect synaptic_webPHP8 | grep '"Id"'
```

### Production Logging: ELK Stack Setup

For centralized log aggregation, use Elasticsearch + Logstash + Kibana:

1. **Add to docker-compose.yml:**

```yaml
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.14.0
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
    ports:
      - "9200:9200"
    volumes:
      - es_data:/usr/share/elasticsearch/data

  logstash:
    image: docker.elastic.co/logstash/logstash:7.14.0
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
    ports:
      - "5000:5000/udp"
    depends_on:
      - elasticsearch

  kibana:
    image: docker.elastic.co/kibana/kibana:7.14.0
    ports:
      - "5601:5601"
    depends_on:
      - elasticsearch
```

2. **Create logstash.conf:**

```
input {
  syslog {
    port => 5000
    codec => json
  }
}

filter {
  if [docker][name] {
    mutate {
      add_field => { "container" => "%{[docker][name]}" }
    }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "docker-logs-%{+YYYY.MM.dd}"
  }
}
```

3. **Update docker-compose logging to use Logstash:**

```yaml
logging:
  driver: "syslog"
  options:
    syslog-address: "udp://localhost:5000"
    tag: "php-app"
```

4. **Access Kibana:**
   - URL: `http://localhost:5601`
   - Create index pattern: `docker-logs-*`
   - View and analyze logs through dashboard

---

## 4. Apache Logging Configuration

### Enable Access and Error Logging

The Dockerfiles can be enhanced to log Apache access/error:

```dockerfile
# Add to Dockerfile after SSL configuration
RUN mkdir -p /var/log/apache2 && \
    chmod 755 /var/log/apache2 && \
    chown -R www-data:www-data /var/log/apache2
```

### View Apache Logs

```bash
# Access logs
docker exec synaptic_webPHP8 tail -f /var/log/apache2/access.log

# Error logs
docker exec synaptic_webPHP8 tail -f /var/log/apache2/error.log
```

### MySQL Logging

Enable query logging in production (performance impact):

```yaml
db_webPHP8:
  image: mysql:8.0
  command: 
    - --general-log=1
    - --general-log-file=/var/log/mysql/general.log
    - --log-error=/var/log/mysql/error.log
```

---

## 5. Monitoring & Health Checks

### Health Check Status

```bash
# Check health of all services
docker ps --format "table {{.Names}}\t{{.Status}}"

# Example output:
# NAME                STATUS
# synaptic_webPHP8    Up 2 hours (healthy)
# synaptic_db_webPHP8 Up 2 hours (healthy)
```

### Setup Prometheus Monitoring

1. **Add Prometheus service:**

```yaml
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
```

2. **Create prometheus.yml:**

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'docker'
    static_configs:
      - targets: ['localhost:9323']
```

3. **Monitor container metrics:**
   - CPU usage
   - Memory usage
   - Network I/O
   - Disk usage

---

## 6. Security Hardening Checklist

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

### HSTS Header

Add to Dockerfile security-headers.conf:

```dockerfile
echo '  Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"' >> /etc/apache2/conf-available/security-headers.conf
```

### Firewall Rules (iptables)

```bash
# Allow only from specific IPs
sudo iptables -A INPUT -p tcp --dport 8443 -s 192.168.1.0/24 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8443 -j DROP
```

---

## 7. Backup Strategy

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

## 8. Deployment Checklist

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

## 9. Troubleshooting

### HTTPS Connection Issues

```bash
# Test SSL certificate
openssl s_client -connect localhost:8443

# Check certificate details
openssl x509 -in /var/containers/certs/php8/certificate.crt -text -noout
```

### Database Connection Issues

```bash
# Test connection from web container
docker exec synaptic_webPHP8 curl http://db_webPHP8:3306

# Check database logs
docker logs synaptic_db_webPHP8
```

### Permission Errors

```bash
# Reset file permissions
docker exec -u root synaptic_webPHP8 chown -R www-data:www-data /var/www/src
```

---

## Support & References

- [Apache SSL Documentation](https://httpd.apache.org/docs/2.4/ssl/)
- [MySQL User Privileges](https://dev.mysql.com/doc/refman/8.0/en/grant.html)
- [Docker Logging Drivers](https://docs.docker.com/config/containers/logging/)
- [Let's Encrypt](https://letsencrypt.org/)
- [OWASP Security Best Practices](https://owasp.org/www-project-secure-coding-practices-quick-reference-guide/)
