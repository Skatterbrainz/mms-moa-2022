# MMS MOA 2022 Session

## Title: Automate ConfigMgr Health Checks with Azure Automation

## Demo Setup

Refer to the [ReadMe]() file in the Terraform sub-folder

### ConfigMgr Setup

1. Log onto ConfigMgr primary server as administrator
2. Copy _New-HybridWorkerSetup.ps1_ to local computer
3. Open PowerShell console as Administrator
4. Edit/Save _New-HybridWorkerSetup.ps1_ to suit your environment
5. Run _New-HybridWorkerSetup.ps1_
6. Install the [cmhealth](https://powershellgallery.com/packages/cmhealth/) PowerShell module

### Test Runbook

1. Log into the Azure portal
2. Navigate to __Automation Accounts__ / __aa-cm-lab__
3. Select __Runbooks__
4. Select runbook __Runbook-TestHybridWorker__
5. Click __Start__
6. Select Run on = _Hybrid Worker_
7. Make sure _hw-cm-lab_ is selected, and click __OK__
8. When Status changes to "Completed" select "Output"
9. Verify the NetBIOS hostname is displayed (e.g. "CM01")
