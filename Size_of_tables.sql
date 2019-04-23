select t.name as TableName, Min(t.create_date) as CreateDate, ds.name as FileGroupName, SUM(u.total_pages) * 8 / 1024 as SizeMB
from sys.tables as t
inner join sys.partitions as p on t.object_id = p.object_id
inner join sys.allocation_units as u on p.partition_id = u.container_id
inner join sys.data_spaces as ds on u.data_space_id = ds.data_space_id
where t.name like '%part_of_name%'
group by t.name, ds.name
order by SizeMB desc