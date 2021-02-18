PRAGMA foreign_keys = ON;
INSERT INTO runtime VALUES("foo", "1", "2", "3", "90", 265, 0, 0, 1, '', 'iebdev11', 1, 1);
INSERT INTO runtime VALUES("foo", "1", "2", "3", "80", 0, 0, 0, 1, '', 'blastdev5', 0, 1);
INSERT INTO runtime(label, elapsed_time, system_time, user_time, pcpu) VALUES("bar", 3, 2, 1, 90);
INSERT INTO runtime(label, elapsed_time, system_time, user_time, pcpu, finished_at) VALUES("bar", 3, 2, 1, 90, "2020-01-01");

INSERT INTO system_info(hostname, pmem_usage, pcpu_usage) VALUES("blastdev5", 55.8, 99.3);
INSERT INTO system_info(hostname, timestamp, pmem_usage, pcpu_usage) VALUES("blastdev5", "2021-02-18", 57.8, 39.3);
/*INSERT INTO runtime VALUES("bar", "-1", "2", "3", "99");*/
-- INSERT INTO export(label) VALUES("foo");
