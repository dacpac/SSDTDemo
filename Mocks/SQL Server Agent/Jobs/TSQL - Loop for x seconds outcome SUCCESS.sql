:setvar JobName "SQLBitsXI"
:setvar WaitSeconds 60

/*=================================================================================================== 
 * Job history is valuable so attempt to apply changes via update procs instead of job delete/create. 
 *===================================================================================================
 */
DECLARE @jobName     SYSNAME    = N'$(JobName)';
DECLARE @jobId       BINARY(16) = (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = @jobName)
      , @jobCategory SYSNAME    = N'MOCK'
      , @jobStepName SYSNAME    = ''   -- set later at job step create/update
      , @jobStepId   INT        = 0          -- set later at job step create/update
      , @returnCode  INT        = 0;
      
RAISERROR('', 10, 1);
RAISERROR('Starting script for SQL Server Agent job [%s]', 10, 1, @jobName);

BEGIN TRANSACTION

-- JobCategory 
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name = @jobCategory AND category_class = 1) 
    BEGIN
        RAISERROR('   creating job category [$s].', 10, 1, @jobCategory);
        EXEC @returnCode = msdb.dbo.sp_add_category @class = N'JOB'
                                                  , @type  = N'LOCAL'
                                                  , @name  = @jobCategory;
    END
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback     
     
-- create/modify job
IF @jobId IS NULL 
    BEGIN
        RAISERROR('   creating job [%s]', 10, 1, @jobName);
        EXEC @ReturnCode = msdb.dbo.sp_add_job @job_name              = @jobName
                                             , @enabled               = 0
                                             , @notify_level_eventlog = 0
                                             , @notify_level_email    = 0
                                             , @notify_level_netsend  = 0
                                             , @notify_level_page     = 0
                                             , @delete_level          = 0
                                             , @description           = N'MOCK TSQL JOB'
                                             , @category_name         = @jobCategory
                                             , @owner_login_name      = N'sa'
                                             , @job_id                = @jobId OUTPUT;
    END
ELSE 
    BEGIN
        RAISERROR('   amending job [%s]', 10, 1, @jobName);
        EXEC @returnCode = msdb.dbo.sp_update_job @job_id                = @jobId
                                                , @enabled               = 0
                                                , @notify_level_eventlog = 0
                                                , @notify_level_email    = 0
                                                , @notify_level_netsend  = 0
                                                , @notify_level_page     = 0
                                                , @delete_level          = 0
                                                , @description           = N'MOCK TSQL JOB'
                                                , @category_name         = @jobCategory
                                                , @owner_login_name      = N'sa'
    END
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

SET @jobStepName = N'Loop for x seconds and report success';
SET @jobStepId += 1;
      
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId AND step_id = @jobStepId) 
    BEGIN
        RAISERROR('   creating job step [%s]', 10, 1, @jobStepName);
        EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
               @job_id               = @jobId
             , @step_name            = @jobStepName
             , @step_id              = @jobStepId
             , @cmdexec_success_code = 0
             , @on_success_action    = 1
             , @on_success_step_id   = 0
             , @on_fail_action       = 2
             , @on_fail_step_id      = 0
             , @retry_attempts       = 0
             , @retry_interval       = 0
             , @os_run_priority      = 0
             , @subsystem            = N'TSQL'
             , @command=N'DECLARE @StartTime DATETIME , @EndTime DATETIME 
             DECLARE @WaitSeconds INT = $(WaitSeconds)

SET NOCOUNT ON 

SELECT @StartTime = GETUTCDATE(), @EndTime = DATEADD(ss, @WaitSeconds, GETUTCDATE());
      
WHILE (@StartTime <= @EndTime) 
    BEGIN 
        WAITFOR DELAY ''00:00:01'';
        SET @StartTime = GETUTCDATE();
    END'
             , @database_name        = N'master'
             , @flags                = 0
    END
ELSE 
    BEGIN
        RAISERROR('   amending job step %s', 10, 1, @jobStepName);
        EXEC @ReturnCode = msdb.dbo.sp_update_jobstep 
               @job_id               = @jobId
             , @step_name            = @jobStepName
             , @step_id              = @jobStepId
             , @cmdexec_success_code = 0
             , @on_success_action    = 1
             , @on_success_step_id   = 0
             , @on_fail_action       = 2
             , @on_fail_step_id      = 0
             , @retry_attempts       = 0
             , @retry_interval       = 0
             , @os_run_priority      = 0
             , @subsystem            = N'TSQL'
             , @command=N'DECLARE @StartTime DATETIME , @EndTime DATETIME 
             DECLARE @WaitSeconds INT = $(WaitSeconds)

SET NOCOUNT ON 

SELECT @StartTime = GETUTCDATE(), @EndTime = DATEADD(ss, @WaitSeconds, GETUTCDATE());
      
WHILE (@StartTime <= @EndTime) 
    BEGIN 
        WAITFOR DELAY ''00:00:01'';
        SET @StartTime = GETUTCDATE();
    END'
             , @database_name        = N'master'
             , @flags                = 0

    END
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback      

-- job starting step
RAISERROR('   setting job starting step as %d ([%s])', 10, 1, 1, @jobStepName);
EXEC @returnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1;
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

-- job server
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobservers WHERE job_id = @jobId AND server_id = 0) 
    BEGIN
        RAISERROR('   configuring job server as [(local)].', 10, 1)
        EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
        IF @@ERROR | @returnCode <> 0 
            GOTO QuitWithRollback
    END

COMMIT TRANSACTION
RAISERROR('   Job script for [%s] completed.', 10, 1, @jobName);
GOTO EndSave


QuitWithRollback:
RAISERROR('***ERROR***   Job script for [%s] failed.', 16, 1, @jobName);
IF @@TRANCOUNT > 0 
    ROLLBACK TRANSACTION

EndSave:
GO
