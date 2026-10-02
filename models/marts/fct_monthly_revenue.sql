select
    order_month,
    product_id,
    sum(quantity)                                     as actual_units,
    sum(revenue)                                      as actual_revenue,
    cast(sum(revenue) / nullif(sum(quantity), 0) as decimal(12, 4)) as actual_avg_price
from {{ ref('stg_orders') }}
group by 1, 2
