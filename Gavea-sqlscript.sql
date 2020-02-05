USE master;
GO
--Not required by new API
--ALTER DATABASE tempdb 
--MODIFY FILE (NAME = tempdev, FILENAME = 'G:\TEMPDB\tempdb.mdf');
--GO

--ALTER DATABASE tempdb 
--MODIFY FILE (NAME = templog, FILENAME = 'G:\TEMPDB\templog.ldf');
--GO
select @@version
GO