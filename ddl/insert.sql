PRAGMA foreign_keys = ON;
INSERT INTO runtime VALUES("foo", "1", "2", "3", "90", 1, '', 'iebdev11');
INSERT INTO runtime VALUES("foo", "1", "2", "3", "80", 1, '', 'blastdev5');
INSERT INTO runtime(label, elapsed_time, system_time, user_time, pcpu) VALUES("bar", 3, 2, 1, 90);
INSERT INTO runtime(label, elapsed_time, system_time, user_time, pcpu, finished_at) VALUES("bar", 3, 2, 1, 90, "2020-01-01");
/*INSERT INTO runtime VALUES("bar", "-1", "2", "3", "99");*/
-- INSERT INTO export(label) VALUES("foo");
