# Provenance: Executive Orders in SQL

## Sources, with what was taken from each

1. American Presidency Project (APP), University of California, Santa Barbara. Guidebook listing of executive orders: president, date, title, and a link to each order page. This is the row level backbone of the source dataset.
   - Listing pattern used by the source project: https://www.presidency.ucsb.edu/documents/presidential-documents-archive-guidebook/executive-orders-beginning-with-jq-adams?page=N
   - Note: the listing begins with John Quincy Adams. That is why John Adams, Thomas Jefferson, James Madison, and James Monroe have zero rows in this dataset.
   - APP's own note, quoted in the source project: its collection of executive order texts is complete beginning with the Hoover administration.

2. Federal Register API, Office of the Federal Register, National Archives. Presidential documents of type executive_order. This gives the official title, signing date, EO number, disposition notes, and links, and it was used to enrich APP rows.
   - API pattern: https://www.federalregister.gov/api/v1/documents.json with conditions for presidential_document_type set to executive_order.
   - Federal Register full text pages, one per EO number, were downloaded for recent orders and used only for word counts. Full text pattern: https://www.federalregister.gov/documents/full_text/text/YYYY/MM/DD/DOCUMENT.txt

3. National Archives executive order disposition tables, for context and cross checks, via the Competitive Enterprise Institute Table 4 tabulation.

4. Published per president totals, from the APP counts table, cross checked against the CEI Table 4 tabulation. These are reference totals, not rows in the dataset. They are kept in a separate table (`published_reference_totals`) and a separate file (`data/published_reference_totals.csv`) so the two are never confused. The Trump reference total combines both terms: 220 first term plus 292 second term through 2026-10-22, total 512.

## Files taken from the source project (read, not modified)

- `~/workspace/us-executive-orders/data/processed/executive_orders.csv`: 10,879 rows, 21 columns, date range 1791-01-22 to 2026-10-22.
- `~/workspace/us-executive-orders/data/processed/orders_by_president_dataset.csv`: 40 rows, one per president in the dataset, with dataset counts.
- `~/workspace/us-executive-orders/data/processed/orders_by_year.csv`: 187 rows, one per year that has orders, with dataset counts. Both summary tables sum to 10,879, and both match the main table exactly (verified by join, difference 0 on every row).
- The published reference totals were copied from the source project's script `~/workspace/us-executive-orders/scripts/presidents.py` (REFERENCE_TOTALS), values unchanged.

## Data quirks, handled honestly in the loader

- `executive_order_number` in the source CSV is a float formatted string such as '14438.0', or empty for unnumbered orders. The loader stores the raw value as TEXT in `executive_order_number` and adds a cleaned integer column `eo_number_int`, NULL when unnumbered.
- `text_word_count` is float formatted ('168.0') and empty for the 9,330 title only rows. The loader stores it as INTEGER, NULL when empty.
- `year`, `decade`, and `title_word_count` are plain integers in the source, with no empty values.
- Keyword categories come from keyword rules on titles in the source project. They are good for broad shares, not for labeling any single order (50 percent agreement on a hard 30-item hand check in the source project).
- Disposition notes exist only for rows with Federal Register notes. The `disposition_status` values combine flags such as revoked, amended, superseded, and noted. Note based flags only, not a full legal status check.

## What was not done

- No data was re-downloaded, scraped, or purchased for this project.
- No rows were invented to fill the pre-1929 gap.
- No language model was trained or used.
- Nothing was published, posted, or signed into anywhere. Local build only.
