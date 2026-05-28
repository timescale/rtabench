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

# This benchmark uses terraform to provision a ClickHouse Cloud instance.

# set in CI with github actions secrets and auto-benchmark tool
# export CLICKHOUSE_ORGANIZATION_ID=...
# export CLICKHOUSE_TOKEN_KEY=...
# export CLICKHOUSE_TOKEN_SECRET=...
# export SIZE=... # GB size
export CLICKHOUSE_PASSWORD=testpass

#install clickhouse client
curl https://clickhouse.com/ | sh
sudo ./clickhouse install --noninteractive

#install terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
sudo apt-get install terraform

terraform init
 
terraform apply -auto-approve -var organization_id="$CLICKHOUSE_ORGANIZATION_ID" \
  -var token_key="$CLICKHOUSE_TOKEN_KEY" \
  -var token_secret="$CLICKHOUSE_TOKEN_SECRET" \
  -var service_password="$CLICKHOUSE_PASSWORD" \ 
  -var memory_gb="$SIZE" 

export CLICKHOUSE_HOST=$(terraform output --raw CLICKHOUSE_HOST)

clickhouse client --host "${CLICKHOUSE_HOST}" --password "${CLICKHOUSE_PASSWORD}" < create.sql #import

clickhouse client --host "${CLICKHOUSE_HOST}" --password "${CLICKHOUSE_PASSWORD}" --time --query "INSERT INTO customers FORMAT CSV" < dataset/customers.csv #import
clickhouse client --host "${CLICKHOUSE_HOST}" --password "${CLICKHOUSE_PASSWORD}" --time --query "INSERT INTO products FORMAT CSV" < dataset/products.csv #import
clickhouse client --host "${CLICKHOUSE_HOST}" --password "${CLICKHOUSE_PASSWORD}" --time --query "INSERT INTO orders FORMAT CSV" < dataset/orders.csv #import
clickhouse client --host "${CLICKHOUSE_HOST}" --password "${CLICKHOUSE_PASSWORD}" --time --query "INSERT INTO order_items FORMAT CSV" < dataset/order_items.csv #import
clickhouse client --host "${CLICKHOUSE_HOST}" --password "${CLICKHOUSE_PASSWORD}" --time --query "INSERT INTO order_events FORMAT CSV" < dataset/order_events.csv #import


# Create the projections. Note that we have to do this after the insert, otherwise
# the column structure of the event_payload is not deduced, and we get an error
# about missing column event_payload.terminal.:String.
clickhouse client --host "${CLICKHOUSE_HOST}" --password "${CLICKHOUSE_PASSWORD}" < mat_views.sql

# Run the queries

./run.sh "$@" #results

clickhouse client --host "${CLICKHOUSE_HOST}" --password "${CLICKHOUSE_PASSWORD}" --query "SELECT sum(total_bytes) FROM system.tables WHERE (name = 'orders' OR name = 'order_events' OR name = 'order_items' OR name = 'products' OR name = 'customers') and database = 'default'" #datasize

terraform destroy -auto-approve -var organization_id="$CLICKHOUSE_ORGANIZATION_ID" \
                    -var token_key="$CLICKHOUSE_TOKEN_KEY" \
                    -var token_secret="$CLICKHOUSE_TOKEN_SECRET" \
                    -var service_password="$CLICKHOUSE_PASSWORD" \
                    -var memory_gb="$SIZE" 

[[ "$SIZE" == "8" ]] && echo "6 vCPU 24 GB (3x: 2vCPU 8GB)" || ([[ "$SIZE" == "16" ]] && echo "12 vCPU 48 GB (3x: 4vCPU 16GB)") || ([[ "$SIZE" == "32" ]] && echo "24 vCPU 96 GB (3x: 8vCPU 32GB)") #machineType

echo "Real-time Analytics" #tag
echo "Batch Analytics" #tag
echo "3" #clusterSize
echo "ClickHouse Cloud (aws)" #name
echo "Insert" #mv_supported_capability