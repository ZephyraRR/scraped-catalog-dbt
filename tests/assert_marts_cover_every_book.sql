-- Singular test: the per-category mart must account for every scraped book, and the rating
-- distribution must add up to 100 percent (within rounding). Returns a row (= fails) when they do not.
with totals as (
    select
        (select count(*) from {{ ref('stg_books') }})                          as staged,
        (select sum(books) from {{ ref('mart_category_price_stats') }})         as in_category_mart,
        (select sum(books) from {{ ref('mart_rating_distribution') }})          as in_rating_mart,
        (select sum(share_pct) from {{ ref('mart_rating_distribution') }})      as share_total
)
select *
from totals
where staged <> in_category_mart
   or staged <> in_rating_mart
   or abs(share_total - 100) > 0.5
