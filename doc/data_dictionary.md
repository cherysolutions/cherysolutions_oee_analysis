# Data Dictionary: production_events_sample.csv

| Column | Type | Unit | Nullable | Example | Allowed Values (sampled) | Validation Rules | Description |
|---|---|---|---|---|---|---|---|
| plant | STRING |  | No | ATL02 | ATL01, ATL02 |  | Plant identifier (e.g., Atlanta site code). |
| line | STRING |  | No | L3 | L1, L2, L3 |  | Production line identifier within the plant. |
| machine_code | STRING |  | No | CAPR02 | CAPR02, CASE04, FILL01, LBLR03 |  | Machine code on the line (e.g., filler, capper). |
| ts | TIMESTAMP_NTZ | YYYY-MM-DD HH:MM:SS | Yes | 2025-10-06 09:00:00 |  | non-null; valid timestamp format | Event window start timestamp (local). |
| planned_time_min | NUMBER | minutes | No | 60 |  | >= 0 | Planned production time in the window. |
| unplanned_downtime_min | NUMBER | minutes | No | 9 |  | >= 0; unplanned_downtime_min <= planned_time_min (soft rule) | Unplanned downtime minutes in the window. |
| ideal_ct_sec | NUMBER(6,3) | seconds/unit | No | 0.274 |  |  | Ideal cycle time (sec per unit). |
| total_count | NUMBER | units | No | 9540 |  | >= 0 | Total units produced in the window. |
| good_count | NUMBER | units | No | 9160 |  | >= 0; good_count <= total_count (soft rule) | Good units produced. |
| scrap_count | NUMBER | units | No | 380 |  | >= 0 | Scrap units produced. |
| sku | STRING |  | No | COKE_12OZ | COKE_12OZ, COKE_16OZ, DIET_12OZ, SPRITE_12OZ |  | SKU code (package/flavor). |
| shift | STRING |  | No | A | A, B, C |  | Shift code. |
| downtime_cause | STRING |  | Yes | PM | Blocked, Breakdown, Changeover, None, PM, Starved |  | Primary downtime cause category. |
| labor_cost | NUMBER(12,2) | USD | No | 76.8 |  |  | Labor cost allocated to the window. |
| material_cost | NUMBER(12,2) | USD | No | 182.23 |  |  | Material cost allocated to the window. |
| energy_cost | NUMBER(12,2) | USD | No | 13.15 |  |  | Energy cost allocated to the window. |
