
WITH customer_ages AS (
    SELECT
        c.customer_id,
        age(now(), c.birthday) AS customer_age
    FROM
        customers c
)
SELECT
    sum(p.price * oi.amount) FILTER (WHERE ca.customer_age >= '18 year'::interval AND ca.customer_age < '26 year'::interval) AS "18-25",
    sum(p.price * oi.amount) FILTER (WHERE ca.customer_age >= '26 year'::interval AND ca.customer_age < '36 year'::interval) AS "26-35",
    sum(p.price * oi.amount) FILTER (WHERE ca.customer_age >= '36 year'::interval AND ca.customer_age < '51 year'::interval) AS "36-50",
    sum(p.price * oi.amount) FILTER (WHERE ca.customer_age >= '51 year'::interval AND ca.customer_age < '66 year'::interval) AS "51-65",
    sum(p.price * oi.amount) FILTER (WHERE ca.customer_age >= '66 year'::interval) AS "66+"
FROM
    products p
    INNER JOIN order_items oi USING (product_id)
    INNER JOIN orders o ON o.order_id = oi.order_id AND o.created_at > '2024-01-01' AND o.created_at < '2024-01-07'
    INNER JOIN customer_ages ca ON ca.customer_id = o.customer_id
    ;
