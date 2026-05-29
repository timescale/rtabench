
SELECT
    product_id,
    p.name,
    sum(oi.amount * p.price)
FROM
    products p
    INNER JOIN order_items oi USING (product_id)
    INNER JOIN orders o ON o.order_id = oi.order_id
        AND o.created_at > '2024-12-24'
        AND o.created_at < '2025-01-01'
    INNER JOIN customers c ON c.customer_id = o.customer_id
        AND age(now(), c.birthday) >= '18 years' AND age(now(), c.birthday) < '26 years'
GROUP BY
    product_id
ORDER BY
    sum(oi.amount * p.price) DESC
LIMIT 10;

