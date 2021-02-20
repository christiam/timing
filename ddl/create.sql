PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS host_info (
    rowid       INTEGER PRIMARY KEY,
    name        VARCHAR(45) NOT NULL,
    platform    VARCHAR(45) NOT NULL,
    num_cpus    INTEGER CHECK(num_cpus >= 0),
    cpu_speed   FLOAT CHECK(cpu_speed >= 0.0),
    ram         INTEGER CHECK(ram >= 0)
);

CREATE TABLE IF NOT EXISTS runtime (
    label                           VARCHAR(255) NOT NULL,
    elapsed_time                    FLOAT CHECK(elapsed_time >= 0.0),
    system_time                     FLOAT CHECK(system_time >= 0.0),
    user_time                       FLOAT CHECK(user_time >= 0.0),
    pcpu                            INTEGER CHECK(pcpu >= 0),
    mrss                            INTEGER CHECK(mrss >= 0),
    arss                            INTEGER CHECK(arss >= 0),
    avg_mem_usage                   INTEGER CHECK(avg_mem_usage >= 0),
    exit_status                     INTEGER DEFAULT 0,
    finished_at                     TEXT DEFAULT '',
    host_id                         INTEGER NOT NULL,
    setup_exit_status               INTEGER DEFAULT 0,
    teardown_exit_status            INTEGER DEFAULT 0,
    PRIMARY KEY(label, host_id),
    FOREIGN KEY(host_id) REFERENCES host_info(rowid) ON DELETE CASCADE
);
CREATE TRIGGER IF NOT EXISTS finished_at_trigger AFTER INSERT ON runtime
BEGIN
    UPDATE runtime
    SET finished_at = datetime('now', 'localtime')
    WHERE rowid = NEW.rowid and finished_at is '';
END;

CREATE TABLE IF NOT EXISTS system_info (
    host_id                         INTEGER NOT NULL,
    timestamp                       TEXT DEFAULT '',
    pmem_usage                      FLOAT CHECK(pmem_usage > 0.0),
    pcpu_usage                      FLOAT CHECK(pcpu_usage > 0.0),
    PRIMARY KEY(timestamp, host_id),
    FOREIGN KEY(host_id) REFERENCES host_info(rowid) ON DELETE CASCADE
);
CREATE TRIGGER IF NOT EXISTS timestamp_trigger AFTER INSERT ON system_info
BEGIN
    UPDATE system_info
    SET timestamp = datetime('now', 'localtime')
    WHERE rowid = NEW.rowid and timestamp is '';
END;

CREATE VIEW IF NOT EXISTS runtime_view AS
SELECT
    label, 
    elapsed_time,
    system_time,
    user_time,
    pcpu,
    mrss,
    arss,
    avg_mem_usage,
    exit_status
    finished_at,
    HI.name as hostname,
    setup_exit_status,
    teardown_exit_status
FROM host_info HI join runtime R on HI.rowid = R.host_id;

CREATE VIEW IF NOT EXISTS system_info_view AS
SELECT HI.name as hostname, timestamp, pmem_usage, pcpu_usage
FROM host_info HI join system_info SI on HI.rowid = SI.host_id;
