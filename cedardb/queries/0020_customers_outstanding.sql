
SELECT
    c.customer_id,
    c.name
FROM
    customers c
WHERE
    EXISTS (
        SELECT
            *
        FROM
            orders o
        WHERE
            o.customer_id = c.customer_id AND
            o.created_at >= '2024-12-25' AND o.created_at < '2025-01-01'
            AND NOT EXISTS (
                SELECT
                FROM
                    order_events oe
                WHERE
                    oe.event_type = 'Delivered'
                    AND oe.order_id = o.order_id))
ORDER BY c.customer_id;

