.width 40
SELECT label,
       elapsed_time 'elapsed',
       system_time 'system',
       user_time 'user',
       pcpu,
       mrss,
       arss,
       avg_mem_usage,
       exit_status,
       setup_exit_status 'setup',
       teardown_exit_status 'teardown',
       finished_at,
       hostname
FROM runtime
ORDER BY label, finished_at desc;
