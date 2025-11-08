# 01 — Problem Statement & Solution Outline (OEE + Cost)

## Business Context
Coca‑Cola production teams report **OEE softness** and **rising unit cost** without timely, trusted visibility by **plant / line / machine / shift / SKU**. Data is siloed in CSV exports and manual spreadsheets.

## Objective
Deliver a reusable analytics pipeline (CSV → Snowflake → dbt → Power BI) that produces **trusted OEE and cost KPIs** at hourly/day granularity with automated refresh and data quality controls.

## Critical KPIs
- **OEE** = Availability × Performance × Quality
- **Availability** = (Planned − Unplanned Downtime) / Planned
- **Performance** = (Total Count × Ideal CT) / Run Time
- **Quality** = Good / Total
- **Downtime (min)**, **Scrap (%)**, **Cost per Good Unit** = (Labor + Material + Energy) / Good

## Questions to Answer
- Top downtime causes this week by plant/line/machine?
- Which machines regressed vs last month on OEE?
- Cost per good unit by shift & SKU; which levers move it most?
- Where are data quality hotspots (bad timestamps, counts, costs)?

## Data Scope (Initial)
Single fact file: `production_events_sample.csv` capturing 60‑min windows with: plant, line, machine_code, ts, planned_time_min, unplanned_downtime_min, ideal_ct_sec, total/good/scrap, sku, shift, downtime_cause, labor/material/energy cost. **Includes intentional outliers** to validate tests.

## Target Model
- **RAW** (landing) → **STG** (clean) → **MART** (star schema)
- **Fact**: `fact_production` at machine×SKU×shift×time grain
- **Dims**: date, machine, SKU, shift, downtime_cause

## Quality & Governance
- dbt tests: not_null, accepted_values, relationships, freshness
- Soft-rule checks for outliers (e.g., downtime>planned, good>total) with quarantine table
- Lineage + docs via `dbt docs`
- Role-based access: ingest/transform/bi

## Success Criteria
- dbt `build` green; <60 min pipeline latency
- Power BI dashboard with OEE trend, downtime Pareto, cost/Good trend
- Runbook (SOP) enabling repeatable operation per repo

## Out of Scope (Phase 1)
- Real-time streaming; external ELT tools; predictive maintenance

## Next Step
Create Snowflake objects (roles, warehouses, DB, schemas, stage/file format) and land the CSV into RAW.
