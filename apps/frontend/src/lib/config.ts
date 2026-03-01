// Central configuration for Snowflake database, schema, and table name references.
// All API routes must import from here — no hardcoded database/schema/table strings
// should exist anywhere in the route files.

// Configurable via environment — may differ per deployment environment
export const SNOWFLAKE_DATABASE = process.env.SNOWFLAKE_DATABASE || 'COCO_SDLC_HOL';
export const SNOWFLAKE_SCHEMA = process.env.SNOWFLAKE_SCHEMA || 'MARTS';

// Fixed table names — same in all environments for this project
export const TABLE_AUTHORIZATIONS = 'AUTHORIZATIONS';
export const TABLE_SETTLEMENTS = 'SETTLEMENTS';
export const TABLE_DEPOSITS = 'DEPOSITS';
export const TABLE_CHARGEBACKS = 'CHARGEBACKS';
export const TABLE_RETRIEVALS = 'RETRIEVALS';
export const TABLE_ADJUSTMENTS = 'ADJUSTMENTS';

// Fully-qualified table references — use these in SQL queries
export const FULL_TABLE_AUTHORIZATIONS = `${SNOWFLAKE_DATABASE}.${SNOWFLAKE_SCHEMA}.${TABLE_AUTHORIZATIONS}`;
export const FULL_TABLE_SETTLEMENTS = `${SNOWFLAKE_DATABASE}.${SNOWFLAKE_SCHEMA}.${TABLE_SETTLEMENTS}`;
export const FULL_TABLE_DEPOSITS = `${SNOWFLAKE_DATABASE}.${SNOWFLAKE_SCHEMA}.${TABLE_DEPOSITS}`;
export const FULL_TABLE_CHARGEBACKS = `${SNOWFLAKE_DATABASE}.${SNOWFLAKE_SCHEMA}.${TABLE_CHARGEBACKS}`;
export const FULL_TABLE_RETRIEVALS = `${SNOWFLAKE_DATABASE}.${SNOWFLAKE_SCHEMA}.${TABLE_RETRIEVALS}`;
export const FULL_TABLE_ADJUSTMENTS = `${SNOWFLAKE_DATABASE}.${SNOWFLAKE_SCHEMA}.${TABLE_ADJUSTMENTS}`;
