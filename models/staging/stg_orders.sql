-- One row per completed order line. Refunds are excluded from recognised revenue.
select
    order_id,
    cast(order_date as date)                        as order_date,
    cast(date_trunc('month', cast(order_date as date)) as date) as order_month,
    customer_id,
    product_id,
    cast(quantity as integer)                       as quantity,
    cast(unit_price as decimal(12, 2))              as unit_price,
    cast(quantity * unit_price as decimal(14, 2))   as revenue
from {{ ref('orders') }}
where status = 'completed'
