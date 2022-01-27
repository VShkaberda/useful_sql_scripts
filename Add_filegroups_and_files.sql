-- Add FILEGROUP and FILES for the whole year for every month, alter partition scheme and function (RANGE RIGHT)
declare @i int = 1									-- month as int
declare @m char(2)									-- month formatted as 'd2'
declare @year char(4) = 2022						-- year
declare @server_version char(2) = 13				-- version of SQL Server
declare @db_name varchar(256) = 'MyDB'				-- name of the database
declare @my_fname varchar(256) = 'my_fname-'		-- template of filegroups and files name
declare @schema_name varchar(256) = 'my_schema'		-- PARTITION SCHEME name
declare @function_name varchar(256) = 'my_partfunc'	-- PARTITION FUNCTION name

while @i < 13
begin
	set @m = FORMAT(@i, 'd2')

	declare @query nvarchar(max) = N'
	-- Add filegroup
	ALTER DATABASE [' + @db_name + '] ADD FILEGROUP [' + @my_fname + @year + @m + N'01]
	-- Add file
	ALTER DATABASE [' + @db_name + '] ADD  FILE ( NAME = N''' + @my_fname + @year  + @m +
	N'01'', FILENAME = N''D:\MSSQL\MSSQL' + @server_version + '.MSSQLSERVER\MSSQL\DATA\' + @my_fname + @year  + @m +
	N'01.ndf'' , SIZE = 8192KB , FILEGROWTH = 65536KB )
	TO FILEGROUP [' + @my_fname  + @year  + @m + N'01]
	-- Alter PARTITION SCHEME and FUNCTION
    ALTER PARTITION SCHEME [' + @schema_name + '] NEXT USED [' + @my_fname  + @year + @m + N'01]
    ALTER PARTITION FUNCTION [' + @function_name + ']() SPLIT RANGE (''' + @year + N'-' + @m + N'-01T00:00:00'')
	'
	exec sp_executesql @query

	set @i += 1
end