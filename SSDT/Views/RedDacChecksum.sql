CREATE VIEW [dbo].[RedDacChecksum]
AS
    SELECT Id, DacChecksum FROM dbo.DacChecksum WHERE [Colour] = 'Red' ;