# ClickHouse Take-Home Exercise — Process Document

## 1. Research Approach

- Started with zero ClickHouse experience; 
- Read official ClickHouse docs: Docker install guide, Access Control & RBAC, Keeper configuration
- Referenced Altinity Knowledge Base for practical Keeper examples
- Referenced GitHub issues for row policy behavior (#33775, #11400, #21670)
- Built mental model before touching any config:
  - `config.xml` / `config.d/` for server-level settings
  - SQL DDL for user/access management
  - Keeper for cross-node coordination

## 2. Environment Setup

| Decision | Reasoning |
|----------|-----------|
| Used Docker (not local install) | Part 2 requires Docker; Maria's issues are Docker-specific |
| Pinned version 25.8.1 | Match customer's exact environment. Caught mistake of accidentally pulling latest |
| Mounted `server-config/` to `config.d/` | Config overrides without editing container internals |
| Started server standalone first, added Keeper later | Avoid debugging two unknowns at once |

## 3. Req 1 — Limit Databases to 3

**Troubleshooting steps:**

- **First attempt:** Used setting name `max_number_of_databases` — it was silently ignored, no error
- **Discovery:** Queried `system.server_settings WHERE name LIKE '%database%'` to find correct setting name
- **Finding:** Correct setting is `max_database_num_to_throw`

**Testing:**

- Fresh install has 4 databases: `system`, `INFORMATION_SCHEMA`, `information_schema`, `default`
- Set limit to 3, created test databases
- Could create `test_db`, `test_db2`, but `test_db3` was blocked

**Conclusion:**

- `default` counts toward the limit; system databases do not
- Limit of 3 = `default` + 2 user databases
- **Implication for Maria:** If she needs 3 user databases, set the value to 4

## 4. Req 2a — Admin User

**Decision 1:**
1. SQL DDL over XML for users. ClickHouse recommended approach. XML is legacy.
2. Immediate change. Using SQL DDL to manage users from inside ClickHouse itself. Changes take effect immediately, no restart needed. With XML, it's all external file manipulation. Restart is needed to effect xml.
3. Auditable. I can verify everything with SHOW CREATE USER, SHOW GRANTS, SHOW ROW POLICIES — all inspectable from inside the database.
4. Row policies (CREATE ROW POLICY) only exist in the SQL DDL system


**Decision 2:**
I chose GRANT CURRENT GRANTS because GRANT ALL failed — the default user doesn't hold every possible privilege. Rather than manually listing each grant line by line, which is error-prone and version-dependent, CURRENT GRANTS is a mirror, and gives an exact copy of whatever the executing user holds.

**Steps:**

1. Checked `SHOW GRANTS FOR default` first to understand what permissions to replicate
2. Created admin: `CREATE USER admin IDENTIFIED BY 'admin123'`

**Finding:**

- `GRANT ALL ON *.* TO admin WITH GRANT OPTION` failed with error 497
- `default` user is missing `SHOW NAMED COLLECTIONS SECRETS` privilege, so it can't grant `ALL`

**Fix:**

- Used `GRANT CURRENT GRANTS ON *.* TO admin WITH GRANT OPTION` — grants exactly what `default` has
- Verified with `SHOW GRANTS FOR admin`

## 5. Req 2b — Developer User with Limits

**Permissions:**

- Granted `SELECT ON *.*` to developer — Maria did not specify what developer can do beyond the limits, so we assumed read-only access. This is a follow-up question for Maria.

**Settings profile:**

- `max_execution_time = 0.5 READONLY` (500ms — note: setting is in seconds, not milliseconds)
- `max_memory_usage = 104857600 READONLY` (100MB in bytes)
- `READONLY` is critical — without it, user can override limits with `SET` command

**Bug found:**

- Profile was not attached to user after creation
- `SHOW CREATE USER developer` showed no profile reference
- **Root cause:** CREATE USER command likely split at line break when pasting; profile clause was lost
- **Fix:** `ALTER USER developer SETTINGS PROFILE developer_profile`
- **Lesson:** Always verify with `SHOW CREATE USER` immediately after creation

**Demonstration:**

- Time limit: triggered at 501ms with error `TIMEOUT_EXCEEDED`
- Memory limit: triggered with error `MEMORY_LIMIT_EXCEEDED`
- Both errors saved as evidence

## 6. Req 2b — Row Policy on system.tables

**Steps:**

1. Verified column name with `DESCRIBE system.tables` — confirmed column is `database`
2. Created policy: `CREATE ROW POLICY dev_filter ON system.tables FOR SELECT USING database != 'system' TO developer`

**Critical discovery:**

- Row policies in ClickHouse affect ALL users when any policy exists on a table — not just the named user
- Source: GitHub issues #33775, #11400 confirmed this is by design
- Version 25.8.1 has `users_without_row_policies_can_read_rows = true` by default, so admin/default were not affected in testing

**Defensive measure:**

- Created `allow_all` policy: `USING 1 TO ALL EXCEPT developer` as safeguard against future config changes

**Verification:**

- `developer` sees 3 databases (no `system`)
- `admin` and `default` see all 4 including `system`

## 7. Req 3 — Keeper Config Bug

**Methodology: reproduce first, then diagnose.**

1. Created Docker network `clickhouse-net` for inter-container communication
2. Connected existing ClickHouse server container to the new network (`docker network connect clickhouse-net clickhouse-server`) — existing containers don't auto-join new networks
3. Deployed Maria's exact config unchanged

**Test 1 — from inside Keeper container:**

```
echo ruok | nc localhost 9181 → imok (Keeper is healthy)
```

**Test 2 — from ClickHouse server container:**

```
echo ruok | nc clickhouse-keeper 9181 → connection refused
```

**Diagnosis:**

- Hostname resolved (got IP 172.19.0.3) but connection was refused
- Keeper was listening on `127.0.0.1` (localhost) only, not on the Docker network interface

**Root cause:**

- `<listen_host>0.0.0.0</listen_host>` was placed inside `<keeper_server>` block
- Keeper only reads `listen_host` at the `<clickhouse>` root level
- Because it was in the wrong place, Keeper ignored it and defaulted to localhost

**Fix:**

- Moved `<listen_host>0.0.0.0</listen_host>` to the `<clickhouse>` root level
- Restarted Keeper

**Verification:**

- `ruok` from server container returned `imok`
- Created server-side config `keeper-connection.xml` pointing to Keeper on port 9181
- `SELECT * FROM system.zookeeper WHERE path = '/'` returned Keeper entries — connection confirmed

## 8. Additional Findings and Recommendations for Maria

- Mount `/var/lib/clickhouse` in production to persistent storage so data and access configs survive container replacement
- Single Keeper node works for dev but not production — recommend 3 nodes
- Keeper data should be on dedicated storage, not shared with ClickHouse data directories
- Monitor Keeper latency — it's on the critical path for every replicated write
- `default` user has full access with no password — recommend locking down after admin is verified
- **Decision:** Followed ClickHouse official docs recommended approach: create users via `default` first, then lock down `default`. Did not execute the lockdown during exercise to avoid losing access during live interview, but documented it as a production recommendation for Maria
- Maria may have forgotten the server-side Keeper config (`<zookeeper>` node config telling the server where Keeper is)

## 9. Follow-up Questions for Maria

- How many user-created databases do you need? (affects limit setting value)
- What permissions should the `developer` user have beyond SELECT? (we assumed SELECT only)
- Are you planning replicated tables or distributed DDL? (determines if Keeper is needed at all)
- How many ClickHouse server nodes will you run in production?
- What are your availability requirements — is downtime acceptable during maintenance?
- What Docker networking setup are you using? (docker-compose, manual network, host networking?)

## 10. Verification Commands Reference

| Requirement | Verification Command |
|-------------|---------------------|
| Req 1: DB limit | `SELECT name, value FROM system.server_settings WHERE name = 'max_database_num_to_throw'` |
| Req 1: Config file | `cat /etc/clickhouse-server/config.d/max-databases.xml` |
| Req 2a: Admin | `SHOW CREATE USER admin` + `SHOW GRANTS FOR admin` |
| Req 2b: Developer profile | `SHOW CREATE USER developer` + `SHOW CREATE SETTINGS PROFILE developer_profile` |
| Req 2b: Developer limits | Connect as developer → `SELECT name, value FROM system.settings WHERE name IN ('max_execution_time', 'max_memory_usage')` |
| Req 2b: Row policy (dev) | `SHOW CREATE ROW POLICY dev_filter ON system.tables` |
| Req 2b: Row policy (allow) | `SHOW CREATE ROW POLICY allow_all ON system.tables` |
| Req 3: Keeper health | `echo ruok \| nc clickhouse-keeper 9181` |
| Req 3: Server→Keeper | `SELECT * FROM system.zookeeper WHERE path = '/'` |
