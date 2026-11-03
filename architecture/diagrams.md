# Azure Architecture & System Flow Diagrams: Project Pulse

This document compiles the visual architecture models representing the actual Azure infrastructure deployed via Terraform.

---

## 1. End-to-End Infrastructure Topology

```mermaid
flowchart TD
    subgraph AzureCloud["Microsoft Azure Cloud - Central India Region"]
        subgraph Sub["Azure Subscription (029048c9-25c1-4d71-acfb-58fb9e765f9f)"]
            subgraph Backend["Remote State Foundation"]
                RS_RG["Resource Group: rg-healops-tfstate-cin-01"]
                RS_ST["Storage Account: sthealopstfstate01"]
                RS_CT["Blob Container: pulsetfstate"]
                RS_BL["State File: pulseterraform.tfstate"]
                RS_RG --- RS_ST --- RS_CT --- RS_BL
            end

            subgraph RG_Workload["Workload Resource Group: rg-pulse-workload-01"]
                KV["Key Vault: kv-pulse-cin-01<br/>Standard SKU / Disk Encryption"]
                PIP["Public IP: pip-pulse-linux-01<br/>Static / Standard SKU"]
                
                subgraph VNet["Virtual Network: vnet-pulse-cin-01 (10.0.0.0/16)"]
                    subgraph Subnet["Subnet: snet-pulse-workload-cin-01 (10.0.1.0/24)"]
                        NIC["NIC: nic-pulse-linux-01<br/>Dynamic Private IP"]
                        VM["Linux VM: vm-pulse-linux-01<br/>Standard_B2ts_v2 / Ubuntu 22.04 LTS"]
                        OSDisk["Managed OS Disk: disk-pulse-os-01<br/>Standard_LRS / 30 GB"]
                        
                        NIC --> VM
                        VM --> OSDisk
                    end
                end

                NSG["NSG: nsg-pulse-workload-cin-01"]
                PIP --> NIC
            end

            subgraph RG_Monitoring["Monitoring Resource Group: rg-pulse-monitor-01"]
                AG1["Action Group: ag-pulse-email-alert<br/>Short Name: email"]
                AG2["Action Group: ag-pulse-itil-alert<br/>Short Name: itil"]
                LOGIC["Logic App Workflow: logic-app-pulse-01<br/>Consumption Workflow"]
                ALERT["Metric Alert: alert-pulse<br/>CPU Utilization > 40%"]
            end
        end
    end

    VM -.->|Telemetry Scope| ALERT
    ALERT -->|Triggers Action| AG2
    AG2 -.->|Webhook Integration| LOGIC
```

---

## 2. Network & Security Architecture

```mermaid
flowchart LR
    Internet["Public Internet"] <-->|Inbound and Outbound| PIP["Public IP: pip-pulse-linux-01<br/>Static / Standard SKU"]

    subgraph Boundary["VNet Isolation Boundary: 10.0.0.0/16"]
        subgraph Subnet_Workload["Workload Subnet: 10.0.1.0/24"]
            NIC["NIC: nic-pulse-linux-01"]
            VM["VM: vm-pulse-linux-01<br/>Ubuntu 22.04 LTS"]
            NIC --- VM
        end
    end

    PIP <--> NIC

    subgraph Security_Perimeter["Perimeter Security"]
        NSG_Box["NSG: nsg-pulse-workload-cin-01"]
    end

    subgraph Secrets_Boundary["Secrets and Encryption"]
        KV["Key Vault: kv-pulse-cin-01<br/>Disk Encryption: Enabled<br/>Soft Delete: 7 Days"]
    end
```

---

## 3. Azure Monitor Telemetry & Alerting Pipeline

```mermaid
flowchart TD
    VM["Linux Virtual Machine: vm-pulse-linux-01"] -->|Hypervisor CPU Metric Stream| METRIC_STORE["Azure Monitor Metric Platform"]
    
    subgraph EvaluationEngine["Metric Alert Rule: alert-pulse"]
        CRITERIA["Condition: Average CPU > 40%<br/>Evaluation Frequency: 1 Minute<br/>Lookback Window: 5 Minutes"]
        STATUS_EVAL{"Threshold Breached?"}
    end

    METRIC_STORE --> CRITERIA
    CRITERIA --> STATUS_EVAL

    STATUS_EVAL -->|"Yes - Alert Fired"| TRIGGER_AG["Action: Trigger Action Group"]
    STATUS_EVAL -->|"No - Normal"| MITIGATE["Auto-Mitigate State"]

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
    Client->>PIP: Traffic Request (SSH / Management)
    PIP->>NIC: Route Traffic via Dynamic Private IP
    NIC->>VM: Pass packet to guest network stack
    VM->>Storage: Read and Write execution

    Note over VM,Logic: Observability and Health Monitoring
    loop Every 60 Seconds
        VM->>Monitor: Push Platform CPU Metrics
    end
    Note over Monitor: Evaluates 5-Minute Window
    alt CPU > 40%
        Monitor->>AG: Dispatch Alert Notification
        AG->>Logic: Trigger HTTP POST Webhook
        Logic-->>Client: Alert Notification / ITIL Action
    end
```
