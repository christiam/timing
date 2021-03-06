.width 40
SELECT label,
       elapsed_time,
       exit_status,
       setup_exit_status 'setup',
       teardown_exit_status 'teardown' 
FROM runtime_view
ORDER BY label, finished_at DESC;

SELECT timestamp, 
       pmem_usage 'RAM usage %', 
       pcpu_usage 'CPU usage %'
FROM system_info_view
ORDER BY timestamp DESC;
