-- Planted defect: naming only (no standard prefix).
select * from {{ ref('fct_monthly_revenue') }}
