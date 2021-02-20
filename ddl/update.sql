PRAGMA foreign_keys = ON;
UPDATE host_info SET ram = 100 where name = 'blastdev6';
UPDATE runtime SET exit_status = 100, pcpu = 800 where label = 'foo';
UPDATE system_info SET pmem_usage = 25.0 where host_id = (select rowid from host_info where name = 'blastdev5');
