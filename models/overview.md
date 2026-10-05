{% docs __overview__ %}

# Why did revenue miss budget?

Revenue came in under budget. This demo shows why, in one table.

## The answer, for Pro Plan in January 2026

| | EUR |
|---|---|
| **Total variance vs budget** | **-29.80** |
| Volume effect (sold more units) | +596.00 |
| Price effect (sold at lower prices) | -625.80 |

**Growth hid a discounting problem.** Sales volume beat the plan, but discounting ate the gain.

## What the model does

It splits the budget gap into a volume part and a price part, for every product and every month. A dbt test fails the build if volume + price stop adding up to the total.

## Start here

Open the [fct_revenue_variance model](#!/model/model.revenue_variance.fct_revenue_variance).

Fictional data. SQL portable to Snowflake.

Built by Simon Sangla — [simonsangla.com](https://simonsangla.com)

{% enddocs %}
