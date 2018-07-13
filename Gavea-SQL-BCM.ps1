<#
.Synopsis
   Gavea scripts to change Azure VM SQL server and SQL Agent/permission
.DESCRIPTION
   This script will:
   1- Update/change MSSQLSERVER/MSSQLAGENT Windows service account (restart SQL and Agent services)
   2- Add local\Administrators group as sa (restart SQL and Agent services)
   3- Run sql-cmd tempdb.sql for details (restart SQL and Agent services)
.EXAMPLE
   powershell -ExecutionPolicy Unrestricted -File Gavea-SQL-BCM.ps1 -UName "Domain\user" -PWord "P@ssw0rd!" -artifactsLocation "https://raw.githubusercontent.com/d13g0s0uz4/Gavea-DR-SQL/master" -artifactsLocationSasToken "" -folderName "." -fileToInstall "Gavea-sqlscript.sql"
.INPUTS
   -UName "Domain\user" -PWord "P@ssw0rd!"
.OUTPUTS
   NONE
.NOTES
   Source https://dba.stackexchange.com/questions/22006/how-to-change-sql-server-service-account-using-ps
.FUNCTIONALITY
   Update MSSQLSERVER and SQLSERVERAGENT Windows services accounts
#>



Param (
    [string]$UName,
    [string]$PWord,
    [string]$artifactsLocation = "https://raw.githubusercontent.com/d13g0s0uz4/Gavea-DR-SQL/master"

)

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement") | out-null
$ErrorActionPreference="continue"

$Server = $env:COMPUTERNAME #Enter the name of SQL Server Instance
New-Item -Path "C:\WindowsAzure\Logs\Gavea-SQL-BCM" -ItemType directory | Out-Null
function log($string, $color)
{
if ($Color -eq $null) {$color = "white"}
#cd C:\WindowsAzure\Logs
#$Loc = Get-Location
$Date = Get-Date -format yyyyMMdd
$logfile = "C:\WindowsAzure\Logs\Gavea-SQL-BCM\log" + $Date + ".txt"

write-host $string -foregroundcolor $color
$temp = ": " + $string
$string = Get-Date -format "yyyy.MM.dd hh:mm:ss tt"
$string += $temp
$string | out-file -Filepath $logfile -append
}
function changesvcaccount {
    log "Starting Function 'changesvcaccount' to change Windows Services MSSQLSERVER and SQLSERVERAGENT service accounts" red
    $SMOWmiserver = New-Object ('Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer') $Server #Suck in the server you want
    #These just act as some queries about the SQL Services on the machine you specified.
    #$SMOWmiserver.Services | select name, type, ServiceAccount, DisplayName, Properties, StartMode, StartupParameters | Format-Table
    #Same information just pivot the data
    #$SMOWmiserver.Services | select name, type, ServiceAccount, DisplayName, Properties, StartMode, StartupParameters | Format-List

    #Specify the "Name" (from the query above) of the one service whose Service Account you want to change.
    log "Preparing to change MSSQLSERVER service account" green
    $ChangeService1=$SMOWmiserver.Services | where {$_.name -eq "MSSQLSERVER"} #Make sure this is what you want changed!
    log "Preparing to change SQLSERVERAGENT service account" green
    $ChangeService2=$SMOWmiserver.Services | where {$_.name -eq "SQLSERVERAGENT"} #Make sure this is what you want changed!

    #Check which service you have loaded first
    #$ChangeService1
    #$ChangeService2

    #change services accounts
    log "Changing MSSQLSERVER service account" green
    $ChangeService1.SetServiceAccount($UName, $PWord)
    log "Changing SQLSERVERAGENT service account" green
    $ChangeService2.SetServiceAccount($UName, $PWord)

    #set startup auto
    log "Changing MSSQLSERVER service startup" green
    Set-Service -name MSSQLSERVER -StartupType Automatic
    log "Changing SQLSERVERAGENT service startup" green
    Set-Service -name SQLSERVERAGENT -StartupType Automatic

    #ReStart services
    log "Restarting MSSQLSERVER service" green
    ReStart-Service MSSQLSERVER -Force
    log "Restarting MSSQLSERVER service" green
    ReStart-Service SQLSERVERAGENT -Force

    log "Finished function Function 'changesvcaccount'" red
}


function addlocaladministrators {
    log "Starting Function 'addlocaladministrators' to add LOCALHOST\ADMINISTRATORS as MSSQL sa" red
    log "Stopping SQLSERVERAGENT service" green
    Stop-Service SQLSERVERAGENT -Force
    log "Stopping MSSQLSERVER service" green
    Stop-Service MSSQLSERVER -Force
    #NET STOP $ServiceName 
    log "Starting MSSQLSERVER /mSQLCMD" green
    NET START MSSQLSERVER /mSQLCMD 
    #Start-Service MSSQLSERVER /mSQLCMD
    log "Running SQLCMD to add Administrators as sysadmin" green
    SQLCMD -S $Server -Q "if not exists(select * from sys.server_principals where name='BUILTIN\administrators') CREATE LOGIN [BUILTIN\administrators] FROM WINDOWS;EXEC master..sp_addsrvrolemember @loginame = N'BUILTIN\administrators', @rolename = N'sysadmin'"
    log "Restarting MSSQLSERVER service" green
    Restart-Service MSSQLSERVER -Force
    log "Starting SQLSERVERAGENT service" green
    Start-Service SQLSERVERAGENT

    $execute = SQLCMD -S $Server -Q "if exists( select * from fn_my_permissions(NULL, 'SERVER') where permission_name = 'CONTROL SERVER') print 'You are a sysadmin.'" 
    log($execute, red)

}

function downloadscript {
    $fileToInstall = "Gavea-sqlscript.sql"
    $source = $artifactsLocation + "/" + $fileToInstall
    $dest = "C:\WindowsAzure\sqlscript"
    New-Item -Path $dest -ItemType directory
    Invoke-WebRequest $source -OutFile "$dest\$fileToInstall"
}
function runsqlscript {
    log "Starting Function 'runsqlscript' to move TEMPDB data and log files to new location" red
    log "Stopping SQLSERVERAGENT service" green
    Stop-Service SQLSERVERAGENT -Force
    log "Stopping MSSQLSERVER service" green
    Stop-Service MSSQLSERVER -Force
    log "Creating folder F:\TempDB\" green
    New-Item -Path "F:\TempDB\" -ItemType directory | Out-Null
    log "Starting MSSQLSERVER /mSQLCMD" green
    NET START MSSQLSERVER /mSQLCMD 
    #Start-Service MSSQLSERVER /mSQLCMD
    log 'starting sql script SQLCMD -S $Server -i C:\WindowsAzure\sqlscript\Gavea-sqlscript.sql -o C:\WindowsAzure\sqlscript\Gavea-sqlscript.rpt' green
    SQLCMD -S $Server -i C:\WindowsAzure\sqlscript\Gavea-sqlscript.sql -o C:\WindowsAzure\sqlscript\Gavea-sqlscript.rpt
    log(cat C:\WindowsAzure\sqlscript\Gavea-sqlscript.rpt)
    log "Restaring SQL Service to apply new tempdb location.." green
    Restart-Service MSSQLSERVER -Force
    log "Starting SQLSERVERAGENT service" green
    Start-Service SQLSERVERAGENT
}

downloadscript
changesvcaccount
addlocaladministrators
runsqlscript
log "Finished Gavea-SQL-BCM script" red