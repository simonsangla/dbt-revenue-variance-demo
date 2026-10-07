-- Completeness: every budgeted month must have completed order lines. A month that never loaded otherwise
-- reads as a 100% miss in the bridge while every other test passes (both sides of the known-answer tests are 0).
select b.budget_month
from (select distinct budget_month from {{ ref('stg_budget') }}) b
left join (select distinct order_month from {{ ref('stg_orders') }}) o on o.order_month = b.budget_month
where o.order_month is null
