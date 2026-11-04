# Executive Orders in SQL

Learn SQL on a real archive, not toy data. One table holds 10,879 executive orders, from George Washington in 1791 to EO 14438 in 2026. You start with simple filters and end with window functions, CTEs, joins, and five recruiter style interview questions, all in SQLite.

An executive order is a signed instruction from the President to the federal government. It has the force of law until a later President, Congress, or a court changes it. Presidents have used this tool since Washington, but not the same way in every era. Early orders were often short, routine paperwork. Later orders are more often about national policy.

## How to run it

You need only Python and SQLite. Charts need matplotlib.

```bash
pip install -r requirements.txt
python3 scripts/load_database.py
sqlite3 executive_orders.db < sql/01_foundations.sql
```

Repeat the last command for files 02 through 06, in order. Each file is self contained and heavily commented, with the question in plain words, what you will learn, and how the query works line by line.

The database file is gitignored on purpose. You rebuild it any time with the load script. Query outputs live in `results/`. Charts live in `charts/` and in `docs/charts/`. The story site is `docs/index.html`, with one chapter per ladder step.

## The learning ladder

1. `sql/01_foundations.sql`: SELECT, WHERE, ORDER BY, LIMIT, DISTINCT, LIKE. Look at rows.
2. `sql/02_aggregations.sql`: COUNT, SUM, AVG, MIN, MAX, GROUP BY, HAVING. Count and group.
3. `sql/03_joins.sql`: INNER JOIN, LEFT JOIN, self-join. Combine tables and check they agree.
4. `sql/04_window_functions.sql`: ROW_NUMBER, RANK, running totals, LAG. Rank and compare without collapsing rows.
5. `sql/05_ctes_and_case.sql`: WITH clauses, CASE WHEN buckets. Break hard questions into steps.
6. `sql/06_capstone.sql`: five recruiter style interview questions, each answered in one well commented query.

## Headline findings, all from the queries in this repo

- Total rows: 10,879. Date range: 1791-01-22 to 2026-10-22. Latest order: EO 14438, Decreasing Housing Costs for the American People.
- Most orders by president: Franklin D. Roosevelt with 3,725, then Herbert Hoover with 1,004, then Harry S. Truman with 907.
- Busiest year: 1933 with 657 orders. Next: 1934 with 472, then 1935 with 384.
- Busiest decade: the 1930s, with 3,313 orders, about 30 percent of the whole archive.
- Largest keyword category: Other or General with 3,612 orders, 33.2 percent. Next: Land and Public Lands with 1,714, then Government Administration with 1,351.
- Numbered orders: 9,989. Unnumbered early orders: 890.
- Full text rows: 1,549. Title only rows: 9,330. Longest full text: EO 14110, the Biden AI order, 19,863 words. Shortest: EO 12936, 133 words. Median: 974 words.
- The summary tables match the main table exactly: every president count and every year count differs by 0.

## The honest limits, read this before you quote a total

This dataset is row level complete from Herbert Hoover onward. Before Hoover, it is a large titled sample, not a complete row list. Published historical totals are much higher for early presidents than the rows here. Wilson shows 150 rows against a published total of 1,803. Coolidge shows 79 against 1,203. Theodore Roosevelt shows 104 against 1,081. Taft shows 75 against 724. Harding shows 27 against 522. Five published names have zero dataset rows at all: John Adams, Thomas Jefferson, James Madison, and James Monroe, whose presidencies predate the start of the listing used here, plus William Henry Harrison, whose published total is 0 anyway. Lincoln is the reverse: 119 rows against a published total of 48, because the listing counts some general orders as well. Never quote a row count as if it were the published historical total for a pre-1929 president.

Full text is recent only. Older orders are title only here.

Keyword categories are good for broad shares, not for labeling any single order. On a hard hand checked sample of 30 orders in the earlier project, they agreed with a human reading on 15, or 50 percent.

No language model was trained or used here. This project is SQL only, by design: the point is to master SQL.

## Data notes

The source CSV stores EO numbers as float formatted strings such as '14438.0', and text word counts the same way, such as '168.0'. The load script stores the raw value as TEXT and adds a cleaned integer column: `eo_number_int` for EO numbers, and an INTEGER `text_word_count` that is NULL for title only rows. This is documented in `scripts/load_database.py` and in `PROVENANCE.md`, not hidden.

## Files

- `scripts/load_database.py`: builds executive_orders.db from the verified CSVs.
- `scripts/export_results.py`: runs the key queries and writes `results/` CSVs.
- `scripts/make_charts.py`: builds the 8 charts from `results/` CSVs.
- `sql/`: the six ladder files, in order.
- `results/`: 11 CSV outputs of the key queries.
- `charts/` and `docs/charts/`: 8 charts.
- `docs/index.html`: the story site, one chapter per ladder step.
- `data/published_reference_totals.csv`: published historical totals per president, kept separate from dataset rows.
- `BUILD_REPORT.md`, `PROVENANCE.md`: sources, build steps, verification log.

Local build only. Nothing here has been published, posted, or signed into anywhere.
