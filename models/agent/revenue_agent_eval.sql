{{
  config(
    materialized = 'cortex_agent_eval',
    enabled      = (target.type == 'snowflake'),
    stage        = '@' ~ target.database ~ '.' ~ target.schema ~ '.board_lock_eval_stage'
  )
}}
dataset:
  table_name: "{{ ref('board_figures_ground_truth') }}"
  dataset_name: "board_figures_golden"
  column_mapping:
    query_text: question
    ground_truth: expected
evaluation:
  agent_params:
    agent_name: "{{ ref('revenue_agent') }}"
    agent_type: "CORTEX AGENT"
    agent_version: "{{ var('agent_version', 'LIVE') }}"
  run_params:
    label: "board-figure-lock"
    description: "Does the agent reproduce the published board figures?"
  source_metadata:
    type: "dataset"
    dataset_name: "board_figures_golden"
metrics:
  - "answer_correctness"
