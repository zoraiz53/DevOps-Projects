# Azure Advanced Networking with Terraform 🌐

## Azure Terraform Backend 💾
This project uses an **Azure Storage Account** with a **Blob Container** to store the Terraform state file (`terraform.tfstate`).  
The state file is saved inside the container, ensuring it is **centrally managed** and **secure**. Access to the backend is controlled via **Azure IAM roles** assigned to the Storage Account, so only authorized users or service principals can read/write the state.  
By keeping the state in Azure:
- All team members share a single, consistent source of truth.
- State is protected by Azure’s redundancy and security features.
- Changes to infrastructure can be tracked and applied safely across environments.

---

## Overview
This Terraform stack provisions a **hub-style VNet** with **public & private subnets**, a **NAT Gateway** for secure outbound from private resources, and **per-subnet NSGs**. It reads an existing Resource Group (data source), deploys network components into a **variable-driven Azure region**, and applies explicit egress and security rules.

---

## What This Deploys (at a glance)
- **Existing Resource Group (data source)**
- **Virtual Network (VNet)** in a variableized Azure region
- **Two Subnets**:
  - `public-subnet` — for internet-facing workloads
  - `private-subnet` — no public IPs, outbound only via NAT
- **NAT Gateway** in public zone, associated with private-subnet for egress
- **Two NSGs**, one per subnet, with tailored inbound/outbound rules

---

## How It Works (Deep Technical Dive) 🔧
1. **Resource Group Lookup:** Uses a Terraform data block to reference an existing Resource Group and inherit its location.
2. **VNet & Subnets:** VNet CIDR and subnet CIDRs are set via variables, enabling flexibility and avoiding CIDR conflicts.
3. **NAT Gateway:** A Public IP is attached to the NAT Gateway, which is linked to the private-subnet to allow outbound-only internet traffic with a consistent public IP.
4. **NSGs:**  
   - Public-subnet NSG — allows only necessary inbound ports and restricts others.  
   - Private-subnet NSG — blocks all inbound internet traffic, allows internal VNet and required Azure service traffic.
5. **Traffic Flow:** Private workloads reach the internet via the NAT Gateway (SNAT), inbound to private workloads is blocked by design. For controlled access, Bastion, VPN, or Private Link can be used.

---

## Traffic Patterns 🛣️
**Outbound (Private Subnet):**
- Workload initiates a connection → NAT Gateway assigns outbound public IP → internet.
- Return traffic flows back through the same NAT mapping.

**Inbound (External → Private):**
- Blocked by default; requires additional services like Bastion, VPN, Application Gateway, or Private Link for secure access.

---

## Why This Design Works (Security, Ops & Scale) 🧠
- **Principle of Least Exposure:** No public IPs on private workloads, controlled outbound.
- **Layered Security:** NSGs applied at subnet level enforce strict network boundaries.
- **Deterministic Egress:** Fixed outbound IP simplifies allow-listing and monitoring.
- **Repeatable Deployments:** Variables allow the same design to be rolled out to multiple environments.
- **Future-Ready:** Easily integrates with hub-spoke networks, Azure Firewall, WAF, or private AKS clusters.

---

## Benefits (Organizational) 🏢✨
- **Improved Security Posture:** Reduced attack surface by isolating private workloads.
- **Compliance Friendly:** Centralized NAT IPs simplify vendor integrations and audits.
- **Cost Efficient:** Avoids per-VM public IP costs and simplifies egress routing.
- **Operational Simplicity:** Clear separation of public and private resources for easier management.
- **Scalable:** Can expand with additional subnets, peerings, or security services without redesign.
