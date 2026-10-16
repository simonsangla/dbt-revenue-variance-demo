{{ config(materialized='semantic_view', enabled=(target.type == 'snowflake')) }}

tables (
    revenue as {{ ref('fct_monthly_revenue') }}
        primary key (order_month, product_id)
        comment = 'Actual revenue and units by month and product'
)
dimensions (
    revenue.order_month as order_month
        with synonyms = ('month', 'period'),
    revenue.product_id as product_id
)
metrics (
    revenue.total_revenue as sum(actual_revenue)
        with synonyms = ('revenue', 'sales', 'turnover'),
    revenue.total_units as sum(actual_units)
        with synonyms = ('units', 'volume', 'quantity sold')
)
comment = 'Board Figure Lock demo: revenue semantic view'
