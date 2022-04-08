# Terraform Lab Setup

## Edit terraform project files

  * main.tf (change the "job schedule" and "credential" parameters as desired)
  * variables.tf (change "default" values as desired)

## Install Terraform

  * Download Windows setup from Hashicorp, or...
  * Chocolatey: choco install terraform -y

## Execute Terraform

  * Open PowerShell console
  * CD to terraform project folder
  * Run: az login (login to your tenant)
  * Run: terraform init
  * Run: terraform validate
  * Run: terraform plan -out:planfile
  * Run: terraform apply "planfile"

## Hybrid Worker

  * Log onto CM SMS Provider host
  * Copy the "New-HybridWorkerSetup.ps1" script locally
  * Edit the script file (resource group, automation account, etc.)
  * Open PowerShell console (run as administrator)
  * Invoke the script
  * Allow 20-30 minutes for hybrid worker to show in Azure Automation portal

## Rollback

  * Run: terraform destroy (answer "yes" to confirmation)
  * Run hybrid worker script on CM host with -Remove switch