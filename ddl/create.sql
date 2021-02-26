PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS host_info (
    rowid       INTEGER PRIMARY KEY,
    name        VARCHAR(45) NOT NULL,
    platform    VARCHAR(45) NOT NULL,
    num_cpus    INTEGER CHECK(num_cpus >= 0),
    cpu_speed   FLOAT CHECK(cpu_speed >= 0.0),
    /* in Kb, from /proc/meminfo */
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
    started_at                      TEXT DEFAULT '',
    finished_at                     TEXT DEFAULT '',
    host_id                         INTEGER NOT NULL,
    setup_exit_status               INTEGER DEFAULT 0,
    teardown_exit_status            INTEGER DEFAULT 0,
    PRIMARY KEY(label, host_id),
    FOREIGN KEY(host_id) REFERENCES host_info(rowid) ON DELETE CASCADE
);
/* Update both the started_at and finished_at timestamps on the runtime table */
CREATE TRIGGER IF NOT EXISTS start_finish_times_on_runtime_trigger AFTER INSERT ON runtime
BEGIN
    UPDATE runtime
    SET finished_at = datetime('now', 'localtime')
    WHERE rowid = NEW.rowid and finished_at is '';

    UPDATE runtime
    SET started_at = datetime((strftime('%s', finished_at) - CAST(elapsed_time AS INT)), 'unixepoch')
    WHERE rowid = NEW.rowid and started_at is '';
END;

CREATE TABLE IF NOT EXISTS system_info (
    host_id                         INTEGER NOT NULL,
    timestamp                       TEXT DEFAULT '',
    /* memory stored in Kb */
    used_memory                     INTEGER CHECK(used_memory > 0),
    free_memory                     INTEGER CHECK(free_memory > 0),
    shared_memory                   INTEGER CHECK(shared_memory > 0),
    cached_memory                   INTEGER CHECK(cached_memory > 0),
    available_memory                INTEGER CHECK(available_memory > 0),
    /* pmem_usage computed as ((used+cached+shared)*100.)/(total_memory*1.) */
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
    exit_status,
    started_at,
    finished_at,
    HI.name as hostname,
    setup_exit_status,
    teardown_exit_status
FROM host_info HI join runtime R on HI.rowid = R.host_id;

CREATE VIEW IF NOT EXISTS system_info_view AS
SELECT
    HI.name as hostname,
    timestamp,
    HI.ram as total_memory,
    used_memory,
    free_memory,
    shared_memory,
    cached_memory,
    available_memory,
    pmem_usage,
    pcpu_usage
FROM host_info HI join system_info SI on HI.rowid = SI.host_id;
