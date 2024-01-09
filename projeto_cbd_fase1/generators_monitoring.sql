use WWIGlobal
GO

-- Generate Inserts
DROP PROCEDURE IF EXISTS spGenInserts
GO
CREATE PROCEDURE spGenInserts(
    @tableName VARCHAR(30)
)
AS
BEGIN
    EXEC spAutoGenerateMetadata
    DECLARE @insertString VARCHAR(200)
    DECLARE @count INT
    DECLARE @columnName VARCHAR(30)
    DECLARE @dataType VARCHAR(30)
    DECLARE @maxLength INT
    DECLARE @tableScheama VARCHAR(40)
    SET @count=0
    SET @insertString = CONCAT('CREATE PROCEDURE ',LOWER(@tableName),'_insert(')
    DECLARE insert_cursor CURSOR  
FOR SELECT v.[Column Name], v.[Data Type], v.[Max Length]
    FROM dbo.vTableMetadata v
    WHERE v.[Table Name]=@tableName
    OPEN insert_cursor
    FETCH NEXT FROM  insert_cursor
INTO @columnName,@dataType,@maxLength
    WHILE @@FETCH_STATUS = 0  
	BEGIN
        IF(@count=0)
        BEGIN
            SET @insertString = CONCAT(@insertString,'@',@columnName,' ',IIF(@dataType='varchar',CONCAT(@dataType,'(',@maxLength,')'),@dataType))
            SET @count=@count+1
        END
        ELSE
        BEGIN
            SET @insertString = CONCAT(@insertString,',@',@columnName,' ',IIF(@dataType='varchar',CONCAT(@dataType,'(',@maxLength,')'),@dataType))
            SET @count=@count+1
        END
        FETCH NEXT FROM  insert_cursor
	INTO @columnName,@dataType,@maxLength
    END
    CLOSE insert_cursor
    DEALLOCATE insert_cursor
    SET @tableScheama = (SELECT distinct s.name as schema_name
    FROM sys.columns AS c
        INNER JOIN sys.tables AS t ON t.object_id = c.object_id
        INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.name = @tableName)
    SET @insertString = CONCAT(@insertString,') AS BEGIN INSERT INTO ',@tableScheama,'.',@tableName,' VALUES (')
    SET @count=0
    DECLARE insert_cursor CURSOR  
FOR SELECT v.[Column Name], v.[Data Type], v.[Max Length]
    FROM dbo.vTableMetadata v
    WHERE v.[Table Name]=@tableName
    OPEN insert_cursor
    FETCH NEXT FROM  insert_cursor
    INTO @columnName,@dataType,@maxLength
    WHILE @@FETCH_STATUS = 0  
	BEGIN
        IF(@count=0)
        BEGIN
            SET @insertString = CONCAT(@insertString,'@',@columnName)
            SET @count=@count+1
        END
        ELSE
        BEGIN
            SET @insertString = CONCAT(@insertString,',@',@columnName)
            SET @count=@count+1
        END
        FETCH NEXT FROM  insert_cursor
	INTO @columnName,@dataType,@maxLength
    END
    CLOSE insert_cursor
    DEALLOCATE insert_cursor
    SET @insertString = CONCAT(@insertString,') END')
    EXEC (@insertString)
END
GO

-- Generate Updates
DROP PROCEDURE IF EXISTS spGenUpdates
GO
CREATE PROCEDURE spGenUpdates(
    @tableName VARCHAR(30)
)
AS
BEGIN
    EXEC spAutoGenerateMetadata
    DECLARE @updateString VARCHAR(400)
    DECLARE @count INT
    DECLARE @columnName VARCHAR(30)
    DECLARE @dataType VARCHAR(30)
    DECLARE @maxLength INT
    DECLARE @tableScheama VARCHAR(40)
    DECLARE @isPrimaryKey VARCHAR(3)
    DECLARE @whereString VARCHAR(50)
    SET @count=0
    SET @updateString = CONCAT('CREATE PROCEDURE ',LOWER(@tableName),'_update(')
    DECLARE insert_cursor CURSOR  
FOR SELECT v.[Column Name], v.[Data Type], v.[Max Length], v.[Primary Key]
    FROM dbo.vTableMetadata v
    WHERE v.[Table Name]=@tableName
    OPEN insert_cursor
    FETCH NEXT FROM  insert_cursor
INTO @columnName,@dataType,@maxLength,@isPrimaryKey
    WHILE @@FETCH_STATUS = 0  
	BEGIN
        IF(@count=0)
        BEGIN
            SET @updateString = CONCAT(@updateString,'@',@columnName,' ',IIF(@dataType='varchar',CONCAT(@dataType,'(',@maxLength,')'),@dataType))
            SET @count=@count+1
        END
        ELSE
        BEGIN
            SET @updateString = CONCAT(@updateString,',@',@columnName,' ',IIF(@dataType='varchar',CONCAT(@dataType,'(',@maxLength,')'),@dataType))
            SET @count=@count+1
        END
        IF(@isPrimaryKey='YES')
        BEGIN
            SET @whereString=CONCAT('WHERE ',@columnName,'=@',@columnName)
        END
        FETCH NEXT FROM  insert_cursor
	INTO @columnName,@dataType,@maxLength,@isPrimaryKey
    END
    CLOSE insert_cursor
    DEALLOCATE insert_cursor
    SET @tableScheama = (SELECT distinct s.name as schema_name
    FROM sys.columns AS c
        INNER JOIN sys.tables AS t ON t.object_id = c.object_id
        INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.name = @tableName)
    SET @updateString = CONCAT(@updateString,') AS BEGIN ')
    SET @count=0
    DECLARE insert_cursor CURSOR  
FOR SELECT v.[Column Name], v.[Data Type], v.[Max Length], v.[Primary Key]
    FROM dbo.vTableMetadata v
    WHERE v.[Table Name]=@tableName
    OPEN insert_cursor
    FETCH NEXT FROM  insert_cursor
    INTO @columnName,@dataType,@maxLength,@isPrimaryKey
    WHILE @@FETCH_STATUS = 0  
	BEGIN
        IF(@isPrimaryKey='No')
        BEGIN
            SET @updateString = CONCAT(@updateString,' UPDATE ',CONCAT(@tableScheama,'.',@tableName),' SET ',@columnName,'=@',@columnName,' ',@whereString)
        END
        FETCH NEXT FROM  insert_cursor
	INTO @columnName,@dataType,@maxLength,@isPrimaryKey
    END
    CLOSE insert_cursor
    DEALLOCATE insert_cursor
    SET @updateString = CONCAT(@updateString,' END')
    EXEC (@updateString)
END
GO

-- Generate Deletes
DROP PROCEDURE IF EXISTS spGenDelete
GO
CREATE PROCEDURE spGenDelete(
    @tableName VARCHAR(30)
)
AS
BEGIN
    EXEC spAutoGenerateMetadata
    DECLARE @deleteString VARCHAR(200)
    DECLARE @columnName VARCHAR(30)
    DECLARE @dataType VARCHAR(30)
    DECLARE @maxLength INT
    DECLARE @isPrimaryKey VARCHAR(3)
    DECLARE @tableScheama VARCHAR(40)
    SET @tableScheama = (SELECT distinct s.name as schema_name
    FROM sys.columns AS c
        INNER JOIN sys.tables AS t ON t.object_id = c.object_id
        INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.name = @tableName)
    SET @deleteString = CONCAT('CREATE PROCEDURE ',LOWER(@tableName),'_delete(')
    DECLARE insert_cursor CURSOR  
FOR SELECT v.[Column Name], v.[Data Type], v.[Max Length], v.[Primary Key]
    FROM dbo.vTableMetadata v
    WHERE v.[Table Name]=@tableName
    OPEN insert_cursor
    FETCH NEXT FROM  insert_cursor
INTO @columnName,@dataType,@maxLength,@isPrimaryKey
    WHILE @@FETCH_STATUS = 0  
	BEGIN
        IF(@isPrimaryKey='Yes')
            SET @deleteString = CONCAT(@deleteString,'@',@columnName,' ',IIF(@dataType='varchar',CONCAT(@dataType,'(',@maxLength,')'),@dataType),') AS BEGIN DELETE ',@tableScheama,'.',@tableName,' WHERE ',@columnName,'=@',@columnName)
        FETCH NEXT FROM  insert_cursor
	INTO @columnName,@dataType,@maxLength,@isPrimaryKey
    END
    CLOSE insert_cursor
    DEALLOCATE insert_cursor
    SET @deleteString = CONCAT(@deleteString,' END')
    EXEC (@deleteString)
END
GO

-- Generates the metadata for every table in the Database
DROP PROCEDURE IF EXISTS dbo.spGenerateMetadataPerTable
GO
CREATE PROCEDURE dbo.spGenerateMetadataPerTable(
    @MetadataID INT,
    @tableName VARCHAR(50),
    @schemaName VARCHAR(30))
AS
BEGIN
    DECLARE @columnName VARCHAR(50)
    DECLARE @dataType VARCHAR(20)
    DECLARE @maxLength INT
    DECLARE @precision INT
    DECLARE @isNullable BIT
    DECLARE @isPrimaryKey BIT
    DECLARE @isForeignKey BIT
    DECLARE registry_cursor CURSOR  
FOR SELECT
        c.name 'Column Name',
        t.Name 'Data type',
        c.max_length 'Max Length',
        c.precision ,
        c.is_nullable,
        ISNULL(i.is_primary_key, 0) 'Primary Key'
    FROM sys.columns c
        INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
        LEFT OUTER JOIN sys.index_columns ic
        ON ic.object_id = c.object_id
            AND ic.column_id = c.column_id
        LEFT OUTER JOIN sys.indexes i
        ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    WHERE
c.object_id = OBJECT_ID(CONCAT(@schemaName,'.',@tableName))
    OPEN registry_cursor
    FETCH NEXT FROM  registry_cursor
INTO @columnName,@dataType,@maxLength,@precision,@isNullable,@isPrimaryKey
    WHILE @@FETCH_STATUS = 0  
	BEGIN
        SET @isForeignKey = IIF((@columnName in(SELECT
    COL_NAME(fc.parent_object_id,fc.parent_column_id) 'Coluna Origem'
FROM sys.foreign_keys f
    INNER JOIN sys.foreign_key_columns AS fc
    ON f.object_id = fc.constraint_object_id
WHERE f.parent_object_id = object_id(CONCAT(@schemaName,'.',@tableName)))),1,0)

        INSERT INTO WWIGlobal.dbo.MetadataLogDetail
            (MetadataID,TableName,ColumnName,DataType,MaxLength,[Precision],isNullable,isPrimaryKey,isForeignKey)
        VALUES
            (@MetadataID, @tableName, @columnName, @dataType, @maxLength, @precision, @isNullable, @isPrimaryKey, @isForeignKey)

        FETCH NEXT FROM  registry_cursor
	INTO @columnName,@dataType,@maxLength,@precision,@isNullable,@isPrimaryKey
    END
    CLOSE registry_cursor
    DEALLOCATE registry_cursor
END
GO

-- Generates the metadata for a table in the Database
DROP PROCEDURE IF EXISTS dbo.spGenMetadata 
GO
CREATE PROCEDURE dbo.spGenMetadata
    (@MetadataID INT)
AS
BEGIN
    DECLARE @name VARCHAR(30);
    DECLARE @schemaName VARCHAR(30);
    DECLARE table_cursor CURSOR  
FOR SELECT SCHEMA_NAME(s.schema_id), name
    FROM sys.all_objects s
    WHERE (OBJECTPROPERTY(object_id, N'SchemaId') = SCHEMA_ID(N'USERS') OR OBJECTPROPERTY(object_id, N'SchemaId') = SCHEMA_ID(N'SALES')) AND type_desc='USER_TABLE'
    OPEN table_cursor
    FETCH NEXT FROM  table_cursor
INTO @schemaName,@name
    WHILE @@FETCH_STATUS = 0  
	BEGIN
        EXEC dbo.spGenerateMetadataPerTable @MetadataID,@name,@schemaName
        FETCH NEXT FROM  table_cursor
	INTO @schemaName,@name
    END
    CLOSE table_cursor
    DEALLOCATE table_cursor
END
GO

-- Auto generates the metadata for all tables
DROP PROCEDURE IF EXISTS dbo.spAutoGenerateMetadata
GO
CREATE PROCEDURE dbo.spAutoGenerateMetadata
AS
BEGIN
    DECLARE @ID INT
    INSERT INTO WWIGlobal.dbo.MetadataLog
        (ExecuteDate)
    VALUES
        (SYSDATETIME())
    SET @ID = SCOPE_IDENTITY()
    EXEC dbo.spGenMetadata @ID
END
GO

--Displays the last execution of the spAutoGenerateMetadata
DROP VIEW IF EXISTS vTableMetadata
GO
CREATE VIEW vTableMetadata
AS
    SELECT mld.TableName'Table Name', mld.ColumnName'Column Name', mld.DataType 'Data Type', mld.MaxLength'Max Length',
        mld.[Precision], IIF(mld.isNullable=1,'Yes','No')'Nullable', IIF(mld.isPrimaryKey=1,'Yes','No')'Primary Key', IIF(mld.isForeignKey=1,'Yes','No')'Foreign Key'
    FROM WWIGlobal.dbo.MetadataLog ml
        JOIN WWIGlobal.dbo.MetadataLogDetail mld on mld.MetadataID=ml.MetadataID
    WHERE ml.MetadataID=(SELECT TOP 1
        m.MetadataID
    FROM WWIGlobal.dbo.MetadataLog m
    ORDER BY m.MetadataID DESC)
GO

--Auxiliary view to list the number of rows and space occupied per table
DROP VIEW IF EXISTS vSizeOccupied
GO
CREATE VIEW vSizeOccupied
AS
    SELECT
        OBJECT_NAME(t.object_id) ObjectName,
        sum(u.total_pages) * 8 + (select sum(max_length)
        from sys.columns
        where object_NAME(object_id) = OBJECT_NAME(t.object_id))Total_Reserved_kb ,
        max(p.rows) RowsCount
    FROM
        sys.allocation_units u
        JOIN sys.partitions p on u.container_id = p.hobt_id

        JOIN sys.tables t on p.object_id = t.object_id
    WHERE u.type_desc='IN_ROW_DATA' AND OBJECT_NAME(t.object_id) IN (SELECT name
        FROM sys.all_objects s
        WHERE (OBJECTPROPERTY(object_id, N'SchemaId') = SCHEMA_ID(N'USERS') OR OBJECTPROPERTY(object_id, N'SchemaId') = SCHEMA_ID(N'SALES')) AND type_desc='USER_TABLE')
    GROUP BY
  t.object_id,
  OBJECT_NAME(t.object_id),
  u.type_desc
  GO


-- Generates the space occupied per table tables
DROP PROCEDURE IF EXISTS spGenerateSpacePerTable
GO
CREATE PROCEDURE spGenerateSpacePerTable(
    @SpaceID INT,
    @tableName VARCHAR(50)
)
AS
BEGIN
    DECLARE @rows INT
    DECLARE @size INT
    SET @rows = (SELECT v.RowsCount
    FROM vSizeOccupied v
    WHERE v.ObjectName=@tableName)
    SET @size =(SELECT v.Total_Reserved_kb
    FROM vSizeOccupied v
    WHERE v.ObjectName=@tableName)

    INSERT INTO WWIGlobal.dbo.SpaceOccupiedLogDetail
        (SpaceID,TableName,SpaceUsed,NumberOfRows)
    VALUES
        (@SpaceID, @tableName, @size, @rows)
END
GO

-- Generates the space occupied for all tables
DROP PROCEDURE IF EXISTS dbo.spGenSpaceOccupied
GO
CREATE PROCEDURE dbo.spGenSpaceOccupied
    (@SpaceID INT)
AS
BEGIN
    DECLARE @name VARCHAR(30);
    DECLARE table_cursor CURSOR  
FOR SELECT name
    FROM sys.all_objects s
    WHERE (OBJECTPROPERTY(object_id, N'SchemaId') = SCHEMA_ID(N'USERS') OR OBJECTPROPERTY(object_id, N'SchemaId') = SCHEMA_ID(N'SALES')) AND type_desc='USER_TABLE'
    OPEN table_cursor
    FETCH NEXT FROM  table_cursor
INTO @name
    WHILE @@FETCH_STATUS = 0  
	BEGIN
        EXEC spGenerateSpacePerTable @SpaceID, @name
        FETCH NEXT FROM  table_cursor
	INTO @name
    END
    CLOSE table_cursor
    DEALLOCATE table_cursor
END
GO

-- Auto generates the Space used and Row Count for all tables
DROP PROCEDURE IF EXISTS dbo.spAutoGenerateSpaceUsed
GO
CREATE PROCEDURE dbo.spAutoGenerateSpaceUsed
AS
BEGIN
    DECLARE @ID INT
    INSERT INTO WWIGlobal.dbo.SpaceOccupiedLog
        (ExecuteDate)
    VALUES
        (SYSDATETIME())
    SET @ID = SCOPE_IDENTITY()
    EXEC dbo.spGenSpaceOccupied @ID
END
GO

-- Displays the last execution of spAutoGenerateSpaceUsed
DROP VIEW IF EXISTS vTableSizeOccupied
GO
CREATE VIEW vTableSizeOccupied
AS
    SELECT sod.TableName 'Table Name', sod.NumberOfRows'Number Of Rows', sod.SpaceUsed 'Space Used (Kb)'
    FROM WWIGlobal.dbo.SpaceOccupiedLogDetail sod
    WHERE sod.SpaceID=(SELECT TOP 1
        sd.SpaceID
    FROM WWIGlobal.dbo.SpaceOccupiedLogDetail sd
    ORDER BY sd.SpaceID DESC)
GO

--Create job to execute every hour spAutoGenerateMetadata AND Create job to execute every hour spAutoGenerateSpaceUsed
USE msdb;  
GO

EXEC dbo.sp_add_job  
    @job_name = N'Run_Auto_Tasks' ;  
GO

EXEC sp_add_jobstep  
    @job_name = N'Run_Auto_Tasks',  
    @step_name = N'Run spCheckTokenValid',  
    @subsystem = N'TSQL',  
    @database_name=N'WWIGlobal',
    @command = N'EXEC Users.spCheckTokenValid',   
    @retry_attempts = 5,  
    @retry_interval = 5,
    @on_success_action=3
GO

EXEC sp_add_jobstep  
    @job_name = N'Run_Auto_Tasks',  
    @step_name = N'Run spAutoGenerateSpaceUsed',  
    @subsystem = N'TSQL',  
    @database_name=N'WWIGlobal',
    @command = N'EXEC spAutoGenerateSpaceUsed',   
    @retry_attempts = 5,  
    @retry_interval = 5 , 
    @on_success_action=3
GO

EXEC sp_add_jobstep
    @job_name = N'Run_Auto_Tasks',  
    @step_name = N'Run spAutoGenerateMetadata',  
    @subsystem = N'TSQL',  
    @database_name=N'WWIGlobal',
    @command = N'EXEC spAutoGenerateMetadata',   
    @retry_attempts = 5,  
    @retry_interval = 5,
    @on_success_action=1
GO

EXEC dbo.sp_add_schedule  
    @schedule_name = N'RunEveryHour',  
    @freq_type = 4,  
	@freq_interval = 1,
	@freq_subday_type=0x8,
	@freq_subday_interval=1
GO

EXEC sp_attach_schedule  
   @job_name = N'Run_Auto_Tasks',  
   @schedule_name = N'RunEveryHour';  
GO

EXEC dbo.sp_add_jobserver  
    @job_name = N'Run_Auto_Tasks';  
GO

USE WWIGlobal
GO

