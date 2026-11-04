-- ============================================================
-- Step 5: CTEs and CASE. WITH clauses and buckets.
--
-- The question: how do I break a hard question into steps, and
-- how do I sort rows into readable buckets?
--
-- What you will learn:
--   WITH gives a name to a step, called a common table
--   expression, or CTE. Later steps can use that name like a
--   table. CTEs make long queries readable, because each step
--   does one job and has a clear name.
--   CASE WHEN tests rows one condition at a time and returns
--   the first matching label. It is how you turn numbers into
--   buckets such as "Very busy year" or "Short title".
--   A CTE chain runs top to bottom: each CTE can use the ones
--   above it, but not the ones below it.
-- ============================================================

-- Query 5.1: Presidents above the average president total.
-- Step one (president_counts) counts orders per president.
-- Step two (average_total) averages those counts. The final
-- SELECT keeps presidents above that average. Without CTEs,
-- this would need the same subquery written twice. With CTEs,
-- each step is written once and named.
WITH president_counts AS (
    SELECT president, COUNT(*) AS orders
    FROM executive_orders
    GROUP BY president
),
average_total AS (
    SELECT AVG(orders) AS avg_orders
    FROM president_counts
)
SELECT p.president, p.orders
FROM president_counts AS p, average_total AS a
WHERE p.orders > a.avg_orders
ORDER BY p.orders DESC;

-- Query 5.2: Years sorted into busyness buckets.
-- CASE WHEN checks the order count from top to bottom and
-- returns the first label that fits. A year with 657 orders
-- hits the first branch, "Very busy year". A year with 3
-- orders falls through to "Quiet year". Then GROUP BY counts
-- how many years fall in each bucket.
SELECT
    CASE
        WHEN orders >= 500 THEN 'Very busy year'
        WHEN orders >= 200 THEN 'Busy year'
        WHEN orders >= 50 THEN 'Active year'
        ELSE 'Quiet year'
    END AS busyness,
    COUNT(*) AS years_in_bucket
FROM (
    SELECT year, COUNT(*) AS orders
    FROM executive_orders
    GROUP BY year
)
GROUP BY busyness
ORDER BY years_in_bucket DESC;

-- Query 5.3: Titles sorted into length buckets.
-- Same CASE pattern, applied to title word counts. Short titles
-- have 5 words or fewer. Medium titles have 6 to 12 words.
-- Long titles have more than 12 words. This shows at a glance
-- whether presidents wrote short labels or long sentences.
SELECT
    CASE
        WHEN title_word_count <= 5 THEN 'Short title'
        WHEN title_word_count <= 12 THEN 'Medium title'
        ELSE 'Long title'
    END AS title_length,
    COUNT(*) AS orders
FROM executive_orders
GROUP BY title_length
ORDER BY orders DESC;

-- Query 5.4: Each decade's share of all orders.
-- Step one (decade_counts) counts orders per decade.
-- Step two (total) counts all orders, 10,879. The final SELECT
-- divides each decade count by the total and multiplies by 100,
-- so the result reads as a percent. The 1930s hold about 30
-- percent of the whole archive, which is the headline story
-- of this query. Note the 100.0, not 100: in SQLite, dividing
-- two integers gives an integer, so 100.0 forces decimal math.
WITH decade_counts AS (
    SELECT decade, COUNT(*) AS orders
    FROM executive_orders
    GROUP BY decade
),
total AS (
    SELECT COUNT(*) AS all_orders
    FROM executive_orders
)
SELECT
    d.decade,
    d.orders,
    ROUND(100.0 * d.orders / t.all_orders, 1) AS share_percent
FROM decade_counts AS d, total AS t
ORDER BY d.decade ASC;

-- Query 5.5: Top 5 categories with their share of all orders.
-- Step one counts orders per category. Step two ranks them with
-- ROW_NUMBER. The final SELECT keeps ranks 1 to 5 and adds each
-- share of the 10,879 total. Other or General alone is about
-- 33 percent, which is why categories must be read as broad
-- shares, not exact labels.
WITH category_counts AS (
    SELECT category, COUNT(*) AS orders
    FROM executive_orders
    GROUP BY category
),
ranked AS (
    SELECT
        category,
        orders,
        ROW_NUMBER() OVER (ORDER BY orders DESC) AS rank_num
    FROM category_counts
),
total AS (
    SELECT COUNT(*) AS all_orders
    FROM executive_orders
)
SELECT
    r.category,
    r.orders,
    ROUND(100.0 * r.orders / t.all_orders, 1) AS share_percent
FROM ranked AS r, total AS t
WHERE r.rank_num <= 5
ORDER BY r.orders DESC;

-- Query 5.6: Era profile in one CTE chain.
-- Step one counts orders per era and averages title length.
-- Step two adds the full text share: full text orders divided
-- by all orders in that era, times 100. Recent eras show a high
-- full text share, because full text here is recent only.
-- Early eras show 0, which is a data limit, not a behavior.
WITH era_counts AS (
    SELECT
        era,
        COUNT(*) AS orders,
        AVG(title_word_count) AS avg_title_words,
        SUM(CASE WHEN text_available = 'Full text downloaded'
                 THEN 1 ELSE 0 END) AS full_text_orders
    FROM executive_orders
    GROUP BY era
)
SELECT
    era,
    orders,
    ROUND(avg_title_words, 1) AS avg_title_words,
    full_text_orders,
    ROUND(100.0 * full_text_orders / orders, 1) AS full_text_share_percent
FROM era_counts
ORDER BY orders DESC;
