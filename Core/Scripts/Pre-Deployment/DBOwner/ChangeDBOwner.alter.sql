DECLARE @DBOwner AS NVARCHAR(128)
DECLARE @DatabaseName AS NVARCHAR(128)

SELECT @DBOwner = SUSER_SNAME([owner_sid]), @DatabaseName = DB_NAME() FROM [sys].[databases] WHERE [name] = DB_NAME()

IF (@DBOwner != '$(DBOwner)') 
    BEGIN
        RAISERROR('Changing database owner from [%s] to [%s] for database [%s]', 0, 1, @DBOwner, '$(DBOwner)', @DatabaseName)
        ALTER AUTHORIZATION ON DATABASE::$(DatabaseName) TO $(DBOwner)
    END