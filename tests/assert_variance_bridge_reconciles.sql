-- Ties the variance bridge to the raw order lines.
-- budget_revenue + volume_effect + price_effect must equal the completed revenue recomputed straight from the
-- orders seed, per month and product. The recomputation does not use stg_orders or fct_monthly_revenue, so a
-- changed filter (refunds counted as revenue), a changed revenue formula (a discount applied) or a join that
-- drops or duplicates rows moves one side and not the other, and the test fails.
-- (volume_effect + price_effect = actual_revenue - budget_revenue holds by construction, so testing that alone
-- could never fail; see README.)
with raw as (
    select
        cast(date_trunc('month', cast(order_date as date)) as date) as month,
        product_id,
        sum(quantity * unit_price)                                   as raw_revenue
    from {{ ref('orders') }}
    where status = 'completed'
    group by 1, 2
)
select
    v.month,
    v.product_id,
    v.budget_revenue + v.volume_effect + v.price_effect as bridge_revenue,
    coalesce(r.raw_revenue, 0)                          as raw_revenue
from {{ ref('fct_revenue_variance') }} v
left join raw r on r.month = v.month and r.product_id = v.product_id
where abs(v.budget_revenue + v.volume_effect + v.price_effect - coalesce(r.raw_revenue, 0)) > 0.01
