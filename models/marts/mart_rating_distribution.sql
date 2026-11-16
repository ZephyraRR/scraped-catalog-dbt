select
    rating,
    count(*)                                              as books,
    round(100.0 * count(*) / sum(count(*)) over (), 1)    as share_pct
from {{ ref('fct_books') }}
group by rating
