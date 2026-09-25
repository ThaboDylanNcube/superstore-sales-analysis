# Superstore sales analysis with MySQL

A practice SQL project examining sales, profit, product performance, regional results, and ordering patterns. The queries use MySQL 8.0 window functions and common table expressions. Source: `order_file2.csv`, 51,067 order lines dated 2011–2014.

## Verified findings

- Total sales are **12,577,781** and total profit is **1,459,798.42**. The CSV does not specify a currency.
- The dataset contains **25,709 distinct order combinations** and **177,480 units**.
- **Central** has the highest total profit at **308,829.99**.
- **12,505 order lines** have negative profit.
- **Technology** leads category sales with **4,692,845**.

These figures come from the supplied CSV, not from screenshots or estimated chart values.

## Questions answered

- What are total sales, profit, units sold, and distinct orders?
- Which products, categories, regions, countries, and subcategories perform best?
- How do sales change by month and accumulate by day?
- Which order lines lose money, and how does profitability vary across discount levels?
- How many named customers appear in one order versus multiple distinct orders?

## Method

The script uses `superstore.order_file2`. Each row is treated as an **order line**. Some order IDs appear with different customers and dates: counting `DISTINCT order_id` alone gives 24,990, while the combination of **order ID, date, and customer name** gives 25,709. The script uses the combination when counting orders. Profit margin is `SUM(profit) / SUM(sales)`, with a zero-sales guard. Monthly results are sorted by month, and ranking queries use window functions.

Customer grouping uses `customer_name` because the CSV has no customer ID. Two customers with the same name could be combined. The first versus subsequent order analysis describes orders **within this dataset**, not whether a customer was new to the business.

## Files and setup

1. Import `order_file2.csv` into a MySQL schema named `superstore`, with the source table named `order_file2`.
2. Confirm the columns listed in the SQL header exist and `order_date` is a date or datetime value.
3. Run `Superstore_Sales_Analysis.sql` in MySQL Workbench.

All 14 analyses were checked against the supplied CSV using an equivalent in-memory SQL engine for the query logic, plus independent aggregates. MySQL-specific functions and the multi-column `COUNT(DISTINCT ...)` were adapted for that check. The script has **not** been executed in a live MySQL 8 instance, so check the import types and run it in MySQL Workbench before publishing numerical screenshots. Add the original dataset source or download link if known.

## Authorship

This version refines the original Superstore queries supplied by Thabo. The original questions and query attempts were his; the portfolio cleanup, safeguards, and documentation were assisted. If you followed a video or public exercise, credit its source here as well.
