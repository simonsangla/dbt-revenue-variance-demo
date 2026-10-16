-- Board Figure Lock: every published figure must be reproduced by the warehouse.
-- Warn, never block: a gap goes to the figure's owner, who decides which side is right.
{{ config(severity='warn') }}

with board as (
    select * from {{ ref('board_figures') }}
),

warehouse as (
    select
        b.figure_id,
        case b.metric
            when 'revenue' then sum(r.actual_revenue)
            when 'units' then sum(r.actual_units)
        end as warehouse_value
    from board b
    left join {{ ref('fct_monthly_revenue') }} r
        on r.order_month between b.period_start and b.period_end
    group by b.figure_id, b.metric
)

select
    b.figure_id,
    b.metric,
    b.period_start,
    b.period_end,
    b.published_value,
    w.warehouse_value,
    b.published_value - w.warehouse_value as gap,
    b.owner,
    case
        when w.warehouse_value is null then 'missing_in_warehouse'
        when abs(b.published_value - w.warehouse_value) < 1 then 'rounding'
        else 'definition_or_manual_adjustment'
    end as gap_cause
from board b
left join warehouse w on b.figure_id = w.figure_id
where w.warehouse_value is null
   or abs(b.published_value - w.warehouse_value) >= 0.01
