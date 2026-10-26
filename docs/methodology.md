# Methodology

This document describes the analytical methodology used in the **Olist Commercial & Customer Analytics** project, including data-quality treatment, metric definitions, customer-retention logic, seller attribution, statistical validation and key limitations.

The objective is to ensure that business findings are based on consistent analytical definitions and that limitations in the source data are handled explicitly rather than hidden.

---

# 1. Analytical Scope

The project addresses the business question:

> **How can an e-commerce marketplace improve commercial performance and customer retention by understanding customer behaviour, product/category performance, seller performance and fulfilment experience?**

The analysis is organised around three analytical pillars:

1. **Commercial Performance**
   - GMV and order trends
   - product-category performance
   - customer geography
   - payment behaviour
   - seller concentration

2. **Customer & Retention**
   - repeat purchasing
   - fixed-horizon repeat rates
   - cohort retention
   - customer segmentation
   - first-order characteristics associated with subsequent purchases

3. **Seller & Fulfilment**
   - seller processing performance
   - delivery duration
   - late-delivery rates
   - customer reviews
   - geographic fulfilment differences
   - seller operational-risk identification

---

# 2. Data Pipeline

The analytical workflow follows:

```text
Olist source CSVs
      ↓
PostgreSQL raw schema
      ↓
data-quality audit
      ↓
clean staging tables
      ↓
validated analytical marts
      ↓
SQL business analysis
      ↓
Python statistical validation
      ↓
BI-facing SQL views
      ↓
reproducible CSV extracts
      ↓
Power BI + DAX
```

Business logic is implemented primarily in PostgreSQL rather than directly in Power BI.

This keeps:

- cleaning,
- metric definitions,
- analytical grains,
- customer lifecycle logic,
- seller attribution

consistent across SQL, Python and dashboard analysis.

---

# 3. Source Data Validation

Before transformation, the raw source tables were audited for:

- row counts,
- expected key uniqueness,
- duplicate records,
- referential integrity,
- order-status distribution,
- customer identity,
- timestamp completeness,
- numeric validity,
- review multiplicity,
- multiple products/sellers/payments per order,
- date coverage.

The audit confirmed expected referential relationships between the major Olist datasets.

Special cases were retained and handled explicitly rather than dropped without investigation.

---

# 4. Customer Identity

The Olist dataset contains both:

```text
customer_id
```

and:

```text
customer_unique_id
```

These fields serve different purposes.

`customer_id` represents an order-level customer record and is unique across the customer table.

`customer_unique_id` is used to identify the same customer across multiple orders.

Therefore:

> **All repeat-purchase, retention and customer-lifecycle analysis uses `customer_unique_id`.**

Using `customer_id` would incorrectly classify effectively every order as belonging to a separate customer.

---

# 5. Delivered Orders as the Core Analytical Population

Most commercial, customer and fulfilment analyses use orders with:

```text
order_status = delivered
```

This ensures that commercial KPIs and customer-behaviour metrics are based on completed marketplace transactions.

Non-delivered orders remain available in the underlying order mart for audit and broader analysis but are excluded from core delivered-transaction KPIs unless stated otherwise.

The validated dataset contains:

```text
96,478 delivered orders
```

from:

```text
93,358 unique customers
```

---

# 6. GMV Definition

Commercial performance is measured using **Gross Merchandise Value (GMV)**.

In this project:

```text
GMV = sum of item prices
```

Freight is tracked separately.

The source dataset does not contain:

- marketplace commission,
- take rate,
- cost of goods sold,
- seller acquisition costs,
- operating expenses,
- refunds sufficient for profitability modelling.

Therefore:

> **GMV is not described as Olist corporate revenue or profit.**

Terms such as profitability and corporate revenue are deliberately avoided unless supported by available data.

---

# 7. Order-Level Aggregation

Several Olist tables contain one-to-many relationships with orders:

- order items,
- payments,
- reviews,
- sellers,
- categories.

Joining these tables directly at raw grain could multiply rows and overstate values such as GMV or payment totals.

The `analytics.order_mart` therefore aggregates each one-to-many source **before joining to the order grain**.

The final mart contains:

```text
1 row per order
```

and reconciles exactly to source item-level GMV and freight totals.

---

# 8. Product Category Attribution

For order-level analysis, a `primary_category` is assigned to each order.

The primary category is:

> the product category contributing the largest item-level GMV within that order.

This provides one interpretable category per order for dashboard analysis.

However, category-level SQL analysis uses item-level data when exact category GMV allocation is required.

Therefore:

- **SQL category analysis:** item-level category attribution
- **Power BI primary-category visuals:** dominant category per order

These should not be interpreted as identical analytical views.

---

# 9. Payment Attribution

Orders may contain multiple payment components.

For order-level analysis, the `primary_payment_type` is defined as:

> the payment method associated with the largest payment-value component of the order.

Payment behaviour is treated as descriptive.

Observed differences in order value or customer return rates by payment method are not interpreted as causal effects of payment method.

---

# 10. Review Handling

The review source contains:

- multiple review rows for some orders,
- review IDs that are not globally unique.

A surrogate:

```text
review_row_id
```

is therefore generated at staging level.

All review rows are retained.

Where an order-level review score is required, the most recent review is identified using review timing and stored as:

```text
latest_review_score
```

This avoids silently dropping review records or assuming that `review_id` is a valid global primary key.

---

# 11. Fulfilment Metrics

Core operational metrics include:

### Seller processing time

```text
order approval
→
carrier handoff
```

### Delivery time

```text
purchase
→
customer delivery
```

### Carrier delivery time

```text
carrier handoff
→
customer delivery
```

### Delivery lateness

An order is classified as late when:

```text
actual delivery date > estimated delivery date
```

Invalid operational timestamps are not forced into artificial durations.

For example, delivered orders with:

- missing approval timestamps,
- missing carrier timestamps,
- carrier handoff before approval

retain their commercial information while invalid fulfilment metrics are set to `NULL`.

This allows commercial analysis to retain valid transactions without contaminating operational metrics.

---

# 12. Repeat Customer Definition

A repeat customer is defined as:

```text
customer with >= 2 delivered orders
```

Across the delivered-order population:

```text
2,801 customers
```

meet this definition, corresponding to an observed repeat-customer rate of approximately:

```text
3.00%
```

This is an **ever-repeat** measure over the available observation window.

It does not control for how long each customer had the opportunity to return.

---

# 13. Right-Censoring and Fixed Follow-Up Windows

Customers entering the dataset near the end of the observation period have less time to make a subsequent purchase.

Comparing their repeat behaviour directly with earlier customers would create **right-censoring bias**.

The customer mart therefore contains eligibility indicators for:

```text
30-day follow-up
60-day follow-up
90-day follow-up
```

For example:

```text
eligible_90d_followup = TRUE
```

only when a customer's first delivered purchase occurred at least 90 days before the dataset observation end.

The 90-day repeat rate is calculated as:

```text
customers with second delivered purchase within 90 days
---------------------------------------------------------
customers with at least 90 days of observable follow-up
```

This produced:

```text
75,387 eligible customers
1,715 90-day repeaters
2.27% observed 90-day repeat rate
```

---

# 14. Repeat Transaction vs Genuine Return Behaviour

Analysis of repeat timing showed that:

```text
852 of 2,801 repeat customers
```

made their second purchase within 24 hours.

This represents approximately:

```text
30.4%
```

of all repeat customers.

Purchases made within such a short interval may represent:

- split transactions,
- forgotten items,
- continuation of the same shopping session,

rather than genuine customer return behaviour.

The project therefore distinguishes:

### Repeat purchase

Any second delivered purchase.

### Strict return purchase

A second delivered purchase occurring:

```text
>= 1 day
and
<= 90 days
```

after the first purchase, among customers with at least 90 days of observable follow-up.

The strict 1–90 day measure contains:

```text
932 returners
```

from:

```text
75,387 eligible customers
```

for an observed return rate of:

```text
1.24%
```

This stricter metric is used where the analysis intends to discuss customer return behaviour rather than transaction repetition alone.

---

# 15. Time to Second Purchase

`days_to_second_purchase` is calculated using exact purchase timestamps rather than rounded calendar dates.

This preserves distinctions between:

- purchases made hours apart,
- purchases made on consecutive days,
- genuinely later return purchases.

For dashboard analysis, repeat timing is grouped into:

```text
< 1 day
1–7 days
8–30 days
31–60 days
61–90 days
91–180 days
180+ days
```

---

# 16. Cohort Retention

Customers are assigned to a cohort based on the month of their first delivered purchase.

For each cohort:

```text
month 0 = first purchase month
month 1 = one calendar month after first purchase month
...
```

Retention is calculated as:

```text
active cohort customers at month offset
---------------------------------------
original cohort size
```

The earliest source cohorts contain extremely small samples, including cohorts with only one customer.

These records are retained in the analytical mart for completeness but are excluded from dashboard interpretation when they would produce unstable percentages.

For dashboard comparisons across Months 1–6, cohorts may also be restricted to those with a complete six-month observation window to avoid confusing unavailable future periods with zero retention.

---

# 17. Customer Segmentation

Classic RFM scoring was considered but not used.

Approximately:

```text
97%
```

of delivered customers have only one order.

Dividing frequency into quintiles would therefore create artificial distinctions among customers with identical observed purchase frequency.

Instead, segmentation combines:

### Behaviour

- Repeat
- Recent One-Time
- Lapsed One-Time

### Value

- High Value
- Standard Value

High Value is defined using the:

```text
75th percentile of total customer GMV
```

which was:

```text
R$154.74
```

The resulting six segments are:

```text
Repeat High Value
Repeat Standard Value
Recent High Value One-Time
Recent Standard One-Time
Lapsed High Value One-Time
Lapsed Standard One-Time
```

`Lapsed` is an observational description:

> no observed purchase within the final 90 days of the dataset.

It is **not equivalent to confirmed churn**.

---

# 18. Seller Commercial Attribution

Seller commercial metrics are constructed from item-level data.

Because each order item identifies its seller directly, metrics such as:

- seller GMV,
- items sold,
- delivered orders,
- unique customers

can be attributed to sellers even when multiple sellers participate in the same order.

Seller-level GMV reconciles exactly to delivered order-level GMV:

```text
R$13,221,498.11
```

---

# 19. Seller Operational Attribution

Operational metrics require more caution.

Order-level outcomes such as:

- total delivery duration,
- late/on-time outcome,
- review score

cannot reliably be attributed to one individual seller when an order contains products from multiple sellers.

Therefore:

> **Seller-specific operational metrics use single-seller orders only.**

This prevents the analysis from assigning a shared order delay or customer review independently to every seller participating in a multi-seller order.

Commercial metrics still use all attributable seller items.

This distinction is preserved in both SQL and the Power BI dashboard.

---

# 20. Minimum Sample Thresholds

Small groups can produce unstable percentages.

The project therefore applies minimum sample-size filters where appropriate.

Examples include:

- excluding very small product categories from retention ranking,
- filtering seller operational comparisons to sellers with meaningful order volume,
- restricting geographic comparisons where necessary,
- excluding tiny early cohorts from dashboard interpretation.

Thresholds are used to improve descriptive stability rather than to alter the underlying analytical tables.

The complete data remains preserved in PostgreSQL.

---

# 21. Statistical Validation

SQL is used for descriptive analysis.

Python is then used to test whether selected observed relationships are statistically meaningful and whether their effect sizes are practically important.

The purpose is **validation**, not predictive modelling.

---

## 21.1 Late Delivery vs Review Score

Review scores are ordinal and highly non-normal.

Therefore, late and on-time review distributions are compared using the:

```text
Mann–Whitney U test
```

Effect size is measured using:

```text
rank-biserial correlation
```

Observed result:

```text
rank-biserial ≈ -0.554
p < 0.001
```

This represents a large negative association between late delivery and review score.

Approximately:

```text
46.2% of late orders received 1 star
```

compared with:

```text
6.6% of on-time orders
```

---

## 21.2 Delivery Duration vs Review Score

The relationship between total delivery duration and review score is assessed using:

```text
Spearman rank correlation
```

rather than Pearson correlation because:

- review score is ordinal,
- delivery duration is skewed,
- a linear relationship is not assumed.

Observed result:

```text
Spearman rho ≈ -0.235
p < 0.001
```

This indicates a statistically significant but modest negative association.

The relationship also appears nonlinear, with customer ratings deteriorating substantially for very long delivery durations.

---

## 21.3 First-Order Characteristics vs Customer Return

Customers with sufficient 90-day observation are divided into:

```text
returned within 1–90 days
vs
did not return within 1–90 days
```

Continuous first-order variables are compared using Mann–Whitney U tests and rank-biserial effect sizes.

Variables examined include:

- first-order GMV,
- freight-to-GMV ratio,
- item count,
- review score,
- delivery duration.

Because the sample is large, statistical significance alone is not treated as evidence of practical importance.

Effect sizes are interpreted alongside p-values.

Observed effects on return behaviour were generally small.

---

## 21.4 Categorical Variables vs Customer Return

Categorical associations are evaluated using:

```text
chi-square tests of independence
```

and:

```text
Cramér's V
```

for effect size.

Examples include:

### First-order lateness vs return

```text
p ≈ 0.045
Cramér's V ≈ 0.007
```

Despite nominal statistical significance, the effect size is negligible.

### Payment method vs return

```text
p ≈ 0.648
Cramér's V ≈ 0.005
```

No meaningful association is observed.

### Product category vs return

```text
p < 0.001
Cramér's V ≈ 0.035
```

Category differences are statistically detectable but weak overall.

---

# 22. Statistical Significance vs Practical Significance

Large datasets can produce very small p-values even when differences are commercially trivial.

The project therefore avoids treating:

```text
p < 0.05
```

as sufficient evidence of a meaningful business relationship.

Interpretation considers:

- effect size,
- absolute difference,
- sample size,
- stability of the comparison,
- business relevance.

For example:

> Late delivery shows a large relationship with review satisfaction but only a negligible relationship with customer return behaviour.

This distinction is central to the final business interpretation.

---

# 23. Commercial Trend Window

The source data covers purchases beginning in 2016 and extending into 2018.

However:

- 2016 contains extremely sparse early-period activity,
- August 2018 is incomplete.

For clean month-on-month commercial trend comparisons, the primary dashboard trend uses:

```text
January 2017
through
July 2018
```

This prevents partial or extremely sparse months from distorting trend interpretation.

The complete dataset remains available for overall aggregate KPIs.

---

# 24. Power BI Data Delivery

The analytical pipeline terminates in four validated PostgreSQL BI views:

```text
bi.order_dashboard
bi.customer_dashboard
bi.cohort_dashboard
bi.seller_dashboard
```

Because the Power BI environment used for this project did not use a direct PostgreSQL connection, the views are exported as reproducible CSV extracts.

Exports are generated using:

```bash
./scripts/export_powerbi_data.sh
```

The transport layer is therefore:

```text
PostgreSQL validated views
        ↓
reproducible CSV extracts
        ↓
Power BI
```

Analytical logic remains in PostgreSQL rather than being duplicated in CSV preparation.

---

# 25. Power BI Semantic Model

The Power BI model contains:

```text
customer_dashboard
        1
        │
        *
order_dashboard
```

using:

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

using:

```text
purchase_date
```

`cohort_dashboard` and `seller_dashboard` remain disconnected purpose-specific tables.

This avoids creating relationships between tables at incompatible analytical grains.

DAX is used primarily for:

- KPI aggregation,
- time intelligence,
- dashboard filtering,
- presentation-level calculations.

Core business transformations remain in SQL.

---

# 26. Observational Nature of the Analysis

The Olist dataset is observational.

There is no randomised intervention or experimental design.

Therefore, the project uses language such as:

- associated with,
- differs between,
- corresponds to,
- observed relationship,
- descriptive pattern.

It avoids unsupported causal statements such as:

- causes,
- increases the probability of,
- drives retention,
- leads customers to return.

For example:

> Late deliveries are strongly associated with lower review scores.

is supported.

Whereas:

> Late delivery causes customers to churn.

is not supported by this analysis.

---

# 27. Key Limitations

## Limited customer history

The dataset covers a finite observation period.

Customers classified as one-time or lapsed may make purchases outside the dataset window.

Fixed follow-up eligibility reduces but does not eliminate this limitation.

---

## Low repeat-purchase prevalence

Repeat purchasing is rare.

This limits the strength and stability of customer-retention comparisons, particularly within smaller product categories.

---

## No profitability data

The dataset does not contain sufficient information to estimate:

- profit,
- contribution margin,
- seller economics,
- marketplace take rate.

The project therefore focuses on GMV and transaction behaviour.

---

## No customer acquisition or marketing exposure data

The analysis cannot determine:

- acquisition channel,
- campaign exposure,
- marketing spend,
- promotion history.

These may materially influence both first purchases and return behaviour.

---

## Limited behavioural variables

The dataset observes completed transaction activity but does not include:

- browsing behaviour,
- cart activity,
- search behaviour,
- abandoned transactions,
- app/site engagement.

Therefore, customer-return behaviour cannot be explained comprehensively.

---

## Seller attribution constraints

Operational metrics such as review score and total delivery time are measured at order level.

Restricting seller operational analysis to single-seller orders improves attribution but excludes some multi-seller activity.

---

## Geographic interpretation

Differences in delivery performance across states may reflect:

- logistics distance,
- carrier infrastructure,
- seller location,
- product mix,
- customer geography,

rather than a single operational cause.

Geographic differences are therefore treated descriptively.

---

# 28. Interpretation Principle

The project follows the principle:

> **Use the strongest conclusion supported by the evidence, but no stronger.**

This means:

- validating transformations before analysis,
- reconciling marts to source totals,
- controlling for observation windows,
- distinguishing repeat transactions from genuine return behaviour,
- accounting for analytical grain,
- reporting effect sizes alongside statistical significance,
- avoiding causal claims from observational data.

The resulting dashboard and recommendations are therefore intended as evidence-based decision support rather than claims of causal business impact.
