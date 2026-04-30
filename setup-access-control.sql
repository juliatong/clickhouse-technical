-- Req 2a: Admin user
CREATE USER admin IDENTIFIED BY 'admin123';
GRANT CURRENT GRANTS ON *.* TO admin WITH GRANT OPTION;

-- Req 2b: Developer user with settings profile
CREATE SETTINGS PROFILE developer_profile
SETTINGS
    max_execution_time = 0.5 READONLY,
    max_memory_usage = 104857600 READONLY;

CREATE USER developer IDENTIFIED BY 'dev123'
SETTINGS PROFILE developer_profile;

GRANT SELECT ON *.* TO developer;

-- Req 2b: Row policies on system.tables
CREATE ROW POLICY dev_filter ON system.tables
FOR SELECT USING database != 'system' TO developer;

CREATE ROW POLICY allow_all ON system.tables
FOR SELECT USING 1 TO ALL EXCEPT developer;
