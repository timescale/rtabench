#!/bin/bash

sudo apt-get update

# Download the dataset
wget --no-verbose --continue 'https://rtadatasets.timescale.com/customers.csv.gz'
wget --no-verbose --continue 'https://rtadatasets.timescale.com/products.csv.gz'
wget --no-verbose --continue 'https://rtadatasets.timescale.com/orders.csv.gz'
wget --no-verbose --continue 'https://rtadatasets.timescale.com/order_items.csv.gz'
wget --no-verbose --continue 'https://rtadatasets.timescale.com/order_events.csv.gz'
gzip -d customers.csv.gz products.csv.gz orders.csv.gz order_items.csv.gz order_events.csv.gz
sudo chmod og+rX ~
chmod 777 customers.csv products.csv orders.csv order_items.csv order_events.csv
mkdir -p dataset
mv *.csv dataset/

sudo apt install -y postgresql-common
sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y
sudo bash -c 'echo "deb https://packagecloud.io/timescale/timescaledb/ubuntu/ $(lsb_release -c -s) main" > /etc/apt/sources.list.d/timescaledb.list'
wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | sudo apt-key add -

sudo apt-get update
sudo apt install -y timescaledb-2-postgresql-16 postgresql-client-16 gnupg apt-transport-https lsb-release wget
sudo timescaledb-tune -yes
sudo systemctl restart postgresql

sudo -u postgres psql -c "CREATE DATABASE test"
sudo -u postgres psql test -c "SHOW default_toast_compression;"
sudo -u postgres psql test -c "SHOW work_mem;"
sudo -u postgres psql test -c "ALTER DATABASE test SET work_mem TO '50MB';"
sudo -u postgres psql test -c "CREATE EXTENSION timescaledb WITH VERSION '2.18.1';"

sudo -u postgres psql test -c "ALTER DATABASE test SET timescaledb.enable_chunk_skipping to true;"

# Import the data
sudo -u postgres psql test < create.sql #import
sudo -u postgres psql test -c "SELECT create_hypertable('order_events', 'event_created', chunk_time_interval => interval '3 day', create_default_indexes => false)" #import
sudo -u postgres psql test -c "SELECT * FROM enable_chunk_skipping('order_events', 'order_id');"
sudo -u postgres psql test -c "ALTER TABLE order_events SET (timescaledb.compress, timescaledb.compress_segmentby = '', timescaledb.compress_orderby = 'order_id, event_created')" #import

sudo -u postgres timescaledb-parallel-copy -table customers -file dataset/customers.csv -connection "host=/var/run/postgresql dbname=test"  -workers 8 #import
sudo -u postgres timescaledb-parallel-copy -table products -file dataset/products.csv -connection "host=/var/run/postgresql dbname=test"  -workers 8 #import
sudo -u postgres timescaledb-parallel-copy -table orders -file dataset/orders.csv -connection "host=/var/run/postgresql dbname=test"  -workers 8 #import
sudo -u postgres timescaledb-parallel-copy -table order_items -file dataset/order_items.csv -connection "host=/var/run/postgresql dbname=test"  -workers 8 #import
sudo -u postgres timescaledb-parallel-copy -table order_events -file dataset/order_events.csv -connection "host=/var/run/postgresql dbname=test"  -workers 8 #import

./compress.sh #import

sudo -u postgres psql test -t -c '\timing' -c "vacuum freeze analyze orders;" #import
sudo -u postgres psql test -t -c '\timing' -c "vacuum freeze analyze order_events;" #import

sudo -u postgres psql test < caggs.sql

sudo -u postgres psql test -c "\t" -c "SELECT hypertable_size('order_events') + pg_total_relation_size('orders') + pg_total_relation_size('order_items') + pg_total_relation_size('products') + pg_total_relation_size('customers');" #datasize

./run.sh 2>&1 | tee log.txt

cat log.txt | grep -oP 'Time: \d+\.\d+ ms' | sed -r -e 's/Time: ([0-9]+\.[0-9]+) ms/\1/' |
  awk '{ if (i % 3 == 0) { printf "[" }; printf $1 / 1000; if (i % 3 != 2) { printf "," } else { print "]," }; ++i; }'  #results

./explain.sh

echo "General Purpose" #tag
echo "Real-time Analytics" #tag
echo "TimescaleDB" #name
echo "Insert" #mv_supported_capability
echo "Update" #mv_supported_capability
echo "Upsert" #mv_supported_capability
echo "Delete" #mv_supported_capability
