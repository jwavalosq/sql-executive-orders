-- ============================================================
-- Step 6: Capstone. Five recruiter style interview questions.
--
-- Each question below is the kind of question a hiring manager
-- asks a data analyst: a plain business question that needs one
-- clear query and one honest answer. Each query is self contained
-- and well commented, so you can explain every line out loud.
--
-- The answers, in short:
--   1. Roosevelt leads with 3,725, ahead of Hoover by 2,721.
--   2. 1933 is the busiest year with 657 orders, 6.0 percent
--      of the whole archive.
--   3. Other or General is the biggest category with 3,612
--      orders, 33.2 percent of the archive.
--   4. The archive is not complete before 1929. Wilson shows
--      150 rows against a published total of 1,803.
--   5. Volume peaks in the 1930s and falls back after that.
--      Modern presidents sign far fewer orders per term.
-- ============================================================

-- Capstone question 1: Who signed the most executive orders,
-- and by how much did they lead the runner up?
-- How it works: count orders per president, rank the counts
-- with ROW_NUMBER, keep ranks 1 and 2, then use MAX with CASE
-- to turn those two rows into one answer row. The lead is the
-- top count minus the second count: 3,725 minus 1,004, which
-- is 2,721. A recruiter likes this question because it tests
-- ranking, filtering, and turning rows into a comparison.
WITH president_counts AS (
    SELECT president, COUNT(*) AS orders
    FROM executive_orders
    GROUP BY president
),
ranked AS (
    SELECT
        president,
        orders,
        ROW_NUMBER() OVER (ORDER BY orders DESC) AS rank_num
    FROM president_counts
)
SELECT
    MAX(CASE WHEN rank_num = 1 THEN president END) AS top_president,
    MAX(CASE WHEN rank_num = 1 THEN orders END) AS top_orders,
    MAX(CASE WHEN rank_num = 2 THEN president END) AS runner_up,
    MAX(CASE WHEN rank_num = 2 THEN orders END) AS runner_up_orders,
    MAX(CASE WHEN rank_num = 1 THEN orders END)
        - MAX(CASE WHEN rank_num = 2 THEN orders END) AS lead
FROM ranked
WHERE rank_num <= 2;

-- Capstone question 2: Which year had the most orders, and what
-- share of all orders was that?
-- How it works: count orders per year, order by the count
-- descending, keep the first row. The share divides that count
-- by the full total of 10,879. The answer is 1933, with 657
-- orders, which is 6.0 percent of the archive. One year holding
-- 6 percent of 235 years of orders is a striking fact, and it
-- points straight at the New Deal.
SELECT
    year,
    orders,
    ROUND(100.0 * orders / (SELECT COUNT(*) FROM executive_orders), 1)
        AS share_percent
FROM (
    SELECT year, COUNT(*) AS orders
    FROM executive_orders
    GROUP BY year
)
ORDER BY orders DESC
LIMIT 1;

-- Capstone question 3: Which policy topics dominate, and how
-- much of the archive sits in the vague Other or General bucket?
-- How it works: count orders per category, order biggest first,
-- keep the top 5, and add each share of the total. Other or
-- General holds 3,612 orders, 33.2 percent. The honest follow
-- up, which you should say out loud in an interview, is that
-- categories come from keyword rules on titles, so they are
-- good for broad shares, not for labeling any single order.
WITH category_counts AS (
    SELECT category, COUNT(*) AS orders
    FROM executive_orders
    GROUP BY category
)
SELECT
    category,
    orders,
    ROUND(100.0 * orders / (SELECT COUNT(*) FROM executive_orders), 1)
        AS share_percent
FROM category_counts
ORDER BY orders DESC
LIMIT 5;

-- Capstone question 4: Is this archive complete? Compare dataset
-- rows with published historical totals, and name the gaps.
-- How it works: count dataset rows per president, then LEFT
-- JOIN that result to published_reference_totals, starting
-- from the reference table so every published name appears,
-- even names with zero dataset rows. COALESCE turns the NULL
-- for "no rows" into 0. The gap is the published total minus
-- the dataset rows. A positive gap means rows are missing
-- from this dataset. The answer: the archive is row level
-- complete from Hoover onward, but thin before that. Wilson
-- shows 150 rows against a published total of 1,803. Coolidge
-- shows 79 against 1,203. Theodore Roosevelt shows 104 against
-- 1,081. Taft shows 75 against 724. Harding shows 27 against
-- 522. Five published names have zero dataset rows at all:
-- John Adams, Thomas Jefferson, James Madison, and James
-- Monroe, whose presidencies predate the start of the APP
-- listing used here, plus William Henry Harrison, whose
-- published total is 0 anyway. Lincoln is the reverse: 119
-- rows against a published total of 48, because the listing
-- counts some general orders as well. A negative gap, like
-- Roosevelt at 3,725 rows against 3,721, means the dataset
-- holds a few more rows than the reference total, because
-- counting rules differ. Never quote a pre-1929 row count as
-- if it were the published historical total.
SELECT
    ref.president,
    COALESCE(grouped.orders_in_dataset, 0) AS orders_in_dataset,
    ref.published_reference_total,
    ref.published_reference_total
        - COALESCE(grouped.orders_in_dataset, 0) AS gap,
    CASE
        WHEN ref.published_reference_total
            - COALESCE(grouped.orders_in_dataset, 0) > 100
            THEN 'Large gap: source is a sample, not complete rows'
        WHEN ref.published_reference_total
            - COALESCE(grouped.orders_in_dataset, 0) < 0
            THEN 'Dataset holds more rows than the reference total'
        ELSE 'Close match'
    END AS reading
FROM published_reference_totals AS ref
LEFT JOIN (
    SELECT president, COUNT(*) AS orders_in_dataset
    FROM executive_orders
    GROUP BY president
) AS grouped
    ON grouped.president = ref.president
ORDER BY gap DESC;

-- Capstone question 5: How has the use of executive orders
-- changed over time?
-- How it works: count orders per decade, add each decade share
-- of the total, and order by decade. The story reads clearly:
-- volume is low in the 1800s, climbs through the early 1900s,
-- peaks in the 1930s at 3,313 orders, stays high through the
-- 1940s, then falls back. Modern presidents sign far fewer
-- orders per term, roughly 150 to 400, but each order tends to
-- carry more policy weight. Timing alone is not proof of cause:
-- this query shows when volume changed, not why it changed.
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
