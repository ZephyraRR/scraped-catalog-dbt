-- One row per scraped book: typed, trimmed, with a stable key.
-- The seed already carries typed columns (dbt_project.yml); the casts here make the contract explicit
-- so a change in the scraper's output fails loudly in this model and not further downstream.
select
    md5(url)                              as book_id,
    trim(category)                        as category,
    trim(title)                           as title,
    cast(price_gbp as decimal(8, 2))      as price_gbp,
    cast(in_stock as boolean)             as in_stock,
    cast(rating as integer)               as rating,
    url,
    cast(scraped_on as date)              as scraped_on
from {{ ref('raw_books') }}
