-- MySQL initialization script for PHP 5.6 environment
-- Sets up restricted database user with limited permissions

-- Create restricted application user (no password change, no user management)
CREATE USER IF NOT EXISTS '${MYSQL_USER_PHP5}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD_PHP5}';

-- Grant minimal necessary permissions for application
-- SELECT, INSERT, UPDATE, DELETE on application database only
GRANT SELECT, INSERT, UPDATE, DELETE ON `${MYSQL_DATABASE_PHP5}`.* TO '${MYSQL_USER_PHP5}'@'%';

-- Deny dangerous permissions
REVOKE ALL PRIVILEGES ON *.* FROM '${MYSQL_USER_PHP5}'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON `${MYSQL_DATABASE_PHP5}`.* TO '${MYSQL_USER_PHP5}'@'%';

-- Flush privileges to apply changes
FLUSH PRIVILEGES;

-- Log the user creation
SELECT CONCAT('Application user ', '${MYSQL_USER_PHP5}', ' configured with restricted permissions on ', '${MYSQL_DATABASE_PHP5}') AS 'Status';
