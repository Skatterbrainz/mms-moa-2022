<#
.SYNOPSIS
	Install and configure Azure Automation Hybrid Worker
.DESCRIPTION
	Same as above :)
.PARAMETER ResourceGroupName
	Name of Azure Resource Group which contains Automation Account and Log Analytics Workspace
.PARAMETER AutomationAccountName
	Name of Azure Automation Account
.PARAMETER WorkspaceName
	Name of Log Analytics Workspace
.NOTES
	1.0.0.0 - 12/29/2021 - David Stein
	https://github.com/skatterbrainz/mms-moa-2022/cm-healthcheck
#>
[CmdletBinding()]
param (
	[parameter(Mandatory=$False)][string]$ResourceGroupName = "rg-cm-lab",
	[parameter(Mandatory=$False)][string]$AutomationAccountName = "aa-cm-lab",
	[parameter(Mandatory=$False)][string]$WorkspaceName = "ws-cm-lab"
)

try {
	$azconn = Connect-AzAccount
	if (!$azconn) { 
		throw "Authentication was not successful"
	}
	$SubscriptionId = $azconn.Context.Subscription.Id
	if (-not (Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue)) {
		throw "Resource Group not found: $ResourceGroupName"
	} else {
		$rg = Get-AzResourceGroup -Name $ResourceGroupName
		$Location = $rg.Location
		Write-Host "Resource Group verified: $ResourceGroupName" -ForegroundColor Cyan
	}
	if (-not (Get-InstalledScript -Name New-OnPremiseHybridWorker -ErrorAction SilentlyContinue)) {
		Write-Host "Installing script from powershell gallery" -ForegroundColor Cyan
		Install-Script -Name New-OnPremiseHybridWorker
	} else {
		Write-Host "Script is already installed" -ForegroundColor Green
	}

	$NewOnPremiseHybridWorkerParameters = @{
		HybridGroupName       = "hw-cm-lab"
		AutomationAccountName = $AutomationAccountName
		AAResourceGroupName   = $ResourceGroupName
		OMSResourceGroupName  = $ResourceGroupName
		SubscriptionID        = $SubscriptionId
		WorkspaceName         = $WorkspaceName
	}
	
	New-OnPremiseHybridWorker.ps1 @NewOnPremiseHybridWorkerParameters
	
	Write-Host "Completed successfully!" -ForegroundColor Green
}
catch {
	Write-Error $_.Exception.Message
}
