# Links
1. https://clickhouse.com/docs/operations/access-rights
2. https://clickhouse.com/docs/sql-reference/statements/create/row-policy
3. ClickHouse Keeper deep dive (Altinity KB) — [kb.altinity.com/.../clickhouse-keeper](https://kb.altinity.com/altinity-kb-setup-and-maintenance/altinity-kb-zookeeper/clickhouse-keeper/)
Referenced for Keeper config. Read the XML structure, and understood the Raft port vs client port distinction from the working examples.  
Note : "... but we don’t recommend running more than three Keeper nodes. Increasing the number of nodes offers no significant advantages" from the doc.

4. Altinity RBAC practical examples — [kb.altinity.com/.../rba](https://kb.altinity.com/altinity-kb-setup-and-maintenance/rbac/)
Referenced real working SQL for creating users, roles, profiles with constraints. 

5. ClickHouse examples repo (Docker Compose recipes) — [github.com/ClickHouse/examples/.../docker-compose-recipes](https://github.com/ClickHouse/examples/blob/main/docker-compose-recipes/README.md)
6. https://kb.altinity.com/altinity-kb-setup-and-maintenance/altinity-kb-zookeeper/clickhouse-keeper-service/ 
7. https://github.com/Altinity/clickhouse-operator/blob/master/deploy/clickhouse-keeper/clickhouse-keeper-manually/clickhouse-keeper-3-nodes.yaml

8. Altinity HA Architecture — [docs.altinity.com/.../availability-architecture](https://docs.altinity.com/operationsguide/availability-and-recovery/availability-architecture/)
ClickHouse High Availability Architecture. About Keeper in production in best practice: odd number of nodes, separate machines, availability zones.

