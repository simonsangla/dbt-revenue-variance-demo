-- Planted defect: documented but untested, mid-DAG.
select o.*, p.category
from {{ ref('stg_orders') }} o
join {{ ref('stg_products') }} p using (product_id)
