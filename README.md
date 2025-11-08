# Chery Solutions — OEE Analytics Demo (Snowflake + dbt + Power BI)

End-to-end OEE pipeline: CSV → Snowflake (RAW/STG/CORE/MART) → dbt Cloud (tests/builds) → Power BI.

## Overview
- **Source:** CSV production events (counts, downtime, costs)
- **Warehouse:** Snowflake `OEE_DEMO` (schemas: `RAW`, `STG`, `CORE`, `MART`)
- **Transform:** dbt models (staging → dimensional core → marts) with tests
- **KPIs:** Availability × Performance × Quality = **OEE**
- **Status:** All models + tests **green**; jobs configured

## Architecture
CSV → **RAW** (`production_events_raw`) → **STG** (`stg_production_events`, `stg_production_events_dedup`)  
→ **CORE** (`dim_*`, `fact_production` incl. `downtime_cause`)  
→ **MART** (`mart_oee_daily`, `mart_downtime_pareto`, `mart_cost_summary`) → Power BI

> OEE = (RunTime/PlannedTime) × ((TotalCount×IdealCT)/(RunTime×60)) × (Good/Total)

## Current State
- Schemas: `OEE_DEMO.RAW | STG | CORE | MART`
- Example counts: `CORE.fact_production ≈ 804`, `MART.mart_oee_daily ≈ 40`
- dbt tests: not_null, unique, relationships → **all passing**
- Schema mapping via `dbt_project.yml` + `macros/generate_schema_name.sql`

## Repo Structure
docs/
- 01_problem_statement.md
- data_dictionary.md

macros/
- generate_schema_name.sql

models/
- sources.yml
- stg/
  - stg_production_events.sql
  - stg_production_events_dedup.sql
  - schema.yml
- core/
  - dim_machine.sql
  - dim_sku.sql
  - dim_shift.sql
  - dim_date.sql
  - fact_production.sql
  - schema.yml
- marts/
  - mart_oee_daily.sql
  - mart_downtime_pareto.sql
  - mart_cost_summary.sql
  - schema.yml

dbt_project.yml

## Load Data (CSV → RAW)
1) Upload CSV(s) to stage `OEE_DEMO.RAW.STAGE` (unique filenames).
2) Load:
```sql
COPY INTO OEE_DEMO.RAW.production_events_raw
FROM (
  SELECT
    $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,
    METADATA$FILENAME::string, CURRENT_TIMESTAMP()
  FROM @OEE_DEMO.RAW.STAGE
)
FILE_FORMAT=(FORMAT_NAME => 'OEE_DEMO.RAW.CSV_FMT')
PATTERN='.*\\.csv'
ON_ERROR='CONTINUE'
FORCE=FALSE; -- skips files already loaded by name
