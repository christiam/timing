PRAGMA foreign_keys = ON;
INSERT INTO runtime VALUES("foo", "1", "2", "3", "90", 1, '');
INSERT INTO runtime(label, ellapsed_time, system_time, user_time, pcpu) VALUES("bar", 3, 2, 1, 90);
/*INSERT INTO runtime VALUES("bar", "-1", "2", "3", "99");*/
-- INSERT INTO export(label) VALUES("foo");
