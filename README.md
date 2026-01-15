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
- **Port Mapping**: Port 33067 (host) → Port 3306 (container)
- **Credentials**: Root password: `rootpassword`
- **Database**: `synaptic_db_webPHP7`
- **User**: `synaptic_db_webPHP7` / Password: `synaptic_db_webPHP7`
- **Restart Policy**: Restarts unless explicitly stopped

### db_webPHP8

- **Purpose**: MySQL 8.0 database for PHP 8 application
- **Container Name**: `synaptic_db_webPHP8`
- **Image**: `mysql:8.0`
- **Port Mapping**: Port 33068 (host) → Port 3306 (container)
- **Credentials**: Root password: `rootpassword`
- **Database**: `synaptic_db_webPHP8`
- **User**: `synaptic_db_webPHP8` / Password: `secrsynaptic_db_webPHP8et`
- **Restart Policy**: Restarts unless explicitly stopped

## Volumes

- **db_data**: Named volume for persistent MySQL data storage shared between both database services

## Notes

- Each web service has its own separate source code directory (dockerphp7/src and dockerphp8/src)
- Both database services share the same volume for data persistence
- **⚠️ Security Issue**: Hard-coded database credentials should be moved to environment variables or `.env` files
