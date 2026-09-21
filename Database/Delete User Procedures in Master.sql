use master;

declare @sql nvarchar(max)=N'';


select  @Sql+=N'DROP PROCEDURE'
            +QUOTENAME(Schema_Name(Schema_id))
            +N'.'
            + QUOTENAME(name) 
            +N';'
            +char(13)
            +char(10)
from sys.procedures
where name like 'usp_%'
and is_ms_shipped=0;

print @Sql;
--exec sp_executesql  @Sql;
