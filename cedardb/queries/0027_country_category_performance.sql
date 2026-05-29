
SELECT
	c.country,
    p.category,
    sum(p.price * oi.amount)
FROM
    products p
    INNER JOIN order_items oi USING (product_id)
    INNER JOIN orders o ON o.order_id = oi.order_id
    INNER JOIN customers c ON c.customer_id = o.customer_id AND c.country = 'Switzerland'
    INNER JOIN order_events oe ON oe.order_id = o.order_id
WHERE oe.event_created >= '2024-01-01' and oe.event_created < '2024-02-01'
AND oe.event_type = 'Delivered'
GROUP BY
    c.country, p.category ORDER BY country, p.category;

