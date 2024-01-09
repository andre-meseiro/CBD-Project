-- Backup e recuperação
-- Modelo de Recuperação
alter database WWIGLOBAL set recovery full;

-- Full Backup
backup database WWIGlobal
to disk = 'C:\Programs\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\WWIGlobal.bak';

-- Log Backup
backup log[WWIGlobal] to disk = 'C:\Programs\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\WWIGlobal_norecovery.trn' 
with norecovery, no_truncate;

-- Backup Diferencial
backup log WWIGlobal
to disk = 'C:\Programs\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\transaction_back_001.trn'
with differential;