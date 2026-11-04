"""Build executive_orders.db from the verified CSV files.

Run from the project root:
    python3 scripts/load_database.py

Inputs (already verified, no download needed):
    ../us-executive-orders/data/processed/executive_orders.csv
    ../us-executive-orders/data/processed/orders_by_president_dataset.csv
    ../us-executive-orders/data/processed/orders_by_year.csv
    data/published_reference_totals.csv (this repo)

Output:
    executive_orders.db (gitignored, rebuild it any time with this script)

Honest data notes, handled here and documented, not hidden:
    - executive_order_number in the source CSV is a float formatted string
      such as '14438.0', or empty for unnumbered early orders. We store the
      raw value as TEXT in executive_order_number, and we add a cleaned
      integer column eo_number_int (NULL when the order is unnumbered).
    - text_word_count is also float formatted ('168.0') and empty for the
      9,330 title only rows. We store it as INTEGER, NULL when empty.
    - year, decade, and title_word_count are plain integers in the source.
    - published_reference_totals.csv holds published historical totals per
      president. Those are reference totals, not dataset rows. They are kept
      in their own table so the two are never confused.
"""

import csv
import os
import sqlite3
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
EO_DIR = os.path.expanduser("~/workspace/us-executive-orders/data/processed")
DB_PATH = os.path.join(ROOT, "executive_orders.db")


def parse_int(value):
    """Return an int from a plain or float formatted string, else None."""
    value = (value or "").strip()
    if not value:
        return None
    try:
        return int(float(value))
    except ValueError:
        return None


def main():
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)
    con = sqlite3.connect(DB_PATH)
    cur = con.cursor()

    cur.execute("""
        CREATE TABLE executive_orders (
            executive_order_number TEXT,
            eo_number_int INTEGER,
            president TEXT,
            party TEXT,
            term TEXT,
            era TEXT,
            date_signed TEXT,
            year INTEGER,
            decade INTEGER,
            title TEXT,
            title_clean TEXT,
            title_word_count INTEGER,
            category TEXT,
            category_keyword TEXT,
            disposition_status TEXT,
            disposition_notes TEXT,
            source TEXT,
            text_available TEXT,
            text_word_count INTEGER,
            app_url TEXT,
            federal_register_url TEXT,
            president_app_label TEXT
        )
    """)
    cur.execute("""
        CREATE TABLE orders_by_president (
            president TEXT,
            party TEXT,
            orders_in_dataset INTEGER
        )
    """)
    cur.execute("""
        CREATE TABLE orders_by_year (
            year INTEGER,
            orders INTEGER
        )
    """)
    cur.execute("""
        CREATE TABLE published_reference_totals (
            president TEXT,
            published_reference_total INTEGER
        )
    """)

    main_csv = os.path.join(EO_DIR, "executive_orders.csv")
    with open(main_csv, newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    for r in rows:
        cur.execute(
            """INSERT INTO executive_orders VALUES
               (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                r["executive_order_number"],
                parse_int(r["executive_order_number"]),
                r["president"],
                r["party"],
                r["term"],
                r["era"],
                r["date_signed"],
                parse_int(r["year"]),
                parse_int(r["decade"]),
                r["title"],
                r["title_clean"],
                parse_int(r["title_word_count"]),
                r["category"],
                r["category_keyword"],
                r["disposition_status"],
                r["disposition_notes"],
                r["source"],
                r["text_available"],
                parse_int(r["text_word_count"]),
                r["app_url"],
                r["federal_register_url"],
                r["president_app_label"],
            ),
        )

    with open(os.path.join(EO_DIR, "orders_by_president_dataset.csv"),
              newline="", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            cur.execute("INSERT INTO orders_by_president VALUES (?, ?, ?)",
                        (r["president"], r["party"],
                         parse_int(r["orders_in_dataset"])))

    with open(os.path.join(EO_DIR, "orders_by_year.csv"),
              newline="", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            cur.execute("INSERT INTO orders_by_year VALUES (?, ?)",
                        (r["year"], parse_int(r["orders"])))

    with open(os.path.join(ROOT, "data", "published_reference_totals.csv"),
              newline="", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            cur.execute("INSERT INTO published_reference_totals VALUES (?, ?)",
                        (r["president"],
                         parse_int(r["published_reference_total"])))

    cur.execute("CREATE INDEX idx_eo_president ON executive_orders(president)")
    cur.execute("CREATE INDEX idx_eo_year ON executive_orders(year)")
    cur.execute("CREATE INDEX idx_eo_category ON executive_orders(category)")
    con.commit()

    checks = {
        "executive_orders": "SELECT COUNT(*) FROM executive_orders",
        "orders_by_president": "SELECT COUNT(*) FROM orders_by_president",
        "orders_by_year": "SELECT COUNT(*) FROM orders_by_year",
        "published_reference_totals":
            "SELECT COUNT(*) FROM published_reference_totals",
        "numbered": "SELECT COUNT(*) FROM executive_orders "
                    "WHERE eo_number_int IS NOT NULL",
        "unnumbered": "SELECT COUNT(*) FROM executive_orders "
                      "WHERE eo_number_int IS NULL",
        "full_text": "SELECT COUNT(*) FROM executive_orders "
                    "WHERE text_available = 'Full text downloaded'",
    }
    for name, sql in checks.items():
        print(name, "=", cur.execute(sql).fetchone()[0])
    con.close()
    print("Wrote", DB_PATH)


if __name__ == "__main__":
    sys.exit(main())
