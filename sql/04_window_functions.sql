-- ============================================================
-- Step 4: Window functions. ROW_NUMBER, RANK, running totals, LAG.
--
-- The question: how do I rank things, track a running total, and
-- compare each year with the year before, without collapsing rows?
--
-- What you will learn:
--   A window function computes a value across a set of rows that
--   are related to the current row, but it keeps every row in the
--   result. That is the big difference from GROUP BY, which
--   collapses each group into one row.
--   OVER defines the window. PARTITION BY splits rows into
--   separate groups inside the window. ORDER BY inside OVER
--   sets the order used for ranking or for running totals.
--   ROW_NUMBER gives each row a unique number: 1, 2, 3, with no
--   ties. RANK gives tied rows the same number, then skips the
--   next numbers. If two rows tie for rank 1, the next rank is 3.
--   LAG pulls a value from the previous row in the window, so
--   you can compute a change from one year to the next.
--   A running total is SUM over all rows up to the current row.
-- ============================================================

-- Query 4.1: Rank presidents by orders, with RANK.
-- First we count orders per president in a subquery. Then RANK
-- orders those counts from biggest to smallest. Roosevelt is
-- rank 1 with 3,725. No two presidents tie at the top here, so
-- RANK and ROW_NUMBER agree on the first rows.
SELECT
    president,
    orders,
    RANK() OVER (ORDER BY orders DESC) AS rank_by_orders
FROM (
    SELECT president, COUNT(*) AS orders
    FROM executive_orders
    GROUP BY president
)
ORDER BY rank_by_orders ASC;

-- Query 4.2: Rank presidents with ROW_NUMBER, top 10 only.
-- ROW_NUMBER never ties: even if two presidents had the same
-- count, they would get different numbers. The outer query keeps
-- only rows numbered 1 to 10. This is the standard "top N" pattern
-- with window functions.
SELECT president, orders, row_num
FROM (
    SELECT
        president,
        COUNT(*) AS orders,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS row_num
    FROM executive_orders
    GROUP BY president
)
WHERE row_num <= 10;

-- Query 4.3: The top year in each decade.
-- PARTITION BY decade restarts the numbering in every decade.
-- Inside each decade, years are ordered by orders descending, so
-- row 1 is the busiest year of that decade. The outer query keeps
-- only row 1 per decade. This shows that 1933 leads the 1930s,
-- and every decade has its own peak.
SELECT decade, year, orders
FROM (
    SELECT
        decade,
        year,
        COUNT(*) AS orders,
        ROW_NUMBER() OVER (
            PARTITION BY decade ORDER BY COUNT(*) DESC
        ) AS row_num
    FROM executive_orders
    GROUP BY decade, year
)
WHERE row_num = 1
ORDER BY decade ASC;

-- Query 4.4: Running total of orders by year.
-- The subquery counts orders per year. The window SUM adds up
-- every year from the first year through the current year, so
-- the last row reaches the full total of 10,879. The window frame
-- ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW means
-- "from the start of the list up to this row".
SELECT
    year,
    orders,
    SUM(orders) OVER (
        ORDER BY year ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM (
    SELECT year, COUNT(*) AS orders
    FROM executive_orders
    GROUP BY year
)
ORDER BY year ASC;

-- Query 4.5: Year over year change, using LAG on years present.
-- LAG(orders) pulls the previous row's order count, which is the
-- previous year that appears in the table. The change column is
-- this year minus last year. The percent change divides the
-- change by last year and multiplies by 100.
-- Honest note: years with zero orders do not appear in this
-- table, so "previous year" here means the previous year with
-- at least one order, not always the calendar year before.
-- Query 4.6 fixes that with a complete year list.
SELECT
    year,
    orders,
    LAG(orders) OVER (ORDER BY year ASC) AS previous_year_orders,
    orders - LAG(orders) OVER (ORDER BY year ASC) AS change_from_previous,
    ROUND(
        100.0 * (orders - LAG(orders) OVER (ORDER BY year ASC))
        / LAG(orders) OVER (ORDER BY year ASC),
        1
    ) AS percent_change
FROM (
    SELECT year, COUNT(*) AS orders
    FROM executive_orders
    GROUP BY year
)
ORDER BY year ASC;

-- Query 4.6: True year over year change, with every calendar year.
-- WITH RECURSIVE builds a list of every year from 1791 to 2026,
-- one row per year, even years with zero orders. LEFT JOIN adds
-- the real counts, with COALESCE turning missing counts into 0.
-- Now LAG compares each year with the calendar year before it,
-- so a jump from 0 to a busy year is visible, and quiet years
-- are no longer hidden. This is the careful version of 4.5.
WITH RECURSIVE all_years(year) AS (
    SELECT 1791
    UNION ALL
    SELECT year + 1 FROM all_years WHERE year < 2026
),
yearly AS (
    SELECT year, COUNT(*) AS orders
    FROM executive_orders
    GROUP BY year
)
SELECT
    a.year,
    COALESCE(y.orders, 0) AS orders,
    LAG(COALESCE(y.orders, 0)) OVER (ORDER BY a.year ASC) AS previous_year_orders,
    COALESCE(y.orders, 0)
        - LAG(COALESCE(y.orders, 0)) OVER (ORDER BY a.year ASC)
        AS change_from_previous
FROM all_years AS a
LEFT JOIN yearly AS y
    ON a.year = y.year
ORDER BY a.year ASC;

-- Query 4.7: Each president's most recent order.
-- PARTITION BY president restarts the numbering for each
-- president. ORDER BY date_signed DESC puts the newest order
-- first inside each group, so row 1 is that president's latest
-- order. The outer query keeps only row 1 per president.
-- This is a classic interview pattern: "latest row per group".
SELECT president, date_signed, executive_order_number, title
FROM (
    SELECT
        president,
        date_signed,
        executive_order_number,
        title,
        ROW_NUMBER() OVER (
            PARTITION BY president ORDER BY date_signed DESC
        ) AS row_num
    FROM executive_orders
)
WHERE row_num = 1
ORDER BY date_signed DESC;
