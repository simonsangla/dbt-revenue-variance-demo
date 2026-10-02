select
    cast(month as date)                    as budget_month,
    product_id,
    cast(budget_units as integer)          as budget_units,
    cast(budget_price as decimal(12, 2))   as budget_price,
    cast(budget_units * budget_price as decimal(14, 2)) as budget_revenue
from {{ ref('budget') }}
