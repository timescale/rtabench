SELECT * FROM order_events
WHERE event_created >= '2024-03-01' and event_created < '2024-08-01'
  AND processor LIKE '%ron%' ORDER BY event_created LIMIT 10;
