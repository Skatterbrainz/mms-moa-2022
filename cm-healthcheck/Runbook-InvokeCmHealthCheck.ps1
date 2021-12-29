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
#>
[CmdletBinding()]
param (
	[parameter()][string]$CMHost = "cm01.contoso.local",
	[parameter()][string]$CMSiteCode = "P01",
	[parameter()][string]$SQLHost = "cm01.contoso.local",
	[parameter()][string]$DBName = "CM_P01"
)

if (-not(Get-Module cmhealth -ListAvailable)) {
	Install-Module -Name cmhealth -Scope CurrentUser -Force
}
if (-not (Get-Module cmhealth -ListAvailable)) {
	Write-Output "ERROR: Failed to install cmhealth module"
	break
}
Import-Module -Name cmhealth

$params = @{
	SiteServer = $CMHost
	SiteCode = $CMSiteCode
	SqlInstance = $SQLHost
	Database = $DBName
	TestingScope = "All"
}

$result = Test-CmHealth  @params

$params = @{
	Name = "LastHealthCheck"
	Value = "$(Get-Date -f 'yyyy-MM-dd hh:mm')"
	AutomationAccountName = $AutomationAccountName
	ResourceGroupName = $ResourceGroupName
	Encrypted = $False
}
Set-AzAutomationVariable @params