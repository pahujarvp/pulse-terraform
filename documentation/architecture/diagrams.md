# Azure Architecture & System Flow Diagrams: Project Pulse

This document compiles the visual architecture models representing the actual Azure infrastructure deployed via Terraform.

---

## 1. End-to-End Infrastructure Topology

```mermaid
flowchart TD
    subgraph AzureCloud["Microsoft Azure Cloud (Tenant: 361ad487)"]
        subgraph Sub["Subscription: 029048c9-25c1-4d71-acfb-58fb9e765f9f"]
            subgraph Backend["Remote State Infrastructure"]
                RS_RG["rg-healops-tfstate-cin-01"]
                RS_ST["sthealopstfstate01"]
                RS_CT["Container: pulsetfstate"]
                RS_BL["Blob: pulseterraform.tfstate"]
                RS_RG --- RS_ST --- RS_CT --- RS_BL
            end

            subgraph RG_Workload["Resource Group: rg-pulse-workload-01 (Central India)"]
                KV["Key Vault: kv-pulse-cin-01<br/>(Standard SKU / Purge Protection: Off)"]
                PIP["Public IP: pip-pulse-linux-01<br/>(Static / Standard)"]
                
                subgraph VNet["Virtual Network: vnet-pulse-cin-01 (10.0.0.0/16)"]
                    subgraph Subnet["Subnet: snet-pulse-workload-cin-01 (10.0.1.0/24)"]
                        NIC["NIC: nic-pulse-linux-01<br/>(Private IP: Dynamic)"]
                        VM["Linux VM: vm-pulse-linux-01<br/>(Standard_B2ts_v2 / Ubuntu 22.04)"]
                        OSDisk["Managed OS Disk: disk-pulse-os-01<br/>(Standard_LRS / 30 GB)"]
                        
                        NIC --> VM
                        VM --> OSDisk
                    end
                end

                NSG["NSG: nsg-pulse-workload-cin-01<br/>(Standalone / Unassociated)"]
                PIP --> NIC
            end

            subgraph RG_Monitoring["Resource Group: rg-pulse-monitor-01 (Central India)"]
                AG1["Action Group: ag-pulse-email-alert<br/>(Short Name: email)"]
                AG2["Action Group: ag-pulse-itil-alert<br/>(Short Name: itil)"]
                LOGIC["Logic App Workflow: logic-app-pulse-01<br/>(Workflow Schema: 2016-06-01)"]
                ALERT["Metric Alert: alert-pulse<br/>(Percentage CPU > 40%)"]
            end
        end
    end

    VM -.->|Telemetry Scope| ALERT
    ALERT -->|Triggers Action| AG2
    AG2 -.->|Webhook Target| LOGIC
```

---

## 2. Network & Security Segmentation Model

```mermaid
flowchart LR
    Internet["Public Internet"] <-->|Inbound / Outbound 0.0.0.0/0| PIP["pip-pulse-linux-01<br/>(Standard Public IP)"]

    subgraph Boundary["VNet Isolation Boundary: 10.0.0.0/16"]
        subgraph Subnet_Workload["Workload Subnet: 10.0.1.0/24"]
            NIC["nic-pulse-linux-01"]
            VM["vm-pulse-linux-01<br/>(azureuser / Password Auth)"]
            NIC --- VM
        end
    end

    PIP <--> NIC

    subgraph Security_Perimeter["Perimeter Security State"]
        NSG_Box["nsg-pulse-workload-cin-01"]
        NSG_State["Status: Created in RG<br/>Subnet Assoc: NONE<br/>NIC Assoc: NONE<br/>Rules: Azure Defaults Only"]
        NSG_Box --- NSG_State
    end

    subgraph Secrets_Boundary["Secrets & Encryption Plane"]
        KV["kv-pulse-cin-01<br/>(Disk Encryption: Enabled<br/>RBAC: Disabled<br/>Access Policies: None)"]
    end
```

---

## 3. Azure Monitor Telemetry & Alerting Pipeline

```mermaid
flowchart TD
    VM["Linux Virtual Machine: vm-pulse-linux-01"] -->|Hypervisor CPU Metric| METRIC_STORE["Azure Monitor Metric Platform"]
    
    subgraph EvaluationEngine["Metric Alert Rule: alert-pulse"]
        CRITERIA["Condition: Average CPU > 40%<br/>Evaluation Frequency: 1 Minute (PT1M)<br/>Window Size: 5 Minutes (PT5M)"]
        STATUS_EVAL{"Threshold Breached?"}
    end

    METRIC_STORE --> CRITERIA
    CRITERIA --> STATUS_EVAL

    STATUS_EVAL -->|Yes (Fired)| TRIGGER_AG["Action: Trigger ag-pulse-itil-alert"]
    STATUS_EVAL -->|No (Resolved)| MITIGATE["Auto-Mitigate State"]

    TRIGGER_AG --> ACTION_GROUP["Action Group: ag-pulse-itil-alert"]
    ACTION_GROUP --> LOGIC_APP["Logic App Workflow: logic-app-pulse-01"]
```

---

## 4. End-to-End Application & Traffic Sequence

```mermaid
sequenceDiagram
    autonumber
    actor Client as External Client / Administrator
    participant PIP as Public IP (pip-pulse-linux-01)
    participant NIC as Network Interface (nic-pulse-linux-01)
    participant VM as Linux VM (vm-pulse-linux-01)
    participant Storage as Managed OS Disk
    participant Monitor as Azure Monitor Engine
    participant AG as Action Group (ag-pulse-itil-alert)
    participant Logic as Logic App Workflow

    Note over Client,Storage: Workload Ingress Data Flow
    Client->>PIP: Traffic Request (Port 22 / 80 / 443)
    PIP->>NIC: Route Traffic via Dynamic Private IP
    NIC->>VM: Pass packet to guest network stack
    VM->>Storage: Read / Write execution

    Note over VM,Logic: Observability & Health Monitoring
    loop Every 60s
        VM->>Monitor: Push Platform CPU Metrics
    end
    Note over Monitor: Evaluates 5-Minute Window
    alt CPU > 40%
        Monitor->>AG: Dispatch Alert Notification
        AG->>Logic: Trigger HTTP POST Webhook
        Logic-->>Client: Alert Notification / ITIL Action
    end
```

