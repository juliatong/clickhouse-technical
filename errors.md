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

# row-policy-verification

> ```
> SHOW ROW POLICIES

> 
> Query id: 802a0860-e5a2-4dcf-a9ef-49e46b9706d5
>    ┌─name────────────────────────┐
> 1. │ allow_all ON system.tables  │
> 2. │ dev_filter ON system.tables │
>    └─────────────────────────────┘
> ```

> ```
> SHOW CREATE ROW POLICY dev_filter ON system.tables
> Query id: 22bd31e6-8c20-406c-8952-a747028df6b0
> 
>    ┌─CREATE ROW POLICY dev_filter ON system.tables────────────────────────────────────────────────────┐
> 1. │ CREATE ROW POLICY dev_filter ON system.tables FOR SELECT USING database != 'system' TO developer │
>    └──────────────────────────────────────────────────────────────────────────────────────────────────┘

> 1 row in set. Elapsed: 0.003 sec. 
> ```


# Verify the actual setting values in the developer's session

> ```
> julia@Julias-MacBook-Pro keeper-config % docker exec -it clickhouse-server clickhouse-client -q "SHOW CREATE USER developer"
> CREATE USER developer IDENTIFIED WITH sha256_password SETTINGS PROFILE `developer_profile`
> julia@Julias-MacBook-Pro keeper-config % docker exec -it clickhouse-server clickhouse-client --user developer --password dev123 -q "SELECT name, value FROM system.settings WHERE name IN ('max_execution_time', 'max_memory_usage')"
> max_execution_time	0.5
> max_memory_usage	104857600
> ```