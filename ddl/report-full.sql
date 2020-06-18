SELECT label,
       elapsed_time 'elapsed',
       system_time 'system',
       user_time 'user',
       pcpu,
       exit_status,
       setup_exit_status 'setup',
       teardown_exit_status 'teardown',
       finished_at,
       hostname
FROM runtime;
