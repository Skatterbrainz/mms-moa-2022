terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.1"
    }
  }
  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resgroup
  location = var.location
  tags = {
    environment = var.environment
    created_by  = var.creator
    project     = var.project
  }
}

// ----------------- Automation Account -------------------------
// https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_account

resource "azurerm_automation_account" "aa" {
  name                = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Basic"
  tags = {
    environment = var.environment
    type        = "automation"
    created_by  = var.creator
    project     = var.project
  }
}

// ---------------------- Credential -------------------------
// https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_credential

resource "azurerm_automation_credential" "ac" {
  name                    = "Automation-CMInstaller"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.aa.name
  username                = "contoso\\cm-install"
  password                = "Xx09340934$$"
  description             = "On-prem service account"
}

// ------------------------ Runbooks --------------------------
// https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_runbook

data "local_file" "rbf1" {
  filename = "${path.module}/runbooks/Runbook-InvokeCmHealthCheck.ps1"
}

data "local_file" "rbf2" {
  filename = "${path.module}/runbooks/Test-HybridWorker.ps1"
}

resource "azurerm_automation_runbook" "rb1" {
  name                    = "Invoke-CmHealthCheck"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.aa.name
  log_verbose             = "false"
  log_progress            = "false"
  description             = "Run CM health check"
  runbook_type            = "PowerShell"
  content                 = data.local_file.rbf1.content
  tags = {
    environment = var.environment
    runon       = "hybridworker"
    createdby   = var.creator
    project     = var.project
  }
}

resource "azurerm_automation_runbook" "rb2" {
  name                    = "Test-HybridWorker"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.aa.name
  log_verbose             = "false"
  log_progress            = "false"
  description             = "Test Hybrid Worker"
  runbook_type            = "PowerShell"
  content                 = data.local_file.rbf2.content
  tags = {
    environment = var.environment
    runon       = "hybridworker"
    createdby   = var.creator
    project     = var.project
  }
}

// ------------------------ Job Schedule -------------------------
// https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_schedule

resource "azurerm_automation_schedule" "sch1" {
  name                    = "fridays-7am-et"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.aa.name
  frequency               = "Week"
  interval                = 1
  timezone                = "America/New_York"
  start_time              = "2022-04-08T07:00:00-04:00"
  description             = "Runs every Friday at 7:00 AM EST"
  week_days               = ["Friday"]
}

// ----------------------- Variables --------------------------
// https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_variable_string

resource "azurerm_automation_variable_string" "var1" {
  name                    = "LastHealthCheck"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.aa.name
  value                   = "NEVER"
  encrypted               = "false"
  description             = "Last CM Health Check completion date"
}

resource "azurerm_automation_variable_string" "var2" {
  name                    = "LastHealthResult"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.aa.name
  value                   = "PENDING"
  encrypted               = "false"
  description             = "Last CM Health Check result"
}

resource "azurerm_automation_variable_string" "var3" {
  name                    = "CM-HostName"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.aa.name
  value                   = "cm01.contoso.local"
  encrypted               = "true"
  description             = "CM SMS Provider host"
}

resource "azurerm_automation_variable_string" "var4" {
  name                    = "CM-SiteCode"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.aa.name
  value                   = "P01"
  encrypted               = "true"
  description             = "CM site code"
}

resource "azurerm_automation_variable_string" "var5" {
  name                    = "CM-Database"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.aa.name
  value                   = "CM_P01"
  encrypted               = "true"
  description             = "CM site database name"
}

resource "azurerm_automation_variable_string" "var6" {
  name                    = "CM-SQLInstance"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.aa.name
  value                   = "cm01.contoso.local"
  encrypted               = "true"
  description             = "CM site database hostname"
}

resource "azurerm_automation_variable_string" "var7" {
  name                    = "AA-Name"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.aa.name
  value                   = azurerm_automation_account.aa.name
  encrypted               = "true"
  description             = "Automation Account Name"
}

resource "azurerm_automation_variable_string" "var8" {
  name                    = "RG-Name"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.aa.name
  value                   = azurerm_resource_group.rg.name
  encrypted               = "true"
  description             = "Resource Group Name"
}

// ------------------- Log Analytics Workspace -----------------------
// https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace

resource "azurerm_log_analytics_workspace" "ws1" {
  name                = var.project
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags = {
    environment = var.environment
    type        = "logs"
    created_by  = var.creator
    project     = var.project
  }
}

// --------------------- Link to Automation Account ----------------------
// https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_linked_service

resource "azurerm_log_analytics_linked_service" "lnk1" {
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id        = azurerm_log_analytics_workspace.ws1.id
  read_access_id      = azurerm_automation_account.aa.id
}

resource "azurerm_monitor_diagnostic_setting" "diag1" {
  name               = "CM Health Checks"
  target_resource_id = azurerm_automation_account.aa.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.ws1.id
  log {
    category = "JobStreams" # "AuditEvent"
    enabled  = true
    retention_policy {
      enabled = false
    }
  }
  metric {
    category = "AllMetrics"
    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_log_analytics_saved_search" "laquery" {
  name                       = "CM Health Check"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.ws1.id
  category     = "IT & Management Tools"
  display_name = "CM Health Check"
  query        = <<EOT
AzureDiagnostics 
| where Category == "JobStreams" and ResultDescription startswith "Computer"
| where ResultDescription contains "Status      : FAIL"
| sort by TimeGenerated
| project TimeGenerated, ResultDescription
| parse-where ResultDescription with * "Computer    :" Computer "\n" *
| parse-where ResultDescription with * "Category    :" Category "\n" *
| parse-where ResultDescription with * "TestGroup   :" TestGroup "\n" *
| parse-where ResultDescription with * "TestName    :" TestName "\n" *
| parse-where ResultDescription with * "Status      :" Status "\n" *
| parse-where ResultDescription with * "Description :" Description "\n" *
| parse-where ResultDescription with * "Message     :" Message "\n" *
| parse-where ResultDescription with * "RunTime     :" RunTime "\n" *
| project TimeGenerated,Computer,Category,TestGroup,TestName,Status,Message,Description,RunTime
EOT
}