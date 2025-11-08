{{ config(materialized='view', alias='stg_production_events') }}

with src as (
  select * from OEE_DEMO.RAW.production_events_raw
)
select
  CAST(ts AS DATE)                              as date_key,         -- ✅ was TRY_TO_DATE(ts)
  UPPER(plant)                                  as plant,
  UPPER(line)                                   as line,
  UPPER(machine_code)                           as machine_code,
  UPPER(sku)                                    as sku_code,
  UPPER(shift)                                  as shift_code,
  planned_time_min::NUMBER                      as planned_time_min,
  GREATEST(unplanned_downtime_min,0)::NUMBER    as unplanned_downtime_min,
  GREATEST(planned_time_min - unplanned_downtime_min, 0) as run_time_min,
  ideal_ct_sec::NUMBER                          as ideal_ct_sec,
  total_count::NUMBER                           as total_count,
  GREATEST(good_count,0)::NUMBER                as good_count,
  GREATEST(scrap_count,0)::NUMBER               as scrap_count,
  downtime_cause,
  labor_cost::NUMBER                            as labor_cost,
  material_cost::NUMBER                         as material_cost,
  energy_cost::NUMBER                           as energy_cost,
  ts, file_name
from src
where
  ts is not null
  and planned_time_min > 0
  and unplanned_downtime_min <= planned_time_min
  and good_count <= total_count
  and scrap_count >= 0
  and ideal_ct_sec > 0
  and machine_code is not null and trim(machine_code) <> ''
