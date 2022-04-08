<#
.SYNOPSIS
	Invoke a CMHealth health check on primary site server
.DESCRIPTION
	Invoke a health check on configuration manager primary site server
	and save results to automation account variable (for demo purposes only)
.PARAMETER CMHost
	Name of primary site server
.PARAMETER CMSiteCode
	ConfigMgr site code
.PARAMETER SQLHost
	Name of SQL instance or host server
.PARAMETER DBName
	Database name for ConfigMgr site
.NOTES
	1.0.0.4 - 2022-04-07 - David Stein
	https://github.com/skatterbrainz/mms-moa-2022/cm-healthcheck
#>
[CmdletBinding()]
[OutputType()]
param (
	[parameter()][string]$Scope = "All"
)

#$AutomationAccountName = Set-AutomationVariable -Name 'AA-Name'
#$ResourceGroupName     = Set-AutomationVariable -Name 'RG-Name'
$CMHost     = Set-AutomationVariable -Name 'CM-HostName'
$CMSiteCode = Set-AutomationVariable -Name 'CM-SiteCode'
$SQLHost    = Set-AutomationVariable -Name 'CM-SQLInstance'
$DBName     = Set-AutomationVariable -Name 'CM-Database'
$Credential = Get-AutomationPSCredential -Name 'Automation-CMInstaller'

try {
	if (-not(Get-Module cmhealth -ListAvailable)) {
		Install-Module -Name cmhealth -Scope CurrentUser -Force
	}
	if (-not (Get-Module cmhealth -ListAvailable)) {
		throw "Failed to install cmhealth module"
	}

	Import-Module -Name cmhealth

	$params = @{
		SiteServer = $CMHost
		SiteCode = $CMSiteCode
		SqlInstance = $SQLHost
		Database = $DBName
		TestingScope = $Scope
		NoVersionCheck = $True
		Credential = $Credential
	}

	$result = Test-CmHealth @params -ErrorAction Stop
	$hcresult = ($result | Where-Object {$_.Status -in ('Error','Fail')} | Select-Object Category,TestName,Status | ConvertTo-Json -Compress)
	#$hcresult

	Set-AutomationVariable -Name 'LastHealthCheck' -Value "$(Get-Date -f 'yyyy-MM-dd hh:mm') EST"
	Set-AutomationVariable -Name 'LastHealthResult' -Value $hcresult

	$res = @{
		Status   = 'Success'
		Message  = "completed"
	}
	$res = $result | Select-Object Computer,Category,TestGroup,TestName,Status,Description,Message,RunTime | ConvertTo-Json
}
catch {
	$res = @{
		Status   = 'Error'
		Message  = $($_.Exception.Message -join(';'))
		Activity = $($_.CategoryInfo.Activity -join(";"))
		Trace    = $($_.ScriptStackTrace -join(";"))
		RunAs    = $($env:USERNAME)
		RunOn    = $($env:COMPUTERNAME)
	}
}
finally {
	$res
}