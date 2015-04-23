PRAGMA foreign_keys = ON;
UPDATE runtime SET exit_status = 100, pcpu = 800 where label = 'foo';
