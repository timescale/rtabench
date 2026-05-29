SELECT
    c.customer_id,
    c.name,
    count(o.order_id)
FROM
    customers c
    INNER JOIN orders o USING (customer_id)
    INNER JOIN order_events oe USING (order_id)
WHERE
    oe.event_created >= '2024-01-01' and oe.event_created < '2024-07-01'
    and oe.event_type = 'Delivered'
GROUP BY
    c.customer_id
ORDER BY
    count(o.order_id) DESC
LIMIT 10;