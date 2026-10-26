# Findings and Recommendations

This document summarises the main business findings from the **Olist Commercial & Customer Analytics** project and translates them into evidence-based recommendations.

The findings combine:

- validated PostgreSQL analysis,
- customer and seller analytical marts,
- cohort and segmentation analysis,
- Python statistical validation,
- Power BI dashboard analysis.

Because the source data is observational, the recommendations should be interpreted as decision-support priorities rather than estimates of causal business impact.

---

# 1. Executive Summary

The analysed marketplace generated approximately **R$13.22 million in delivered GMV** across **96,478 delivered orders** from **93,358 customers**.

Commercial activity grew substantially over the primary 2017–2018 analysis period, while average order value remained comparatively stable. Marketplace activity was diversified across product categories but more geographically concentrated, with São Paulo accounting for a particularly large share of GMV.

Customer repeat purchasing was low. While **3.00%** of customers made more than one delivered purchase during the available observation period, the repeat rate fell to **2.27%** when restricting analysis to customers with at least 90 days of follow-up. After excluding second purchases occurring within 24 hours, the stricter **1–90 day customer return rate was only 1.24%**.

Fulfilment performance showed the strongest relationship with customer satisfaction. Late deliveries had substantially worse review distributions than on-time deliveries, with a large rank-biserial effect size of approximately **−0.554**. However, fulfilment variables showed only weak relationships with subsequent customer return behaviour.

The evidence therefore suggests that:

1. fulfilment improvement should primarily be treated as a **customer-experience and service-quality priority**;
2. retention initiatives should be evaluated separately from fulfilment improvements;
3. operational intervention should focus on sellers and geographies where poor fulfilment performance occurs at meaningful transaction volume;
4. retention strategies should be targeted and tested by customer/product context rather than based on generic payment or delivery assumptions.

---

# 2. Commercial Performance

## Finding 2.1 — The marketplace generated R$13.22M in delivered GMV

Across delivered transactions:

- **GMV:** R$13,221,498.11
- **Delivered orders:** 96,478
- **Customers:** 93,358
- **Average order value:** R$137.04
- **Freight as a percentage of GMV:** 16.63%

The marketplace therefore operated at meaningful transaction scale, although the relatively small difference between orders and customers is an early indication that repeat purchasing was uncommon.

---

## Finding 2.2 — Growth was driven more by transaction volume than by changes in order value

During the primary comparable trend period from January 2017 to July 2018, order volumes changed substantially while average order value remained within a comparatively narrower range.

For example, November 2017 recorded approximately:

- **+52.4% month-on-month GMV growth**
- **+62.8% month-on-month order growth**

The dataset does not establish the external reason for this increase, so the spike should not be attributed to a specific commercial campaign or seasonal event without additional evidence.

### Business implication

Marketplace growth during the observed period appears to have depended more heavily on generating additional transactions than on materially increasing the value of each transaction.

---

## Finding 2.3 — Product demand is diversified across categories

The largest categories contribute meaningful shares of marketplace GMV, but no single category dominates overall commercial performance.

The five largest categories together contributed roughly **40% of delivered GMV**.

This suggests a relatively diversified product marketplace rather than dependence on one dominant product vertical.

### Business implication

Commercial planning should avoid over-optimising around a single category.

Category-level strategies remain useful, but marketplace-wide performance depends on a broader portfolio of product groups.

---

## Finding 2.4 — Commercial activity is more geographically concentrated than category activity

São Paulo alone contributed approximately **38% of marketplace GMV**.

São Paulo, Rio de Janeiro and Minas Gerais together accounted for roughly **63% of GMV**.

### Business implication

Customer demand is substantially concentrated in the largest southeastern states.

This geographic concentration may create both:

- commercial opportunities in high-density markets,
- dependency risk if marketplace performance relies heavily on a small number of regions.

Regional commercial performance should therefore be monitored alongside fulfilment performance.

---

## Finding 2.5 — Credit cards dominate transaction behaviour

Approximately **75.5% of delivered orders** used credit card as the primary payment method.

Credit-card orders also had a higher observed average order value than several other payment methods.

However, payment method showed essentially no relationship with subsequent 1–90 day customer return behaviour.

Statistical validation produced approximately:

- **p = 0.648**
- **Cramér's V = 0.005**

### Business implication

Payment method is commercially important for transaction processing but does not appear to be a meaningful retention differentiator in this dataset.

Retention initiatives should therefore not be prioritised around payment-method differences without additional evidence.

---

# 3. Seller Performance

## Finding 3.1 — Seller performance follows a long-tail distribution

The marketplace contains approximately **2,970 sellers with delivered activity**.

The median seller completed only **7 delivered orders**, compared with an average of approximately **33 orders per seller**.

This difference indicates substantial skew in seller activity.

Seller GMV concentration showed:

- Top 10 sellers: approximately **13.3% of GMV**
- Top 50 sellers: approximately **33.2%**
- Top 100 sellers: approximately **45.5%**

No individual seller dominates the marketplace, but a relatively small group of sellers contributes a substantial share of total GMV.

### Business implication

Seller management should distinguish between:

- a small group of commercially material sellers,
- a long tail of lower-volume sellers.

Operational intervention on higher-volume sellers can affect a much larger share of marketplace activity.

---

# 4. Customer Retention

## Finding 4.1 — Observed repeat purchasing is very low

Across delivered customers:

- **Repeat-customer rate:** 3.00%
- **30-day repeat rate:** 1.58%
- **60-day repeat rate:** 1.95%
- **90-day repeat rate:** 2.27%

The fixed-horizon metrics use only customers with sufficient observation time.

### Business implication

Customer retention is structurally limited in the observed marketplace.

Increasing repeat purchasing therefore represents a potential growth opportunity, but interventions should first recognise that many purchases may naturally belong to low-frequency product categories.

---

## Finding 4.2 — A substantial portion of repeat transactions occur within 24 hours

Of the 2,801 customers with multiple delivered purchases:

- **852**, or approximately **30.4%**, placed their second order within 24 hours.

These transactions may represent:

- forgotten items,
- split transactions,
- continuation of the same shopping session,

rather than genuine customer return behaviour.

After excluding these transactions, only:

- **932 of 75,387 eligible customers**

returned between 1 and 90 days after their first purchase.

This corresponds to a stricter observed return rate of:

- **1.24%**

### Business implication

Marketplace reporting should distinguish:

> repeat transactions

from:

> genuine return behaviour.

Using only an "ever purchased twice" metric can materially overstate meaningful customer retention.

---

## Finding 4.3 — Time to return is highly skewed

Among repeat customers, the median time to second purchase was approximately **29 days**, while the mean was much higher.

This difference reflects a long right tail in customer return timing.

### Business implication

Average time-to-return alone can be misleading.

Retention reporting should include:

- median time to second purchase,
- fixed 30/60/90-day repeat rates,
- timing distributions.

---

## Finding 4.4 — Product category contains some retention signal, but the relationship is weak overall

Return rates vary across first-purchase categories.

For example, some higher-volume categories such as:

- bed/bath/table,
- sports/leisure,
- fashion bags/accessories

showed different observed 1–90 day return rates.

However, statistical validation produced:

- **p < 0.001**
- **Cramér's V ≈ 0.035**

The relationship is therefore statistically detectable but weak overall.

### Business implication

Retention programmes may benefit from category-specific experimentation, but category alone should not be treated as a strong predictor of customer return.

More useful targeting would likely require additional behavioural, promotional or customer-acquisition information not available in this dataset.

---

## Finding 4.5 — Payment method provides essentially no retention signal

Observed 1–90 day return rates were similar across major payment methods.

Statistical validation showed:

- **p ≈ 0.648**
- **Cramér's V ≈ 0.005**

### Business implication

There is no evidence in this dataset to justify prioritising retention campaigns based on payment method.

---

# 5. Fulfilment and Customer Experience

## Finding 5.1 — Late delivery has a large relationship with customer satisfaction

The marketplace-wide late-delivery rate was approximately:

- **8.11%**

On-time orders received substantially better customer reviews than late orders.

Approximately:

- **62.5% of on-time orders received 5 stars**
- **22.2% of late orders received 5 stars**

Conversely:

- **6.6% of on-time orders received 1 star**
- **46.2% of late orders received 1 star**

The Mann–Whitney analysis produced:

- **p < 0.001**
- **rank-biserial correlation ≈ −0.554**

This represents a large negative association.

### Business implication

Late delivery is one of the clearest operational signals associated with poor customer experience in the dataset.

Reducing severe fulfilment failures should therefore be a high-priority customer-experience objective.

---

## Finding 5.2 — Customer satisfaction deteriorates sharply for very long deliveries

Average review scores declined as delivery duration increased:

- 0–5 days: approximately **4.45**
- 6–10 days: approximately **4.36**
- 11–15 days: approximately **4.27**
- 16–20 days: approximately **4.13**
- 21–30 days: approximately **3.68**
- 30+ days: approximately **2.25**

Spearman correlation between delivery duration and review score was approximately:

- **ρ = −0.235**
- **p < 0.001**

The overall relationship is modest, but the grouped results show a substantial deterioration among the longest delivery durations.

### Business implication

Operational monitoring should not focus only on average delivery time.

The tail of very long deliveries is particularly important because severe delays are associated with disproportionately poor customer satisfaction.

---

## Finding 5.3 — Fulfilment quality is strongly related to satisfaction but weakly related to customer return

Customers returning within 1–90 days experienced somewhat shorter first-order delivery times and slightly higher first-order review scores than non-returners.

However, effect sizes were small.

First-order late delivery versus 1–90 day customer return produced approximately:

- **p = 0.045**
- **Cramér's V = 0.007**

The observed return rate was approximately:

- **1.26% following on-time first delivery**
- **0.97% following late first delivery**

The difference is statistically detectable but practically negligible.

### Business implication

Improving delivery performance is strongly supported as a customer-satisfaction initiative.

However:

> the evidence does not support assuming that fulfilment improvement alone will materially increase customer retention.

Satisfaction and retention should therefore be managed as related but distinct objectives.

---

# 6. Geographic Fulfilment Differences

Delivery performance differs materially across customer states.

Some states experience substantially:

- longer average delivery times,
- higher late-delivery rates,
- higher freight burden.

These differences are likely influenced by multiple factors, including:

- shipping distance,
- carrier infrastructure,
- seller geography,
- product characteristics,
- customer location.

### Business implication

Fulfilment interventions should consider geographic context rather than applying a single marketplace-wide performance benchmark.

High-volume regions with elevated late-delivery rates should be investigated separately from low-volume remote regions where logistics constraints may be structurally different.

---

# 7. Seller Operational Risk

Seller-level commercial and operational analysis uses different attribution rules.

Commercial metrics can be attributed directly from seller-specific items.

Operational outcomes such as:

- delivery duration,
- lateness,
- review score

are evaluated using single-seller orders to avoid assigning a shared order outcome to multiple sellers.

The resulting seller analysis identifies higher-volume sellers with:

- above-market processing time,
- elevated late-delivery rates,
- weaker customer review outcomes.

### Business implication

Seller intervention should prioritise:

> operational underperformance × meaningful order volume

rather than simply ranking sellers by worst percentage.

A seller with a very high late rate across a handful of orders is less operationally material than a high-volume seller with a moderately elevated late rate affecting hundreds of transactions.

---

# 8. Business Recommendations

## Recommendation 1 — Prioritise high-volume fulfilment outliers

Create an operational monitoring framework that identifies sellers and fulfilment segments with both:

- meaningful transaction volume,
- above-market processing or late-delivery performance.

Priority should be given to sellers appearing above marketplace benchmarks for:

- seller processing time,
- late-delivery rate,

particularly when they serve a large number of orders.

### Why

Late delivery has the strongest validated relationship with poor customer satisfaction in the dataset.

Targeting commercially material outliers is likely to provide more operational value than applying identical intervention thresholds to every seller.

### Suggested KPIs

Monitor:

- late-delivery rate,
- seller processing time,
- severe-delay volume,
- review-score distribution,
- number of affected orders.

---

## Recommendation 2 — Focus on severe delivery failures, not only average delivery time

Marketplace operations should explicitly monitor the tail of the delivery distribution.

Orders taking more than 20–30 days are associated with substantially worse customer ratings than normal delivery ranges.

### Why

Average delivery time can remain acceptable while a smaller group of severely delayed orders creates disproportionate customer dissatisfaction.

### Suggested actions

Operational reporting could include:

- percentage of orders exceeding 20 days,
- percentage exceeding 30 days,
- severe-delay volume by state,
- severe-delay volume by seller,
- customer review outcomes following severe delays.

---

## Recommendation 3 — Separate satisfaction strategy from retention strategy

Fulfilment improvement should be evaluated primarily against:

- customer review outcomes,
- late-delivery reduction,
- severe-delay reduction.

Retention programmes should separately track:

- 30-day repeat rate,
- 60-day repeat rate,
- 90-day repeat rate,
- strict 1–90 day return rate.

### Why

The analysis shows:

- a **large relationship** between late delivery and customer satisfaction,
- but only a **negligible relationship** between late first delivery and subsequent customer return.

Using retention alone to evaluate fulfilment improvements could therefore understate their customer-experience value.

Conversely, expecting delivery improvements to solve low repeat purchasing would overstate the evidence.

---

## Recommendation 4 — Use category-specific retention experiments rather than generic payment incentives

Product category showed more variation in customer return behaviour than payment method, although the category association remained weak overall.

Retention experimentation should therefore be more targeted toward:

- categories with meaningful transaction scale,
- categories with relatively stronger observed return behaviour,
- product groups where repeat purchasing is commercially plausible.

### Why

Payment method showed essentially no meaningful relationship with customer return.

A generic strategy such as encouraging one payment method for retention is therefore unsupported by the analysis.

### Possible experiments

Examples could include:

- category-specific post-purchase recommendations,
- replenishment reminders for repeatable products,
- cross-sell recommendations based on first category,
- category-specific return incentives.

These should be tested experimentally rather than assumed to cause higher retention.

---

## Recommendation 5 — Report genuine return behaviour separately from repeat transactions

Marketplace retention reporting should distinguish:

```text
Repeat Customer
```

from:

```text
Returned After Initial Purchase
```

A practical framework could report:

- ever-repeat rate,
- 30-day repeat rate,
- 60-day repeat rate,
- 90-day repeat rate,
- strict 1–90 day return rate.

### Why

More than 30% of observed repeat customers placed their second order within 24 hours.

Treating all such transactions as retention risks overstating genuine customer return behaviour.

---

# 9. Overall Business Interpretation

The marketplace's primary analytical challenge is not simply:

> improving delivery

or:

> increasing repeat customers.

The evidence suggests two distinct problems.

### Customer experience problem

Fulfilment failures—especially late and severely delayed deliveries—are strongly associated with poor customer satisfaction.

This supports targeted operational intervention.

### Customer retention problem

Genuine customer return behaviour is rare and only weakly explained by the first-order variables available in the dataset.

This suggests that retention is likely influenced by factors beyond fulfilment alone, potentially including:

- product purchasing cycles,
- customer acquisition source,
- pricing and promotion,
- marketplace usage habits,
- product assortment,
- behavioural engagement.

These variables are not available in the current dataset and should be incorporated before developing stronger predictive or causal retention strategies.

The resulting business priority is therefore:

> **Improve fulfilment where the customer-experience evidence is strongest, while treating retention as a separate problem requiring targeted experimentation and richer behavioural data.**
