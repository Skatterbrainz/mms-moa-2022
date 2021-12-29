#requires -Modules Az.Accounts,Az.Automation,Az.OperationalInsights
<#
.SYNOPSIS
	Demo Lab setup script
.DESCRIPTION
	Demo lab setup script for Azure Automation
.NOTES
	1.0.0.0 - 12/29/2021 - David Stein
	https://github.com/skatterbrainz/mms-moa-2022/cm-healthcheck
#>
[CmdletBinding()]
param (
	[parameter(Mandatory=$False)][string]$ResourceGroupName = "rg-cm-lab",
	[parameter(Mandatory=$False)][string]$AutomationAccountName = "aa-cm-lab",
	[parameter(Mandatory=$False)][string]$WorkspaceName = "ws-cm-lab",
	[parameter(Mandatory=$False)][string]$Location = "East US",
	[parameter(Mandatory=$False)][string]$Tags = "@{ServiceType='ConfigMgr';Environment='Lab';Operation='Hybrid'}",
	[parameter(Mandatory=$False)][switch]$ResetDemoEnvironment
)

try {
	if (-not $azconn) { $azconn = Connect-AzAccount }
	if (-not $azconn) { throw "authentication not completed" }

	if (-not [string]::IsNullOrEmpty($Tags)) {
		$TagSet = Invoke-Expression $Tags
	}
	# Create Resource Group

	$params = @{
		Name = $ResourceGroupName
		Location = $Location
	}

	if (-not (Get-AzResourceGroup @params -ErrorAction SilentlyContinue)) {
		Write-Host "creating resource group: $($params.Name)" -ForegroundColor Cyan
		$params.Add("Tag", $TagSet)
		New-AzResourceGroup @params
	} else {
		Write-Host "resource group exists: $($params.Name)" -ForegroundColor Green
		if ($ResetDemoEnvironment -eq $True) {
			Write-Warning "removing entire demo lab!"
			Get-AzResourceGroup -Name $ResourceGroupName | Remove-AzResourceGroup -Force 
			Write-Host "allow time for resources to be removed before running setup again" -ForegroundColor Yellow
			return "completed"
		}
	}

	# Create Automation Account

	$params = @{
		Name = $AutomationAccountName
		ResourceGroupName = $ResourceGroupName
		Location = $Location
		AssignSystemIdentity = $True
		Tags = $TagSet
	}

	if (-not (Get-AzAutomationAccount -Name $params.Name -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue)) {
		Write-host "creating automation account: $($params.Name)" -ForegroundColor Cyan
		New-AzAutomationAccount @params
	} else {
		Write-host "automation account exists: $($params.Name)" -ForegroundColor Green
	}

	# Create Log Analytics Workspace

	if ($Location -eq "East US") {
		$WSLocation = "East US 2"
	} elseif ($Location -eq "East US 2") {
		$WSLocation = "East US"
	} else {
		$WSLocation = $Location
	}

	$params = @{
		ResourceGroupName = $ResourceGroupName
		Name = $WorkspaceName
		Location = $WSLocation
		Tag = $TagSet
	}

	if (-not (Get-AzOperationalInsightsWorkspace -Name $params.Name -ResourceGroupName $params.ResourceGroupName -ErrorAction SilentlyContinue)) {
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

	if (-not (Get-AzAutomationVariable -Name $params.Name -ResourceGroupName $params.ResourceGroupName -AutomationAccountName $params.AutomationAccountName -ErrorAction SilentlyContinue)) {
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

	if (-not (Get-AzAutomationVariable -Name $params.Name -ResourceGroupName $params.ResourceGroupName -AutomationAccountName $params.AutomationAccountName -ErrorAction SilentlyContinue)) {
		Write-host "creating variable: $($params.Name)" -ForegroundColor Cyan
		New-AzAutomationVariable @params
	} else {
		Write-Host "variable exists: $($params.Name)" -ForegroundColor Green
	}

	$runbooks = ("Runbook-InvokeCmHealthCheck.ps1","Runbook-TestHybridWorker.ps1")
	foreach ($runbook in $runbooks) {
		$params = @{
			Path = ".\$($runbook)"
			ResourceGroup = $ResourceGroupName
			AutomationAccountName = $AutomationAccountName
			Type = "PowerShell"
			Tags = $Tags
			Published = $True
		}
		$runbookName = $(Get-Item $params.Path -ErrorAction Stop | Select-Object -ExpandProperty BaseName)	
		if (-not (Get-AzAutomationRunbook -Name $runbookName -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue)) {
			Write-host "importing runbook: $runbookName" -ForegroundColor Cyan
			Import-AzAutomationRunbook @params
		} else {
			Write-Host "runbook exists: $runbookName" -ForegroundColor Green
		}
	}
	
	$params = @{
		Name = "hw-cm-lab"
		ResourceGroupName = $ResourceGroupName
		AutomationAccountName = $AutomationAccountName
	}
	
	if (-not (Get-AzAutomationHybridWorkerGroup @params -ErrorAction SilentlyContinue)) {
		Write-Host "creating hw group: $($params.Name)" -ForegroundColor Cyan
		$hwg = New-AzAutomationHybridWorkerGroup @params
		$hwg | select *
	} else {
		Write-Host "hw group exists: $($params.Name)" -ForegroundColor Green
	}
	
	Write-Host "Azure lab environment setup completed!" -ForegroundColor Green
}
catch {
	if ($_.Exception.Message -like "Cannot find path*") {
		Write-Warning "runbook source file not found! $($params.Path)"
	} else {
		Write-Error $_.Exception.Message
	}
}
