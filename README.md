# Docker Multi-PHP Environment

## 📚 Documentation Menu

- **[README.md](README.md)** - Main documentation and setup guide
- **[SECURITY.md](SECURITY.md)** - Security configuration and best practices

---

## Docker Compose Configuration Documentation

## Overview

This Docker Compose configuration sets up a multi-container environment for running PHP applications with MySQL databases. It supports PHP 5.6, PHP 7, and PHP 8 versions running simultaneously with separate web servers and databases.

## Services

### web5

- **Purpose**: Apache web server running PHP 5.6
- **Container Name**: `synaptic_webPHP5`
- **Port Mapping**: Port 8080 (host) → Port 80 (container), Port 8443 (host) → Port 443 (container)
- **Volume Mounts**: `./dockerphp5/src` → `/var/www/src`
- **Dependencies**: Requires `db_webPHP5` service to be running
- **Restart Policy**: Restarts unless explicitly stopped
- **Networks**: `backend_php5`

### web7

- **Purpose**: Apache web server running PHP 7
- **Container Name**: `synaptic_webPHP7`
- **Port Mapping**: Port 8081 (host) → Port 80 (container), Port 8444 (host) → Port 443 (container)
- **Volume Mounts**: `./dockerphp7/src` → `/var/www/src`
- **Dependencies**: Requires `db_webPHP7` service to be running
- **Restart Policy**: Restarts unless explicitly stopped
- **Networks**: `backend_php7`

### web8

- **Purpose**: Apache web server running PHP 8
- **Container Name**: `synaptic_webPHP8`
- **Port Mapping**: Port 8082 (host) → Port 80 (container), Port 8445 (host) → Port 443 (container)
- **Volume Mounts**: `./dockerphp8/src` → `/var/www/src`
- **Dependencies**: Requires `db_webPHP8` service to be running
- **Restart Policy**: Restarts unless explicitly stopped
- **Networks**: `backend_php8`

### db_webPHP5

- **Purpose**: MySQL 5.7 database for PHP 5.6 application
- **Container Name**: `synaptic_db_webPHP5`
- **Image**: `mysql:5.7`
- **Credentials**: Root password: `${MYSQL_ROOT_PASSWORD_PHP5}` (from .env)
- **Database**: `${MYSQL_DATABASE_PHP5}`
- **User**: `${MYSQL_USER_PHP5}` / Password: `${MYSQL_PASSWORD_PHP5}` (from .env)
- **Restart Policy**: Restarts unless explicitly stopped
- **Networks**: `backend_php5`

### db_webPHP7

- **Purpose**: MySQL 8.0 database for PHP 7 application
- **Container Name**: `synaptic_db_webPHP7`
- **Image**: `mysql:8.0`
- **Credentials**: Root password: `${MYSQL_ROOT_PASSWORD_PHP7}` (from .env)
- **Database**: `${MYSQL_DATABASE_PHP7}`
- **User**: `${MYSQL_USER_PHP7}` / Password: `${MYSQL_PASSWORD_PHP7}` (from .env)
- **Restart Policy**: Restarts unless explicitly stopped
- **Networks**: `backend_php7`

### db_webPHP8

- **Purpose**: MySQL 8.0 database for PHP 8 application
- **Container Name**: `synaptic_db_webPHP8`
- **Image**: `mysql:8.0`
- **Credentials**: Root password: `${MYSQL_ROOT_PASSWORD_PHP8}` (from .env)
- **Database**: `${MYSQL_DATABASE_PHP8}`
- **User**: `${MYSQL_USER_PHP8}` / Password: `${MYSQL_PASSWORD_PHP8}` (from .env)
- **Restart Policy**: Restarts unless explicitly stopped
- **Networks**: `backend_php8`

## Networks

- **backend_php5**: Isolated network for PHP 5.6 web server and MySQL 5.7 database
- **backend_php7**: Isolated network for PHP 7 web server and MySQL 8.0 database  
- **backend_php8**: Isolated network for PHP 8 web server and MySQL 8.0 database

## Volumes

- **db_data_php5**: Named volume for persistent MySQL data storage (PHP 5.6 database)
- **db_data_php7**: Named volume for persistent MySQL data storage (PHP 7 database)
- **db_data_php8**: Named volume for persistent MySQL data storage (PHP 8 database)

## Notes

- Each web service has its own separate source code directory (dockerphp5/src, dockerphp7/src, and dockerphp8/src)
- Each database service has its own separate named volume for data persistence
- Each service pair (web + database) runs on an isolated Docker network for security
- Database credentials are managed via `.env` file (copy `.env.example` to `.env` and update with secure passwords)
- Database ports are not exposed to the host for security (containers communicate internally)
- HTTPS is available on ports 8443 (PHP5), 8444 (PHP7), and 8445 (PHP8)
- To connect to MySQL from host, use: `docker exec -it synaptic_db_webPHP5 mysql -u ${MYSQL_USER_PHP5} -p` (or replace PHP5 with PHP7/PHP8)
