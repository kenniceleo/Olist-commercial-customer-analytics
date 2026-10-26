-- ============================================================
-- Olist Commercial & Customer Analytics
-- 06_clean_orders.sql
--
-- Purpose:
-- Standardise orders and derive reliable operational metrics.
--
-- Grain:
-- One row per order_id.
-- ============================================================


DROP TABLE IF EXISTS staging.orders CASCADE;


CREATE TABLE staging.orders AS

SELECT
    TRIM(o.order_id) AS order_id,

    TRIM(o.customer_id) AS customer_id,

    c.customer_unique_id,

    c.customer_zip_code_prefix,
    c.customer_city,
    c.customer_state,

    LOWER(TRIM(o.order_status))
        AS order_status,

    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,


    -- ========================================================
    -- CALENDAR FIELDS
    -- ========================================================

    o.order_purchase_timestamp::DATE
        AS purchase_date,

    DATE_TRUNC(
        'month',
        o.order_purchase_timestamp
    )::DATE AS purchase_month,

    EXTRACT(
        YEAR FROM o.order_purchase_timestamp
    )::INTEGER AS purchase_year,

    EXTRACT(
        MONTH FROM o.order_purchase_timestamp
    )::INTEGER AS purchase_month_number,


    -- ========================================================
    -- ORDER STATUS
    -- ========================================================

    CASE
        WHEN LOWER(TRIM(o.order_status)) = 'delivered'
        THEN TRUE
        ELSE FALSE
    END AS is_delivered,


    -- ========================================================
    -- TIMESTAMP VALIDITY
    -- ========================================================

    CASE
        WHEN o.order_approved_at IS NULL
            THEN FALSE

        WHEN o.order_approved_at <
             o.order_purchase_timestamp
            THEN FALSE

        ELSE TRUE
    END AS valid_approval_timestamp,


    CASE
        WHEN o.order_delivered_carrier_date IS NULL
            THEN FALSE

        WHEN o.order_delivered_carrier_date <
             o.order_purchase_timestamp
            THEN FALSE

        ELSE TRUE
    END AS valid_carrier_timestamp,


    CASE
        WHEN o.order_delivered_customer_date IS NULL
            THEN FALSE

        WHEN o.order_delivered_customer_date <
             o.order_purchase_timestamp
            THEN FALSE

        WHEN o.order_delivered_carrier_date IS NOT NULL
         AND o.order_delivered_customer_date <
             o.order_delivered_carrier_date
            THEN FALSE

        ELSE TRUE
    END AS valid_delivery_timestamp,


    -- ========================================================
    -- SELLER PROCESSING TIME
    --
    -- Approval -> carrier handoff
    --
    -- Invalid or missing chronology becomes NULL rather than
    -- deleting the order.
    -- ========================================================

    CASE
        WHEN o.order_approved_at IS NOT NULL

         AND o.order_delivered_carrier_date IS NOT NULL

         AND o.order_delivered_carrier_date >=
             o.order_approved_at

        THEN ROUND(
            (
                EXTRACT(
                    EPOCH FROM (
                        o.order_delivered_carrier_date
                        - o.order_approved_at
                    )
                ) / 86400.0
            )::NUMERIC,
            2
        )

        ELSE NULL
    END AS seller_processing_days,


    -- ========================================================
    -- END-TO-END DELIVERY TIME
    --
    -- Purchase -> customer delivery
    -- ========================================================

    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL

         AND o.order_delivered_customer_date >=
             o.order_purchase_timestamp

         AND (
             o.order_delivered_carrier_date IS NULL

             OR

             o.order_delivered_customer_date >=
             o.order_delivered_carrier_date
         )

        THEN ROUND(
            (
                EXTRACT(
                    EPOCH FROM (
                        o.order_delivered_customer_date
                        - o.order_purchase_timestamp
                    )
                ) / 86400.0
            )::NUMERIC,
            2
        )

        ELSE NULL
    END AS delivery_days,


    -- ========================================================
    -- CARRIER DELIVERY TIME
    --
    -- Carrier handoff -> customer delivery
    -- ========================================================

    CASE
        WHEN o.order_delivered_carrier_date IS NOT NULL

         AND o.order_delivered_customer_date IS NOT NULL

         AND o.order_delivered_customer_date >=
             o.order_delivered_carrier_date

        THEN ROUND(
            (
                EXTRACT(
                    EPOCH FROM (
                        o.order_delivered_customer_date
                        - o.order_delivered_carrier_date
                    )
                ) / 86400.0
            )::NUMERIC,
            2
        )

        ELSE NULL
    END AS carrier_delivery_days,


    -- ========================================================
    -- PERFORMANCE AGAINST ESTIMATE
    -- ========================================================

    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL

         AND o.order_estimated_delivery_date IS NOT NULL

         AND o.order_delivered_customer_date >=
             o.order_purchase_timestamp

         AND (
             o.order_delivered_carrier_date IS NULL

             OR

             o.order_delivered_customer_date >=
             o.order_delivered_carrier_date
         )

        THEN ROUND(
            (
                EXTRACT(
                    EPOCH FROM (
                        o.order_delivered_customer_date
                        - o.order_estimated_delivery_date
                    )
                ) / 86400.0
            )::NUMERIC,
            2
        )

        ELSE NULL
    END AS days_vs_estimated_delivery,


    CASE
        WHEN o.order_delivered_customer_date IS NULL
          OR o.order_estimated_delivery_date IS NULL
            THEN NULL

        WHEN o.order_delivered_customer_date <
             o.order_purchase_timestamp
            THEN NULL

        WHEN o.order_delivered_carrier_date IS NOT NULL
         AND o.order_delivered_customer_date <
             o.order_delivered_carrier_date
            THEN NULL

        WHEN o.order_delivered_customer_date >
             o.order_estimated_delivery_date
            THEN TRUE

        ELSE FALSE
    END AS late_delivery_flag


FROM raw.orders o

LEFT JOIN staging.customers c
    ON o.customer_id = c.customer_id;


ALTER TABLE staging.orders
ADD CONSTRAINT pk_staging_orders
PRIMARY KEY (order_id);


ALTER TABLE staging.orders
ADD CONSTRAINT fk_staging_orders_customer
FOREIGN KEY (customer_id)
REFERENCES staging.customers (customer_id);


CREATE INDEX idx_staging_orders_unique_customer
ON staging.orders (customer_unique_id);


CREATE INDEX idx_staging_orders_purchase_date
ON staging.orders (purchase_date);


CREATE INDEX idx_staging_orders_status
ON staging.orders (order_status);