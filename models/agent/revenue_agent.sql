{{
  config(
    materialized = 'cortex_agent',
    enabled      = (target.type == 'snowflake'),
    comment      = 'Board Figure Lock demo: revenue analyst agent'
  )
}}
instructions:
  response: "Answer with the figure first, then the period and the metric used."
tools:
  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "RevenueAnalyst"
      description: "Revenue and units by month and product."
tool_resources:
  RevenueAnalyst:
    semantic_view: "{{ ref('revenue_semantic_view') }}"
    execution_environment:
      type: "warehouse"
      warehouse: "{{ target.warehouse }}"
