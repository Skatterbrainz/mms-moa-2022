# Terraform Lab Setup

## Edit terraform project files

  * main.tf (change the "job schedule" and "credential" parameters as desired)
  * variables.tf (change "default" values as desired)

## Install Terraform

1. Download Windows setup from Hashicorp, or...
2. Chocolatey: choco install terraform -y
3. Install Azure CLI: choco install azurecli -y

## Execute Terraform

1. Open PowerShell console
2. CD to terraform project folder
3. Run: az login (login to your tenant)
4. Run: terraform init
5. Run: terraform validate
6. Run: terraform plan -out:planfile
7. Run: terraform apply "planfile"

## Hybrid Worker

1. Log onto CM SMS Provider host (must have full admin rights to host)
2. Copy the "New-HybridWorkerSetup.ps1" script locally
3. Edit the script file (resource group, automation account, etc.)
4. Open PowerShell console (run as administrator)
5. Invoke the script
6. Allow 20-30 minutes for hybrid worker to show in Azure Automation portal
7. Install the [cmhealth](https://powershellgallery.com/packages/cmhealth/) PowerShell module

## Initial Testing

1. Locate the "Test-HybridWorker" runbook in Azure Automation
2. Click "Start"
3. Change "RunOn" to "Hybrid Worker"
4. Select the appropriate Hybrid Worker (e.g. "cm-lab")
5. Click the OK button
6. When the status changes from Running to Completed, click on "Output"
7. The return value should show the hostname of the hybrid worker

## Rollback

1. Run: terraform destroy (answer "yes" to confirmation)
2. Run: hybrid worker script on CM host with -Remove switch