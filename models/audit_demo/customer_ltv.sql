-- Planted defect: no prefix, no tests, no description, reads the raw source directly.
select customer_id, sum(quantity * unit_price) as lifetime_revenue
from {{ source('raw', 'orders') }}
where status = 'completed'
group by customer_id
