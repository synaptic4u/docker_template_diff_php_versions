#!/bin/bash

# Create SSL directory structure
mkdir -p ssl/{ca,server,client}

# Generate CA private key
openssl genrsa 2048 > ssl/ca/ca-key.pem

# Generate CA certificate
openssl req -new -x509 -nodes -days 3600 -key ssl/ca/ca-key.pem -out ssl/ca/ca-cert.pem -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=MySQL-CA"

# Generate server private key
openssl req -newkey rsa:2048 -days 3600 -nodes -keyout ssl/server/server-key.pem -out ssl/server/server-req.pem -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=MySQL-Server"

# Generate server certificate
openssl rsa -in ssl/server/server-key.pem -out ssl/server/server-key.pem
openssl x509 -req -in ssl/server/server-req.pem -days 3600 -CA ssl/ca/ca-cert.pem -CAkey ssl/ca/ca-key.pem -set_serial 01 -out ssl/server/server-cert.pem

# Generate client private key
openssl req -newkey rsa:2048 -days 3600 -nodes -keyout ssl/client/client-key.pem -out ssl/client/client-req.pem -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=MySQL-Client"

# Generate client certificate
openssl rsa -in ssl/client/client-key.pem -out ssl/client/client-key.pem
openssl x509 -req -in ssl/client/client-req.pem -days 3600 -CA ssl/ca/ca-cert.pem -CAkey ssl/ca/ca-key.pem -set_serial 01 -out ssl/client/client-cert.pem

# Set permissions
chmod 600 ssl/ca/ca-key.pem ssl/server/server-key.pem ssl/client/client-key.pem
chmod 644 ssl/ca/ca-cert.pem ssl/server/server-cert.pem ssl/client/client-cert.pem

# Clean up request files
rm ssl/server/server-req.pem ssl/client/client-req.pem

echo "SSL certificates generated successfully!"