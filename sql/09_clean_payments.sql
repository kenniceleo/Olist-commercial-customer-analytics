-- ============================================================
-- Olist Commercial & Customer Analytics
-- 08_clean_payments.sql
--
-- Purpose:
-- Standardise payment records while preserving payment-level
-- grain.
--
-- Grain:
-- One row per order_id + payment_sequential.
-- ============================================================


DROP TABLE IF EXISTS staging.payments CASCADE;


CREATE TABLE staging.payments AS

SELECT
    TRIM(order_id) AS order_id,

    payment_sequential,

    LOWER(
        TRIM(payment_type)
    ) AS payment_type,

    payment_installments,

    payment_value,


    CASE
        WHEN payment_value >= 0
        THEN TRUE
        ELSE FALSE
    END AS valid_payment_value,


    CASE
        WHEN payment_value = 0
        THEN TRUE
        ELSE FALSE
    END AS zero_payment_flag,


    CASE
        WHEN payment_installments >= 0
        THEN TRUE
        ELSE FALSE
    END AS valid_installments


FROM raw.order_payments;


ALTER TABLE staging.payments
ADD CONSTRAINT pk_staging_payments
PRIMARY KEY (
    order_id,
    payment_sequential
);


ALTER TABLE staging.payments
ADD CONSTRAINT fk_staging_payments_order
FOREIGN KEY (order_id)
REFERENCES staging.orders (order_id);


CREATE INDEX idx_staging_payments_type
ON staging.payments (payment_type);