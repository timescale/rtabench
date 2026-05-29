SELECT p.product_id, p.name, sum(amount) 
FROM products p 
INNER JOIN order_items oi USING(product_id)
INNER JOIN order_events oe USING(order_id)
WHERE oe.event_created >= '2024-01-01' AND oe.event_created < '2024-02-01'
AND oe.event_type = 'Delivered'
GROUP BY product_id
ORDER BY sum(amount), p.name DESC LIMIT 10;
