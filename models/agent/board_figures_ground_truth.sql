-- The board's published figures become the agent's ground truth.
{{ config(materialized='view', enabled=(target.type == 'snowflake')) }}

select
    figure_id,
    question,
    object_construct(
        'ground_truth_output',
        to_varchar(published_value) || ' (' || metric || ', '
            || to_varchar(period_start) || ' to ' || to_varchar(period_end) || ')'
    ) as expected
from {{ ref('board_figures') }}
