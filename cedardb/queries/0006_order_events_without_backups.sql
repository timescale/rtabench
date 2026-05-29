SELECT * FROM order_events 
         WHERE backup_processor <> '' ORDER BY event_created LIMIT 10;
