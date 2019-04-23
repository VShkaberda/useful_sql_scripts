SELECT distinct SCHEMA_NAME(objects.schema_id)
      ,OBJECT_NAME(objects.object_id)
      ,objects.type
FROM syscomments  INNER JOIN 
     sys.objects  ON syscomments.id = objects.object_id
WHERE syscomments.text LIKE '%text_to_search%'