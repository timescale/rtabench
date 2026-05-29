
SELECT
    p.name,
    p.stock,
    sum(oi.amount)
FROM
    orders o
    INNER JOIN order_items oi USING (order_id)
    INNER JOIN products p USING (product_id)
WHERE
    o.created_at > '2024-12-01' AND o.created_at < '2024-12-07' AND
    NOT EXISTS (
        SELECT
        FROM
            order_events oe
        WHERE
            oe.event_type = 'Shipped'
            AND oe.order_id = oi.order_id)
GROUP BY
    p.product_id
HAVING (sum(oi.amount) < p.stock);

