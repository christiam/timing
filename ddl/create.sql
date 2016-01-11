PRAGMA foreign_keys = ON;
CREATE TABLE IF NOT EXISTS runtime (
    label           VARCHAR(255) NOT NULL,
    ellapsed_time   FLOAT CHECK(ellapsed_time >= 0.0),
    system_time     FLOAT CHECK(system_time >= 0.0),
    user_time       FLOAT CHECK(user_time >= 0.0),
    pcpu            INTEGER CHECK(pcpu >= 0),
    exit_status     INTEGER DEFAULT 0,
    finished_at     TEXT DEFAULT '',
    hostname        VARCHAR(255),
    PRIMARY KEY(label, hostname)
);
CREATE TRIGGER IF NOT EXISTS finished_at_trigger AFTER INSERT ON runtime
BEGIN
    UPDATE runtime
    SET finished_at = datetime('now', 'localtime')
    WHERE rowid = NEW.rowid;
END;

/*
CREATE TABLE IF NOT EXISTS export(
    label           VARCHAR(255) PRIMARY KEY,
    exported        INTEGER DEFAULT 0,
    FOREIGN KEY(label) REFERENCES runtime(label) ON DELETE CASCADE
);
*/
