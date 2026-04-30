# database-limit-blocked

> ```
> julia@Julias-MacBook-Pro server-config % docker exec -it clickhouse-server clickhouse-client -q "CREATE DATABASE test_db3"
> Received exception from server (version 25.8.1):
> Code: 725. DB::Exception: Received from localhost:9000. DB::Exception: Too many databases. The limit (server configuration parameter `max_database_num_to_throw`) is set to 3, the current number of databases is 3. (TOO_MANY_DATABASES)
> (query: CREATE DATABASE test_db3)
> ```

> ```
> julia@Julias-MacBook-Pro server-config % docker exec -it clickhouse-server clickhouse-client -q "SHOW DATABASES"
> INFORMATION_SCHEMA
> default
> information_schema
> system
> test_db
> test_db2
> ```



# timeout-exceeded
> ```
> …
> 3532085
> Received exception from server (version 25.8.1):
> Code: 159. DB::Exception: Received from localhost:9000. DB::Exception: Timeout exceeded: elapsed 501.528375 ms, maximum: 500 ms. (TIMEOUT_EXCEEDED)
> (query: SELECT * FROM system.numbers LIMIT 1000000000)
> ```


# memory-limit-exceeded
> ```
> julia@Julias-MacBook-Pro server-config % docker exec -it clickhouse-server clickhouse-client --user developer --password dev123 -q "SELECT arrayJoin(range(100000000))"
> Received exception from server (version 25.8.1):
> Code: 241. DB::Exception: Received from localhost:9000. DB::Exception: Query memory limit exceeded: would use 381.53 MiB (attempt to allocate chunk of 381.53 MiB bytes), maximum: 100.00 MiB: In scope SELECT arrayJoin(range(100000000)). (MEMORY_LIMIT_EXCEEDED)
> (query: SELECT arrayJoin(range(100000000)))
> ```


# Grant on admin failure

> ```
> GRANT ALL ON *.* TO admin WITH GRANT OPTION
> Query id: 5b123475-e94c-4bfe-a163-16bd23b81946
> Elapsed: 0.009 sec. 
> Received exception from server (version 25.8.1):
> Code: 497. DB::Exception: Received from localhost:9000. DB::Exception: default: Not enough privileges. To execute this query, it's necessary to have the grant ALL ON *.* WITH GRANT OPTION (Missing permissions: SHOW NAMED COLLECTIONS SECRETS ON *). You can try to use the `GRANT CURRENT GRANTS(...)` statement. (ACCESS_DENIED)
> ```


# row-policy-verification

> ```
> SHOW ROW POLICIES
> Query id: 802a0860-e5a2-4dcf-a9ef-49e46b9706d5
>
>    ┌─name────────────────────────┐
> 1. │ allow_all ON system.tables  │
> 2. │ dev_filter ON system.tables │
>    └─────────────────────────────┘
> 2 rows in set. Elapsed: 0.013 sec. 
> ```

> ```
> SHOW CREATE ROW POLICY dev_filter ON system.tables
> Query id: 22bd31e6-8c20-406c-8952-a747028df6b0
> 
>    ┌─CREATE ROW POLICY dev_filter ON system.tables────────────────────────────────────────────────────┐
> 1. │ CREATE ROW POLICY dev_filter ON system.tables FOR SELECT USING database != 'system' TO developer │
>    └──────────────────────────────────────────────────────────────────────────────────────────────────┘
>
> 1 row in set. Elapsed: 0.003 sec. 
> ```


# Verify the actual setting values in the developer's session

> ```
> julia@Julias-MacBook-Pro keeper-config % docker exec -it clickhouse-server clickhouse-client -q "SHOW CREATE USER developer"
> CREATE USER developer IDENTIFIED WITH sha256_password SETTINGS PROFILE `developer_profile`
> ```

> ```
> julia@Julias-MacBook-Pro keeper-config % docker exec -it clickhouse-server clickhouse-client --user developer --password dev123 -q "SELECT name, value FROM system.settings WHERE name IN ('max_execution_time', 'max_memory_usage')"
> max_execution_time	0.5
> max_memory_usage	104857600
> ```


# Troubleshoot Maria's config
> ```
> julia@Julias-MacBook-Pro keeper-config % docker exec -it clickhouse-server bash -c "echo ruok | nc clickhouse-keeper 9181"
> nc: can't connect to remote host (172.19.0.3): Connection refused
> ```


# Test from localhost- keeper container
> ```
> julia@Julias-MacBook-Pro keeper-config % docker exec -it clickhouse-keeper bash -c "echo ruok | nc localhost 9181"
> imok%
> ```


# Post server keeper conenction: The server doesn't recognize the Keeper connection

> ```
> julia@Julias-MacBook-Pro keeper-config % docker exec -it clickhouse-server clickhouse-client -q "SELECT * FROM system.zookeeper WHERE path = '/'"
> Received exception from server (version 25.8.1):
> Code: 60. DB::Exception: Received from localhost:9000. DB::Exception: Unknown table expression identifier 'system.zookeeper' in scope SELECT * FROM system.zookeeper WHERE path = '/'. (UNKNOWN_TABLE)
> (query: SELECT * FROM system.zookeeper WHERE path = '/')
> ```

