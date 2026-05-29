SELECT date_trunc('day', event_created) as day,
       count(*)                            as count
FROM order_events
WHERE event_created >= '2024-05-01' and event_created < '2024-06-01'
  AND event_payload -> 'status' @> '["Delayed", "Priority"]'
GROUP BY day
ORDER BY count desc, day
limit 20;
