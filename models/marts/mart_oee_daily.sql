{{ config(materialized='table', alias='mart_oee_daily') }}

with f as (select * from {{ ref('fact_production') }}),
dd as (select * from {{ ref('dim_date') }}),
dm as (select * from {{ ref('dim_machine') }})

select
  f.date_key,
  dm.machine_key,
  -- daily rollups
  sum(f.planned_time_min)           as planned_time_min,
  sum(f.unplanned_downtime_min)     as unplanned_downtime_min,
  sum(f.run_time_min)               as run_time_min,
  sum(f.total_count)                as total_count,
  sum(f.good_count)                 as good_count,
  sum(f.scrap_count)                as scrap_count,
  sum(f.labor_cost)                 as labor_cost,
  sum(f.material_cost)              as material_cost,
  sum(f.energy_cost)                as energy_cost,
  -- recompute KPIs at the aggregate grain
  (sum(f.run_time_min) / nullif(sum(f.planned_time_min),0))                                       as availability,
  ((sum(f.total_count) * avg(f.ideal_ct_sec)) / nullif(sum(f.run_time_min) * 60,0))               as performance,
  (sum(f.good_count) / nullif(sum(f.total_count),0))                                              as quality,
  (
    (sum(f.run_time_min) / nullif(sum(f.planned_time_min),0)) *
    ((sum(f.total_count) * avg(f.ideal_ct_sec)) / nullif(sum(f.run_time_min) * 60,0)) *
    (sum(f.good_count) / nullif(sum(f.total_count),0))
  ) as oee
from f
join dd on dd.date_key = f.date_key
join dm on dm.machine_key = f.machine_key
group by 1,2
