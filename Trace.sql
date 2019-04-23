declare @sql_handle varbinary(64) ,
             @spid int

set @spid = 335 --номер процесса

select @sql_handle=(select sql_handle from  sys.dm_exec_requests er where session_id = @spid)
select er.command, SUBSTRING(text, er.statement_start_offset/2+1, (er.statement_end_offset - er.statement_start_offset)/2+1 ) 
from sys.dm_exec_sql_text(@sql_handle)
inner join sys.dm_exec_requests er on session_id = @spid