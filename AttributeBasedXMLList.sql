-- create varchar list from attribute [i] of [table]
DECLARE @List VARCHAR(MAX), @XMLbuildScript NVARCHAR(MAX)

SELECT @List = STUFF((SELECT ', ' + cast([i] as varchar(10)) FROM [table] FOR XML PATH('')),1,1,'')

-- create attribute based XMLList
DECLARE @AttributeBasedXMLList XML
SELECT @XMLBuildScript='SELECT @AttributeBasedXMLList = ( SELECT x AS "@x" FROM (values ('
      +REPLACE(@List,',','),(')+'))d(x) FOR XML PATH(''y''), ROOT(''root''), TYPE )'
EXEC sp_executesql @XMLBuildScript, N'@AttributeBasedXMLList XML OUT',
                    @AttributeBasedXMLList OUT

-- create attribute based XMLList directly from table
SELECT @AttributeBasedXMLList = (SELECT [i] AS "@x" FROM [table] FOR XML PATH('y'), ROOT('root'), TYPE )

-- select to parse attribute based XMLList into table
SELECT x.y.value('.','int')
FROM @AttributeBasedXMLList.nodes('root/y/@x') AS x( y )
