
SELECT
    c.country,
    c.state,
    sum(amount * price)
FROM
    customers c
    INNER JOIN orders o ON o.customer_id = c.customer_id AND o.created_at >= '2024-12-24' AND o.created_at < '2025-01-01'
    INNER JOIN order_items oi USING (order_id)
    INNER JOIN products USING (product_id)
GROUP BY GROUPING SETS ((country), (country, state), ())
ORDER BY
    sum(amount * price), country, state;

