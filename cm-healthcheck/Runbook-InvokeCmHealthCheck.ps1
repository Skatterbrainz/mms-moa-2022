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
	1.0.0.0 - 12/29/2021 - David Stein
	https://github.com/skatterbrainz/mms-moa-2022/cm-healthcheck
#>
[CmdletBinding()]
param (
	[parameter()][string]$CMHost = "cm01.contoso.local",
	[parameter()][string]$CMSiteCode = "P01",
	[parameter()][string]$SQLHost = "cm01.contoso.local",
	[parameter()][string]$DBName = "CM_P01"
)

$AutomationAccountName = "aa-cm-lab"
$ResourceGroupName = "rg-cm-lab"

try {
	if (-not(Get-Module cmhealth -ListAvailable)) {
		Install-Module -Name cmhealth -Scope CurrentUser -Force
	}
	if (-not (Get-Module cmhealth -ListAvailable)) {
		throw "Failed to install cmhealth module"
	}

	Import-Module -Name cmhealth
	$Credential = Get-AutomationPSCredential -Name 'On-Prem'

	$params = @{
		SiteServer = $CMHost
		SiteCode = $CMSiteCode
		SqlInstance = $SQLHost
		Database = $DBName
		TestingScope = "Host"
		NoVersionCheck = $True
	}

	$result = Test-CmHealth @params -ErrorAction Stop
	$hcresult = ($result | Where-Object {$_.Status -in ('Error','Fail')} | Select-Object Category,TestName,Status | ConvertTo-Json -Compress)
	$hcresult

	Set-AutomationVariable -Name 'LastHealthCheck' -Value "$(Get-Date -f 'yyyy-MM-dd hh:mm') EST"
	Set-AutomationVariable -Name 'LastHealthResult' -Value $hcresult

	$res = @{
		Status   = 'Success'
		Message  = "completed"
	}
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