/*
Do not change the database path or name variables.
It will be properly coded for build and deployment
This is using sqlcmd variable substitution
*/
ALTER DATABASE [$(DatabaseName)]
    ADD FILE
    (
        NAME = [DataFile],
        FILENAME = '$(DefaultDataPath)$(DatabaseName)_Data.ndf', 
        SIZE = 50 MB, 
        MAXSIZE = UNLIMITED, 
        FILEGROWTH = 50 MB
    )
    TO FILEGROUP [DATA]
    
