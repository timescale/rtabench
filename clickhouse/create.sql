DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS order_events;

CREATE TABLE customers
(
    customer_id integer not null,
    name text,
    birthday DateTime64,
    email text,
    address text,
    city text,
    zip text,
    state text,
    country text,
    PRIMARY KEY (customer_id)
);

CREATE TABLE products
(
    product_id integer not null,
    name text,
    description text,
    category text,
    price decimal(10,2),
    stock int,
    PRIMARY KEY (product_id)
);

CREATE TABLE orders
(
    order_id     integer not null,
    customer_id integer not null,
    created_at timestamp not null,
    PRIMARY KEY (order_id)
);

CREATE TABLE order_items
(
    order_id integer not null,
    product_id integer not null,
    amount integer not null,
    PRIMARY KEY (order_id, product_id)
);

CREATE TABLE order_events
(
    order_id         integer   not null,
    counter          integer,
    event_created    timestamp not null,
    event_type       text      not null,
    satisfaction     Float32      not null,
    processor        text      not null,
    backup_processor text,
    event_payload    text,
    PRIMARY KEY (order_id, event_created)
) ENGINE = MergeTree
PARTITION BY toYYYYMM(event_created);
