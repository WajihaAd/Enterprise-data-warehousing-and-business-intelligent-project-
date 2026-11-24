# CT-472 | Enterprise Data Warehouse — SQL Analytics Submission

**Course:** CT-472 — Data Warehousing & Business Intelligence  
**Instructor:** Umar Farooq  
**Students:** Iqra (DT-48), Wajiha Adnan (DT-01), Sarisa Parvez (DT-26)

## Purpose

This folder contains the **12 read-only SQL analytics queries** used for the CT-472 warehouse and Power BI reporting. The queries cover Sales (4), Purchasing (2), Inventory (3) and Finance (3). They target the central **Neon PostgreSQL** warehouse's `dw` schema. The original Google Colab Python code executes the same analytical logic and exports the results to CSV for Power BI.

## Files

- `CT472_12_Analytics_Queries.sql` — the twelve numbered SQL `SELECT` queries; no table creation or data modification.
- `README.md` — database requirements, run order and CSV export instructions.

## Correct overall project run order

The SQL file is an **analytics step**, not the full project setup. For a fresh rebuild, run the project's existing notebooks/scripts in this logical order (their exact filenames depend on the Drive folder):

1. **Prepare source databases:** Sales (Supabase PostgreSQL), Purchasing (Aiven MySQL), Inventory (MongoDB) and Finance (Neon PostgreSQL). Use the original source schema and population scripts if rebuilding from scratch.
2. **Extract and stage:** Use Google Colab Python to extract the 28 source datasets. Store raw Parquet snapshots in Google Drive; retain batch identifiers and original source records.
3. **Profile, clean and map:** Validate keys, dates, joins and business totals. Resolve shared Product and Location identities and apply documented movement and finance rules.
4. **Build the warehouse:** Create the separate Neon warehouse and its `dw` schema. Create/load **12 dimension tables first**, including unknown key-0 members, then create/load **8 fact tables** using the project's actual DDL and ETL notebooks. Do not run the analytics SQL until these tables exist and are populated.
5. **Validate and reconcile:** Check primary keys, foreign keys, row counts, sales/purchase totals, stock movements/balances and journal debit-credit balance.
6. **Run analytics SQL:** Connect to the **warehouse** Neon database (not the Finance source Neon database), open a PostgreSQL SQL editor or `psql`, and execute `CT472_12_Analytics_Queries.sql`. Queries are numbered 01–12. Each produces one result set.
7. **Export to Power BI:** If CSV files are needed, run the **existing original Colab Python analytics-export cell** (the one using `warehouse_engine`, pandas and `PowerBI_12_Analytics_CSV`). It creates 12 CSV files, a summary and a ZIP. A SQL editor may also export each query result manually.
8. **Power BI and AI:** Load/refresh the CSVs or configured warehouse views in Power BI; perform AI forecasting/anomaly steps using the separate existing project scripts. Verify outputs independently.
9. **Incremental tests (optional):** Run the project's existing controlled incremental ETL and validation scripts only after the baseline is verified. Do not treat this SQL analytics file as an ETL or testing script.

## Quick start for an already populated warehouse

If the warehouse already contains all 20 tables, **skip steps 1–5** and start at step 6. No data loading is required merely to inspect the 12 analytics results.

**Option A — Neon SQL Editor:** Open the correct Neon warehouse project → SQL Editor → paste one numbered query from the `.sql` file → Run → inspect results. Repeat for queries 01–12. Some editors display only the last result if all 12 are run together; execute individually when exporting.

**Option B — PostgreSQL CLI (`psql`):** With a secure warehouse connection string set in your environment, run:

```bash
psql "$DW_WAREHOUSE_DATABASE_URL" -v ON_ERROR_STOP=1 -f CT472_12_Analytics_Queries.sql
```

Do not paste passwords or connection strings into the SQL file or README.

## Original Colab CSV export

The original Python exporter provided in the project requires:

- `warehouse_engine` already initialized as a SQLAlchemy engine connected to the warehouse.
- Python packages `pandas`, `sqlalchemy` and a PostgreSQL driver.
- Google Colab for `/content/...` output paths and `google.colab.files.download`.

Its outputs are:

```text
/content/PowerBI_12_Analytics_CSV/
  00_Export_Summary.csv
  01_Monthly_Sales.csv
  02_Category_Sales_Performance.csv
  03_City_Wise_Sales.csv
  04_Payment_Method_And_Status.csv
  05_Supplier_Purchasing_Analysis.csv
  06_Monthly_Purchasing_Trend.csv
  07_Inventory_Movement_By_Type.csv
  08_Monthly_Inventory_Movement.csv
  09_Warehouse_Stock_Position.csv
  10_Account_Debit_Credit_Analysis.csv
  11_Cost_Center_Financial_Activity.csv
  12_Budget_Vs_Actual_By_Cost_Center_Period.csv
/content/PowerBI_12_Analytics_CSV.zip
```

## Important notes

- SQL identifiers for warehouse tables use **double quotes** because the actual table names are mixed case (`dw."Fact_Sales"`).
- In the original Colab script, descriptive dimension column names were selected dynamically. The standalone SQL uses PostgreSQL `to_jsonb(row)` plus `COALESCE` to achieve equivalent label fallback without assuming an optional column exists. The grouping logic, measures and joins remain aligned with the provided 12 queries.
- Query 09 follows the original snapshot aggregation. If multiple inventory snapshot dates are present, filter to the intended date before adding balances across warehouses/products.
- Query 12's "actual" is **net debit minus credit**, as in the supplied code. It is not necessarily equivalent to a standard expense-only budget comparison; accounting sign conventions should be confirmed before business interpretation.
- The original project baseline was **1,810,547 warehouse rows**; later controlled testing may change totals. Do not assume the baseline is the current live count.
- **This submission has been prepared from the supplied code; no live database execution or fresh CSV export was performed.**

## Suggested Google Drive placement

```text
MyDrive/Enterprise_DW_Project/
  SQL_Analytics_Submission/
    CT472_12_Analytics_Queries.sql
    README.md
```

Upload the two files from this submission into that folder. Keep existing ETL notebooks, raw snapshots, and warehouse scripts in their original Drive locations; this README gives the run sequence without inventing their filenames.
