-- Suppose we already have a partition scheme and function until 2020
-- and our last filegroup filled with data

-- Add filegroup
ALTER DATABASE [DATABASE_Name] ADD FILEGROUP [dh_sales-20200101]
GO
-- Add file
ALTER DATABASE [DATABASE_Name] ADD FILE ( NAME = N'dh_sales-20200101', FILENAME = N'D:\MSSQL\MSSQL13.MSSQLSERVER\MSSQL\DATA\dh_sales-20200101.ndf' , SIZE = 8192KB , FILEGROWTH = 65536KB ) 
TO FILEGROUP [dh_sales-20200101]
GO
-- All above could be done simultaneously. E.g. using dynamic SQL:
/*
-- Add FILEGROUP and FILES for the whole year
declare @i int = 1
declare @m char(2)

while @i < 13
begin
	set @m = FORMAT(@i, 'd2')

	declare @query nvarchar(max) = N'
	ALTER DATABASE [DATABASE_Name] ADD FILEGROUP [dh_sales-2020' + @m + N'01]
	ALTER DATABASE [DATABASE_Name] ADD  FILE ( NAME = N''dh_sales-2020' + @m + N'01'', FILENAME = N''D:\MSSQL\MSSQL13.MSSQLSERVER\MSSQL\DATA\dh_sales-2020' + @m + N'01.ndf'' , SIZE = 8192KB , FILEGROWTH = 65536KB ) 
	TO FILEGROUP [dh_sales-2020' + @m + N'01]
	'
	exec sp_executesql @query

	set @i += 1
end
*/

-- Alter partition scheme and function
ALTER PARTITION SCHEME [scpart_dh_sales] NEXT USED [dh_sales-20200101]
ALTER PARTITION FUNCTION [fnpart_dh_sales]() SPLIT RANGE ('2020-01-01T00:00:00')
