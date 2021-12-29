[CmdletBinding()]
param()

$ResourceGroupName = "rg-cm-lab"
$AutomationAccountName = "aa-cm-lab"
$Location = "East US"
$WSName = "ws-cm-lab"
$SubscriptionId = "86c94f9c-af2f-4193-9b58-aeb65f052494"

if (!(Get-InstalledScript -Name New-OnPremiseHybridWorker -ErrorAction SilentlyContinue)) {
	Write-Host "installing script from powershell gallery" -ForegroundColor Cyan
	Install-Script -Name New-OnPremiseHybridWorker
} else {
	Write-Host "script is already installed" -ForegroundColor Green
}

$NewOnPremiseHybridWorkerParameters = @{
	HybridGroupName       = "hw-cm-lab"
	AutomationAccountName = $AutomationAccountName
	AAResourceGroupName   = $ResourceGroupName
	OMSResourceGroupName  = $ResourceGroupName
	SubscriptionID        = $SubscriptionId
	WorkspaceName         = $WSName
}

New-OnPremiseHybridWorker.ps1 @NewOnPremiseHybridWorkerParameters
