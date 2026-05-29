#!/bin/bash

sudo apt-get update -y
sudo apt-get install -y postgresql-client gzip

#Download the dataset
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

echo "Installing CedarDB..."
curl https://get.cedardb.com > install.sh
chmod +x install.sh
./install.sh -y # non-interactive install
./cedar/cedardb --createdb db &

# wait for cedardb to start
until pg_isready -h localhost -U postgres > /dev/null 2>&1; do sleep 1; done

# set the password for the postgres user via domain socket
psql -h /tmp -U postgres -c "ALTER USER postgres with password 'test';"

# We can now login with password
export PGPASSWORD=test
psql -h localhost -U postgres -c "CREATE DATABASE test"

# Import the data
psql -h localhost -U postgres --dbname=test < create.sql #import

psql -h localhost -U postgres --dbname=test -t -c '\timing' -c "\\COPY customers FROM 'dataset/customers.csv' WITH (FORMAT csv);" #import
psql -h localhost -U postgres --dbname=test -t -c '\timing' -c "\\COPY products FROM 'dataset/products.csv' WITH (FORMAT csv);" #import
psql -h localhost -U postgres --dbname=test -t -c '\timing' -c "\\COPY orders FROM 'dataset/orders.csv' WITH (FORMAT csv);" #import
psql -h localhost -U postgres --dbname=test -t -c '\timing' -c "\\COPY order_items FROM 'dataset/order_items.csv' WITH (FORMAT csv);" #import
psql -h localhost -U postgres --dbname=test -t -c '\timing' -c "\\COPY order_events FROM 'dataset/order_events.csv' WITH (FORMAT csv);" #import

psql -h localhost -U postgres --dbname=test -c "\t" -c "SELECT pg_total_relation_size('order_events') + pg_total_relation_size('orders') + pg_total_relation_size('order_items') + pg_total_relation_size('products') + pg_total_relation_size('customers');" #datasize

./run.sh 2>&1 | tee log.txt

cat log.txt | grep -oP 'Time: \d+\.\d+ ms' | sed -r -e 's/Time: ([0-9]+\.[0-9]+) ms/\1/' |
  awk '{ if (i % 3 == 0) { printf "[" }; printf $1 / 1000; if (i % 3 != 2) { printf "," } else { print "]," }; ++i; }'  #results

echo "General Purpose" #tag
echo "Real-time Analytics" #tag
echo "CedarDB" #name
pkill cedardb
