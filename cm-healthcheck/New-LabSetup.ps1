#requires -Modules Az.Accounts,Az.Automation,Az.OperationalInsights
<#
.SYNOPSIS
	Demo Lab setup script
.DESCRIPTION
	Demo lab setup script for Azure Automation
.NOTES
	1.0.0.0 - 12/29/2021 - David Stein
#>
[CmdletBinding()]
param()

if (!$azconn) { $azconn = Connect-AzAccount }
if (!$azconn) { break }

$ResetDemoEnvironment = $False
$ResourceGroupName = "rg-cm-lab"
$AutomationAccountName = "aa-cm-lab"
$Location = "East US"
if ($Location -eq "East US") {
	$WSLocation = "East US 2"
} elseif ($Location -eq "East US 2") {
	$WSLocation = "East US"
} else {
	$WSLocation = $Location
}
$WSName = "ws-cm-lab"
$Tags = @{serviceType="configmgr"; environment="lab"; operation="hybrid"}

# Create Resource Group

$params = @{
	Name = $ResourceGroupName
	Location = $Location
}

if (!(Get-AzResourceGroup @params -ErrorAction SilentlyContinue)) {
	Write-Host "creating resource group: $($params.Name)" -ForegroundColor Cyan
	New-AzResourceGroup @params
} else {
	Write-Host "resource group exists: $($params.Name)" -ForegroundColor Green
	if ($ResetDemoEnvironment -eq $True) {
		Write-Warning "removing entire demo lab!"
		Get-AzResourceGroup @params | Remove-AzResourceGroup -Force 
		Write-Host "allow time for resources to be removed before running setup again" -ForegroundColor Yellow
		break
	}
}

# Create Automation Account

$params = @{
	Name = $AutomationAccountName
	ResourceGroupName = $ResourceGroupName
	Location = $Location
	AssignSystemIdentity = $True
	Tags = $Tags
}

if (!(Get-AzAutomationAccount -Name $params.Name -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue)) {
	Write-host "creating automation account: $($params.Name)" -ForegroundColor Cyan
	New-AzAutomationAccount @params
} else {
	Write-host "automation account exists: $($params.Name)" -ForegroundColor Green
}

# Create Log Analytics Workspace

$params = @{
	ResourceGroupName = $ResourceGroupName
	Name = $WSName
	Location = $WSLocation
}

if (!(Get-AzOperationalInsightsWorkspace -Name $params.Name -ResourceGroupName $params.ResourceGroupName -ErrorAction SilentlyContinue)) {
	Write-host "creating workspace: $($params.Name)" -ForegroundColor Cyan
	New-AzOperationalInsightsWorkspace @params
} else {
	Write-host "workspace exists: $($params.Name)" -ForegroundColor Green
}

# Create Automation Account Variables

$params = @{
	Name = "LastHealthResult"
	Encrypted = $False
	Value = "PENDING"
	AutomationAccountName = $AutomationAccountName
	ResourceGroupName = $ResourceGroupName
}

if (!(Get-AzAutomationVariable -Name $params.Name -ResourceGroupName $params.ResourceGroupName -AutomationAccountName $params.AutomationAccountName -ErrorAction SilentlyContinue)) {
	Write-host "creating variable: $($params.Name)" -ForegroundColor Cyan
	New-AzAutomationVariable @params
} else {
	Write-Host "variable exists: $($params.Name)" -ForegroundColor Green
}

$params = @{
	Name = "LastHealthCheck"
	Encrypted = $False
	Value = "PENDING"
	AutomationAccountName = $AutomationAccountName
	ResourceGroupName = $ResourceGroupName
}

if (!(Get-AzAutomationVariable -Name $params.Name -ResourceGroupName $params.ResourceGroupName -AutomationAccountName $params.AutomationAccountName -ErrorAction SilentlyContinue)) {
	Write-host "creating variable: $($params.Name)" -ForegroundColor Cyan
	New-AzAutomationVariable @params
} else {
	Write-Host "variable exists: $($params.Name)" -ForegroundColor Green
}

# Create (Import) Runbook

$params = @{
	Path = ".\Runbook-InvokeCmHealthCheck.ps1"
	ResourceGroup = $ResourceGroupName
	AutomationAccountName = $AutomationAccountName
	Type = "PowerShell"
	Description = "Run ConfigMgr Health Check"
	Tags = $Tags
	Published = $True
}

try {
	$runbookName = $(Get-Item $params.Path -ErrorAction Stop | Select-Object -ExpandProperty BaseName)
	if (!(Get-AzAutomationRunbook -Name $runbookName -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue)) {
		Write-host "importing runbook: $runbookName" -ForegroundColor Cyan
		Import-AzAutomationRunbook @params
	} else {
		Write-Host "runbook exists: $runbookName" -ForegroundColor Green
	}
	$go = $true
}
catch {
	if ($_.Exception.Message -like "Cannot find path*") {
		Write-Warning "runbook source file not found! $($params.Path)"
	} else {
		Write-Error $_.Exception.Message
	}
}

if (!$go) { break }
# Create Hybrid Worker Group

$params = @{
	Name = "hw-cm-lab"
	ResourceGroupName = $ResourceGroupName
	AutomationAccountName = $AutomationAccountName
}

if (!(Get-AzAutomationHybridWorkerGroup @params -ErrorAction SilentlyContinue)) {
	Write-Host "creating hw group: $($params.Name)" -ForegroundColor Cyan
	$hwg = New-AzAutomationHybridWorkerGroup @params
	$hwg | select *
} else {
	Write-Host "hw group exists: $($params.Name)" -ForegroundColor Green
}

<#
$params = @{
	ResourceGroupName = $ResourceGroupName 
	WorkspaceName = $WSName 
	IntelligencePackName = "AzureAutomation" 
	Enabled = $true
}
Set-AzOperationalInsightsIntelligencePack @params
#>