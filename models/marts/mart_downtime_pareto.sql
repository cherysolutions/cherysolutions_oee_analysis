{{ config(materialized='table', alias='mart_downtime_pareto') }}
with f as (select * from {{ ref('fact_production') }})
select
  date_key,
  machine_key,
  coalesce(downtime_cause,'UNSPECIFIED') as downtime_cause,
  sum(unplanned_downtime_min)            as downtime_min,
  sum(scrap_count)                       as scrap_units,
  sum(total_count)                       as total_units,
  rank() over (
    partition by date_key, machine_key
    order by sum(unplanned_downtime_min) desc
  ) as cause_rank
from f
group by 1,2,3
