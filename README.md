# scraped-catalog-dbt

A small dbt project that takes **scraped product data** and turns it into a tested analytics layer: staging, a dimension and a fact, two marts, generic and singular tests, a macro, and a pytest suite that proves bad data is caught.

The data is a one-time scrape of [books.toscrape.com](https://books.toscrape.com), a public **scraping sandbox**, made with my own scraper ([product-catalog-scraper](https://github.com/ZephyraRR/product-catalog-scraper)): 189 books from 8 categories. The warehouse is a local **DuckDB** file, so everything runs on a laptop with no account and no cost.

## What is in it

```
seeds/raw_books.csv              the scraper's output (category, title, price, stock, rating, url, scraped_on)
models/staging/stg_books         typed, trimmed, stable key (md5 of the url)
models/marts/dim_categories      one row per category
models/marts/fct_books           one row per book + price band (macro) + highly-rated flag
models/marts/mart_category_price_stats   avg / median / min / max price, avg rating, stock per category
models/marts/mart_rating_distribution    books and share per star rating
macros/price_band.sql            the price-band rule in one place
tests/generic/positive_value.sql a custom generic test
tests/assert_marts_cover_every_book.sql  a singular test: the marts must add up to the staged rows
pytest_tests/test_pipeline.py    runs dbt end to end and checks the numbers and the failure cases
```

## Run it

```bash
python -m venv .venv && source .venv/bin/activate      # Windows: .venv\Scripts\activate
pip install -r requirements.txt
dbt build --profiles-dir . --project-dir .             # seed + 5 models + 26 tests
dbt docs generate --profiles-dir . --project-dir . && dbt docs serve --profiles-dir . --project-dir .
pytest -q pytest_tests                                  # clean build + 3 bad-data cases
```

Result on my machine (dbt-core 1.12, dbt-duckdb 1.11): `PASS=32 WARN=0 ERROR=0` (1 seed, 4 table models, 1 view, 26 tests); `pytest`: 4 passed.

## What the tests prove

- `unique` / `not_null` on keys, `accepted_values` on rating (1 to 5) and price band, `relationships` from the fact to the dimension.
- A custom generic test (`positive_value`) on prices and counts.
- A singular test: the sum of `books` in both marts equals the number of staged rows, and the rating shares add up to 100%.
- `pytest` copies the project, appends a **negative price**, a **rating of 9** and a **duplicate url** to the seed, and checks that `dbt build` fails each time with the right test named. A test suite that never fails proves nothing.

## A look at the output

| category | books | avg price (GBP) | median | avg rating |
|---|---|---|---|---|
| Fantasy | 48 | 39.59 | 43.58 | 3.08 |
| Romance | 35 | 33.93 | 34.53 | 2.63 |
| Mystery | 32 | 31.72 | 25.38 | 2.94 |
| Poetry | 19 | 35.97 | 38.77 | 3.53 |
| History | 18 | 37.29 | 41.29 | 2.94 |
| Science Fiction | 16 | 33.80 | 35.31 | 2.25 |
| Travel | 11 | 39.79 | 38.95 | 2.73 |
| Humor | 10 | 33.50 | 31.29 | 3.40 |

Price bands (macro): 36 budget (under 20), 73 standard (20 to 40), 80 premium (40 and over).

## Limits (honest)

- It is a **sample of a sandbox site**, not a business dataset: 189 rows, one scrape, no history, no incremental models, no snapshots.
- The warehouse is **DuckDB**. The SQL is plain and portable, but I have **not** run it on BigQuery, Snowflake, Redshift or Postgres, and I make no claim about those engines.
- No orchestration (Airflow, Dagster, dbt Cloud) and no deployment. `ci-parked/dbt.yml` is a GitHub Actions workflow that runs `dbt build` and `pytest`; it is parked because my GitHub account's Actions are locked by a billing issue, so **no CI run is claimed**.
- No `dbt_utils` or other packages: the project depends only on dbt-core and dbt-duckdb.

MIT licence.
