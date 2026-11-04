"""Run the key queries and write their outputs to results/ as CSVs.

Run from the project root, after scripts/load_database.py:
    python3 scripts/export_results.py

The CSVs feed the charts in scripts/make_charts.py and let a reader
check every headline number without running SQL by hand.
"""

import csv
import os
import sqlite3

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DB_PATH = os.path.join(ROOT, "executive_orders.db")
RESULTS = os.path.join(ROOT, "results")

QUERIES = {
    "orders_by_president.csv": """
        SELECT president, COUNT(*) AS orders
        FROM executive_orders GROUP BY president ORDER BY orders DESC
    """,
    "orders_by_year.csv": """
        SELECT year, COUNT(*) AS orders
        FROM executive_orders GROUP BY year ORDER BY year ASC
    """,
    "orders_by_category.csv": """
        SELECT category, COUNT(*) AS orders
        FROM executive_orders GROUP BY category ORDER BY orders DESC
    """,
    "orders_by_decade.csv": """
        SELECT decade, COUNT(*) AS orders,
               ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM executive_orders), 1)
               AS share_percent
        FROM executive_orders GROUP BY decade ORDER BY decade ASC
    """,
    "top_years.csv": """
        SELECT year, COUNT(*) AS orders
        FROM executive_orders GROUP BY year ORDER BY orders DESC LIMIT 10
    """,
    "text_availability.csv": """
        SELECT text_available, COUNT(*) AS orders
        FROM executive_orders GROUP BY text_available
    """,
    "running_total_by_year.csv": """
        SELECT year, orders,
               SUM(orders) OVER (ORDER BY year ASC
                   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
               AS running_total
        FROM (SELECT year, COUNT(*) AS orders
              FROM executive_orders GROUP BY year)
        ORDER BY year ASC
    """,
    "orders_by_party.csv": """
        SELECT party, COUNT(*) AS orders
        FROM executive_orders GROUP BY party ORDER BY orders DESC
    """,
    "president_rankings.csv": """
        SELECT president, orders,
               RANK() OVER (ORDER BY orders DESC) AS rank_by_orders
        FROM (SELECT president, COUNT(*) AS orders
              FROM executive_orders GROUP BY president)
        ORDER BY rank_by_orders ASC
    """,
    "yoy_change.csv": """
        WITH RECURSIVE all_years(year) AS (
            SELECT 1791 UNION ALL
            SELECT year + 1 FROM all_years WHERE year < 2026
        ),
        yearly AS (
            SELECT year, COUNT(*) AS orders
            FROM executive_orders GROUP BY year
        )
        SELECT a.year, COALESCE(y.orders, 0) AS orders,
               LAG(COALESCE(y.orders, 0)) OVER (ORDER BY a.year ASC)
               AS previous_year_orders,
               COALESCE(y.orders, 0)
               - LAG(COALESCE(y.orders, 0)) OVER (ORDER BY a.year ASC)
               AS change_from_previous
        FROM all_years AS a LEFT JOIN yearly AS y ON a.year = y.year
        ORDER BY a.year ASC
    """,
    "capstone_gap.csv": """
        SELECT ref.president, COALESCE(grouped.orders_in_dataset, 0)
               AS orders_in_dataset,
               ref.published_reference_total,
               ref.published_reference_total
               - COALESCE(grouped.orders_in_dataset, 0) AS gap
        FROM published_reference_totals AS ref
        LEFT JOIN (SELECT president, COUNT(*) AS orders_in_dataset
              FROM executive_orders GROUP BY president) AS grouped
            ON grouped.president = ref.president
        ORDER BY gap DESC
    """,
}


def main():
    os.makedirs(RESULTS, exist_ok=True)
    con = sqlite3.connect(DB_PATH)
    for filename, sql in QUERIES.items():
        cur = con.execute(sql)
        columns = [d[0] for d in cur.description]
        rows = cur.fetchall()
        path = os.path.join(RESULTS, filename)
        with open(path, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow(columns)
            writer.writerows(rows)
        print(filename, "=", len(rows), "rows")
    con.close()


if __name__ == "__main__":
    main()
