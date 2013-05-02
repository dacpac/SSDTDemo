/*
	Create a master key in the database.
*/

DECLARE @KeyFile VARCHAR(50) 
DECLARE @SQL NVARCHAR(500)

--Create filename

SELECT @KeyFile = '$(DefaultDataPath)$'
SELECT @KeyFile = CONVERT(VARCHAR(8),GETDATE(),112)
SELECT @KeyFile += REPLACE(CONVERT(VARCHAR(8),GETDATE(),108),':','')
SELECT @KeyFile += '$(DatabaseName)_MasterKey'
SELECT @SQL = 'BACKUP MASTER KEY TO FILE = ''' + @KeyFile + '''ENCRYPTION BY PASSWORD = ''$(MasterKeyEncryptionBy)'';'

--Create a database master key
IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE symmetric_key_id = 101)
BEGIN
	RAISERROR('************* CREATING MASTER KEY FOR [%s] *************',1 , 1, '$(DatabaseName)');
	CREATE MASTER KEY ENCRYPTION BY PASSWORD = '$(MasterKeyDecryptionBy)';

	--Backup the master key and store securely
	OPEN MASTER KEY DECRYPTION BY PASSWORD = '$(MasterKeyDecryptionBy)';
    -- Add Encryption by service master
	ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY

	EXEC sp_executesql @sql
	  	                
	CLOSE MASTER KEY 
END
