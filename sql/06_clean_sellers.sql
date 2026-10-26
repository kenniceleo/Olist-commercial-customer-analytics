-- ============================================================
-- SELLERS
--
-- Grain:
-- One row per seller_id.
-- ============================================================

DROP TABLE IF EXISTS staging.sellers CASCADE;


CREATE TABLE staging.sellers AS

SELECT
    TRIM(seller_id) AS seller_id,

    seller_zip_code_prefix,

    NULLIF(
        TRIM(seller_city),
        ''
    ) AS seller_city,

    NULLIF(
        UPPER(TRIM(seller_state)),
        ''
    ) AS seller_state

FROM raw.sellers;


ALTER TABLE staging.sellers
ADD CONSTRAINT pk_staging_sellers
PRIMARY KEY (seller_id);


CREATE INDEX idx_staging_sellers_state
ON staging.sellers (seller_state);