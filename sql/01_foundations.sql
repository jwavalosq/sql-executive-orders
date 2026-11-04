-- ============================================================
-- Step 1: Foundations. SELECT, WHERE, ORDER BY, LIMIT, DISTINCT.
--
-- The question: what is in this table, and how do I look at just
-- the rows I care about?
--
-- What you will learn:
--   SELECT picks columns. FROM picks the table. WHERE filters rows.
--   ORDER BY sorts rows. LIMIT keeps only the first few rows.
--   DISTINCT removes duplicates, so you see each value once.
--   LIKE lets you search inside text. The percent sign means
--   "any characters can go here".
--
-- How to run this file: build the database first with
--   python3 scripts/load_database.py
-- then run this file against executive_orders.db with any SQLite
-- tool. Every query below is independent. Run them in order.
-- ============================================================

-- Query 1.1: The first 10 orders ever signed.
-- SELECT * means "give me every column". ORDER BY date_signed
-- sorts oldest first, because ASC means ascending, smallest first.
-- LIMIT 10 stops after 10 rows, so the result stays small.
SELECT *
FROM executive_orders
ORDER BY date_signed ASC
LIMIT 10;

-- Query 1.2: The 10 most recent orders.
-- Same query, but DESC means descending, largest first, so the
-- newest dates come first. The newest order here is EO 14438,
-- signed 2026-10-22.
SELECT *
FROM executive_orders
ORDER BY date_signed DESC
LIMIT 10;

-- Query 1.3: Ten orders from Franklin D. Roosevelt, oldest first.
-- WHERE keeps only rows where the president column matches the
-- name exactly. Names must match exactly, including middle initials.
SELECT executive_order_number, date_signed, title
FROM executive_orders
WHERE president = 'Franklin D. Roosevelt'
ORDER BY date_signed ASC
LIMIT 10;

-- Query 1.4: Every president in the dataset, listed once.
-- DISTINCT collapses repeats. There are 40 names, not 10,879,
-- because most presidents signed many orders.
SELECT DISTINCT president
FROM executive_orders
ORDER BY president ASC;

-- Query 1.5: Every policy category, listed once.
-- Same idea as 1.4, but for the category column. Categories come
-- from keyword rules on titles, so treat them as broad buckets,
-- not exact labels for single orders.
SELECT DISTINCT category
FROM executive_orders
ORDER BY category ASC;

-- Query 1.6: Ten orders with the word land in the title.
-- LIKE '%land%' means "the title contains the letters land
-- anywhere". The percent signs stand for any characters before
-- and after. This is a quick way to search titles.
SELECT executive_order_number, date_signed, title
FROM executive_orders
WHERE title LIKE '%land%'
ORDER BY date_signed ASC
LIMIT 10;

-- Query 1.7: Orders signed in 1933, the busiest year.
-- WHERE year = 1933 keeps only that year. We limit to 10 rows
-- here, but the full year holds 657 orders, as step 2 will show.
SELECT executive_order_number, date_signed, title
FROM executive_orders
WHERE year = 1933
ORDER BY date_signed ASC
LIMIT 10;

-- Query 1.8: Ten orders that have full text available.
-- text_available has two values: 'Full text downloaded' and
-- 'Title only'. Only recent orders have full text. Older orders
-- are title only in this dataset.
SELECT executive_order_number, president, date_signed, title
FROM executive_orders
WHERE text_available = 'Full text downloaded'
ORDER BY date_signed ASC
LIMIT 10;

-- Query 1.9: Orders with no EO number, the unnumbered early orders.
-- In SQL, missing values are called NULL. You test for them with
-- IS NULL, never with = NULL, because NULL is not equal to anything.
-- These are the 890 early orders from before numbering settled.
SELECT date_signed, president, title
FROM executive_orders
WHERE eo_number_int IS NULL
ORDER BY date_signed ASC
LIMIT 10;
