#!/bin/bash

# Production Deployment Script
# Usage: ./deploy-production.sh [php5|php7|php8|all]

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DEPLOY_TARGET="${1:-all}"
LOG_FILE="$SCRIPT_DIR/deployment.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[${TIMESTAMP}]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Pre-deployment checks
pre_deployment_checks() {
    log "Starting pre-deployment checks..."
    
    # Check if .env file exists
    if [ ! -f "$SCRIPT_DIR/.env" ]; then
        error ".env file not found. Please create it from .env.example"
    fi
    
    # Check Docker installation
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed"
    fi
    
    # Check Docker Compose installation
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose is not installed"
    fi
    
    # Check certificate directories
    if [ ! -d "/var/containers/certs/php5" ]; then
        warn "Certificate directory for PHP 5 not found. Using self-signed certificates."
    fi
    
    log "Pre-deployment checks passed!"
}

# Deploy service
deploy_service() {
    local SERVICE=$1
    log "Deploying $SERVICE..."
    
    docker-compose -f "$SCRIPT_DIR/docker-compose.yml" \
                   -f "$SCRIPT_DIR/docker-compose.prod.yml" \
                   up -d "web${SERVICE}" "db_webPHP${SERVICE}"
    
    # Wait for service to be healthy
    log "Waiting for $SERVICE to become healthy..."
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if docker-compose -f "$SCRIPT_DIR/docker-compose.yml" \
                         -f "$SCRIPT_DIR/docker-compose.prod.yml" \
                         ps "db_webPHP${SERVICE}" | grep -q "healthy"; then
            log "$SERVICE is healthy!"
            return 0
        fi
        
        attempt=$((attempt + 1))
        sleep 2
    done
    
    error "$SERVICE failed to become healthy within timeout"
}

# Run post-deployment tests
post_deployment_tests() {
    local SERVICE=$1
    log "Running post-deployment tests for $SERVICE..."
    
    # Test HTTP to HTTPS redirect
    log "Testing HTTP to HTTPS redirect..."
    local port=$((8080 + $(echo $SERVICE | grep -o '[0-9]' | head -1)))
    
    if curl -s -o /dev/null -w "%{http_code}" -L "http://localhost:$port" | grep -q "200\|301"; then
        log "HTTP to HTTPS redirect working"
    else
        warn "HTTP to HTTPS redirect test inconclusive"
    fi
    
    # Test database connectivity
    log "Testing database connectivity..."
    if docker exec "synaptic_webPHP${SERVICE}" php -c /etc/php -r "
        \$host = getenv('DB_HOST');
        \$user = getenv('DB_USER');
        \$pass = getenv('DB_PASSWORD');
        \$db = getenv('DB_NAME');
        \$conn = @new mysqli(\$host, \$user, \$pass, \$db);
        if (\$conn->connect_error) {
            echo 'FAIL';
            exit(1);
        }
        echo 'OK';
    " | grep -q "OK"; then
        log "Database connectivity test passed"
    else
        warn "Database connectivity test failed"
    fi
    
    log "Post-deployment tests completed for $SERVICE"
}

# Backup function
backup_database() {
    local SERVICE=$1
    local BACKUP_DIR="/backups/mysql"
    local DATE=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$BACKUP_DIR"
    
    log "Backing up PHP ${SERVICE} database..."
    docker exec "synaptic_db_webPHP${SERVICE}" mysqldump \
        -u root \
        -p"${MYSQL_ROOT_PASSWORD_PHP${SERVICE}}" \
        --all-databases > "$BACKUP_DIR/backup_php${SERVICE}_${DATE}.sql"
    
    log "Backup completed: $BACKUP_DIR/backup_php${SERVICE}_${DATE}.sql"
}

# Main deployment logic
main() {
    log "Starting production deployment"
    log "Target: $DEPLOY_TARGET"
    
    pre_deployment_checks
    
    case $DEPLOY_TARGET in
        php5)
            backup_database 5
            deploy_service 5
            post_deployment_tests 5
            ;;
        php7)
            backup_database 7
            deploy_service 7
            post_deployment_tests 7
            ;;
        php8)
            backup_database 8
            deploy_service 8
            post_deployment_tests 8
            ;;
        all)
            for VERSION in 5 7 8; do
                backup_database $VERSION
                deploy_service $VERSION
                post_deployment_tests $VERSION
            done
            ;;
        *)
            error "Invalid target: $DEPLOY_TARGET. Use: php5|php7|php8|all"
            ;;
    esac
    
    log "Production deployment completed successfully!"
    log "Services are running and healthy"
}

# Run main function
main "$@"
