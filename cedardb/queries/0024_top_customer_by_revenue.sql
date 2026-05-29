
SELECT c.customer_id, c.name, sum(oi.amount*p.price) FROM customers c
INNER JOIN orders o ON o.customer_id=c.customer_id AND o.created_at > '2024-12-01' AND o.created_at < '2024-12-07'
INNER JOIN order_items oi USING(order_id)
INNER JOIN products p USING(product_id)
GROUP BY c.customer_id
ORDER BY sum(oi.amount*p.price) DESC LIMIT 10;

