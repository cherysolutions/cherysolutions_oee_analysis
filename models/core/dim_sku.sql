{{ config(materialized='table', alias='dim_sku') }}
select
  dense_rank() over (order by sku_code) as sku_key,
  sku_code
from {{ ref('stg_production_events') }}
group by sku_code
