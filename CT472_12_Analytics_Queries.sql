-- CT-472 Enterprise Data Warehouse | 12 Analytics Queries
-- PostgreSQL (Neon), schema dw. Read-only SELECT statements.
-- Run after the 12 dimensions and 8 facts have been created and loaded.
-- IMPORTANT: The original Colab exporter dynamically detected descriptive columns.
-- This script uses PostgreSQL DO? No: plain SQL with known schema column names.
-- For variable dimension labels, the queries use to_jsonb(dimension_row)->>'column'
-- to select the first existing label, without referencing absent columns.
-- This retains the original Python fallback behaviour.
-- This script DOES NOT create tables, change data, or write CSV files.

-- 01 Monthly Sales
SELECT d.year, d.month, d.month_name,
       SUM(f.line_total) AS total_sales,
       SUM(f.quantity) AS total_units,
       COUNT(*) AS sales_lines
FROM dw."Fact_Sales" f
JOIN dw."Dim_Date" d ON f.date_key = d.date_key
WHERE f.date_key <> 0
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;

-- 02 Category Sales Performance
SELECT p.category_name,
       SUM(f.line_total) AS total_sales,
       SUM(f.quantity) AS total_units,
       COUNT(*) AS sales_lines,
       CASE WHEN SUM(f.quantity) = 0 THEN NULL
            ELSE SUM(f.line_total) / SUM(f.quantity) END AS average_selling_price
FROM dw."Fact_Sales" f
JOIN dw."Dim_Product" p ON f.product_key = p.product_key
GROUP BY p.category_name
ORDER BY total_sales DESC;

-- 03 City Wise Sales
SELECT l.country, l.city, l.location_name,
       SUM(f.line_total) AS total_sales,
       SUM(f.quantity) AS total_units,
       COUNT(*) AS sales_lines
FROM dw."Fact_Sales" f
JOIN dw."Dim_Location" l ON f.location_key = l.location_key
WHERE f.location_key <> 0
GROUP BY l.country, l.city, l.location_name
ORDER BY total_sales DESC;

-- 04 Payment Method And Status
SELECT payment_method, payment_status,
       COUNT(*) AS payment_count,
       SUM(payment_amount) AS total_payment_amount,
       AVG(payment_amount) AS average_payment_amount
FROM dw."Fact_Payment"
GROUP BY payment_method, payment_status
ORDER BY total_payment_amount DESC;

-- 05 Supplier Purchasing Analysis
WITH supplier_names AS (
    SELECT supplier_key,
           COALESCE(to_jsonb(s)->>'supplier_name', to_jsonb(s)->>'name',
                    to_jsonb(s)->>'supplier_code', to_jsonb(s)->>'supplier_key') AS supplier
    FROM dw."Dim_Supplier" s
)
SELECT s.supplier,
       COUNT(*) AS purchase_lines,
       SUM(f.quantity) AS total_quantity,
       SUM(f.line_total) AS total_purchasing_amount,
       AVG(f.unit_cost) AS average_unit_cost
FROM dw."Fact_Purchase" f
JOIN supplier_names s ON f.supplier_key = s.supplier_key
GROUP BY s.supplier
ORDER BY total_purchasing_amount DESC;

-- 06 Monthly Purchasing Trend
SELECT d.year, d.month, d.month_name,
       COUNT(*) AS purchase_lines,
       SUM(f.quantity) AS total_quantity,
       SUM(f.line_total) AS total_purchasing_amount
FROM dw."Fact_Purchase" f
JOIN dw."Dim_Date" d ON f.date_key = d.date_key
WHERE f.date_key <> 0
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;

-- 07 Inventory Movement By Type
WITH movement_names AS (
    SELECT movement_type_key,
           COALESCE(to_jsonb(m)->>'movement_type_name', to_jsonb(m)->>'movement_name',
                    to_jsonb(m)->>'type_name', to_jsonb(m)->>'movement_type',
                    to_jsonb(m)->>'movement_type_key') AS movement_type
    FROM dw."Dim_Movement_Type" m
)
SELECT m.movement_type,
       COUNT(*) AS movement_count,
       SUM(f.quantity_change) AS net_quantity_change,
       SUM(CASE WHEN f.quantity_change > 0 THEN f.quantity_change ELSE 0 END) AS total_increase,
       SUM(CASE WHEN f.quantity_change < 0 THEN ABS(f.quantity_change) ELSE 0 END) AS total_decrease
FROM dw."Fact_Inventory_Movement" f
JOIN movement_names m ON f.movement_type_key = m.movement_type_key
GROUP BY m.movement_type
ORDER BY movement_count DESC;

-- 08 Monthly Inventory Movement
SELECT d.year, d.month, d.month_name,
       COUNT(*) AS movement_count,
       SUM(f.quantity_change) AS net_quantity_change,
       SUM(CASE WHEN f.quantity_change > 0 THEN f.quantity_change ELSE 0 END) AS total_increase,
       SUM(CASE WHEN f.quantity_change < 0 THEN ABS(f.quantity_change) ELSE 0 END) AS total_decrease
FROM dw."Fact_Inventory_Movement" f
JOIN dw."Dim_Date" d ON f.date_key = d.date_key
WHERE f.date_key <> 0
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;

-- 09 Warehouse Stock Position
-- Same as original query: sums rows across available snapshot dates.
-- For multiple snapshot dates, filter to a selected snapshot before summing.
WITH warehouse_names AS (
    SELECT warehouse_key,
           COALESCE(to_jsonb(w)->>'warehouse_name', to_jsonb(w)->>'name',
                    to_jsonb(w)->>'warehouse_code', to_jsonb(w)->>'warehouse_key') AS warehouse
    FROM dw."Dim_Warehouse" w
)
SELECT w.warehouse,
       COUNT(*) AS product_warehouse_records,
       SUM(f.quantity_on_hand) AS total_quantity_on_hand,
       AVG(f.quantity_on_hand) AS average_quantity_on_hand
FROM dw."Fact_Inventory_Balance" f
JOIN warehouse_names w ON f.warehouse_key = w.warehouse_key
GROUP BY w.warehouse
ORDER BY total_quantity_on_hand DESC;

-- 10 Account Debit Credit Analysis
WITH account_names AS (
    SELECT account_key,
           COALESCE(to_jsonb(a)->>'account_name', to_jsonb(a)->>'account_code',
                    to_jsonb(a)->>'account_key') AS account
    FROM dw."Dim_Account" a
)
SELECT a.account,
       COUNT(*) AS journal_line_count,
       SUM(f.debit) AS total_debit,
       SUM(f.credit) AS total_credit,
       SUM(f.debit - f.credit) AS net_debit_minus_credit
FROM dw."Fact_Journal_Entry_Line" f
JOIN account_names a ON f.account_key = a.account_key
GROUP BY a.account
ORDER BY total_debit DESC;

-- 11 Cost Center Financial Activity
WITH cost_center_names AS (
    SELECT cost_center_key,
           COALESCE(to_jsonb(c)->>'cost_center_name', to_jsonb(c)->>'cost_center_code',
                    to_jsonb(c)->>'name', to_jsonb(c)->>'cost_center_key') AS cost_center
    FROM dw."Dim_Cost_Center" c
)
SELECT c.cost_center,
       COUNT(*) AS journal_line_count,
       SUM(f.debit) AS total_debit,
       SUM(f.credit) AS total_credit,
       SUM(f.debit - f.credit) AS net_debit_minus_credit
FROM dw."Fact_Journal_Entry_Line" f
JOIN cost_center_names c ON f.cost_center_key = c.cost_center_key
GROUP BY c.cost_center
ORDER BY total_debit DESC;

-- 12 Budget Vs Actual By Cost Center Period
WITH budget_summary AS (
    SELECT cost_center_key, period_key, SUM(budget_amount) AS total_budget
    FROM dw."Fact_Budget" GROUP BY cost_center_key, period_key
), actual_summary AS (
    SELECT cost_center_key, period_key,
           SUM(debit) AS total_actual_debit,
           SUM(credit) AS total_actual_credit,
           SUM(debit - credit) AS actual_net_debit_minus_credit
    FROM dw."Fact_Journal_Entry_Line" GROUP BY cost_center_key, period_key
), combined AS (
    SELECT COALESCE(b.cost_center_key, a.cost_center_key) AS cost_center_key,
           COALESCE(b.period_key, a.period_key) AS period_key,
           b.total_budget, a.total_actual_debit, a.total_actual_credit,
           a.actual_net_debit_minus_credit
    FROM budget_summary b FULL OUTER JOIN actual_summary a
      ON b.cost_center_key = a.cost_center_key AND b.period_key = a.period_key
)
SELECT COALESCE(to_jsonb(c)->>'cost_center_name',to_jsonb(c)->>'cost_center_code',
                to_jsonb(c)->>'name',to_jsonb(c)->>'cost_center_key') AS cost_center,
       COALESCE(to_jsonb(p)->>'period_name',to_jsonb(p)->>'fiscal_period_name',
                to_jsonb(p)->>'period_code',to_jsonb(p)->>'period_label',
                to_jsonb(p)->>'period_key') AS fiscal_period,
       x.total_budget, x.total_actual_debit, x.total_actual_credit,
       x.actual_net_debit_minus_credit,
       CASE WHEN x.total_budget IS NULL OR x.actual_net_debit_minus_credit IS NULL
            THEN NULL ELSE x.total_budget - x.actual_net_debit_minus_credit
       END AS budget_minus_actual_net
FROM combined x
LEFT JOIN dw."Dim_Cost_Center" c ON x.cost_center_key = c.cost_center_key
LEFT JOIN dw."Dim_Fiscal_Period" p ON x.period_key = p.period_key
ORDER BY cost_center, fiscal_period;
