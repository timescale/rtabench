
SELECT sum(oi.amount*p.price)/count(DISTINCT order_id)
FROM orders o
INNER JOIN order_items oi USING (order_id)
INNER JOIN products p USING (product_id)
WHERE o.created_at >= '2024-01-01' AND o.created_at < '2024-01-07';
