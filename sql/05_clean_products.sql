-- ============================================================
-- Olist Commercial & Customer Analytics
-- 05_clean_products_and_sellers.sql
--
-- Purpose:
-- Clean product and seller dimensions.
-- ============================================================


-- ============================================================
-- PRODUCTS
--
-- Grain:
-- One row per product_id.
--
-- Notes:
-- - Product categories are translated to English where possible.
-- - Missing categories are retained and labelled "Unknown".
-- - Missing physical dimensions are NOT imputed.
-- ============================================================

DROP TABLE IF EXISTS staging.products CASCADE;


CREATE TABLE staging.products AS

SELECT
    TRIM(p.product_id) AS product_id,

    NULLIF(
        TRIM(p.product_category_name),
        ''
    ) AS product_category_name_original,

    COALESCE(
        NULLIF(
            TRIM(t.product_category_name_english),
            ''
        ),
        'unknown'
    ) AS product_category,

    CASE
        WHEN t.product_category_name_english IS NULL
            THEN 'Unknown'

        ELSE INITCAP(
            REPLACE(
                t.product_category_name_english,
                '_',
                ' '
            )
        )
    END AS product_category_label,

    p.product_name_length,
    p.product_description_length,
    p.product_photos_qty,

    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,

    CASE
        WHEN p.product_weight_g IS NOT NULL
         AND p.product_length_cm IS NOT NULL
         AND p.product_height_cm IS NOT NULL
         AND p.product_width_cm IS NOT NULL
        THEN TRUE
        ELSE FALSE
    END AS has_complete_dimensions

FROM raw.products p

LEFT JOIN raw.product_category_translation t
    ON p.product_category_name =
       t.product_category_name;


ALTER TABLE staging.products
ADD CONSTRAINT pk_staging_products
PRIMARY KEY (product_id);


CREATE INDEX idx_staging_products_category
ON staging.products (product_category);