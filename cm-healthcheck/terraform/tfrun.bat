@echo off
cls
cd c:\git\mms-moa-2022\cm-healthcheck\terraform
echo Edit the main.tf schedule date as needed...
pause
echo Open a browser to the target Azure tenant...
pause
echo Authenticating to Azure tenant
az login
echo Initializing terraform project
terraform init
pause
echo Validating terraform project
terraform validate
pause
echo Building a terraform project plan
terraform plan -out=planfile
pause
echo Applying the terraform project plan
terraform apply "planfile"
echo Switch to Azure to monitor progress
rem terraform destroy