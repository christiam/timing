.width 40
SELECT label,
       elapsed_time,
       exit_status,
       setup_exit_status 'setup',
       teardown_exit_status 'teardown' 
FROM runtime
ORDER BY label, finished_at desc;
