-- ============================================================
-- Step 2: Aggregations. COUNT, SUM, AVG, MIN, MAX, GROUP BY, HAVING.
--
-- The question: how many orders are there, who signed the most,
-- and which years and topics dominate?
--
-- What you will learn:
--   COUNT counts rows. SUM adds numbers. AVG takes an average.
--   MIN and MAX find the smallest and largest values.
--   GROUP BY splits rows into groups, one result row per group.
--   HAVING filters groups, the way WHERE filters single rows.
--   You must use HAVING for group filters, because WHERE runs
--   before grouping and cannot see group totals.
--
-- A warning about averages: AVG hides the shape of the data.
-- Always pair an average with a MIN and a MAX, or a count, so
-- you can see whether the average is typical or pulled by outliers.
-- ============================================================

-- Query 2.1: How many orders are in the whole dataset?
-- COUNT(*) counts every row in the table. The answer is 10,879.
SELECT COUNT(*) AS total_orders
FROM executive_orders;

-- Query 2.2: Orders per president, most first.
-- GROUP BY president makes one group per president. COUNT(*)
-- counts the rows in each group. ORDER BY COUNT(*) DESC puts
-- the biggest group first. Franklin D. Roosevelt leads with 3,725.
SELECT president, COUNT(*) AS orders
FROM executive_orders
GROUP BY president
ORDER BY orders DESC;

-- Query 2.3: The 5 busiest years.
-- Same pattern, grouped by year. 1933 leads with 657 orders,
-- then 1934 with 472. LIMIT 5 keeps only the top five years.
SELECT year, COUNT(*) AS orders
FROM executive_orders
GROUP BY year
ORDER BY orders DESC
LIMIT 5;

-- Query 2.4: Orders per policy category, biggest first.
-- The largest bucket is Other or General with 3,612 orders.
-- That bucket is a reminder that keyword rules are blunt: many
-- titles fit no clear topic, so they land in Other or General.
SELECT category, COUNT(*) AS orders
FROM executive_orders
GROUP BY category
ORDER BY orders DESC;

-- Query 2.5: Orders per decade.
-- The decade column holds values like 1930 for the 1930s.
-- The 1930s dominate, with 3,313 orders.
SELECT decade, COUNT(*) AS orders
FROM executive_orders
GROUP BY decade
ORDER BY decade ASC;

-- Query 2.6: The date range of the whole dataset.
-- MIN finds the earliest date, MAX finds the latest date.
-- The range is 1791-01-22 to 2026-10-22.
SELECT MIN(date_signed) AS earliest, MAX(date_signed) AS latest
FROM executive_orders;

-- Query 2.7: Full text versus title only.
-- GROUP BY text_available splits the table into two groups:
-- 1,549 rows with full text, 9,330 rows that are title only.
SELECT text_available, COUNT(*) AS orders
FROM executive_orders
GROUP BY text_available;

-- Query 2.8: Numbered versus unnumbered orders.
-- eo_number_int is NULL for unnumbered orders. CASE WHEN turns
-- that test into a readable label, then GROUP BY counts each label.
-- The result is 9,989 numbered and 890 unnumbered.
SELECT
    CASE WHEN eo_number_int IS NULL THEN 'Unnumbered' ELSE 'Numbered' END AS numbering,
    COUNT(*) AS orders
FROM executive_orders
GROUP BY numbering;

-- Query 2.9: Title length statistics.
-- AVG gives the average title length in words. MIN and MAX show
-- the shortest and longest titles. Most titles are short: the
-- median title is 10 words (computed in the earlier project).
SELECT
    AVG(title_word_count) AS avg_title_words,
    MIN(title_word_count) AS shortest_title_words,
    MAX(title_word_count) AS longest_title_words
FROM executive_orders;

-- Query 2.10: Full text length statistics.
-- SUM adds up all full text words. AVG, MIN, and MAX describe
-- the typical and extreme full texts. NULL rows (title only
-- orders) are ignored by SUM, AVG, MIN, and MAX automatically,
-- which is exactly what we want here.
-- Longest: EO 14110, the Biden AI order, 19,863 words.
-- Shortest: EO 12936, 133 words. Median: 974 words.
SELECT
    COUNT(text_word_count) AS orders_with_text,
    SUM(text_word_count) AS total_full_text_words,
    AVG(text_word_count) AS avg_full_text_words,
    MIN(text_word_count) AS shortest_full_text,
    MAX(text_word_count) AS longest_full_text
FROM executive_orders;

-- Query 2.11: Presidents with more than 500 orders.
-- HAVING COUNT(*) > 500 keeps only groups with over 500 rows.
-- Four presidents clear that bar: Roosevelt, Hoover, Truman,
-- and Trump, whose 512 counts both terms combined. WHERE could
-- not do this, because WHERE cannot see a group total.
SELECT president, COUNT(*) AS orders
FROM executive_orders
GROUP BY president
HAVING COUNT(*) > 500
ORDER BY orders DESC;

-- Query 2.12: Categories with more than 500 orders.
-- Same HAVING pattern, applied to categories. Seven categories
-- clear 500: Other or General, Land and Public Lands, Government
-- Administration, Defense and Military, Economy and Finance,
-- Foreign Policy and Trade, and Emergency and Disaster.
SELECT category, COUNT(*) AS orders
FROM executive_orders
GROUP BY category
HAVING COUNT(*) > 500
ORDER BY orders DESC;
