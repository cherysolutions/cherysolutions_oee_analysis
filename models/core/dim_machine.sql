{{ config(materialized='table', alias='dim_machine') }}
select
  dense_rank() over (order by machine_code) as machine_key,
  machine_code
from {{ ref('stg_production_events') }}
group by machine_code
