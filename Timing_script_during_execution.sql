DECLARE @t1 DATETIME, @t2 DATETIME, @t varchar(max);

SET @t1 = GETDATE();

/*
	Part of the script to be timed.
*/

SET @t2 = GETDATE();
SET @t = 'Message. Elapsed time in seconds: '
SET @t += cast(DATEDIFF(second,@t1,@t2) AS varchar(max));

RAISERROR(@t,0,1) WITH NOWAIT

SET @t1 = GETDATE();

/*
	Part of the script to be timed.
*/

SET @t2 = GETDATE();
SET @t = 'Message. Elapsed time in seconds: '
SET @t += cast(DATEDIFF(second,@t1,@t2) AS varchar(max));

RAISERROR(@t,0,1) WITH NOWAIT

/*
	...
*/