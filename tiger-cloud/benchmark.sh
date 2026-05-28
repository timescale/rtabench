#!/bin/bash

sudo apt-get update

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

# This benchmark uses terraform to provision a Tiger Cloud instance. https://www.timescale.com/blog/create-timescale-services-with-terraform-provider/

# set in CI with github actions secrets and auto-benchmark tool
# export TS_PROJECT_ID=...
# export TS_ACCESS_KEY=...
# export TS_SECRET_KEY=...
# export REGION=${REGION:-us-east-2}
# export SIZE=${MEMORY:-32000}
export REGION=${REGION:-us-east-2}
export MILLI_CPU=$SIZE

#install postgres client
sudo apt-get update
sudo apt install -y postgresql-common gnupg software-properties-common
sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y
sudo bash -c 'echo "deb https://packagecloud.io/timescale/timescaledb/ubuntu/ $(lsb_release -c -s) main" > /etc/apt/sources.list.d/timescaledb.list'
wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | sudo apt-key add -
sudo apt-get update
sudo apt install -y postgresql-client-17 timescaledb-tools

#install terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
sudo apt-get install terraform

terraform init
terraform apply -auto-approve -var region="$REGION" \
  -var ts_access_key="$TS_ACCESS_KEY" \
  -var ts_secret_key="$TS_SECRET_KEY" \
  -var ts_project_id="$TS_PROJECT_ID" \
  -var milli_cpu="$MILLI_CPU"

export CONNECTION_STRING=$(terraform output --raw service_url)

psql "$CONNECTION_STRING" -c "ALTER DATABASE tsdb SET timescaledb.enable_chunk_skipping to ON;"

# Import the data
psql "$CONNECTION_STRING" < create.sql #import
psql "$CONNECTION_STRING" -c "SELECT create_hypertable('order_events', 'event_created', chunk_time_interval => interval '3 day', create_default_indexes => false)" #import
psql "$CONNECTION_STRING" -c "SELECT * FROM enable_chunk_skipping('order_events', 'order_id');"
psql "$CONNECTION_STRING" -c "ALTER TABLE order_events SET (timescaledb.compress, timescaledb.compress_segmentby = '', timescaledb.compress_orderby = 'order_id, event_created')" #import

timescaledb-parallel-copy -table customers -file dataset/customers.csv -connection "$CONNECTION_STRING"  -workers 8 #import      
timescaledb-parallel-copy -table products -file dataset/products.csv  -connection "$CONNECTION_STRING"  -workers 8 #import        
timescaledb-parallel-copy -table orders -file dataset/orders.csv -connection "$CONNECTION_STRING"  -workers 8 #import            
timescaledb-parallel-copy -table order_items -file dataset/order_items.csv -connection "$CONNECTION_STRING"  -workers 8 #import  
timescaledb-parallel-copy -table order_events -file dataset/order_events.csv  -connection "$CONNECTION_STRING"  -workers 8 #import

./compress.sh #import

psql "$CONNECTION_STRING" -c "vacuum freeze analyze orders;" #import
psql "$CONNECTION_STRING" -c "vacuum freeze analyze order_events;" #import

psql "$CONNECTION_STRING" < caggs.sql

psql "$CONNECTION_STRING" -c "\t" -c "SELECT hypertable_size('order_events') + pg_total_relation_size('orders') + pg_total_relation_size('order_items') + pg_total_relation_size('products') + pg_total_relation_size('customers');" #datasize

./run.sh 2>&1 | tee log.txt

cat log.txt | grep -oP 'Time: \d+\.\d+ ms' | sed -r -e 's/Time: ([0-9]+\.[0-9]+) ms/\1/' |
  awk '{ if (i % 3 == 0) { printf "[" }; printf $1 / 1000; if (i % 3 != 2) { printf "," } else { print "]," }; ++i; }'  #results

terraform destroy -auto-approve -var region="$REGION" \
  -var ts_access_key="$TS_ACCESS_KEY" \
  -var ts_secret_key="$TS_SECRET_KEY" \
  -var ts_project_id="$TS_PROJECT_ID" \
  -var milli_cpu="$MILLI_CPU"

[[ "$SIZE" == "16000" ]] && echo "16 vCPU 64GB" || ([[ "$SIZE" == "8000" ]] && echo "8 vCPU 32GB") || ([[ "$SIZE" == "4000" ]] && echo "4 vCPU 16GB") #machineType

echo "Real-time Analytics" #tag
echo "General Purpose" #tag
echo "Tiger Cloud" #name
echo "Insert" #mv_supported_capability
echo "Update" #mv_supported_capability
echo "Upsert" #mv_supported_capability
echo "Delete" #mv_supported_capability
