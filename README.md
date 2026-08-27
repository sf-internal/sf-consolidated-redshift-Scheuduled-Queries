# sf-consolidated Scheduled Queries

## Overview

This repository is the source of truth for Amazon Redshift scheduled-query metadata and the stored procedures executed by those schedules on the `sf-consolidated` cluster.

The files document:

- Scheduled-query configuration and execution frequency.
- SQL statements executed by each schedule.
- Stored-procedure definitions used for aggregation and refresh processing.
- Materialized-view refresh operations.
- VACUUM and ANALYZE maintenance schedules.

The target database for the currently documented workloads is `smartfinancial`.

## Repository Organization

Each scheduled query has its own directory. A directory can contain:

- A metadata file describing the Redshift scheduled-query configuration.
- One or more stored-procedure definitions called by the scheduled query.
- A direct SQL statement when no stored procedure is required.

Example:

```text
QS2-aggregate_visits/
|-- QS2-aggregate_visits_Metadata.sql
|-- recent_aggregate_visits.sql
|-- refresh_pub_aggr_stats.sql
|-- refresh_pub_aggr_state_stats.sql
|-- refresh_graph_aggr_stats.sql
`-- refresh_graph_aggr_state_stats.sql
```

Metadata files are documentation records and are not intended to be executed as a complete SQL script. The executable SQL appears after the `Query statement` or `Query Statement` label.

## Scheduled Workloads

| Scheduled query | Purpose | Frequency | Main object or procedure |
| --- | --- | --- | --- |
| `QS2-aggregate_call_logs` | Aggregate recent call logs | Every 15 minutes, daily | `call_tracking.recent_aggregate_call_logs()` |
| `QS2-aggregate_click_listings` | Refresh click-listing aggregations | Every 30 minutes, daily | `pingpost.recent_aggregate_click_listings()` and downstream refresh procedures |
| `QS2-aggregate_visits` | Refresh Forms visit aggregations | Every 30 minutes, daily | `forms.recent_aggregate_visits()` and downstream refresh procedures |
| `QS2-QS2-aggregate-lead-campaign-sub-sources` | Refresh publisher source-level statistics | Every 30 minutes, daily | `forms.refresh_pub_aggr_source_stats(0)` |
| `QS2-QS2-aggregate-ping-listings` | Refresh Pingpost listing aggregations | Every 30 minutes, daily | `pingpost.recent_aggregate_ping_listings()` and downstream refresh procedures |
| `QS2-QS2-aggregate-query-listings` | Refresh Call Analytics query-listing aggregations | Every 30 minutes, daily | `call_tracking.recent_aggregate_query_listings()` and downstream refresh procedures |
| `QS2-refresh-click-listings` | Refresh the click-listings materialized view | Every 30 minutes, daily | `pingpost.click_listings2` |
| `QS2-vacuum-visits` | Sort and analyze `forms.visits` | At 06:00 | `forms.visits` |
| `QS2-vacuum-click-listings` | Sort and analyze click response listings | At 07:00 | `pingpost.click_ping_response_listings` |
| `QS2-vacuum_aggr_visits` | Sort and analyze aggregated visits | At 08:00 | `forms.aggr_visits` |
| `QS2-All-Brands-table-vacuum-analyze` | Analyze tables whose statistics are stale | At 09:00 | `public.analyze_stale_tables(10, 500)` |
| `QS2-aggr_click_listings-Vaccum-and-analyze` | Sort and analyze aggregated click listings | At 12:00 on Saturday | `pingpost.aggr_click_listings` |

The metadata currently records clock times but does not identify the scheduler timezone. Confirm the configured timezone in the AWS Redshift scheduled-query console before changing or recreating a schedule.

## Aggregation Processing

### Forms Visits

`QS2-aggregate_visits` executes the following procedures in order:

1. `forms.recent_aggregate_visits()`
2. `forms.refresh_pub_aggr_stats(0)`
3. `forms.refresh_pub_aggr_state_stats(0)`
4. `forms.refresh_graph_aggr_stats(0)`
5. `forms.refresh_graph_aggr_state_stats(0)`

The base procedure refreshes `forms.aggr_visits` using recently updated source records. The four downstream procedures refresh publisher and graph aggregates at overall and state levels.

After the procedures complete, the scheduled query removes recent aggregate records whose `aid` is not present in `affiliate_portal.users`, including applicable records with a null `aid`.

### Click Listings

`QS2-aggregate_click_listings` executes:

1. `pingpost.recent_aggregate_click_listings()`
2. `pingpost.refresh_aggr_default_click_listings(0)`
3. `pingpost.refresh_aggr_common_click_listings(0)`
4. `pingpost.refresh_aggr_hourly_click_listings(0)`

### Ping Listings

`QS2-QS2-aggregate-ping-listings` executes:

1. `pingpost.recent_aggregate_ping_listings()`
2. `pingpost.refresh_aggr_default_ping_listings(0)`
3. `pingpost.refresh_aggr_common_ping_listings(0)`
4. `pingpost.refresh_aggr_hourly_ping_listings(0)`

### Query Listings / Call Analytics

`QS2-QS2-aggregate-query-listings` executes:

1. `call_tracking.recent_aggregate_query_listings()`
2. `call_tracking.refresh_aggr_default_query_listings(0)`
3. `call_tracking.refresh_aggr_common_query_listings(0)`
4. `call_tracking.refresh_aggr_hourly_query_listings(0)`

For refresh procedures that accept `p_days_ago`, a value of `0` refreshes the current processing window. Review the procedure-specific date and timezone logic before passing a different value.

## Metadata Standard

Every scheduled-query directory should contain a metadata file with the following fields:

```text
Cluster or workgroup:
Database name:
Query description:
SNS topic:
State:
IAM role:
Authentication:
Frequency:

Query statement:
```

Use the scheduled-query name in both the directory and metadata filename:

```text
<scheduled-query-name>/<scheduled-query-name>_metadata.sql
```

Maintain consistent capitalization for `_metadata.sql` in new files. Existing filenames can remain unchanged to preserve their history.

## Adding or Updating a Scheduled Query

1. Create or update the directory for the scheduled query.
2. Add or update its metadata file.
3. Store every referenced stored procedure in a separate `.sql` file.
4. Preserve the procedure execution order shown in the scheduled query.
5. Document dependencies on source tables, target tables, views and other procedures.
6. Validate the SQL in a non-production environment when available.
7. Submit the change through a pull request and associate it with the applicable Jira ticket.
8. Deploy stored procedures before creating or enabling the schedule that calls them.
9. Validate the initial execution and record the results in the Jira ticket.

## Deployment and Validation

Before deployment:

- Confirm the cluster, database and schema.
- Capture the current procedure definition for rollback.
- Confirm that all referenced objects and permissions exist.
- Review the processing window, timezone conversion and expected row volume.
- Check for overlapping schedules or dependencies.
- Review DELETE, UPDATE, VACUUM and ANALYZE operations carefully.

After deployment:

- Confirm that each procedure completed successfully.
- Review scheduled-query history, runtime and errors.
- Validate source and target row counts.
- Compare minimum and maximum business dates.
- Check for unexpected duplicates or missing records.
- Confirm that the latest reporting and application data is available.
- Monitor Redshift workload, queue time and execution duration.

## Rollback

For each production change, retain the previous SQL definition in Git history and document the rollback steps in the associated Jira ticket.

A rollback may require:

- Disabling the affected scheduled query.
- Restoring the previous stored-procedure definition.
- Reverting the scheduled-query statement or frequency.
- Refreshing affected aggregate tables after restoration.
- Revalidating application and reporting results.

## Security and Change Control

- Do not commit passwords, access keys, temporary credentials, connection strings or tokens.
- IAM role names and non-secret configuration metadata may be documented.
- Repository access does not authorize production execution.
- Production changes require peer review and the applicable deployment approval.
- Coordinate changes that affect application results with the application or reporting team.

## Ownership

The DBA team maintains this repository in partnership with the application and data teams. Application owners are responsible for validating business results when a scheduled-query or stored-procedure change affects application behavior, reporting, or downstream datasets.
