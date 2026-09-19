# Hub-Spoke, Private Link & Routing

> 🎯 Exam Weight: Part of 25–30% Networking domain

---

## 🏰 Hub-and-Spoke Topology

```
                  [On-Premises Network]
                           │
                 (VPN / ExpressRoute)
                           ▼
                  [Hub VNet: GatewaySubnet]
                           │
                  [Azure Firewall / NVA]
                     ▲           ▲
        (VNet Peering)           (VNet Peering)
                     │           │
                     ▼           ▼
             [Spoke 1 VNet]   [Spoke 2 VNet]
             (Workloads)      (Workloads)
```

### Routing Traffic Through Hub Firewall
- Spokes do not communicate directly.
- To force Spoke 1 to route traffic through the Hub Firewall to reach Spoke 2 or the Internet:
  1. Create a **Route Table (User Defined Route - UDR)**.
  2. Add a route: `0.0.0.0/0` (or `10.0.0.0/8`) with Next Hop type = **Virtual Appliance** and Next Hop IP = **Private IP of Azure Firewall**.
  3. Associate the route table with the Spoke subnets.

---

## 🔒 Azure Private Link & Private Endpoints

- Eliminates public internet exposure for Azure PaaS services (Storage, SQL, Key Vault)
- Allocates a **Private IP Address** directly from your VNet subnet to represent the PaaS resource

### Private Endpoint DNS Integration
- PaaS services still use their public FQDN (e.g. `storage1.blob.core.windows.net`).
- Private Link creates a **CNAME alias** to a private link zone:
  `storage1.blob.core.windows.net` ➔ `storage1.privatelink.blob.core.windows.net` ➔ `10.1.0.5`
- Requires creating an **Azure Private DNS Zone** named `privatelink.<service>.core.windows.net` and linking it to the VNet!

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Route all traffic through central firewall | UDR with `0.0.0.0/0` ➔ Next Hop: **Virtual Appliance** |
| Force tunneling | Routes all internet-bound traffic back to on-prem via BGP / default route |
| Private Endpoint IP type | **Private IP** allocated from customer subnet |
| Private Endpoint DNS resolution | Requires Private DNS Zone `privatelink.<service>...` linked to VNet |

---

## 🚨 Common Exam Scenarios (Real Exam MCQs)

**Q: You need to ensure that all outbound internet traffic from VMs in Subnet1 is inspected by a network virtual appliance (NVA) at IP 10.0.1.4.**
→ Create a **Route Table**, add a route for `0.0.0.0/0` with next hop type **Virtual appliance** and IP `10.0.1.4`, and associate the route table with Subnet1.

**Q: You create an Azure Private Endpoint for an Azure SQL Database. Virtual machines in VNet1 resolve the database FQDN to its public IP address instead of its private endpoint IP. What is missing?**
→ An **Azure Private DNS Zone** named `privatelink.database.windows.net` linked to VNet1 with the database's A record.
