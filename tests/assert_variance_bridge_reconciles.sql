-- Fails if volume_effect + price_effect does not equal total_variance (1 cent tolerance).
select *
from {{ ref('fct_revenue_variance') }}
where abs(volume_effect + price_effect - total_variance) > 0.01
