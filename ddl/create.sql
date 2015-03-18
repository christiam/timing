CREATE TABLE IF NOT EXISTS runtime (
    label           VARCHAR(255) PRIMARY KEY,
    ellapsed_time   FLOAT CHECK(ellapsed_time >= 0.0),
    system_time     FLOAT CHECK(system_time >= 0.0),
    user_time       FLOAT CHECK(user_time >= 0.0),
    pcpu            INTEGER CHECK(pcpu >= 0)
);
