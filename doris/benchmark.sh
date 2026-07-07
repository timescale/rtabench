#!/bin/bash

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
sed 's/""/\\"/g' ./dataset/order_events.csv > ./dataset/order_events2.csv # fix escaping issues in order_events.csv

# Install
export DORIS_FULL_NAME="apache-doris-3.0.6-bin-x64"
wget https://apache-doris-releases.oss-accelerate.aliyuncs.com/${DORIS_FULL_NAME}.tar.gz
mkdir ${DORIS_FULL_NAME}
tar -xvf ${DORIS_FULL_NAME}.tar.gz --strip-components 1 -C ${DORIS_FULL_NAME}
sudo apt-get update
sudo apt-get install -y mysql-client openjdk-17-jre-headless

# Deploy and configure
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
sudo sysctl -w vm.max_map_count=2000000

sudo swapoff -a

# Start Doris with proper file descriptor limits using wrapper scripts
echo "Starting Doris with file descriptor limits..."
bash -c "ulimit -n 655350 && ${DORIS_FULL_NAME}/be/bin/start_be.sh --daemon"
bash -c "ulimit -n 655350 && ${DORIS_FULL_NAME}/fe/bin/start_fe.sh --daemon"

echo "Sleep 60 sec to wait doris start"
sleep 60s

mysql -P 9030 -h 127.0.0.1 -u root -e "ALTER SYSTEM ADD BACKEND \"127.0.0.1:9050\";"

echo "Sleep 10 sec to wait frontend are connected to backend"
sleep 10s

# Create database and schema
mysql -P 9030 -h 127.0.0.1 -u root -e "DROP DATABASE IF EXISTS rta"
mysql -P 9030 -h 127.0.0.1 -u root -e "CREATE DATABASE rta"
mysql -P 9030 -h 127.0.0.1 -u root -D rta < create.sql

# Import dataset
mysql -P 9030 -h 127.0.0.1 -u root -D rta --local-infile=1 < load.sql #import

# Run the queries
./run.sh 2>&1 | tee log.txt

# Get the data size
mysql -P 9030 -h 127.0.0.1 -u root -D rta -e "SHOW DATA" | awk '{line[NR]=$0} END{split(line[NR-2], a, " "); print a[2] a[3]}' #datasize

cat log.txt |
  grep -P 'rows? in set|Empty set|^ERROR' |
  sed -r -e 's/^ERROR.*$/\-1/; s/^.*?\((([0-9.]+) min )?([0-9.]+) sec\).*?$/\2 \3/' |
  awk '{ if ($2) { print $1 * 60 + $2 } else { print $1 } }' |
  awk '{ if (i % 3 == 0) { printf "[" }; printf $1; if (i % 3 != 2) { printf "," } else { print "]," }; ++i; }' #results

echo "Real-time Analytics" #tag
echo "Batch Analytics" #tag
echo "Doris" #name
