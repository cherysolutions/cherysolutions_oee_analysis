{{ config(materialized='table', alias='dim_date') }}

with bounds as (
  select min(date_key) as start_date, max(date_key) as end_date
  from {{ ref('stg_production_events') }}
),
span as (
  select dateadd(day, seq4(), start_date) as d
  from bounds, table(generator(rowcount => 5000))
  where dateadd(day, seq4(), start_date) <= end_date
)
select
  d                                 as date_key,
  year(d)                           as year,
  month(d)                          as month,
  day(d)                            as day,
  week(d)                           as week,
  quarter(d)                        as quarter,
  to_varchar(d, 'DY')               as day_name,
  (dayofweekiso(d) in (6,7))        as is_weekend
from span
