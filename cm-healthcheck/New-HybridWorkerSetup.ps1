<#
.SYNOPSIS
	Install and configure Azure Automation Hybrid Worker
.DESCRIPTION
	Same as above :) This script should be run AFTER the New-LabSetup.ps1 script has been
	completed successfully.
.PARAMETER GroupName
	Name of new hybrid worker group
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
	[parameter(Mandatory=$False)][string]$GroupName = "cm-lab",
	[parameter(Mandatory=$False)][string]$ResourceGroupName = "cmhealth",
	[parameter(Mandatory=$False)][string]$AutomationAccountName = "cmhealth",
	[parameter(Mandatory=$False)][string]$WorkspaceName = "cmhealth",
	[parameter(Mandatory=$False)][switch]$Remove
)

$regkey = 'HKLM:\SOFTWARE\Microsoft\HybridRunbookWorker'

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

	$params = @{
		HybridGroupName       = $GroupName
		AutomationAccountName = $AutomationAccountName
		AAResourceGroupName   = $ResourceGroupName
		OMSResourceGroupName  = $ResourceGroupName
		SubscriptionID        = $SubscriptionId
		WorkspaceName         = $WorkspaceName
	}
	
	if ($Remove -eq $True) {
		if (Get-Item -Path $RegKey -ErrorAction SilentlyContinue) {
			Write-Verbose "Removing registry key: $RegKey"
			Remove-Item -Path $RegKey -Recurse -Force | Out-Null
		} else {
			Write-Verbose "Registry key not found: $RegKey"
		}
		if (Get-Service HealthService -ErrorAction SilentlyContinue) {
			try {
				Write-Verbose "Restarting HealthService service"
				Get-Service HealthService -ErrorAction Stop | Stop-Service -Force
				Remove-Item -Path 'C:\Program Files\Microsoft Monitoring Agent\Agent\Health Service State' -Recurse
				Start-Service -Name HealthService
			}
			catch {
				$_
			}
		} else {
			Write-Verbose "HealthService was not found"
		}
		Write-Host "Monitoring Agent service has been restarted. Rerun Add-HybridRunbookWorker cmdlet again"
	} else {
		Write-Host "Creating hybrid worker account" -ForegroundColor Cyan
		New-OnPremiseHybridWorker.ps1 @params
		Write-Host "Completed successfully!" -ForegroundColor Green
	}
}
catch {
	Write-Error $_.Exception.Message
}
