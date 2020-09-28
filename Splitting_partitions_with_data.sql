-- Set db to offline to rename *.ndf files
ALTER DATABASE Features SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
ALTER DATABASE Features SET OFFLINE
GO

-- <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>
-- !!!!!!!!!! Rename partition names on disc, e.g. feat_sales-20210101 -> feat_sales-20210201
-- <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>

ALTER DATABASE Features MODIFY FILE (Name='[feat_sales-20210101]', FILENAME='D:\MSSQL\MSSQL13.MSSQLSERVER\MSSQL\DATA\feat_sales-20210201.ndf')
GO
ALTER DATABASE Features MODIFY FILE (Name='feat_sales-20201201', FILENAME='D:\MSSQL\MSSQL13.MSSQLSERVER\MSSQL\DATA\feat_sales-20210101.ndf')
GO
ALTER DATABASE Features MODIFY FILE (Name='feat_sales-20201101', FILENAME='D:\MSSQL\MSSQL13.MSSQLSERVER\MSSQL\DATA\feat_sales-20201201.ndf')
GO
ALTER DATABASE Features MODIFY FILE (Name='feat_sales-20201001', FILENAME='D:\MSSQL\MSSQL13.MSSQLSERVER\MSSQL\DATA\feat_sales-20201101.ndf')
GO
ALTER DATABASE Features MODIFY FILE (Name='feat_sales-20200901', FILENAME='D:\MSSQL\MSSQL13.MSSQLSERVER\MSSQL\DATA\feat_sales-20201001.ndf')
GO
ALTER DATABASE Features MODIFY FILE (Name='feat_sales-20200801', FILENAME='D:\MSSQL\MSSQL13.MSSQLSERVER\MSSQL\DATA\feat_sales-20200901.ndf')
GO

ALTER DATABASE Features SET ONLINE
GO
ALTER DATABASE Features SET MULTI_USER
GO

-- Rename files
ALTER DATABASE Features MODIFY FILE (Name='[feat_sales-20210101]', NewName='feat_sales-20210201')
ALTER DATABASE Features MODIFY FILE (Name='feat_sales-20201201', NewName='feat_sales-20210101')
ALTER DATABASE Features MODIFY FILE (Name='feat_sales-20201101', NewName='feat_sales-20201201')
ALTER DATABASE Features MODIFY FILE (Name='feat_sales-20201001', NewName='feat_sales-20201101')
ALTER DATABASE Features MODIFY FILE (Name='feat_sales-20200901', NewName='feat_sales-20201001')
ALTER DATABASE Features MODIFY FILE (Name='feat_sales-20200801', NewName='feat_sales-20200901')

-- Rename filegroups
ALTER DATABASE Features
MODIFY FILEGROUP [feat_sales-20210101] Name=[feat_sales-20210201]
ALTER DATABASE Features
MODIFY FILEGROUP [feat_sales-20201201] Name=[feat_sales-20210101]
ALTER DATABASE Features
MODIFY FILEGROUP [feat_sales-20201101] Name=[feat_sales-20201201]
ALTER DATABASE Features
MODIFY FILEGROUP [feat_sales-20201001] Name=[feat_sales-20201101]
ALTER DATABASE Features
MODIFY FILEGROUP [feat_sales-20200901] Name=[feat_sales-20201001]
ALTER DATABASE Features
MODIFY FILEGROUP [feat_sales-20200801] Name=[feat_sales-20200901]

-- <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>
-- Spliting partition (#3)
-- Recreating Staging objects first
drop table if exists [feature].[SalesStores_DFL_ix_LDF_staging];
GO
if exists(select * from sys.partition_schemes where name = 'scpart_Staging') drop partition scheme scpart_Staging;
if exists(select * from sys.partition_functions where name = 'fnpart_Staging') drop partition function fnpart_Staging;
go

create partition function fnpart_Staging(date)
as range right for values
(N'2020-07-01T00:00:00.000', N'2020-09-01T00:00:00.000', N'2020-10-01T00:00:00.000');

create partition scheme scpart_Staging
AS PARTITION fnpart_Staging TO ([PRIMARY], [feat_sales-20200701], [feat_sales-20200901], [feat_sales-20201001]);
go


CREATE TABLE [feature].[SalesStores_DFL_ix_LDF_staging](
	[FilialId] [int] NOT NULL,
	[Date] [date] NOT NULL,
	[LagerId] [int] NOT NULL,
	[QtySales] [numeric](18, 3) NULL,
	[QtyReturns] [numeric](18, 3) NULL,
	[QtyReturnsSameDay] [numeric](18, 3) NULL,
	[AmountSales] [numeric](18, 2) NULL,
	[AmountReturns] [numeric](18, 2) NULL,
	[StoreQtyDefault] [numeric](18, 3) NULL,
	[StoreQtyOther] [numeric](18, 3) NULL,
	[AmountDefault] [numeric](18, 2) NULL,
	[PriceOut] [numeric](18, 2) NULL,
	[MechanicId] [int] NULL,
	[ActivityId] [int] NULL,
 CONSTRAINT [pk_SalesStores_DFL_ix_LDF_staging] PRIMARY KEY CLUSTERED 
(
	[Date] ASC,
	[FilialId] ASC,
	[LagerId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 95, DATA_COMPRESSION = PAGE) ON scpart_Staging([Date])
) ON scpart_Staging([Date])
GO

CREATE NONCLUSTERED INDEX [ix_LagerId_Date_FilialId_DFL_staging] ON [feature].[SalesStores_DFL_ix_LDF_staging]
(
	[LagerId] ASC,
	[Date] ASC,
	[FilialId] ASC
)
INCLUDE([QtySales],[AmountSales],[StoreQtyDefault],[PriceOut],[ActivityId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 95, DATA_COMPRESSION = PAGE) ON scpart_Staging([Date])
GO

-- <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>
-- Switching partitions to the staging table
alter table [feature].[SalesStores_DFL_ix_LDF_broken] switch partition 3
to [feature].[SalesStores_DFL_ix_LDF_staging] partition 2;

alter table [feature].[SalesStores_DFL_ix_LDF_broken] switch partition 4
to [feature].[SalesStores_DFL_ix_LDF_staging] partition 3;

-- <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>
-- Merge all partitions after switching
alter partition function [fnpart_feat_sales_broken]() merge range (N'2020-12-01T00:00:00.000');
alter partition function [fnpart_feat_sales_broken]() merge range (N'2020-11-01T00:00:00.000');
alter partition function [fnpart_feat_sales_broken]() merge range (N'2020-10-01T00:00:00.000');
alter partition function [fnpart_feat_sales_broken]() merge range (N'2020-09-01T00:00:00.000');

-- <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>
-- Creating missing .ndf file
ALTER DATABASE [Features] ADD FILEGROUP [feat_sales-20200801]
GO

ALTER DATABASE [Features] ADD  FILE ( NAME = N'feat_sales-20200801', FILENAME = N'D:\MSSQL\MSSQL13.MSSQLSERVER\MSSQL\DATA\feat_sales-20200801.ndf' , SIZE = 8192KB , FILEGROWTH = 65536KB ) 
TO FILEGROUP [feat_sales-20200801]
GO

-- <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>
-- Splitting partition in the main table
alter partition scheme [scpart_feat_sales_broken]
next used [feat_sales-20200801];
alter partition function [fnpart_feat_sales_broken]()
split range (N'2020-08-01T00:00:00.000');
go

alter partition scheme [scpart_feat_sales_broken]
next used [feat_sales-20200901];
alter partition function [fnpart_feat_sales_broken]()
split range (N'2020-09-01T00:00:00.000');
go

alter partition scheme [scpart_feat_sales_broken]
next used [feat_sales-20201001];
alter partition function [fnpart_feat_sales_broken]()
split range (N'2020-10-01T00:00:00.000');
go

alter partition scheme [scpart_feat_sales_broken]
next used [feat_sales-20201101];
alter partition function [fnpart_feat_sales_broken]()
split range (N'2020-11-01T00:00:00.000');
go

alter partition scheme [scpart_feat_sales_broken]
next used [feat_sales-20201201];
alter partition function [fnpart_feat_sales_broken]()
split range (N'2020-12-01T00:00:00.000');
go

-- <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>
-- Switch back all partitions after to be splitted
alter table [feature].[SalesStores_DFL_ix_LDF_staging] switch partition 3
to [feature].[SalesStores_DFL_ix_LDF_broken] partition 5;

-- <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>
-- Now spllitting partition in the Staging table
-- Delete unnecessary partitions
alter partition function [fnpart_Staging]() merge range (N'2020-10-01T00:00:00.000');
alter partition function [fnpart_Staging]() merge range (N'2020-09-01T00:00:00.000');

drop INDEX [ix_LagerId_Date_FilialId_DFL_staging] ON [feature].[SalesStores_DFL_ix_LDF_staging];
go

alter partition scheme scpart_Staging 
next used [feat_sales-20200801];

alter partition function [fnpart_Staging]()
split range (N'2020-08-01T00:00:00.000');
go

alter partition scheme scpart_Staging 
next used [feat_sales-20200901];

alter partition function [fnpart_Staging]()
split range (N'2020-09-01T00:00:00.000');
go

CREATE NONCLUSTERED INDEX [ix_LagerId_Date_FilialId_DFL_staging] ON [feature].[SalesStores_DFL_ix_LDF_staging]
(
	[LagerId] ASC,
	[Date] ASC,
	[FilialId] ASC
)
INCLUDE([QtySales],[AmountSales],[StoreQtyDefault],[PriceOut],[ActivityId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 95, DATA_COMPRESSION = PAGE) ON scpart_Staging([Date])
GO

-- Switching partitions back
alter table [feature].[SalesStores_DFL_ix_LDF_staging] switch partition 2
to [feature].[SalesStores_DFL_ix_LDF_broken] partition 3;

alter table [feature].[SalesStores_DFL_ix_LDF_staging] switch partition 3
to [feature].[SalesStores_DFL_ix_LDF_broken] partition 4;

-- Drop Staging objects
drop table if exists [feature].[SalesStores_DFL_ix_LDF_staging];
GO
if exists(select * from sys.partition_schemes where name = 'scpart_Staging') drop partition scheme scpart_Staging;
if exists(select * from sys.partition_functions where name = 'fnpart_Staging') drop partition function fnpart_Staging;
go
