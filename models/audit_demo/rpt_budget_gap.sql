-- Planted defect: tested but undocumented.
select month, sum(total_variance) as budget_gap
from {{ ref('fct_revenue_variance') }}
group by month
