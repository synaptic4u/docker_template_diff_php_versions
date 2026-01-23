# Security Configuration Guide

## 📚 Documentation Menu

- **[README.md](README.md)** - Main documentation and setup guide
- **[SECURITY.md](SECURITY.md)** - Security configuration and best practices
- **[PRODUCTION_DEPLOYMENT.md](PRODUCTION_DEPLOYMENT.md)** - Production deployment guide

---

## Overview

This document outlines the security improvements implemented in this Docker setup.

## Implemented Security Measures

### 1. **Network Isolation**

- Each PHP version (5, 7, 8) has its own isolated Docker network
- Database containers are NOT accessible to external networks
- Web servers can only communicate with their paired database
- **Networks:**
  - `backend_php5`: PHP 5.6 web ↔ MySQL 5.7
  - `backend_php7`: PHP 7.4 web ↔ MySQL 8.0
  - `backend_php8`: PHP 8.3 web ↔ MySQL 8.0

### 2. **Database Port Security**

- Database containers use `expose` instead of `ports`
- MySQL ports (3306) are NOT exposed to the host machine
- Only web containers on the same network can connect to databases
- Prevents external access to databases

### 3. **Removed Hardcoded Credentials**

- All `.php` files now require environment variables
- Fallback credentials (`elser_db_webPHP*`) have been removed
- Missing credentials will cause immediate failure with generic error
- Error details are logged server-side, not shown to users

### 4. **Improved Error Handling**

- Generic error messages shown to users ("Database configuration error")
- Detailed error messages logged server-side via `error_log()`
- No exposure of connection strings or database structure
- Sensitive information stays in container logs only

### 5. **Container User Restriction**

- All containers now run as `www-data` user instead of root
- `USER www-data` directive added to all Dockerfiles
- Reduces privilege escalation risk
- File permissions properly configured with `chown`

### 6. **Security Headers (Web Servers)**

- All Apache containers enforce security headers:
  - `X-Content-Type-Options: nosniff` - Prevent MIME type sniffing
  - `X-XSS-Protection: 1; mode=block` - Enable XSS protection
  - `X-Frame-Options: SAMEORIGIN` - Prevent clickjacking
  - `Content-Security-Policy` - Control resource loading
  - `Referrer-Policy` - Control referrer information
  - `Permissions-Policy` - Disable sensitive features

## Environment Variables Setup

### Required Steps Before Running

1. **Copy the template file:**

   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` with secure values:**

   ```bash
   # Generate secure passwords (recommended: 16+ characters with mixed case and numbers)
   openssl rand -base64 16
   ```

3. **Set unique passwords for each service:**

   ```env
   MYSQL_ROOT_PASSWORD_PHP5=<unique_secure_password>
   MYSQL_USER_PHP5=<application_user>
   MYSQL_PASSWORD_PHP5=<unique_secure_password>
   # ... repeat for PHP7 and PHP8
   ```

4. **NEVER commit `.env` to version control**
   - File is already listed in `.gitignore`
   - Verify with: `git status .env`

## Recommended Additional Security Measures

### For Production Deployment

1. **Enable HTTPS/TLS**
   - Configure Apache with SSL certificates
   - Use Let's Encrypt or your organization's CA
   - Redirect HTTP to HTTPS

2. **Database User Permissions**
   - Current setup allows all operations
   - Restrict MySQL users to only necessary tables
   - Example:

     ```sql
     GRANT SELECT, INSERT, UPDATE ON appdb_php8.* TO 'appuser'@'%';
     ```

3. **Secrets Management**
   - Use Docker Secrets (Swarm mode)
   - Use external secret management tools (HashiCorp Vault, etc.)
   - Never pass sensitive data via environment variables in production

4. **Network Security**
   - Implement firewall rules on host
   - Restrict port access (8080, 8081, 8082) to trusted IPs
   - Use reverse proxy (nginx, HAProxy) for SSL termination

5. **Container Scanning**
   - Scan images for vulnerabilities: `trivy image php:8.3-apache`
   - Update base images regularly
   - Monitor for security updates

6. **Update PHP 5.6**
   - PHP 5.6 is EOL and receives no security updates
   - Consider removing or isolating completely
   - Migrate to PHP 7.4+ for continued security support

7. **Database Backup**
   - Implement regular automated backups
   - Test backup restoration procedures
   - Store backups securely offline

8. **Monitoring & Logging**
   - Centralize container logs
   - Monitor for suspicious database queries
   - Set up alerts for connection failures

## Verification Checklist

- [ ] `.env` file created from `.env.example`
- [ ] `.env` is NOT tracked by git
- [ ] Unique passwords generated for each service
- [ ] Database connections work from web containers
- [ ] Database is NOT accessible from host machine
- [ ] Error messages are generic (no database details exposed)
- [ ] Containers run as non-root user

## Troubleshooting

### Database Connection Fails

1. Check environment variables: `docker exec <container> env | grep DB_`
2. Verify network connectivity: `docker network inspect backend_php8`
3. Check database logs: `docker logs synaptic_db_webPHP8`

### Port Access Issues

1. Verify port mapping: `docker ps`
2. Test web access: `curl http://localhost:8080`
3. Check firewall rules: `sudo iptables -L | grep 8080`

## References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker/)
