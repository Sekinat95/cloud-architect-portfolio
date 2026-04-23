#!/bin/bash
set -e

# Update and install PostgreSQL
apt-get update
apt-get install -y postgresql postgresql-contrib

# Start PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# Retrieve DB password from instance metadata
DB_PASSWORD=$(curl -s \
  "http://metadata.google.internal/computeMetadata/v1/instance/attributes/db-password" \
  -H "Metadata-Flavor: Google")

# Make PostgreSQL config path version-agnostic
PG_VERSION=$(ls /etc/postgresql/)

# Configure PostgreSQL for logical replication (required for DMS CDC)
cat >> /etc/postgresql/$PG_VERSION/main/postgresql.conf << EOF
wal_level = logical
max_replication_slots = 10
max_wal_senders = 10
listen_addresses = '*'
EOF

# Allow connections from target VPC subnet
# Allow connections from target VPC subnet and DMS private connection subnet
cat >> /etc/postgresql/$PG_VERSION/main/pg_hba.conf << EOF
host    all         all         10.0.2.0/24     md5
host    replication all         10.0.2.0/24     md5
host    all         all         10.0.3.0/29     md5
host    replication all         10.0.3.0/29     md5
host    all         all         10.0.1.0/24     md5
host    replication all         10.0.1.0/24     md5
EOF

# Create migration user and database
sudo -u postgres psql << EOF
CREATE USER migration_user WITH PASSWORD '$DB_PASSWORD' REPLICATION LOGIN;
CREATE DATABASE retail_db;
GRANT ALL PRIVILEGES ON DATABASE retail_db TO migration_user;
EOF

# Restart PostgreSQL to apply config changes
systemctl restart postgresql