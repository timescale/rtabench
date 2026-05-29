
SELECT
    c.country,
    sum(amount * price)
FROM
    customers c
    INNER JOIN orders o USING (customer_id)
    INNER JOIN order_items oi USING (order_id)
    INNER JOIN products USING (product_id)
WHERE
    o.created_at >= '2024-01-01' and o.created_at < '2024-02-01'
GROUP BY
    c.country
ORDER BY
    2 DESC;

