RAISERROR('*************** Insert DacChecksum *****************',1,1) ;
GO

DECLARE @Revision VARCHAR(255) = '$(DacChecksum)' ;
RAISERROR('Revision=%s', 1, 1, @Revision) ;

INSERT  [dbo].[DacChecksum] ([DacChecksum]) VALUES ('$(DacChecksum)') ;

RAISERROR('%d rows inserted into [dbo].[DacChecksum] ', 1, 1, @@ROWCOUNT) ;
GO