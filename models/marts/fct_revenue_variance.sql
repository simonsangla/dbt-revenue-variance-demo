-- Budget vs actual revenue, decomposed into volume and price effects.
--   volume_effect = (actual_units - budget_units) * budget_price
--   price_effect  = (actual_avg_price - budget_price) * actual_units, avg price unrounded
--                   (actual_revenue / actual_units), computed independently of total_variance
--   volume_effect + price_effect = actual_revenue - budget_revenue holds by construction;
--   the tests tie budget_revenue + volume_effect + price_effect to the raw orders seed (tests/)
with b as (select * from {{ ref('stg_budget') }}),
     a as (select * from {{ ref('fct_monthly_revenue') }}),
     p as (select * from {{ ref('stg_products') }})
select
    b.budget_month                                   as month,
    b.product_id,
    p.product_name,
    p.category,
    b.budget_units,
    coalesce(a.actual_units, 0)                      as actual_units,
    b.budget_price,
    coalesce(a.actual_avg_price, b.budget_price)     as actual_avg_price,
    b.budget_revenue,
    coalesce(a.actual_revenue, 0)                    as actual_revenue,
    coalesce(a.actual_revenue, 0) - b.budget_revenue as total_variance,
    (coalesce(a.actual_units, 0) - b.budget_units) * b.budget_price as volume_effect,
    cast(coalesce((a.actual_revenue / nullif(a.actual_units, 0) - b.budget_price) * a.actual_units, 0) as decimal(14, 4)) as price_effect
from b
left join a on a.order_month = b.budget_month and a.product_id = b.product_id
left join p on p.product_id = b.product_id
