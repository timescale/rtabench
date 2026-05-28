#!/bin/bash

WORKERS=8

# we have to get the list of chunks to process outside of workers otherwise
# show_chunks would lock the other workers out
CHUNKS=$(psql $CONNECTION_STRING -t -X -c "SELECT string_agg('(''' || ch::text || ''')', ',') FROM (SELECT row_number() over (), * from show_chunks('order_events') ch) ch GROUP BY row_number%${WORKERS};")

# start processes to compress in parallel
for chunk in $(echo $CHUNKS); do
  psql  $CONNECTION_STRING -c "set client_min_messages to error;SELECT compress_chunk(c::regclass) FROM (VALUES $chunk) v(c);" &
done
wait
