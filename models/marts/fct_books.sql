select
    book_id,
    category,
    title,
    price_gbp,
    {{ price_band('price_gbp') }}    as price_band,
    rating,
    rating >= 4                      as is_highly_rated,
    in_stock,
    url,
    scraped_on
from {{ ref('stg_books') }}
