#!/bin/bash

TRIES=3

for file in "$(dirname "$0")/queries"/*.sql; do
    query="$(cat "$file")"
    # We echo the query without any line breaks
    echo "$(tr '\n' ' ' < "$file" | tr -s " ")"
    for i in $(seq 1 $TRIES); do
        psql "$CONNECTION_STRING" --no-psqlrc --tuples-only \
            --command "\timing on" \
            --command "$query" | grep 'Time'
    done;
done;
