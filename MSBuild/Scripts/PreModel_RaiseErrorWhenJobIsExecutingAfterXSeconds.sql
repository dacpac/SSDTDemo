/*
** Text formatted online http://patorjk.com/software/taag Font=Slant
*/

--:setvar Server "localhost"
--:setvar job_name "MOCK"
--:setvar wait_seconds 4

:CONNECT $(Server)
GO

RAISERROR(N'', 1, 1) WITH NOWAIT ;
RAISERROR(N'   _____ ____    __       ___                    __         __      __        ', 1, 1) WITH NOWAIT ;
RAISERROR(N'  / ___// __ \  / /      /   | ____ ____  ____  / /_       / /___  / /_  _____', 1, 1) WITH NOWAIT ;
RAISERROR(N'  \__ \/ / / / / /      / /| |/ __ `/ _ \/ __ \/ __/  __  / / __ \/ __ \/ ___/', 1, 1) WITH NOWAIT ;
RAISERROR(N' ___/ / /_/ / / /___   / ___ / /_/ /  __/ / / / /_   / /_/ / /_/ / /_/ (__  ) ', 1, 1) WITH NOWAIT ;
RAISERROR(N'/____/\___\_\/_____/  /_/  |_\__, /\___/_/ /_/\__/   \____/\____/_.___/____/  ', 1, 1) WITH NOWAIT ;
RAISERROR(N'                            /____/                                            ', 1, 1) WITH NOWAIT ;
RAISERROR(N'', 1, 1) WITH NOWAIT ;

DECLARE @OwnerLoginName SYSNAME = SUSER_NAME()
DECLARE @job_name       SYSNAME
DECLARE @job_id         UNIQUEIDENTIFIER

DECLARE @StartTime DATETIME, @EndTime DATETIME
DECLARE @Running   INT

BEGIN TRY  

    SELECT  @job_id = job_id
         ,  @job_name = name
    FROM    msdb.dbo.sysjobs
    WHERE   name LIKE '$(job_name)'

    IF @job_id IS NULL 
        BEGIN
            RAISERROR('[%s] - Job does not exist. Deployment will continue...', 10, 127, '$(job_name)');
        END
    ELSE 
        BEGIN
            DECLARE @xpSqlAgentEnumJobs TABLE
                ( job_id                UNIQUEIDENTIFIER                          NOT NULL
                , last_run_date         INT                                       NOT NULL
                , last_run_time         INT                                       NOT NULL
                , next_run_date         INT                                       NOT NULL
                , next_run_time         INT                                       NOT NULL
                , next_run_schedule_id  INT                                       NOT NULL
                , requested_to_run      INT                                       NOT NULL
                , request_source        INT                                       NOT NULL
                , request_source_id     SYSNAME          COLLATE database_default     NULL
                , running               INT                                       NOT NULL
                , current_step          INT                                       NOT NULL
                , current_retry_attempt INT                                       NOT NULL
                , job_state             INT                                       NOT NULL
                )
            
            SET NOCOUNT ON 

            SELECT  @StartTime = GETUTCDATE()
                  , @EndTime = DATEADD(ss, $(wait_seconds), GETUTCDATE());
      
            WHILE (@StartTime <= @EndTime) 
                BEGIN 
                    DELETE  FROM @xpSqlAgentEnumJobs;
                    INSERT  INTO @xpSqlAgentEnumJobs
                            EXEC master.dbo.xp_sqlagent_enum_jobs 1, @OwnerLoginName, @job_id;
                 
                    SELECT  @Running = running
                    FROM    @xpSqlAgentEnumJobs;
                              
                    IF @Running = 0 
                        BREAK;

                    WAITFOR DELAY '00:00:03';

                    SET @StartTime = GETUTCDATE();
                  
                END   
                
            IF @Running = 1 
            BEGIN
                RAISERROR('[%s] - Job waited for [%d] seconds but still Running', 16, 1, @job_name, $(wait_seconds));
            END
            ELSE
            BEGIN
            	RAISERROR('[%s] - Job is not running. Disabling job so deployment can continue...', 10, 127, @job_name);
            	EXEC msdb.dbo.sp_update_job @job_id = @job_id, 
		                                    @enabled = 0
            END
                
        END

END TRY

BEGIN CATCH

    IF (@@TRANCOUNT > 0 OR XACT_STATE() <> 0) 
        ROLLBACK TRANSACTION;
        
    DECLARE @ErrorSeverity INT
          , @ErrorState INT
          , @ErrorMessage NVARCHAR(MAX);
        
    SELECT  @ErrorSeverity = ERROR_SEVERITY()
          , @ErrorState = ERROR_STATE()
          , @ErrorMessage = ERROR_MESSAGE();
     
    RAISERROR (
        @ErrorMessage, 
        @ErrorSeverity, 
        @ErrorState
        );        

END CATCH       
