# Azure Virtual Networks (VNet)

> 🎯 Exam Weight: Part of 25–30% Networking domain — HIGHEST WEIGHT!

---

## 🔑 What is a Virtual Network?

- **Isolated private network** in Azure
- Enables Azure resources (VMs, etc.) to communicate:
  - With each other
  - With the internet
  - With on-premises networks
- Scoped to a **single region** (a VNet cannot span regions)
- Can span **multiple availability zones** within a region

---

## 📐 VNet Address Space

### CIDR Notation
- VNet is defined by an **address space** in CIDR notation
- Example: `10.0.0.0/16` = 65,536 IP addresses

### Address Space Rules
| Rule | Detail |
|------|--------|
| Private address ranges | Use RFC 1918: 10.x.x.x, 172.16-31.x.x, 192.168.x.x |
| Overlapping ranges | VNets that need to communicate CANNOT have overlapping address spaces |
| Multiple address spaces | A VNet can have multiple address ranges |
| Can add address space | Yes, to existing VNet (no disruption) |

---

## 📦 Subnets

### What Are Subnets?
- Divisions of the VNet address space
- Resources are deployed into subnets
- Each subnet must have a **unique, non-overlapping CIDR range** within the VNet

### Reserved IP Addresses (per subnet)
Azure reserves **5 IP addresses** in every subnet:
| Reserved IP | Purpose |
|-------------|---------|
| x.x.x.**0** | Network address |
| x.x.x.**1** | Default gateway |
| x.x.x.**2** | Azure DNS |
| x.x.x.**3** | Azure DNS |
| x.x.x.**255** | Broadcast |

> ⚠️ So a /29 subnet has 8 addresses but only **3 usable** for hosts.

### Special Subnets
| Subnet Name | Purpose |
|-------------|---------|
| **GatewaySubnet** | Required for VPN/ExpressRoute gateways |
| **AzureBastionSubnet** | Required for Azure Bastion (minimum /26) |
| **AzureFirewallSubnet** | Required for Azure Firewall (minimum /26) |
| **AzureFirewallManagementSubnet** | Required for Azure Firewall forced tunneling |

> ⚠️ Special subnet names must be **exact** (case-sensitive) — you cannot rename them.

---

## 🔗 VNet Peering

### What is VNet Peering?
- Connect two VNets so resources can communicate **as if on the same network**
- Traffic stays on **Azure backbone** (low latency, high bandwidth)
- NOT transitive — if VNetA peers with VNetB, and VNetB peers with VNetC, A cannot reach C automatically

### Types of Peering
| Type | Description |
|------|-------------|
| **VNet peering** | Same region peering |
| **Global VNet peering** | Cross-region peering |

### Peering Properties
| Setting | Description |
|---------|-------------|
| **Allow forwarded traffic** | Accept traffic from outside the peered VNet |
| **Allow gateway transit** | Allow peered VNet to use this VNet's gateway |
| **Use remote gateways** | Use the gateway in the peered VNet |

> ⚠️ Peering is **NOT bidirectional automatically** — you must create peering in **both directions** (VNetA→VNetB and VNetB→VNetA).

> ⚠️ **No overlapping address spaces** — peered VNets cannot have overlapping CIDR ranges.

### Peering vs VPN Gateway
| Feature | VNet Peering | VPN Gateway |
|---------|-------------|------------|
| Latency | Low (backbone) | Higher (VPN tunnel) |
| Bandwidth | No limit | Limited by gateway SKU |
| Transitivity | Not transitive | Transitive with route tables |
| Cost | Per GB data transfer | Gateway + data transfer |
| Cross-region | Yes (Global peering) | Yes |

---

## 🌐 VNet Connectivity Options

### Azure-to-Azure
| Method | Use Case |
|--------|---------|
| **VNet Peering** | Connect VNets (same or cross-region) |
| **VPN Gateway** | Encrypted tunnel between VNets |

### Azure-to-On-Premises
| Method | Use Case |
|--------|---------|
| **Site-to-Site VPN** | IPSec/IKE VPN over internet |
| **Point-to-Site VPN** | Individual client VPN |
| **ExpressRoute** | Private dedicated connection (not internet) |

---

## 🔄 Service Endpoints & Private Endpoints

### Service Endpoints
- Extend VNet identity to Azure services (Storage, SQL, etc.)
- Traffic goes over Azure backbone (not internet)
- Service still has **public IP** but accepts VNet traffic

### Private Endpoints
- Give Azure service a **private IP** in your VNet
- Uses **Azure Private Link**
- Traffic never leaves Azure network
- Most secure option

| Feature | Service Endpoint | Private Endpoint |
|---------|-----------------|-----------------|
| IP | Public (VNet routed) | Private (VNet IP) |
| DNS change | Not required | Required (private DNS zone) |
| Can block public access | No (just restrict) | Yes (completely private) |
| Cost | Free | Per endpoint + data |

---

## 🛠️ Creating VNets

```bash
# Azure CLI - Create VNet
az network vnet create \
  --resource-group myRG \
  --name myVNet \
  --address-prefixes 10.0.0.0/16 \
  --subnet-name mySubnet \
  --subnet-prefixes 10.0.0.0/24

# Add another subnet
az network vnet subnet create \
  --resource-group myRG \
  --vnet-name myVNet \
  --name backendSubnet \
  --address-prefixes 10.0.1.0/24

# Create VNet Peering (must do both directions)
az network vnet peering create \
  --name VNetA-to-VNetB \
  --resource-group myRG \
  --vnet-name VNetA \
  --remote-vnet VNetB \
  --allow-vnet-access

az network vnet peering create \
  --name VNetB-to-VNetA \
  --resource-group myRG \
  --vnet-name VNetB \
  --remote-vnet VNetA \
  --allow-vnet-access
```

---

## 🛤️ User-Defined Routes (UDR) & Route Tables

### What Are Route Tables?
- Override Azure's **default routing** to control traffic flow
- Force traffic through a specific appliance (e.g., Azure Firewall, NVA)

### Default System Routes
| Address Prefix | Next Hop |
|----------------|---------|
| 0.0.0.0/0 | Internet |
| VNet address space | VNet local |
| VNet peering addresses | VNet peering |
| 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 | None (if no VPN) |

### Custom Route (UDR)
```bash
# Create route table
az network route-table create \
  --resource-group myRG \
  --name myRouteTable

# Add a route (force internet traffic through firewall)
az network route-table route create \
  --resource-group myRG \
  --route-table-name myRouteTable \
  --name ForceToFirewall \
  --address-prefix 0.0.0.0/0 \
  --next-hop-type VirtualAppliance \
  --next-hop-ip-address 10.0.2.4

# Associate with subnet
az network vnet subnet update \
  --resource-group myRG \
  --vnet-name myVNet \
  --name mySubnet \
  --route-table myRouteTable
```

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| VNet scope | **Single region** |
| VNet span AZs | Yes |
| Reserved IPs per subnet | **5** |
| Minimum /29 subnet usable IPs | **3** |
| VNet peering is transitive | **No** |
| Peering must be created | **Both directions** |
| Overlapping subnets allowed | **No** |
| GatewaySubnet used for | VPN/ExpressRoute gateways |
| AzureBastionSubnet min size | **/26** |
| Private endpoint gives | Private IP in VNet |
| Service endpoint | VNet-routed but still public IP |

---

## 🚨 Common Exam Scenarios

**Q: Two VNets need to communicate. They are in different regions. What do you use?**
→ **Global VNet Peering**

**Q: VNetA peers with VNetB. VNetB peers with VNetC. Can VNetA communicate with VNetC?**
→ **No** — VNet peering is NOT transitive. You need direct peering or a hub-spoke architecture with route tables.

**Q: You need to route all internet-bound traffic from a subnet through Azure Firewall. What do you configure?**
→ **User-Defined Route (UDR)** with next hop = Azure Firewall private IP

**Q: How many usable host IPs are in a /28 subnet?**
→ /28 = 16 addresses, minus 5 reserved = **11 usable IPs**

**Q: You need to connect an on-premises network to Azure privately without going over the internet. What do you use?**
→ **Azure ExpressRoute** (private, dedicated connection)
