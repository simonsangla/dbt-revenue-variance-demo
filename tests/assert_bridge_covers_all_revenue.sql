-- Every completed order line must land in a budgeted month and product: the bridge's revenue (budget + effects),
-- summed over all rows, must equal the total completed revenue in the orders seed. Revenue in a month or product
-- with no budget row would otherwise vanish from the bridge without any other test noticing.
select
    (select sum(quantity * unit_price) from {{ ref('orders') }} where status = 'completed') as raw_total,
    (select sum(budget_revenue + volume_effect + price_effect) from {{ ref('fct_revenue_variance') }}) as bridge_total
where abs(raw_total - bridge_total) > 0.01
