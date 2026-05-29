
SELECT
    p.category,
    sum(p.price * oi.amount)
FROM
    products p
    INNER JOIN order_items oi USING (product_id)
    INNER JOIN orders o ON o.order_id = oi.order_id
    INNER JOIN order_events oe ON oe.order_id = o.order_id
WHERE 
    oe.event_created >= '2024-01-01' and oe.event_created < '2024-01-07'
    AND oe.event_type = 'Delivered'
GROUP BY
    p.category
ORDER BY category;

