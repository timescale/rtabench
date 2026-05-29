SELECT
    max(counter)
FROM
    order_events
WHERE
    event_created >= '2024-04-20' and event_created < '2024-05-20';
