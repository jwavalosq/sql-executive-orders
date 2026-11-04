# Build Report: Executive Orders in SQL

## What was built

A SQL only portfolio project on the verified executive orders dataset, in the same story driven style as the earlier portfolio projects, but with SQL as the whole method. Published Nov 4, 2026 to github.com/jwavalosq/sql-executive-orders, story site jwavalosq.github.io/sql-executive-orders, after the user's explicit go, with a small follow-up commit fixing the local-only wording.

Location: `~/workspace/sql-executive-orders/`

## Sources

See `PROVENANCE.md` for full source notes. In short: the main dataset and two summary tables come from the earlier executive orders project (`~/workspace/us-executive-orders/data/processed/`), which was built from the American Presidency Project listing and the Federal Register API. The published reference totals come from that project's comparison table: APP counts table, cross checked against the Competitive Enterprise Institute Table 4 tabulation of National Archives disposition tables. No data was re-downloaded for this project. The source files were read, not modified.

## Build steps

1. Read the source headers and checked types: 10,879 rows, 21 columns, no empty dates or years. EO numbers are float formatted strings ('14438.0') or empty. Text word counts are float formatted or empty for title only rows.
2. Wrote `data/published_reference_totals.csv` with the 45 published totals, copied exactly from the earlier project's reference table.
3. Wrote `scripts/load_database.py`, which builds `executive_orders.db` with four tables: `executive_orders`, `orders_by_president`, `orders_by_year`, `published_reference_totals`. The loader stores raw EO numbers as TEXT and adds a cleaned integer `eo_number_int` (NULL when unnumbered), and stores `text_word_count` as INTEGER (NULL for title only rows). It adds indexes on president, year, and category.
4. Wrote the six ladder files in `sql/`, each with plain language header comments: the question, what you will learn, and how each query works line by line.
5. Ran every SQL file against the built database. Zero errors allowed, zero errors found.
6. Wrote `scripts/export_results.py` (11 results CSVs) and `scripts/make_charts.py` (8 charts, saved to both `charts/` and `docs/charts/`).
7. Wrote `docs/index.html` (one chapter per ladder step), `README.md`, this report, and `PROVENANCE.md`.
8. Grepped the whole folder for the em-dash character. Result: zero matches.

## Verification log

Loader counts:
- executive_orders: 10,879 rows
- orders_by_president: 40 rows
- orders_by_year: 187 rows
- published_reference_totals: 45 rows
- numbered: 9,989. Unnumbered: 890. Full text: 1,549.

SQL execution (all statements run with Python sqlite3, split on complete statements):
- sql/01_foundations.sql: 9 statements, 0 errors
- sql/02_aggregations.sql: 12 statements, 0 errors
- sql/03_joins.sql: 5 statements, 0 errors
- sql/04_window_functions.sql: 7 statements, 0 errors
- sql/05_ctes_and_case.sql: 6 statements, 0 errors
- sql/06_capstone.sql: 5 statements, 0 errors
- Total: 44 statements, 0 errors.

Headline figures, all matched exactly, no adjustments:
- Total: 10,879
- Franklin D. Roosevelt: 3,725. Herbert Hoover: 1,004. Harry S. Truman: 907.
- Busiest years: 1933 with 657, 1934 with 472, 1935 with 384, 1941 with 382, 1940 with 309.
- Categories: Other or General 3,612, Land and Public Lands 1,714, Government Administration 1,351.
- Date range: 1791-01-22 to 2026-10-22. Latest row: EO 14438, Donald J. Trump, Decreasing Housing Costs for the American People.
- Numbered: 9,989. Unnumbered: 890. Full text rows: 1,549.
- Full text word counts: min 133 (EO 12936, William J. Clinton), max 19,863 (EO 14110, Joseph R. Biden).
- 1930s decade total: 3,313.
- Trump terms: 220 first term, 292 second term through 2026-10-22, 512 combined.
- Join checks: president summary differences nonzero: 0. Year summary differences nonzero: 0.
- Gap table extremes: Wilson 150 rows versus 1,803 published (gap 1,653). Coolidge 79 versus 1,203 (gap 1,124). Theodore Roosevelt 104 versus 1,081 (gap 977). Taft 75 versus 724 (gap 649). Harding 27 versus 522 (gap 495). Reverse cases: Lincoln 119 versus 48 (gap -71). Hoover 1,004 versus 968 (gap -36). Roosevelt 3,725 versus 3,721 (gap -4).
- Reference names with zero dataset rows: John Adams, Thomas Jefferson, James Madison, James Monroe, William Henry Harrison. No dataset president is missing from the reference table.
- Year busyness buckets: Very busy 1 year, Busy 14, Active 47, Quiet 125 (187 years total).
- Title length buckets: Short 1,901, Medium 4,811, Long 4,167 (10,879 total).
- Categories over 500 orders: 7. Presidents over 500 orders: 4 (Roosevelt, Hoover, Truman, Trump).
- Same day pairs: top day is 2025-01-20 with 325 pairs (26 Trump orders on Inauguration Day), then Roosevelt days in the 1930s.

Corrections made during verification (caught before delivery, not glossed over):
- The aggregation comment first said three presidents clear 500 orders. The query shows four, because Trump totals 512 across both terms. Fixed.
- The self-join comment first said the busiest pair days sit in the 1930s. The query shows the top pair day is 2025-01-20. Fixed.
- The capstone gap query first used INNER JOIN, which hides presidents with zero dataset rows. It now uses LEFT JOIN from the reference table with COALESCE, so all 45 published names appear. The results exporter was updated to match.

Charts: 8 PNG files, all validated as readable images, in both `charts/` and `docs/charts/`:
01_top_presidents, 02_orders_per_year, 03_category_shares, 04_orders_by_decade, 05_text_availability, 06_running_total, 07_top_years, 08_orders_by_party.

Em-dash check: grep for the em-dash character across the whole folder returned zero matches.

## Cuts and limits

- No new data was collected. The project reuses the verified dataset from the earlier executive orders project, by design, so the SQL learning is the new work, not another scrape.
- The database file is gitignored and must be rebuilt with the load script. That is intentional: the repo ships code and small CSVs, not a binary database.
- The story site is a local HTML file. It is not published anywhere, per the local only instruction.
- Categories, disposition notes, and the pre-1929 gap carry the same limits as the source project. Those limits are stated in the README, the story site, and the SQL comments, not hidden.
- Charts are matplotlib only, plain styled, built from query result CSVs. No interactive dashboard was built for this project, because the brief asked for SQL mastery, not a dashboard.
