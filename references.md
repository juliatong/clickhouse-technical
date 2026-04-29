# Links
1. https://clickhouse.com/docs/operations/access-rights
2. https://clickhouse.com/docs/sql-reference/statements/create/row-policy
3. ClickHouse Keeper deep dive (Altinity KB) — [kb.altinity.com/.../clickhouse-keeper](https://kb.altinity.com/altinity-kb-setup-and-maintenance/altinity-kb-zookeeper/clickhouse-keeper/)
Best practical reference for Keeper config. Shows the XML structure, explains the Raft port vs client port distinction, and has working examples. This is your primary source for Req 3.

4. Altinity RBAC practical examples — [kb.altinity.com/.../rba](https://kb.altinity.com/altinity-kb-setup-and-maintenance/rbac/)c
Real working SQL for creating users, roles, profiles with constraints. Closest thing to a copy-paste reference for Req 2.

5. ClickHouse examples repo (Docker Compose recipes) — [github.com/ClickHouse/examples/.../docker-compose-recipes](https://github.com/ClickHouse/examples/blob/main/docker-compose-recipes/README.md)
Official Docker Compose examples with Keeper. When you get to Req 3, look at the cluster_1S_2R recipe for a working Keeper + Server setup.

6. Altinity HA Architecture — [docs.altinity.com/.../availability-architecture](https://docs.altinity.com/operationsguide/availability-and-recovery/availability-architecture/)
This is where you'll pull best practices for your response to Maria about Keeper in production: odd number of nodes, separate machines, availability zones.

