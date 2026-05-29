SELECT
    c.customer_id,
    c.name,
    count(o.order_id)
FROM
    customers c
    INNER JOIN orders o USING (customer_id)
WHERE
    o.created_at >= '2024-01-01' and o.created_at < '2024-07-01'
GROUP BY
    c.customer_id
ORDER BY
    count(o.order_id) DESC, c.name
LIMIT 10;

