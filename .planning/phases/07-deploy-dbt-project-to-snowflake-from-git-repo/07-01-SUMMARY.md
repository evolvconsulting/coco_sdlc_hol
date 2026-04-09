# Summary: 07-01 — Fix profiles.yml for Snowflake-native dbt

## What was done

Replaced the dbt `profiles.yml` with a minimal Snowflake-native format that removes all hardcoded credentials (account, user, password, threads). Snowflake-native dbt handles authentication through the session context when using `EXECUTE DBT PROJECT`, so these fields are unnecessary and pose a security risk in a Git repo.

## Key files modified

| File | Change |
|------|--------|
| `packages/dbt/profiles.yml` | Removed `account`, `user`, `password`, `threads`; kept `type`, `database`, `role`, `schema`, `warehouse` |

## Verification

- [x] profiles.yml does NOT contain `account:`
- [x] profiles.yml does NOT contain `user:`
- [x] profiles.yml does NOT contain `password:`
- [x] profiles.yml does NOT contain `threads:`
- [x] profiles.yml contains `type: snowflake`
- [x] profiles.yml contains `database: COCO_SDLC_HOL`
- [x] profiles.yml contains `role: ATTENDEE_ROLE`
- [x] profiles.yml contains `schema: STAGING`
- [x] profiles.yml contains `warehouse: COMPUTE_WH`
- [x] profiles.yml contains `target: dev`
- [x] Profile name `dev` matches `dbt_project.yml` `profile: 'dev'`
