SELECT 
       s.session_id,r.blocking_session_id, r.status, 
       r.percent_complete,
       s.open_transaction_count, 
       [database_name] = DB_NAME(s.database_id),
       s.cpu_time, s.memory_usage, r.reads, r.writes,r.logical_reads, 
       s.login_time, s.last_request_start_time, s.last_request_end_time,
       r.command,s.host_name, s.program_name, s.login_name, s.original_login_name, 
       is_user_process,
       cost = ROW_NUMBER() OVER  (ORDER BY (s.cpu_time+s.memory_usage+s.reads+s.writes+s.logical_reads+s.row_count+CONVERT(INT, s.login_time)-CONVERT(INT, s.last_request_end_time)) DESC),
       wait_type, wait_time,wait_resource,last_wait_type
       --,CASE WHEN DATALENGTH(t.text) >0 THEN SUBSTRING(t.text,statement_start_offset/2,(statement_end_offset-statement_start_offset)/2+2) ELSE '' END stm,t.text
       ,r.plan_handle
FROM sys.dm_exec_sessions s
       LEFT JOIN sys.dm_exec_requests r ON r.session_id=s.session_id
       cross apply sys.dm_exec_sql_text(r.sql_handle) t
WHERE  ((r.blocking_session_id <> 0 ) OR s.session_id in (SELECT DISTINCT bloc.blocking_session_id FROM sys.dm_exec_requests bloc WHERE bloc.blocking_session_id <> 0))
ORDER BY r.session_id