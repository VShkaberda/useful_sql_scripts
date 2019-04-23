SELECT name
       , size/128 as SizeInMb
       , max_size/128 as MaxSizeInMb
       , CAST(FILEPROPERTY(name, 'SpaceUsed') AS bigint)/128 as UsedSpace
       , ( size - CAST(FILEPROPERTY(name, 'SpaceUsed') AS bigint) ) / 128 AS AvailableSpaceInMB
       , ( 100 *  (  max_size - CAST(FILEPROPERTY(name, 'SpaceUsed') AS bigint) ) / 128 ) / ( max_size/128 ) as FreeProcent
FROM sys.database_files where name like 'db_name_log'