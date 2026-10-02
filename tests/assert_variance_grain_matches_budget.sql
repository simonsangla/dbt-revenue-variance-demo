-- Every budget row must appear exactly once in the variance mart.
select (select count(*) from {{ ref('stg_budget') }}) as budget_rows,
       (select count(*) from {{ ref('fct_revenue_variance') }}) as variance_rows
where budget_rows <> variance_rows
