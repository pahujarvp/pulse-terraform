# Azure Monitor & Observability Architecture: Project Pulse

**Document Version:** 1.0.0  
**Status:** Architecture Baseline & Gap Specification  
**Environment:** `dev` (`Central India`)  
**Scope:** Azure Monitor, Metric Alerts, Action Groups, Logic Apps, Log Analytics, Diagnostics, and Dashboards  

---

## 1. Overview & Objectives

This document details the **Observability and Monitoring Architecture** for the Pulse infrastructure. It delineates:
1. **The Current Implementation** as deployed via the Terraform codebase.
2. **The End-to-End Alerting & Notification Workflow**.
3. **The Observability Gap Analysis** (Log Analytics, Diagnostic Settings, Dashboards, and Agent telemetry).
4. **Target Enterprise Observability Blueprint** with implementation specifications.

---

## 2. Current Implementation in Terraform Code

The Terraform configuration currently provisions telemetry and alerting primitives in `rg-pulse-monitor-01`:

```mermaid
flowchart TD
    subgraph Workload_RG["rg-pulse-workload-01"]
        VM["Linux Virtual Machine<br/>(vm-pulse-linux-01)"]
    end

    subgraph Monitoring_RG["rg-pulse-monitor-01"]
        subgraph Alert_Engine["Azure Monitor Metric Engine"]
            RULE["azurerm_monitor_metric_alert<br/>(alert-pulse)"]
            RULE_SPECS["Criteria: Percentage CPU > 40%<br/>Aggregation: Average<br/>Window: PT5M / Frequency: PT1M<br/>Auto-Mitigate: True"]
            RULE --- RULE_SPECS
        end

        subgraph Notification_Plane["Action Groups"]
            AG_EMAIL["azurerm_monitor_action_group<br/>(ag-pulse-email-alert)<br/>Short Name: email"]
            AG_ITIL["azurerm_monitor_action_group<br/>(ag-pulse-itil-alert)<br/>Short Name: itil"]
        end

        subgraph Automation_Plane["Serverless Workflows"]
            LOGIC["azurerm_logic_app_workflow<br/>(logic-app-pulse-01)<br/>State: Enabled"]
        end
    end

    VM -->|Host Metric Stream| RULE
    RULE -->|Action Binding: action_group_id| AG_ITIL
    AG_ITIL -.->|Intended Webhook Target| LOGIC
```

### Component Details

1. **Target Monitored Scope:**  
   * Target Resource: Linux VM `vm-pulse-linux-01`.
   * Telemetry Source: Azure Host Hypervisor Metric Stream (platform-level metrics).
2. **Metric Alert Rule (`modules/alerts`):**  
   * Resource Name: `alert-pulse`
   * Target Resource Group: `rg-pulse-monitor-01`
   * Metric Namespace: `Microsoft.Compute/virtualMachines`
   * Metric Name: `Percentage CPU`
   * Operator: `GreaterThan` | Threshold: `40%` | Aggregation: `Average`
   * Evaluation Frequency: Every 1 minute (`PT1M`)
   * Time Window: Past 5 minutes (`PT5M`)
   * Auto-Mitigate: `true` (Automatically resolves the alert when CPU drops below 40%).
3. **Action Groups (`modules/action_group`):**  
   * `ag-pulse-email-alert`: Dedicated container for operational email alerts.
   * `ag-pulse-itil-alert`: Dedicated container for ITIL / ServiceNow / Jira automated incident creation.
4. **Serverless Orchestrator (`modules/logic_app`):**  
   * `logic-app-pulse-01`: Provisioned consumption workflow capable of receiving HTTP webhooks from Azure Monitor and processing automated runbooks.

---

## 3. End-to-End Monitoring & Alerting Workflow

The diagram below illustrates the exact runtime flow from an anomalous workload event through alert resolution:

```mermaid
sequenceDiagram
    autonumber
    participant Workload as VM Workload (vm-pulse-linux-01)
    participant Hypervisor as Azure Compute Fabric
    participant MetricEngine as Azure Monitor Metric Store
    participant Rule as Metric Alert (alert-pulse)
    participant ActionGroup as Action Group (ag-pulse-itil-alert)
    participant LogicApp as Logic App (logic-app-pulse-01)
    participant SecOps as SysAdmin / ITIL Desk

    Note over Workload,Hypervisor: Step 1: Metric Ingestion
    Workload->>Hypervisor: CPU Utilization spikes to 85%
    Hypervisor->>MetricEngine: Ingests Percentage CPU metric (per-minute granularity)

    Note over MetricEngine,Rule: Step 2: Metric Evaluation
    loop Every 60 Seconds (PT1M)
        Rule->>MetricEngine: Query average CPU for past 5 minutes (PT5M)
        alt Average CPU > 40%
            Rule->>Rule: Transition State: 'Resolved' -> 'Fired'
            Rule->>ActionGroup: Dispatch Common Alert Schema (CAS) Payload
        end
    end

    Note over ActionGroup,LogicApp: Step 3: Notification & Orchestration
    ActionGroup->>LogicApp: HTTP POST with Alert Metadata (JSON)
    LogicApp->>LogicApp: Parse Resource ID, Severity, Metric Value
    LogicApp-->>SecOps: Dispatch ITIL Ticket / Slack Notification

    Note over Workload,Rule: Step 4: Auto-Mitigation
    Workload->>Hypervisor: CPU normalizes to 15%
    Hypervisor->>MetricEngine: Ingests normal metric
    Rule->>Rule: Transition State: 'Fired' -> 'Resolved'
    Rule->>ActionGroup: Dispatch Auto-Mitigation Event
    ActionGroup->>LogicApp: Close / Resolve Associated Ticket
```

---

## 4. Observability Gap Analysis (Current vs. Enterprise Target)

While the metric alerting skeleton is in place, the current Terraform codebase exhibits significant enterprise observability gaps:

| Observability Pillar | Status in Codebase | Current Limitation | Target Enterprise Standard |
| :--- | :--- | :--- | :--- |
| **Log Analytics Workspace** | ❌ **Missing** | Zero central log repository. Cannot run KQL queries, store syslog, or retain audit events. | Dedicated `azurerm_log_analytics_workspace` (PerGB2018, 30-90 day retention). |
| **Diagnostic Settings** | ❌ **Missing** | Key Vault audit logs, NSG flow logs, and Activity Logs are discarded. | `azurerm_monitor_diagnostic_setting` on Key Vault, Network, and Subscription. |
| **Guest OS Telemetry** | ❌ **Missing** | Only hypervisor metrics (CPU/Network IO) are monitored. Memory, Disk Free %, and processes are invisible. | Azure Monitor Agent (AMA) VM extension with Data Collection Rules (DCR). |
| **Action Group Receivers** | ⚠️ **Empty Containers** | Action Groups exist as resource shells without `email_receiver` or `webhook_receiver` blocks. | Configured email recipients, SMS, and secure webhook authorization to Logic App. |
| **Dashboards / Workbooks**| ❌ **Missing** | No Azure Workbook or operational dashboard code declared in Terraform. | `azurerm_portal_dashboard` or `azurerm_application_insights_workbook`. |
| **Multi-Resource Scope** | ⚠️ **Static (1:1)** | Alert rule hardcodes single VM ID (`vm1`). Adding `vm2` requires modifying code. | Multi-resource scopes or dynamic `for_each` over all compute workloads. |

---

## 5. Enterprise Target Architecture Blueprint

The following target design outlines the recommended implementation to achieve enterprise-grade observability:

```mermaid
flowchart TD
    subgraph DataSources["Telemetry Sources"]
        VM_Host["VM Platform Metrics (CPU, Host IO)"]
        VM_Guest["Guest OS Telemetry (Memory, Disk, Syslog) via AMA"]
        KV_Audit["Key Vault Audit Events (Secret Access)"]
        NSG_Flow["NSG Flow Logs / Traffic Analytics"]
        SUB_Audit["Subscription Activity Logs"]
    end

    subgraph CentralHub["Central Log & Metric Analytics Hub (rg-pulse-monitor-01)"]
        LAW["Log Analytics Workspace<br/>(law-pulse-cin-01)"]
        METRIC_STORE["Azure Monitor Metric Engine"]
        WORKBOOK["Azure Monitor Workbook<br/>(Interactive Operations Dashboard)"]
    end

    subgraph DetectionPlane["Alerting & Detection"]
        ALERT_CPU["Metric Alert: High CPU (> 80%)"]
        ALERT_MEM["Log/Metric Alert: Memory Exhaustion (> 85%)"]
        ALERT_DISK["Log/Metric Alert: Disk Space Low (< 15%)"]
        ALERT_SEC["Activity Log Alert: Unauthorized Secret Attempt"]
    end

    subgraph NotificationPlane["Action Groups & Handlers"]
        AG_P1["Action Group: Critical (P1)"]
        AG_P2["Action Group: Warning (P2)"]
    end

    subgraph EgressPlane["Notification & Remediation"]
        EMAIL["Email Notification (Ops Team)"]
        LOGIC_AUTO["Logic App Runbook (Auto-Remediate / Restart)"]
        ITIL_API["ServiceNow / Jira Incident API"]
    end

    VM_Host --> METRIC_STORE
    VM_Guest -->|Azure Monitor Agent + DCR| LAW
    KV_Audit -->|Diagnostic Setting| LAW
    NSG_Flow -->|Diagnostic Setting| LAW
    SUB_Audit -->|Diagnostic Setting| LAW

    LAW --- WORKBOOK
    METRIC_STORE --- WORKBOOK

    METRIC_STORE --> ALERT_CPU
    LAW --> ALERT_MEM
    LAW --> ALERT_DISK
    LAW --> ALERT_SEC

    ALERT_CPU --> AG_P2
    ALERT_MEM --> AG_P1
    ALERT_DISK --> AG_P1
    ALERT_SEC --> AG_P1

    AG_P1 --> EMAIL
    AG_P1 --> LOGIC_AUTO
    AG_P1 --> ITIL_API
    AG_P2 --> EMAIL
```

---

## 6. Implementation Specifications for Proposed Improvements

### 6.1 Log Analytics Workspace Specification
```hcl
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-pulse-cin-01"
  location            = "centralindia"
  resource_group_name = "rg-pulse-monitor-01"
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
```

### 6.2 Key Vault Diagnostic Setting Specification
```hcl
resource "azurerm_monitor_diagnostic_setting" "kv_diag" {
  name                       = "diag-kv-pulse"
  target_resource_id         = module.key_vault.id # or data.azurerm_key_vault.kv.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
```

### 6.3 Action Group Receivers Specification
```hcl
resource "azurerm_monitor_action_group" "ag" {
  name                = "ag-pulse-itil-alert"
  resource_group_name = "rg-pulse-monitor-01"
  short_name          = "itil"

  email_receiver {
    name                    = "OperationsOnCall"
    email_address           = "ops-alerts@pulse.internal"
    use_common_alert_schema = true
  }

  logic_app_receiver {
    name                    = "LogicAppWebhook"
    resource_id             = module.logic_app.id
    callback_url            = module.logic_app.callback_url
    use_common_alert_schema = true
  }
}
```

### 6.4 Key Recommended Metrics & Alerting Matrix

| Alert Name | Target Resource | Metric / Query | Threshold | Window | Severity | Action Group |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **High CPU Alert** | `vm-pulse-linux-01` | `Percentage CPU` | `> 80%` | 5 Min | Sev 2 (Warning) | `ag-pulse-itil-alert` |
| **Memory Pressure** | `vm-pulse-linux-01` | `Available Memory Bytes` | `< 10%` | 5 Min | Sev 1 (Error) | `ag-pulse-itil-alert` |
| **Disk Space Low** | `vm-pulse-linux-01` | `Used Disk Space %` | `> 85%` | 15 Min | Sev 1 (Error) | `ag-pulse-itil-alert` |
| **VM Unavailability** | `vm-pulse-linux-01` | `VmAvailabilityMetric` | `< 1` | 1 Min | Sev 0 (Critical) | `ag-pulse-email-alert` |
| **Key Vault Access Failure** | `kv-pulse-cin-01` | `AuditEvent` status 403 | `> 5 in 5m` | 5 Min | Sev 1 (Error) | `ag-pulse-email-alert` |
