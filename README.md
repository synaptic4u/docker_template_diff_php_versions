# Docker Compose Configuration Documentation

## Overview

This Docker Compose configuration sets up a multi-container environment for running PHP applications with MySQL databases. It supports both PHP 7 and PHP 8 versions running simultaneously with separate web servers and databases.

## Services

### web7

- **Purpose**: Apache web server running PHP 7
- **Container Name**: `synaptic_webPHP7`
- **Port Mapping**: Port 8081 (host) → Port 80 (container)
- **Volume Mounts**: `./dockerphp7/src` → `/var/www/src`
- **Dependencies**: Requires `db_webPHP7` service to be running
- **Restart Policy**: Restarts unless explicitly stopped

### web8

- **Purpose**: Apache web server running PHP 8
- **Container Name**: `synaptic_webPHP8`
- **Port Mapping**: Port 8082 (host) → Port 80 (container)
- **Volume Mounts**: `./dockerphp8/src` → `/var/www/src`
- **Dependencies**: Requires `db_webPHP8` service to be running
- **Restart Policy**: Restarts unless explicitly stopped

### db_webPHP7

- **Purpose**: MySQL 8.0 database for PHP 7 application
- **Container Name**: `synaptic_db_webPHP7`
- **Image**: `mysql:8.0`
- **Credentials**: Root password: `${MYSQL_ROOT_PASSWORD_PHP7}` (from .env)
- **Database**: `synaptic_db_webPHP7`
- **User**: `synaptic_db_webPHP7` / Password: `${MYSQL_PASSWORD_PHP7}` (from .env)
- **Restart Policy**: Restarts unless explicitly stopped

### db_webPHP8

- **Purpose**: MySQL 8.0 database for PHP 8 application
- **Container Name**: `synaptic_db_webPHP8`
- **Image**: `mysql:8.0`
- **Credentials**: Root password: `${MYSQL_ROOT_PASSWORD_PHP8}` (from .env)
- **Database**: `synaptic_db_webPHP8`
- **User**: `synaptic_db_webPHP8` / Password: `${MYSQL_PASSWORD_PHP8}` (from .env)
- **Restart Policy**: Restarts unless explicitly stopped

## Volumes

- **db_data_php7**: Named volume for persistent MySQL data storage (PHP 7 database)
- **db_data_php8**: Named volume for persistent MySQL data storage (PHP 8 database)

## Notes

- Each web service has its own separate source code directory (dockerphp7/src and dockerphp8/src)
- Each database service has its own separate named volume for data persistence
- Database credentials are managed via `.env` file (copy `.env.example` to `.env` and update with secure passwords)
- Database ports are not exposed to the host for security (containers communicate internally)
- To connect to MySQL from host, use: `docker exec -it synaptic_db_webPHP7 mysql -u synaptic_db_webPHP7 -p`
