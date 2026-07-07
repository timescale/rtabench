#!/bin/bash

TRIES=3

# Queries that legitimately return zero rows on the benchmark dataset, so the
# rowcount tripwire below must not flag them. This is engine-independent: 0019
# filters on NOT EXISTS (event_type = 'Shipped'), but the dataset contains no
# 'Shipped' events, so the anti-join is always true and the HAVING
# (sum(amount) < stock) then eliminates every group -> 0 rows. It is identical
# to postgres/queries/0019, which returns the same empty result on a plain row
# store. Keep this list tight -- any query NOT listed here that returns zero
# rows still trips the tripwire.
EXPECTED_EMPTY=("0019_out_of_stock_products.sql")

zero_row_queries=()

for file in "$(dirname "$0")/queries"/*.sql; do
    query="$(cat "$file")"
    # We echo the query without any line breaks
    echo "$(tr '\n' ' ' < "$file" | tr -s " ")"
    for i in $(seq 1 $TRIES); do
        psql "$CONNECTION_STRING" --no-psqlrc --tuples-only \
            --command "\timing on" \
            --command "$query" | grep 'Time'
    done;

    # Rowcount tripwire. Runs once, after the timed tries. A query that returns
    # zero rows against the full dataset is almost always a silent failure --
    # e.g. a misconfiguration that quietly returns empty result sets while still
    # looking fast -- rather than a real speedup, and the timing loop above only
    # greps "Time:", so it is blind to this. Wrapping in count(*) is safe: every
    # query file is a single statement, and CTEs/ORDER BY are legal in a
    # FROM-subquery.
    rows=$(psql "$CONNECTION_STRING" --no-psqlrc --tuples-only --no-align \
        --command "SELECT count(*) FROM (${query%;}) _rtabench_rowcount;")
    base="$(basename "$file")"
    if printf '%s\n' "${EXPECTED_EMPTY[@]}" | grep -qxF "$base"; then
        echo "Rows: ${rows} (expected empty)"
    elif ! [[ "$rows" =~ ^[0-9]+$ ]] || [ "$rows" -eq 0 ]; then
        echo "Rows: ${rows}"
        echo "WARNING: $base returned 0 rows (got '${rows}') -- possible silent failure" >&2
        zero_row_queries+=("$base")
    else
        echo "Rows: ${rows}"
    fi
done;

if [ ${#zero_row_queries[@]} -gt 0 ]; then
    echo "ERROR: ${#zero_row_queries[@]} query/queries returned zero rows -- likely a silent failure, results are NOT trustworthy:" >&2
    printf '  - %s\n' "${zero_row_queries[@]}" >&2
fi
