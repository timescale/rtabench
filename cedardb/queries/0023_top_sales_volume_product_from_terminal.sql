SELECT
    product_id,
    p.name,
    sum(oi.amount * p.price)
FROM
    products p
    INNER JOIN order_items oi USING (product_id)
    INNER JOIN order_events oe ON oe.order_id = oi.order_id
    WHERE oe.event_payload->>'terminal' = 'Berlin'
    AND oe.event_created >= '2024-07-01' and oe.event_created < '2025-01-01'
    AND oe.event_type = 'Delivered'
GROUP BY
    p.product_id
ORDER BY
    sum(oi.amount * p.price) DESC
LIMIT 10;
