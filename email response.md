Hi Maria,
Thank you for reaching out. I've tested each of your requirements against a fresh ClickHouse 25.8.1 Docker deployment. Here's what I found.
1. Limiting databases to 3
The setting for this is max_database_num_to_throw, configured in config.d/:
<clickhouse>
    <max_database_num_to_throw>3</max_database_num_to_throw>
</clickhouse>

One thing to note: the default database counts toward this limit, but system databases do not. So a limit of 3 gives you default plus 2 user-created databases. Could you confirm how many user-created databases you need? If it's 3, I'd recommend setting this to 4.
2. Users and access control
Both users are created via SQL-driven access control.
Admin: created with GRANT CURRENT GRANTS ON *.* TO admin WITH GRANT OPTION, which gives admin the same permission level as default.
Developer: created with a settings profile enforcing max_execution_time = 0.5 (note: seconds, not milliseconds) and max_memory_usage = 104857600 (100MB in bytes). I've verified both limits — queries exceeding either threshold are terminated with TIMEOUT_EXCEEDED or MEMORY_LIMIT_EXCEEDED respectively. I can demonstrate this during a call if helpful.
For system.tables visibility: I applied a row policy so the developer user only sees rows where the database is not system. Admin and default users are unaffected.
One question: I've granted developer read-only access (SELECT). What additional permissions does this user need?
3. ClickHouse Keeper
I found the issue in your config. <listen_host>0.0.0.0</listen_host> is placed inside <keeper_server>, but Keeper only reads this setting at the <clickhouse> root level. Because of this, Keeper defaults to listening on localhost only — which is why your ClickHouse server can't reach it from a different container. Move it to the root level:
<clickhouse>
    <listen_host>0.0.0.0</listen_host>
    <keeper_server>
        ...
    </keeper_server>
</clickhouse>
The XML looks almost identical for standalone and embedded. It's a design quirk that trips up experienced engineers like you, that is,  root XML tag <clickhouse> is the SAME for both, which is probably where your confusion comes from. This is a common configuration issue — the official docs don't explicitly show where listen_host belongs in standalone Keeper configs. I'd recommend adding it at the <clickhouse> root level as shown in the corrected config above.
Also make sure your ClickHouse server has a config pointing to Keeper's client port (9181), and that both containers are on the same Docker network so the hostname resolves.
As for what Keeper does: it's the coordination layer that keeps your servers in sync — replication, schema changes, and leader election all go through Keeper. If you're running more than one ClickHouse server, it's required.
For production, I'd recommend:
3 Keeper nodes on separate machines (your current single node works for development but has no fault tolerance)
Keeper data on dedicated storage, separate from ClickHouse data
In production, always mount /var/lib/clickhouse to persistent storage so data and access configs survive container replacement.
Monitoring Keeper latency, as it's on the critical path for replicated writes
A few questions to help me tailor this further:
Are you planning to use replicated tables or distributed DDL?
How many ClickHouse server nodes in production?
What are your availability requirements — is downtime acceptable during maintenance?
Let me know and I'll adjust the recommendations accordingly.
Thanks, 
Julia


