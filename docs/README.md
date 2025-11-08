Chery Solutions — OEE Analytics Demo (Snowflake + dbt + Power BI)

Production-style, end-to-end pipeline for Overall Equipment Effectiveness (OEE) using CSV inputs → Snowflake (RAW/STG/CORE/MART) → dbt Cloud (tests + builds) → Power BI.

TL;DR

Source: CSV files with production events (counts, downtime, costs)

Warehouse: Snowflake OEE_DEMO (schemas: RAW, STG, CORE, MART)

Transform: dbt models (staging views, dimensional core tables, marts)

KPIs: Availability × Performance × Quality = OEE

Status: All models + tests green. Nightly + weekly jobs ready.

Architecture

CSV → RAW → STG → CORE → MART → Power BI

RAW: production_events_raw (append-only loads via COPY INTO).

STG: stg_production_events (typed/cleaned) + stg_production_events_dedup (row-level dedupe).

CORE: dim_machine, dim_sku, dim_shift, dim_date, fact_production (with OEE components).

MART: mart_oee_daily, mart_downtime_pareto, mart_cost_summary.

OEE = (RunTime/PlannedTime) × ((TotalCount×IdealCT)/(RunTime×60)) × (Good/Total)

Current State (✅)

Snowflake objects live in:

OEE_DEMO.RAW | STG | CORE | MART

Row counts (example): CORE.fact_production ≈ 804, MART.mart_oee_daily ≈ 40

dbt tests: not_null, unique, relationships → all passing

Schema mapping via dbt_project.yml + macro:

stg → STG, core → CORE, marts → MART

macros/generate_schema_name.sql avoids STG_* prefix issues

Repo Layout
docs/
  01_problem_statement.md
  data_dictionary.md
macros/
  generate_schema_name.sql
models/
  sources.yml
  stg/
    stg_production_events.sql
    stg_production_events_dedup.sql
    schema.yml
  core/
    dim_*.sql
    fact_production.sql
    schema.yml
  marts/
    mart_oee_daily.sql
    mart_downtime_pareto.sql
    mart_cost_summary.sql
    schema.yml
dbt_project.yml

One-Time Setup (Snowflake)
-- run as ACCOUNTADMIN
CREATE WAREHOUSE IF NOT EXISTS WH_OEE_DEMO WAREHOUSE_SIZE=SMALL AUTO_SUSPEND=60 AUTO_RESUME=TRUE;
CREATE DATABASE  IF NOT EXISTS OEE_DEMO;
CREATE SCHEMA    IF NOT EXISTS OEE_DEMO.RAW, OEE_DEMO.STG, OEE_DEMO.CORE, OEE_DEMO.MART;

-- role for dbt builds
CREATE ROLE IF NOT EXISTS ROLE_TRANSFORM;
GRANT USAGE ON DATABASE OEE_DEMO TO ROLE ROLE_TRANSFORM;
GRANT USAGE ON SCHEMA OEE_DEMO.STG, OEE_DEMO.CORE, OEE_DEMO.MART TO ROLE ROLE_TRANSFORM;
GRANT CREATE TABLE, CREATE VIEW ON SCHEMA OEE_DEMO.CORE, OEE_DEMO.MART TO ROLE ROLE_TRANSFORM;

-- service user
CREATE USER IF NOT EXISTS DBT_SVC PASSWORD='<set>' DEFAULT_ROLE=ROLE_TRANSFORM DEFAULT_WAREHOUSE=WH_OEE_DEMO DEFAULT_NAMESPACE=OEE_DEMO.STG;
GRANT ROLE ROLE_TRANSFORM TO USER DBT_SVC;

dbt Config (high level)

dbt_project.yml maps folders → schemas and pins session context (on-run-start).
Use dbt Cloud Deployment env with ROLE_TRANSFORM + WH_OEE_DEMO + OEE_DEMO.

Jobs

Nightly Build (2:00 AM ET):

dbt build --select state:modified+ --defer


Weekly Marts Full Refresh (Sun 3:00 AM ET):

dbt run --select marts.* --full-refresh
dbt test --select marts.*


Freshness (1:50 AM ET):

dbt source freshness --select source:raw.production_events_raw

Loading Data (CSV → RAW)

Upload CSV(s) to stage: OEE_DEMO.RAW.STAGE (unique filenames).

Load:

COPY INTO OEE_DEMO.RAW.production_events_raw
FROM (
  SELECT
    $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,
    METADATA$FILENAME::string, CURRENT_TIMESTAMP()
  FROM @OEE_DEMO.RAW.STAGE
)
FILE_FORMAT=(FORMAT_NAME => 'OEE_DEMO.RAW.CSV_FMT')
PATTERN='.*\.csv'
ON_ERROR='CONTINUE'
FORCE=FALSE;  -- skips already-loaded filenames

Dedupe Strategy

Prevention: stg_production_events_dedup uses ROW_NUMBER() on natural key
nk = md5(machine_code || '|' || sku || '|' || to_varchar(ts)) and keeps latest row.

Detection: dbt unique test on the same key.

Power BI (next)

Grant read role:

CREATE ROLE IF NOT EXISTS ROLE_BI;
GRANT USAGE ON DATABASE OEE_DEMO, SCHEMA OEE_DEMO.MART TO ROLE ROLE_BI;
GRANT SELECT ON ALL TABLES IN SCHEMA OEE_DEMO.MART TO ROLE ROLE_BI;
GRANT SELECT ON FUTURE TABLES IN SCHEMA OEE_DEMO.MART TO ROLE ROLE_BI;


Connect Power BI → Snowflake (Account: ewc07339.us-east-1) → use MART tables.

Build visuals from mart_oee_daily, Pareto, and Cost Summary.

Troubleshooting (fast)

Insufficient privileges / cannot drop/replace → grant CREATE TABLE/VIEW, ensure ownership is ROLE_TRANSFORM, or DROP the old object.

Schema like STG_CORE appears → ensure generate_schema_name.sql exists and folder mapping is correct.

dbt “unexpected ;” → remove trailing semicolons in model files.

Timestamp cast error → use CAST(ts AS DATE) (not TRY_TO_DATE on TIMESTAMP_NTZ).

Roadmap

Add Snowflake TASK or Snowpipe for auto-ingest.

Add anomaly flags (e.g., OEE < threshold, sudden downtime spikes).

Publish dbt docs site, add exposures for Power BI datasets.

Owner: Chery Solutions LLC • Pipeline: cherysolutions_oee_analysis • License: MIT
