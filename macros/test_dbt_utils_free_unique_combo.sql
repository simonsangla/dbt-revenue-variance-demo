{% test dbt_utils_free_unique_combo(model, columns) %}
-- Grain test without a package dependency: the expression must be unique.
select {{ columns }} as k, count(*) as n
from {{ model }}
group by 1
having count(*) > 1
{% endtest %}
