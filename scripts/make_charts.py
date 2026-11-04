"""Build 8 charts from results/ CSVs, saving copies to charts/ and docs/charts/.

Run from the project root, after scripts/export_results.py:
    python3 scripts/make_charts.py

Only matplotlib is used. Titles are plain words, no em-dash anywhere.
"""

import csv
import os
import shutil

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
RESULTS = os.path.join(ROOT, "results")
CHARTS = os.path.join(ROOT, "charts")
DOC_CHARTS = os.path.join(ROOT, "docs", "charts")


def read_csv(name):
    with open(os.path.join(RESULTS, name), newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def save(fig, name):
    fig.tight_layout()
    fig.savefig(os.path.join(CHARTS, name), dpi=150)
    fig.savefig(os.path.join(DOC_CHARTS, name), dpi=150)
    plt.close(fig)
    print(name)


def barh_chart(rows, label_key, value_key, title, xlabel, filename):
    rows = list(rows)
    fig, ax = plt.subplots(figsize=(10, 6))
    ax.barh([r[label_key] for r in rows][::-1],
             [float(r[value_key]) for r in rows][::-1])
    ax.set_title(title)
    ax.set_xlabel(xlabel)
    ax.grid(axis="x", alpha=0.3)
    save(fig, filename)


def bar_chart(rows, label_key, value_key, title, ylabel, filename, rotate=45):
    fig, ax = plt.subplots(figsize=(10, 6))
    ax.bar([str(r[label_key]) for r in rows],
           [float(r[value_key]) for r in rows])
    ax.set_title(title)
    ax.set_ylabel(ylabel)
    ax.tick_params(axis="x", rotation=rotate)
    ax.grid(axis="y", alpha=0.3)
    save(fig, filename)


def line_chart(rows, label_key, value_key, title, ylabel, filename):
    fig, ax = plt.subplots(figsize=(12, 6))
    ax.plot([float(r[label_key]) for r in rows],
            [float(r[value_key]) for r in rows])
    ax.set_title(title)
    ax.set_ylabel(ylabel)
    ax.grid(alpha=0.3)
    save(fig, filename)


def main():
    os.makedirs(CHARTS, exist_ok=True)
    os.makedirs(DOC_CHARTS, exist_ok=True)

    presidents = read_csv("orders_by_president.csv")[:10]
    barh_chart(presidents, "president", "orders",
               "Top 10 presidents by executive orders",
               "Orders in dataset", "01_top_presidents.png")

    years = read_csv("orders_by_year.csv")
    line_chart(years, "year", "orders",
               "Executive orders per year, 1791 to 2026",
               "Orders", "02_orders_per_year.png")

    categories = read_csv("orders_by_category.csv")
    barh_chart(categories, "category", "orders",
               "Executive orders by policy category",
               "Orders in dataset", "03_category_shares.png")

    decades = read_csv("orders_by_decade.csv")
    bar_chart(decades, "decade", "orders",
              "Executive orders by decade",
              "Orders", "04_orders_by_decade.png")

    availability = read_csv("text_availability.csv")
    bar_chart(availability, "text_available", "orders",
              "Full text versus title only",
              "Orders", "05_text_availability.png", rotate=0)

    running = read_csv("running_total_by_year.csv")
    line_chart(running, "year", "running_total",
               "Running total of executive orders by year",
               "Cumulative orders", "06_running_total.png")

    top_years = read_csv("top_years.csv")
    bar_chart(top_years, "year", "orders",
              "Top 10 busiest years",
              "Orders", "07_top_years.png", rotate=0)

    parties = read_csv("orders_by_party.csv")
    bar_chart(parties, "party", "orders",
              "Executive orders by party",
              "Orders", "08_orders_by_party.png", rotate=0)


if __name__ == "__main__":
    main()
