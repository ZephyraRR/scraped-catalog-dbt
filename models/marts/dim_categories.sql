select
    category,
    count(*)                      as books,
    min(scraped_on)               as first_scraped_on,
    max(scraped_on)               as last_scraped_on
from {{ ref('stg_books') }}
group by category
