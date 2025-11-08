{{ config(materialized='table', alias='mart_cost_summary') }}

with f as (select * from {{ ref('fact_production') }})

select
  date_key,
  machine_key,
  sum(good_count)                                  as good_units,
  sum(labor_cost)                                  as labor_cost,
  sum(material_cost)                               as material_cost,
  sum(energy_cost)                                 as energy_cost,
  (sum(labor_cost)+sum(material_cost)+sum(energy_cost)) as total_cost,
  ( (sum(labor_cost)+sum(material_cost)+sum(energy_cost))
    / nullif(sum(good_count),0) )                  as cost_per_good
from f
group by 1,2
