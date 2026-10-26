-- ============================================================
-- Olist Commercial & Customer Analytics
-- 07_clean_order_items.sql
--
-- Purpose:
-- Clean transaction line items while preserving item-level grain.
--
-- Grain:
-- One row per order_id + order_item_id.
-- ============================================================


DROP TABLE IF EXISTS staging.order_items CASCADE;


CREATE TABLE staging.order_items AS

SELECT
    TRIM(oi.order_id) AS order_id,

    oi.order_item_id,

    TRIM(oi.product_id) AS product_id,

    TRIM(oi.seller_id) AS seller_id,

    oi.shipping_limit_date,

    oi.price,

    oi.freight_value,


    -- Merchandise value excluding freight
    ROUND(
        oi.price,
        2
    ) AS item_gmv,


    -- Customer transaction value including freight
    ROUND(
        oi.price + oi.freight_value,
        2
    ) AS item_total_value,


    -- Freight relative to merchandise price
    CASE
        WHEN oi.price > 0

        THEN ROUND(
            (
                oi.freight_value / oi.price
            )::NUMERIC,
            4
        )

        ELSE NULL
    END AS freight_to_price_ratio,


    CASE
        WHEN oi.price >= 0
        THEN TRUE
        ELSE FALSE
    END AS valid_price,


    CASE
        WHEN oi.freight_value >= 0
        THEN TRUE
        ELSE FALSE
    END AS valid_freight,


    CASE
        WHEN oi.freight_value = 0
        THEN TRUE
        ELSE FALSE
    END AS free_shipping_flag


FROM raw.order_items oi;


ALTER TABLE staging.order_items
ADD CONSTRAINT pk_staging_order_items
PRIMARY KEY (order_id, order_item_id);


ALTER TABLE staging.order_items
ADD CONSTRAINT fk_staging_items_order
FOREIGN KEY (order_id)
REFERENCES staging.orders (order_id);


ALTER TABLE staging.order_items
ADD CONSTRAINT fk_staging_items_product
FOREIGN KEY (product_id)
REFERENCES staging.products (product_id);


ALTER TABLE staging.order_items
ADD CONSTRAINT fk_staging_items_seller
FOREIGN KEY (seller_id)
REFERENCES staging.sellers (seller_id);


CREATE INDEX idx_staging_items_product
ON staging.order_items (product_id);


CREATE INDEX idx_staging_items_seller
ON staging.order_items (seller_id);