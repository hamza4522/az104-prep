# 🌐 Virtual Networking (VNet)

> **AWS Parallel:** AWS VPC → Azure Virtual Network (VNet)  
> **GCP Parallel:** GCP VPC → Azure VNet  
> **OCI Parallel:** OCI VCN → Azure VNet

## Azure Networking vs AWS VPC — Key Differences

| Concept | Azure VNet | AWS VPC | Key Difference |
|---|---|---|---|
| Address space | VNet CIDR | VPC CIDR | VNet can have MULTIPLE address spaces |
| Subnet | Subnet | Subnet | Azure subnets span all AZs by default |
| Route table | Route table | Route table | Azure has system routes that can't be deleted |
| Internet gateway | Internet gateway (on subnet) | IGW (on VPC) | Azure VNet has implicit internet by default |
| NAT | NAT Gateway | NAT Gateway | Very similar |
| Private DNS | Private DNS Zone | Route 53 Private Hosted Zone | Similar concept |
| Peering | VNet Peering | VPC Peering | Azure peering is NOT transitive |
| Hub-spoke | Azure Virtual WAN / Hub VNet | Transit Gateway | Azure Virtual WAN is managed |
| Security | NSG (Network Security Group) | Security Groups + NACLs | NSG applies to subnet OR NIC |
| Firewall | Azure Firewall | AWS Network Firewall | Similar stateful firewall |
| Load Balancer | Azure LB (L4) + App Gateway (L7) | NLB (L4) + ALB (L7) | Similar split |
| DNS | Azure DNS | Route 53 | Very similar |
| VPN | VPN Gateway | VGW | Similar |
| ExpressRoute | ExpressRoute | Direct Connect | Dedicated private connectivity |

---

## Labs in This Section

| Lab | Title | Difficulty |
|---|---|---|
| Lab-01 | VNet, Subnets & NSGs | 🟢 |
| Lab-02 | VNet Peering & Service Endpoints | 🟡 |
| Lab-03 | Azure Load Balancer (L4) | 🟡 |
| Lab-04 | Application Gateway (L7 + WAF) | 🔴 |
| Lab-05 | VPN Gateway — Site-to-Site & P2S | 🔴 |
| Lab-06 | Azure DNS — Public & Private Zones | 🟡 |
| Lab-07 | NAT Gateway & Private Endpoints | 🟡 |
| Lab-08 | Azure Firewall | 🔴 |
| Lab-09 | Hub-Spoke Network Topology | ⭐ |

---

## Quick Reference

```bash
# Networking resource types
az network --help

# VNet
az network vnet create/list/show/delete/update

# Subnet
az network vnet subnet create/list/show/delete/update

# NSG
az network nsg create/list/show/delete
az network nsg rule create/list

# Route table
az network route-table create/list
az network route-table route create

# Public IP
az network public-ip create/list/show

# Load Balancer
az network lb create/show/delete
az network lb rule create

# Application Gateway
az network application-gateway create/show

# VNet Gateway (VPN)
az network vnet-gateway create/show

# ExpressRoute
az network express-route create/show

# Azure Firewall
az network firewall create/show

# DNS
az network dns zone create/list
az network private-dns zone create
```
