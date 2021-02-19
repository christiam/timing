PRAGMA foreign_keys = ON;
UPDATE runtime SET exit_status = 100, pcpu = 800 where label = 'foo';
UPDATE system_info SET pmem_usage = 25.0 where hostname = 'blastdev5';
