PRAGMA foreign_keys = ON;

INSERT INTO host_info(name,platform,num_cpus,cpu_speed,ram) VALUES('blastdev5','x64-linux',4,2.5,64);
INSERT INTO host_info VALUES('1985', 'blastdev6','x64-linux',4,2.5,64);

INSERT INTO runtime VALUES("foo", "1", "2", "3", "90", 265, 0, 0, 1, '', '', (select rowid from host_info where name = 'blastdev5'), 1, 1);
INSERT INTO runtime VALUES("foo", "1", "2", "3", "80", 0, 0, 0, 1, '', '', (select rowid from host_info where name = 'blastdev6'), 0, 1);
INSERT INTO runtime(label, elapsed_time, system_time, user_time, pcpu,host_id) VALUES("bar", 3, 2, 1, 90, (select rowid from host_info where name='blastdev5'));
INSERT INTO runtime(label, elapsed_time, system_time, user_time, pcpu, finished_at, host_id) VALUES("bar", 3, 2, 1, 90, "2020-01-01 15:00:00", (select rowid from host_info where name='blastdev6'));

INSERT INTO system_info(host_id, pmem_usage, pcpu_usage) VALUES((select rowid from host_info where name = "blastdev5"), 55.8, 99.3);
INSERT INTO system_info(host_id, timestamp, pmem_usage, pcpu_usage) VALUES((select rowid from host_info where name = "blastdev5"), "2021-02-18", 57.8, 39.3);
/*INSERT INTO runtime VALUES("bar", "-1", "2", "3", "99");*/
-- INSERT INTO export(label) VALUES("foo");
