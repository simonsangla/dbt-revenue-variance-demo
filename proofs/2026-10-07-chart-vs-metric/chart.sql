-- dashboard-style query (what dbt Charts would run: models, not the Semantic Layer)
-- Total recognised revenue, read straight from the mart. Independent of the `revenue` metric YAML.
select round(sum(actual_revenue), 2) as revenue from {{ ref('fct_monthly_revenue') }}
