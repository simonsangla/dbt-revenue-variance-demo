-- Returns must still be visible in the source: every budgeted month must carry refunded order lines in the
-- orders seed. If the status is lost at load (refunds relabelled completed), revenue silently includes them and
-- the known-answer tests agree, because they read the same mislabelled seed.
select b.budget_month
from (select distinct budget_month from {{ ref('stg_budget') }}) b
left join (
    select distinct cast(date_trunc('month', cast(order_date as date)) as date) as m
    from {{ ref('orders') }} where status = 'refunded'
) r on r.m = b.budget_month
where r.m is null
