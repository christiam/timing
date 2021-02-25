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
       started_at,
       finished_at,
       hostname
FROM runtime_view
ORDER BY label, finished_at desc;

SELECT hostname,
       timestamp, 
       pmem_usage 'RAM usage %', 
       pcpu_usage 'CPU usage %'
FROM system_info_view
ORDER BY timestamp DESC;
