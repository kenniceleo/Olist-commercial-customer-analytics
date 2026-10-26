# Data

This project uses the **Brazilian E-Commerce Public Dataset by Olist**, a public e-commerce dataset containing customer, order, product, seller, payment, review and geolocation data.

The raw source files are intentionally excluded from this repository. They should be downloaded separately and placed inside:

```text
data/raw/
```

## Expected Source Files

The pipeline expects the following nine CSV files:

```text
olist_customers_dataset.csv
olist_geolocation_dataset.csv
olist_order_items_dataset.csv
olist_order_payments_dataset.csv
olist_order_reviews_dataset.csv
olist_orders_dataset.csv
olist_products_dataset.csv
olist_sellers_dataset.csv
product_category_name_translation.csv
```

## Source Tables

| File                                    | Description                                                                               |
| --------------------------------------- | ----------------------------------------------------------------------------------------- |
| `olist_customers_dataset.csv`           | Customer identifiers and customer location information                                    |
| `olist_geolocation_dataset.csv`         | Brazilian ZIP-code-prefix geolocation data                                                |
| `olist_order_items_dataset.csv`         | Order-item records linking orders, products and sellers, including price and freight      |
| `olist_order_payments_dataset.csv`      | Payment components, payment methods, instalments and payment values                       |
| `olist_order_reviews_dataset.csv`       | Customer review scores and review metadata                                                |
| `olist_orders_dataset.csv`              | Order status and purchase, approval, shipping, delivery and estimated-delivery timestamps |
| `olist_products_dataset.csv`            | Product categories and product attributes                                                 |
| `olist_sellers_dataset.csv`             | Seller identifiers and seller location information                                        |
| `product_category_name_translation.csv` | Portuguese-to-English product-category translations                                       |

## Data Usage

Raw CSV files are loaded into PostgreSQL through:

```text
sql/01_create_raw_schema.sql
sql/02_import_raw_data.sql
```

The project then follows this pipeline:

```text
Raw CSVs
   ↓
PostgreSQL raw schema
   ↓
Data-quality audit
   ↓
Clean staging tables
   ↓
Validated analytical marts
   ↓
SQL business analysis
   ↓
Python statistical validation
   ↓
BI-facing PostgreSQL views
   ↓
Power BI extracts and dashboard
```

Raw source data is not committed to Git because it is external source data rather than a project-generated artifact.

The Power BI CSV extracts under `powerbi/data/` are also excluded from Git because they can be regenerated from the validated PostgreSQL views using:

```bash
./scripts/export_powerbi_data.sh
```
