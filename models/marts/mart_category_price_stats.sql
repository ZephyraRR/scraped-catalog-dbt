-- Price and rating summary per category: what a buyer or a pricing analyst would ask first.
select
    category,
    count(*)                                          as books,
    round(avg(price_gbp), 2)                          as avg_price_gbp,
    round(median(price_gbp), 2)                       as median_price_gbp,
    min(price_gbp)                                    as min_price_gbp,
    max(price_gbp)                                    as max_price_gbp,
    round(avg(rating), 2)                             as avg_rating,
    sum(case when is_highly_rated then 1 else 0 end)  as highly_rated_books,
    sum(case when in_stock then 1 else 0 end)         as in_stock_books
from {{ ref('fct_books') }}
group by category
