#!/bin/bash

WORKERS=8

# convert_to_columnstore is a procedure (since 2.18), so it must be invoked
# with CALL — and CALL doesn't accept a result-set the way SELECT does, so
# we can't batch chunks via a single VALUES list per worker. Instead, dump
# the chunk list once (outside the parallel section to avoid show_chunks
# locking) and fan one CALL per chunk across WORKERS via xargs -P.
sudo -u postgres psql test -At -c "SELECT ch::text FROM show_chunks('order_events') ch;" \
  | xargs -n 1 -P "$WORKERS" -I {} \
      sudo -u postgres psql test -c "SET client_min_messages TO error; CALL convert_to_columnstore('{}'::regclass);"
