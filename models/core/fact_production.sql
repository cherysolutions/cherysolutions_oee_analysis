{{ config(materialized='table', alias='fact_production') }}

with
s   as (select * from {{ ref('stg_production_events') }}),
dm  as (select machine_key, machine_code from {{ ref('dim_machine') }}),
ds  as (select sku_key,     sku_code     from {{ ref('dim_sku') }}),
dsh as (select shift_key,   shift_code   from {{ ref('dim_shift') }}),
dd  as (select date_key                     from {{ ref('dim_date') }})

select
  -- keys
  s.date_key,
  dm.machine_key,
  ds.sku_key,
  dsh.shift_key,

  -- measures
  s.planned_time_min,
  s.unplanned_downtime_min,
  s.run_time_min,
  s.ideal_ct_sec,
  s.total_count,
  s.good_count,
  s.scrap_count,
  s.labor_cost,
  s.material_cost,
  s.energy_cost,

  -- attributes used by marts
  s.downtime_cause,

  -- KPI components
  (s.run_time_min / nullif(s.planned_time_min, 0))                            as availability,
  ((s.total_count * s.ideal_ct_sec) / nullif(s.run_time_min * 60, 0))         as performance,
  (s.good_count / nullif(s.total_count, 0))                                   as quality,

  -- OEE
  (
    (s.run_time_min / nullif(s.planned_time_min, 0)) *
    ((s.total_count * s.ideal_ct_sec) / nullif(s.run_time_min * 60, 0)) *
    (s.good_count / nullif(s.total_count, 0))
  ) as oee
from s
inner join dm  on dm.machine_code = s.machine_code
inner join ds  on ds.sku_code     = s.sku_code
inner join dsh on dsh.shift_code  = s.shift_code
inner join dd  on dd.date_key     = s.date_key
