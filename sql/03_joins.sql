-- ============================================================
-- Step 3: Joins. INNER JOIN, LEFT JOIN, and a self-join.
--
-- The question: how do I combine this table with other tables,
-- and how do I check that two tables agree?
--
-- What you will learn:
--   A JOIN matches rows from two tables on a shared value, here
--   the president name or the year. ON states the matching rule.
--   INNER JOIN keeps only rows that match on both sides. If a
--   row has no match, it disappears from the result.
--   LEFT JOIN keeps every row from the left table, and fills
--   NULL where the right table has no match. Use LEFT JOIN when
--   "no match" is itself an answer you want to see.
--   A self-join joins a table to itself, with two different
--   aliases, to compare rows inside the same table.
--
-- The lookup tables used here:
--   orders_by_president: one row per president, with the dataset
--   count. It is a summary of the main table, stored separately.
--   orders_by_year: one row per year that has orders, with the
--   dataset count for that year.
--   published_reference_totals: published historical totals per
--   president, from the APP counts table, cross checked against
--   the CEI Table 4 tabulation. These are reference totals, not
--   dataset rows. Never confuse the two.
-- ============================================================

-- Query 3.1: INNER JOIN to check the president summary table.
-- We group the main table by president, then join the result to
-- orders_by_president on the president name. The difference column
-- should be 0 on every row: the summary table matches the main
-- table exactly. INNER JOIN is right here because every president
-- in the main table should also be in the summary table.
SELECT
    grouped.president,
    grouped.orders_computed,
    ref.orders_in_dataset,
    grouped.orders_computed - ref.orders_in_dataset AS difference
FROM (
    SELECT president, COUNT(*) AS orders_computed
    FROM executive_orders
    GROUP BY president
) AS grouped
INNER JOIN orders_by_president AS ref
    ON grouped.president = ref.president
ORDER BY grouped.orders_computed DESC;

-- Query 3.2: LEFT JOIN to find presidents with no full text orders.
-- The left table is orders_by_president (all 40 presidents).
-- The right side counts full text orders per president. LEFT JOIN
-- keeps all 40 presidents, even those with zero full text orders.
-- COALESCE turns the NULL for "no match" into 0, so the result
-- reads cleanly. Early presidents show 0, because full text here
-- is recent only. An INNER JOIN would have hidden those rows.
SELECT
    ref.president,
    ref.orders_in_dataset,
    COALESCE(fulltext.full_text_orders, 0) AS full_text_orders
FROM orders_by_president AS ref
LEFT JOIN (
    SELECT president, COUNT(*) AS full_text_orders
    FROM executive_orders
    WHERE text_available = 'Full text downloaded'
    GROUP BY president
) AS fulltext
    ON ref.president = fulltext.president
ORDER BY full_text_orders DESC;

-- Query 3.3: INNER JOIN to check the year summary table.
-- Same check as 3.1, but for years. The difference column should
-- be 0 on every row: 187 years, all matching.
SELECT
    grouped.year,
    grouped.orders_computed,
    ref.orders,
    grouped.orders_computed - ref.orders AS difference
FROM (
    SELECT year, COUNT(*) AS orders_computed
    FROM executive_orders
    GROUP BY year
) AS grouped
INNER JOIN orders_by_year AS ref
    ON grouped.year = ref.year
ORDER BY grouped.year ASC;

-- Query 3.4: JOIN to published reference totals, to see the gap.
-- This is the most important join in the project. It compares
-- dataset rows per president with published historical totals.
-- A positive gap means the published total is higher than the
-- rows we have: a source gap, not a finding about behavior.
-- The biggest gaps are before 1929: Wilson 150 rows versus a
-- published total of 1,803, Coolidge 79 versus 1,203, Theodore
-- Roosevelt 104 versus 1,081, Taft 75 versus 724, Harding 27
-- versus 522. Lincoln is the reverse: 119 rows versus 48.
-- A negative gap means the dataset holds more rows than the
-- reference total, because counting rules differ. Roosevelt
-- shows 3,725 rows versus a reference total of 3,721.
SELECT
    ref.president,
    grouped.orders_in_dataset,
    ref.published_reference_total,
    ref.published_reference_total - grouped.orders_in_dataset AS gap
FROM (
    SELECT president, COUNT(*) AS orders_in_dataset
    FROM executive_orders
    GROUP BY president
) AS grouped
INNER JOIN published_reference_totals AS ref
    ON grouped.president = ref.president
ORDER BY gap DESC;

-- Query 3.5: Self-join to find days with more than one order.
-- We join executive_orders to itself, using aliases a and b.
-- The ON rule matches rows with the same president and the same
-- signing date. The condition a.rowid < b.rowid keeps each pair
-- once, and stops a row from pairing with itself. Without it,
-- every row would match itself and every pair would appear twice.
-- This answers a real question: on which days did one president
-- sign several orders at once? The count here is pairs, not
-- orders, and pairs grow fast when a day holds many orders, so
-- the top pairs point at the busiest days. The top pair day is
-- 2025-01-20, Inauguration Day, with 26 Trump orders, followed
-- by Roosevelt days in the 1930s, when short administrative
-- orders piled up.
SELECT
    a.president,
    a.date_signed,
    COUNT(*) AS pairs_on_that_day
FROM executive_orders AS a
INNER JOIN executive_orders AS b
    ON a.president = b.president
    AND a.date_signed = b.date_signed
    AND a.rowid < b.rowid
GROUP BY a.president, a.date_signed
ORDER BY pairs_on_that_day DESC
LIMIT 20;
