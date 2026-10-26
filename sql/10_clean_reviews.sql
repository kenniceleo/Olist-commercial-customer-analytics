-- ============================================================
-- Olist Commercial & Customer Analytics
-- 09_clean_reviews.sql
--
-- Purpose:
-- Clean review records while preserving all source review rows.
--
-- Important:
-- review_id is NOT globally unique in the raw dataset.
-- Therefore a staging surrogate key is created.
--
-- Grain:
-- One source review row.
-- ============================================================


DROP TABLE IF EXISTS staging.reviews CASCADE;


CREATE TABLE staging.reviews AS

WITH prepared_reviews AS (

    SELECT
        TRIM(review_id) AS review_id,

        TRIM(order_id) AS order_id,

        review_score,

        NULLIF(
            TRIM(review_comment_title),
            ''
        ) AS review_comment_title,

        NULLIF(
            TRIM(review_comment_message),
            ''
        ) AS review_comment_message,

        review_creation_date,
        review_answer_timestamp,


        COUNT(*) OVER (
            PARTITION BY review_id
        ) AS review_id_occurrences,


        COUNT(*) OVER (
            PARTITION BY order_id
        ) AS order_review_count,


        ROW_NUMBER() OVER (

            PARTITION BY order_id

            ORDER BY
                review_answer_timestamp DESC NULLS LAST,
                review_creation_date DESC NULLS LAST,
                review_id DESC

        ) AS review_recency_rank

    FROM raw.order_reviews

),

numbered_reviews AS (

    SELECT
        ROW_NUMBER() OVER (

            ORDER BY
                order_id,
                review_creation_date,
                review_answer_timestamp,
                review_id,
                review_score

        ) AS review_row_id,

        *

    FROM prepared_reviews
)

SELECT
    review_row_id,

    review_id,
    order_id,

    review_score,

    review_comment_title,
    review_comment_message,

    review_creation_date,
    review_answer_timestamp,


    CASE
        WHEN review_score BETWEEN 1 AND 5
        THEN TRUE
        ELSE FALSE
    END AS valid_review_score,


    CASE
        WHEN review_comment_title IS NOT NULL
        THEN TRUE
        ELSE FALSE
    END AS has_review_title,


    CASE
        WHEN review_comment_message IS NOT NULL
        THEN TRUE
        ELSE FALSE
    END AS has_review_comment,


    review_id_occurrences,

    CASE
        WHEN review_id_occurrences > 1
        THEN TRUE
        ELSE FALSE
    END AS duplicated_review_id_flag,


    order_review_count,

    CASE
        WHEN order_review_count > 1
        THEN TRUE
        ELSE FALSE
    END AS multiple_reviews_for_order_flag,


    review_recency_rank,

    CASE
        WHEN review_recency_rank = 1
        THEN TRUE
        ELSE FALSE
    END AS latest_review_for_order_flag


FROM numbered_reviews;


ALTER TABLE staging.reviews
ADD CONSTRAINT pk_staging_reviews
PRIMARY KEY (review_row_id);


ALTER TABLE staging.reviews
ADD CONSTRAINT fk_staging_reviews_order
FOREIGN KEY (order_id)
REFERENCES staging.orders (order_id);


CREATE INDEX idx_staging_reviews_order
ON staging.reviews (order_id);


CREATE INDEX idx_staging_reviews_review_id
ON staging.reviews (review_id);