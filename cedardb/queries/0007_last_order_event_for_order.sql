SELECT DISTINCT ON (oe.order_id) oe.order_id, event_created, event_type 
FROM order_events oe
JOIN orders ON orders.order_id = oe.order_id
WHERE orders.order_id = 2344
ORDER BY
    order_id ASC,
    event_created DESC;
