CREATE TABLE [dbo].[DacChecksum]
    (
     [Id] INT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_DacChecksum PRIMARY KEY CLUSTERED ([Id])
   , [DacChecksum] VARCHAR(255) NOT NULL, 
    [Colour] VARCHAR(50) NOT NULL DEFAULT 'Red'
    )