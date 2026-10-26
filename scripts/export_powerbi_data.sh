#!/bin/bash

set -e

DB_NAME="olist_analytics"
OUTPUT_DIR="powerbi/data"

echo "Exporting Power BI datasets..."

mkdir -p "$OUTPUT_DIR"

psql -d "$DB_NAME" -c "\copy (
    SELECT *
    FROM bi.order_dashboard
    ORDER BY order_id
) TO '$OUTPUT_DIR/order_dashboard.csv'
WITH (FORMAT CSV, HEADER TRUE)"

psql -d "$DB_NAME" -c "\copy (
    SELECT *
    FROM bi.customer_dashboard
    ORDER BY customer_unique_id
) TO '$OUTPUT_DIR/customer_dashboard.csv'
WITH (FORMAT CSV, HEADER TRUE)"

psql -d "$DB_NAME" -c "\copy (
    SELECT *
    FROM bi.cohort_dashboard
    ORDER BY cohort_month, months_since_first_purchase
) TO '$OUTPUT_DIR/cohort_dashboard.csv'
WITH (FORMAT CSV, HEADER TRUE)"

psql -d "$DB_NAME" -c "\copy (
    SELECT *
    FROM bi.seller_dashboard
    ORDER BY seller_id
) TO '$OUTPUT_DIR/seller_dashboard.csv'
WITH (FORMAT CSV, HEADER TRUE)"

echo ""
echo "Export complete."
echo ""

wc -l "$OUTPUT_DIR"/*.csv