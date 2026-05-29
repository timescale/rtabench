
SELECT
    c.customer_id,
    c.name,
    sum(oi.amount * p.price)
FROM
    customers c
    INNER JOIN orders o USING (customer_id)
    INNER JOIN order_items oi USING (order_id)
    INNER JOIN products p USING (product_id)
WHERE
    o.created_at >= '2024-01-01' and o.created_at < '2024-02-01'
GROUP BY
    c.customer_id
ORDER BY
    sum(oi.amount * p.price) DESC
LIMIT 10;

