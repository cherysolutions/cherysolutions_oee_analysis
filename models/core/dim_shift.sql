{{ config(materialized='table', alias='dim_shift') }}

select
  dense_rank() over (order by shift_code) as shift_key,
  shift_code
from {{ ref('stg_production_events') }}
group by shift_code
