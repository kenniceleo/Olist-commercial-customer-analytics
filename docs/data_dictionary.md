# Data Dictionary

This document describes the main cleaned tables, analytical marts and BI-facing views used in the **Olist Commercial & Customer Analytics** project.

The raw Olist source tables are not documented exhaustively here. Instead, this dictionary focuses on the transformed fields used in the analysis, statistical validation and Power BI dashboard.

---

## 1. `staging.customers`

**Grain:** One row per `customer_id`

Cleaned customer identity and location table.

| Field                | Description                                                                             |
| -------------------- | --------------------------------------------------------------------------------------- |
| `customer_id`        | Order-level customer identifier from the source data                                    |
| `customer_unique_id` | Persistent customer identifier used to identify repeat customers across multiple orders |
| `customer_city`      | Cleaned customer city                                                                   |
| `customer_state`     | Customer state code                                                                     |

### Important note

`customer_id` is unique to an order-level customer record and should **not** be used to identify repeat purchasing.

All customer-level retention analysis uses:

```text
customer_unique_id
```

---

## 2. `staging.products`

**Grain:** One row per `product_id`

Cleaned product attributes with translated category names.

| Field                     | Description                                                                |
| ------------------------- | -------------------------------------------------------------------------- |
| `product_id`              | Unique product identifier                                                  |
| `product_category`        | English product-category name after joining the category translation table |
| `product_category_label`  | Cleaned/display-ready product-category label                               |
| `has_complete_dimensions` | Indicates whether required product dimensional attributes are available    |

Products without a successfully translated category are retained and assigned an `unknown` category rather than being removed.

---

## 3. `staging.sellers`

**Grain:** One row per `seller_id`

Cleaned seller identity and location information.

| Field          | Description              |
| -------------- | ------------------------ |
| `seller_id`    | Unique seller identifier |
| `seller_city`  | Cleaned seller city      |
| `seller_state` | Seller state code        |

---

## 4. `staging.orders`

**Grain:** One row per `order_id`

Cleaned order table containing customer identity, purchase timestamps and derived fulfilment metrics.

| Field                        | Description                                                           |
| ---------------------------- | --------------------------------------------------------------------- |
| `order_id`                   | Unique order identifier                                               |
| `customer_id`                | Source customer identifier                                            |
| `customer_unique_id`         | Persistent customer identifier joined from `staging.customers`        |
| `customer_state`             | Customer state                                                        |
| `order_status`               | Source order status                                                   |
| `order_purchase_timestamp`   | Timestamp at which the order was placed                               |
| `purchase_date`              | Date component of the purchase timestamp                              |
| `purchase_month`             | Purchase month used for monthly analysis                              |
| `is_delivered`               | Indicates whether the order status is delivered                       |
| `seller_processing_days`     | Time from order approval to carrier handoff, in days                  |
| `delivery_days`              | Time from purchase to customer delivery, in days                      |
| `carrier_delivery_days`      | Time from carrier handoff to customer delivery                        |
| `days_vs_estimated_delivery` | Difference between actual and estimated delivery date                 |
| `late_delivery_flag`         | Indicates whether the order arrived after the estimated delivery date |

### Timestamp-quality handling

Invalid operational durations are converted to `NULL` rather than forcing incorrect values.

For example, some delivered orders contain:

- missing approval timestamps,
- missing carrier timestamps,
- carrier handoff timestamps occurring before approval.

These orders remain available for commercial analysis while invalid operational metrics are excluded from fulfilment calculations.

---

## 5. `staging.order_items`

**Grain:** One row per `order_id × order_item_id`

Cleaned order-item fact table.

| Field                    | Description                                                        |
| ------------------------ | ------------------------------------------------------------------ |
| `order_id`               | Order identifier                                                   |
| `order_item_id`          | Item sequence within the order                                     |
| `product_id`             | Product identifier                                                 |
| `seller_id`              | Seller responsible for the item                                    |
| `price`                  | Merchandise price                                                  |
| `freight_value`          | Freight charged for the item                                       |
| `item_gmv`               | Merchandise value attributed to the item; equivalent to item price |
| `item_total_value`       | Merchandise price plus freight                                     |
| `freight_to_price_ratio` | Freight divided by merchandise price                               |
| `free_shipping_flag`     | Indicates whether freight value is zero                            |

### GMV definition

Throughout this project:

```text
GMV = merchandise value
```

It is calculated using item prices and should **not** be interpreted as Olist corporate revenue or profit.

---

## 6. `staging.payments`

**Grain:** One row per payment component

An order may contain more than one payment component.

| Field                  | Description                              |
| ---------------------- | ---------------------------------------- |
| `order_id`             | Order identifier                         |
| `payment_sequential`   | Sequence number of the payment component |
| `payment_type`         | Standardised payment method              |
| `payment_installments` | Number of payment instalments            |
| `payment_value`        | Value of the payment component           |

---

## 7. `staging.reviews`

**Grain:** One row per source review row

Every review row is retained, including cases where an order has more than one review record.

| Field                        | Description                                                              |
| ---------------------------- | ------------------------------------------------------------------------ |
| `review_row_id`              | Surrogate identifier generated for each source review row                |
| `review_id`                  | Review identifier from the source dataset                                |
| `order_id`                   | Order associated with the review                                         |
| `review_score`               | Customer review score from 1 to 5                                        |
| `multiple_reviews_for_order` | Indicates whether the order contains multiple review rows                |
| `reused_review_id_flag`      | Indicates whether the same review ID appears in more than one source row |
| `review_recency_rank`        | Ranking used to identify the latest review for an order                  |
| `latest_review_flag`         | Indicates the most recent review record for an order                     |

A surrogate `review_row_id` is required because `review_id` is not globally unique in the source data.

---

# Analytical Marts

## 8. `analytics.order_mart`

**Grain:** One row per order

This is the central order-level analytical mart used for commercial and fulfilment analysis.

One-to-many source tables are aggregated **before joining** to prevent row multiplication.

### Identity and time fields

| Field                      | Description                    |
| -------------------------- | ------------------------------ |
| `order_id`                 | Unique order identifier        |
| `customer_unique_id`       | Persistent customer identifier |
| `customer_state`           | Customer state                 |
| `order_purchase_timestamp` | Exact order purchase timestamp |
| `purchase_date`            | Purchase date                  |
| `purchase_month`           | Purchase month                 |
| `is_delivered`             | Delivered-order indicator      |

### Commercial fields

| Field                      | Description                                                       |
| -------------------------- | ----------------------------------------------------------------- |
| `item_count`               | Number of order items                                             |
| `distinct_products`        | Number of distinct products in the order                          |
| `distinct_sellers`         | Number of distinct sellers participating in the order             |
| `order_gmv`                | Sum of merchandise value across order items                       |
| `freight_value`            | Total freight value across order items                            |
| `merchandise_plus_freight` | GMV plus freight                                                  |
| `freight_to_gmv_ratio`     | Freight divided by order GMV                                      |
| `primary_category`         | Category contributing the largest item-level GMV within the order |
| `distinct_categories`      | Number of distinct product categories in the order                |

### Payment fields

| Field                  | Description                                                  |
| ---------------------- | ------------------------------------------------------------ |
| `payment_components`   | Number of payment components                                 |
| `methods_used`         | Number of distinct payment methods used                      |
| `total_payment_value`  | Sum of payment components                                    |
| `max_installments`     | Maximum instalment count used on the order                   |
| `primary_payment_type` | Payment method associated with the largest payment component |

### Review fields

| Field                 | Description                                                    |
| --------------------- | -------------------------------------------------------------- |
| `review_count`        | Number of review records associated with the order             |
| `avg_review_score`    | Average review score across review records                     |
| `min_review_score`    | Minimum review score                                           |
| `max_review_score`    | Maximum review score                                           |
| `latest_review_score` | Most recent review score                                       |
| `has_review_comment`  | Indicates whether review text/comment information is available |

### Fulfilment fields

| Field                        | Description                                    |
| ---------------------------- | ---------------------------------------------- |
| `seller_processing_days`     | Approval-to-carrier processing time            |
| `delivery_days`              | Purchase-to-delivery duration                  |
| `carrier_delivery_days`      | Carrier-to-customer delivery duration          |
| `days_vs_estimated_delivery` | Actual delivery relative to estimated delivery |
| `late_delivery_flag`         | Whether the order arrived later than estimated |

---

## 9. `analytics.customer_mart`

**Grain:** One row per `customer_unique_id`

Built from delivered orders only.

This mart supports repeat-purchase, retention and first-order behaviour analysis.

### Customer lifecycle fields

| Field                     | Description                                                      |
| ------------------------- | ---------------------------------------------------------------- |
| `customer_unique_id`      | Persistent customer identifier                                   |
| `first_order_timestamp`   | Timestamp of first delivered purchase                            |
| `second_order_timestamp`  | Timestamp of second delivered purchase, where available          |
| `last_order_timestamp`    | Timestamp of most recent delivered purchase                      |
| `first_order_date`        | Date of first delivered purchase                                 |
| `last_order_date`         | Date of most recent delivered purchase                           |
| `delivered_orders`        | Number of delivered orders                                       |
| `repeat_customer_flag`    | Indicates whether the customer has at least two delivered orders |
| `days_to_second_purchase` | Time between first and second delivered purchases                |
| `customer_lifespan_days`  | Time between first and last observed delivered purchase          |
| `recency_days`            | Days since last purchase relative to the dataset observation end |

### Customer value fields

| Field                     | Description                                    |
| ------------------------- | ---------------------------------------------- |
| `total_gmv`               | Customer's total delivered merchandise value   |
| `average_order_value`     | Customer total GMV divided by delivered orders |
| `total_freight`           | Total freight paid across delivered orders     |
| `total_transaction_value` | Merchandise plus freight                       |
| `frequency`               | Delivered-order count                          |
| `monetary`                | Customer total GMV                             |

### First-order features

| Field                         | Description                                          |
| ----------------------------- | ---------------------------------------------------- |
| `first_order_id`              | First delivered order                                |
| `first_order_state`           | Customer state on the first order                    |
| `first_order_gmv`             | Merchandise value of the first order                 |
| `first_order_freight`         | Freight value of the first order                     |
| `first_order_freight_ratio`   | Freight-to-GMV ratio of the first order              |
| `first_order_item_count`      | Number of items in the first order                   |
| `first_order_products`        | Number of distinct products                          |
| `first_order_sellers`         | Number of distinct sellers                           |
| `first_order_category`        | Primary category of the first order                  |
| `first_order_payment_type`    | Primary payment method of the first order            |
| `first_order_installments`    | Instalment count                                     |
| `first_order_review_score`    | Latest review score associated with first order      |
| `first_order_processing_days` | Seller processing duration for first order           |
| `first_order_delivery_days`   | Total delivery duration for first order              |
| `first_order_late_flag`       | Whether first order arrived after estimated delivery |

### Observation-window fields

| Field                   | Description                                                              |
| ----------------------- | ------------------------------------------------------------------------ |
| `eligible_30d_followup` | Customer had at least 30 days of potential observation after first order |
| `eligible_60d_followup` | Customer had at least 60 days of potential observation                   |
| `eligible_90d_followup` | Customer had at least 90 days of potential observation                   |
| `repeated_within_30d`   | Second delivered purchase occurred within 30 days                        |
| `repeated_within_60d`   | Second delivered purchase occurred within 60 days                        |
| `repeated_within_90d`   | Second delivered purchase occurred within 90 days                        |

These eligibility fields are used to reduce **right-censoring** when comparing repeat behaviour.

---

## 10. `analytics.cohort_retention`

**Grain:** One row per:

```text
cohort_month × months_since_first_purchase
```

Supports cohort-retention analysis.

| Field                         | Description                                                                   |
| ----------------------------- | ----------------------------------------------------------------------------- |
| `cohort_month`                | Month of customer's first delivered purchase                                  |
| `months_since_first_purchase` | Number of calendar months since the cohort month                              |
| `cohort_customers`            | Number of customers originally entering the cohort                            |
| `active_customers`            | Distinct customers purchasing in the specified month offset                   |
| `retention_rate_pct`          | Active customers divided by original cohort size, stored as percentage points |

Example:

```text
0.50
```

represents:

```text
0.50%
```

rather than:

```text
50%
```

---

## 11. `analytics.customer_segments`

**Grain:** One row per `customer_unique_id`

Behaviour/value segmentation built from `analytics.customer_mart`.

| Field                  | Description                                                     |
| ---------------------- | --------------------------------------------------------------- |
| `customer_unique_id`   | Customer identifier                                             |
| `customer_value_band`  | High Value or Standard Value                                    |
| `behavior_segment`     | Repeat, Recent One-Time, or Lapsed One-Time                     |
| `customer_segment`     | Combined behaviour/value segment                                |
| `high_value_threshold` | 75th percentile of customer total GMV used to define High Value |

Final segments:

```text
Repeat High Value
Repeat Standard Value
Recent High Value One-Time
Recent Standard One-Time
Lapsed High Value One-Time
Lapsed Standard One-Time
```

### Segment definitions

**High Value**

Customer total GMV is at or above the 75th percentile.

**Recent One-Time**

Customer has one delivered order and their latest purchase is within 90 days of the dataset observation end.

**Lapsed One-Time**

Customer has one delivered order and no observed purchase within the final 90 days of the dataset.

`Lapsed` is an observational label and should **not** be interpreted as confirmed churn.

---

## 12. `analytics.seller_mart`

**Grain:** One row per seller

Supports seller commercial-performance and fulfilment analysis.

### Commercial fields

| Field                      | Description                                                      |
| -------------------------- | ---------------------------------------------------------------- |
| `seller_id`                | Seller identifier                                                |
| `seller_state`             | Seller state                                                     |
| `delivered_orders`         | Delivered orders containing items attributable to the seller     |
| `items_sold`               | Delivered items sold                                             |
| `unique_customers`         | Distinct customers served                                        |
| `seller_gmv`               | Merchandise value attributable to seller items                   |
| `seller_freight`           | Freight attributable to seller items                             |
| `avg_seller_gmv_per_order` | Average seller-attributed GMV per order                          |
| `multi_seller_orders`      | Orders in which the seller participated alongside another seller |
| `seller_gmv_rank`          | Seller rank by delivered GMV                                     |

### Operational fields

| Field                        | Description                                                  |
| ---------------------------- | ------------------------------------------------------------ |
| `single_seller_orders`       | Orders used for seller-specific operational attribution      |
| `avg_seller_processing_days` | Average processing time on attributable single-seller orders |
| `avg_delivery_days`          | Average total delivery duration                              |
| `late_orders`                | Number of attributable late deliveries                       |
| `late_delivery_rate_pct`     | Late-delivery percentage                                     |
| `avg_review_score`           | Average review score on attributable single-seller orders    |

### Attribution rule

Commercial seller metrics use all delivered seller-specific item records because seller ownership is known directly from the order-item table.

Operational order-level metrics use **single-seller orders only**.

This avoids attributing a multi-seller order's:

- delivery delay,
- review score,
- total fulfilment outcome

to every participating seller.

---

# BI-Facing Views

## 13. `bi.order_dashboard`

**Grain:** One row per order

Direct BI-facing view of:

```text
analytics.order_mart
```

Used primarily by:

- Executive Commercial Overview
- marketplace fulfilment analysis
- geography analysis
- payment analysis

---

## 14. `bi.customer_dashboard`

**Grain:** One row per customer

Combines:

```text
analytics.customer_mart
+
analytics.customer_segments
```

through `customer_unique_id`.

Used primarily by:

- repeat-customer analysis,
- 30/60/90-day repeat metrics,
- strict 1–90 day return analysis,
- customer segmentation,
- first-order characteristics.

---

## 15. `bi.cohort_dashboard`

**Grain:** One row per cohort month × month offset

Direct BI-facing view of:

```text
analytics.cohort_retention
```

Used to construct the Power BI cohort-retention heatmap.

---

## 16. `bi.seller_dashboard`

**Grain:** One row per seller

Direct BI-facing view of:

```text
analytics.seller_mart
```

Used for:

- seller operational comparison,
- seller processing-time analysis,
- late-delivery risk,
- high-volume seller investigation.

---

# Key Analytical Definitions

## Delivered Order

An order whose final source status is `delivered`.

Most commercial and customer-behaviour analysis is restricted to delivered transactions.

---

## GMV

```text
GMV = sum of merchandise item prices
```

Freight is tracked separately.

GMV should not be interpreted as:

- corporate revenue,
- gross profit,
- net revenue,
- marketplace take rate.

The source dataset does not contain the information required to calculate those measures.

---

## Repeat Customer

A customer with at least two observed delivered orders.

---

## 90-Day Repeat Rate

Among customers whose first delivered purchase occurred early enough to provide at least 90 days of observation:

```text
customers with second purchase within 90 days
------------------------------------------------
eligible customers
```

---

## Strict 1–90 Day Return Rate

A stricter retention measure excluding second purchases made within the first 24 hours.

```text
second purchase >= 1 day
and
second purchase <= 90 days
```

This is used because purchases occurring within 24 hours may represent:

- split orders,
- forgotten items,
- continuation of the same shopping session,

rather than a genuine customer return.

---

## Late Delivery

An order delivered after its estimated delivery date.

---

## Customer Observation End

The maximum delivered purchase date in the analytical dataset.

Recency and fixed follow-up eligibility are evaluated relative to this observation window.

---

# Power BI Relationships

The Power BI semantic model uses:

```text
customer_dashboard
        1
        │
        *
order_dashboard
```

on:

```text
customer_unique_id
```

and:

```text
Date
  1
  │
  *
order_dashboard
```

on:

```text
purchase_date
```

`cohort_dashboard` and `seller_dashboard` remain purpose-specific disconnected tables to avoid unnecessary or ambiguous relationships between marts at different analytical grains.
