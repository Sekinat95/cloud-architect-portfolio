#!/bin/bash
set -e

apt-get update
apt-get install -y postgresql postgresql-contrib postgresql-13-pglogical

systemctl start postgresql
systemctl enable postgresql

DB_PASSWORD=$(curl -s \
  "http://metadata.google.internal/computeMetadata/v1/instance/attributes/db-password" \
  -H "Metadata-Flavor: Google")

PG_VERSION=$(ls /etc/postgresql/)

cat >> /etc/postgresql/$PG_VERSION/main/postgresql.conf << EOF
wal_level = logical
max_replication_slots = 10
max_wal_senders = 10
listen_addresses = '*'
shared_preload_libraries = 'pglogical'
EOF

cat >> /etc/postgresql/$PG_VERSION/main/pg_hba.conf << EOF
host    all         all         10.0.2.0/24     md5
host    replication all         10.0.2.0/24     md5
host    all         all         10.0.3.0/29     md5
host    replication all         10.0.3.0/29     md5
host    all         all         10.0.1.0/24     md5
host    replication all         10.0.1.0/24     md5
EOF

sudo -u postgres psql << EOF
CREATE USER migration_user WITH PASSWORD '$DB_PASSWORD' REPLICATION LOGIN;
CREATE DATABASE retail_db;
GRANT ALL PRIVILEGES ON DATABASE retail_db TO migration_user;
EOF

systemctl restart postgresql

# Install pglogical extension in both databases
sudo -u postgres psql -c "CREATE EXTENSION pglogical;"
sudo -u postgres psql -d retail_db -c "CREATE EXTENSION pglogical;"

# Grant pglogical privileges to migration_user
sudo -u postgres psql -c "GRANT USAGE ON SCHEMA pglogical TO migration_user;"
sudo -u postgres psql -c "GRANT ALL ON ALL TABLES IN SCHEMA pglogical TO migration_user;"
sudo -u postgres psql -d retail_db -c "GRANT USAGE ON SCHEMA pglogical TO migration_user;"
sudo -u postgres psql -d retail_db -c "GRANT ALL ON ALL TABLES IN SCHEMA pglogical TO migration_user;"