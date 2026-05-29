SELECT *
FROM order_events
WHERE event_created >= '2024-01-01 00:00:00' and event_created < '2024-01-01 23:55:00'
  AND order_id = '512'
ORDER BY event_created;
