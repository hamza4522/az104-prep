# Hub-Spoke Architecture & Azure Private Link

> 🎯 Exam Weight: Part of 25–30% Networking domain — Common scenario questions!

---

## 🌐 Hub-Spoke Network Architecture

### What is Hub-Spoke?
- Common network topology in Azure enterprises
- **Hub VNet**: Central VNet with shared services (firewall, VPN gateway, DNS, monitoring)
- **Spoke VNets**: Individual workload/application VNets peered to the hub

```
                    ┌─────────────────┐
                    │    HUB VNet     │
                    │  ┌───────────┐  │
         On-Prem ───┤  │  Gateway  │  │
         (VPN/ER)   │  └───────────┘  │
                    │  ┌───────────┐  │
                    │  │  Firewall │  │
                    │  └───────────┘  │
                    │  ┌───────────┐  │
                    │  │   DNS     │  │
                    └──┴─────┬─────┘  │
                             │        └─
                    ┌────────┴────────────────────────┐
                    │                                  │
            ┌───────┴───────┐              ┌──────────┴──────┐
            │  Spoke VNet 1 │              │  Spoke VNet 2   │
            │  (Production) │              │  (Development)  │
            └───────────────┘              └─────────────────┘
```

### Why Hub-Spoke?
| Benefit | Description |
|---------|-------------|
| **Centralized security** | Single firewall/NVA inspects all traffic |
| **Shared services** | One VPN gateway serves all spokes |
| **Cost efficiency** | Shared infrastructure reduces costs |
| **Governance** | Central control point for all traffic |
| **Isolation** | Spoke VNets are isolated from each other |

---

## 🔗 VNet Peering in Hub-Spoke

### Non-Transitive Challenge
- By default, peering is **NOT transitive**
- Spoke 1 and Spoke 2 CANNOT communicate through Hub by default
- Solution: Route through **Azure Firewall or NVA** in Hub + UDR

### Enabling Spoke-to-Spoke via Hub
1. Enable **Allow forwarded traffic** on peering connections
2. Enable **Use remote gateways** on spoke peerings (to use Hub's VPN gateway)
3. Enable **Allow gateway transit** on Hub peering
4. Create **UDR** in spokes to route traffic through Hub firewall

### VNet Peering Settings for Hub-Spoke

| Setting | Set on | Purpose |
|---------|--------|---------|
| Allow forwarded traffic | Both Hub→Spoke and Spoke→Hub | Allow traffic from outside the peered VNet |
| Allow gateway transit | Hub→Spoke peering | Hub shares its gateway with spokes |
| Use remote gateways | Spoke→Hub peering | Spoke uses Hub's gateway for on-prem connectivity |

---

## 🏢 Azure Virtual WAN (vWAN)

### What is Azure Virtual WAN?
- Microsoft-managed hub-spoke architecture
- Replaces manual hub-spoke configuration with a managed service
- Automatically handles routing between branches, VNets, and Azure

### vWAN vs Manual Hub-Spoke

| Feature | Manual Hub-Spoke | Azure Virtual WAN |
|---------|-----------------|-------------------|
| Management | Manual (UDR, peering) | Managed by Azure |
| Routing | Manual UDR setup | Automated |
| Scale | Limited | Thousands of connections |
| Cost | Gateway costs | vWAN hub costs |
| Complexity | High | Low (managed) |

### vWAN SKUs
| SKU | Features |
|-----|---------|
| **Basic** | S2S VPN only |
| **Standard** | S2S VPN + ExpressRoute + P2S + VNet connections |

---

## 🔒 Azure Private Link & Private Endpoints

### Private Link Overview
- **Azure Private Link** = the platform service
- **Private Endpoint** = the network interface that uses Private Link
- Makes Azure PaaS services (Storage, SQL, Key Vault, etc.) accessible via **private IP**

### How Private Endpoint Works
```
Your VNet (10.0.0.0/16)
    └── Private Endpoint NIC (10.0.0.10) ← private IP assigned from VNet
            └── Connected via Private Link to:
                    Azure Storage, SQL DB, Key Vault, etc.
```

### Private Endpoint vs Service Endpoint

| Feature | Service Endpoint | Private Endpoint |
|---------|-----------------|-----------------|
| Network path | Azure backbone (optimized) | Azure backbone |
| IP type | Service keeps public IP | Service gets **private IP** |
| VNet IP consumed | No | Yes (from your subnet) |
| DNS change needed | No | **Yes** (private DNS zone) |
| Blocks all public access | No | Yes (can disable public endpoint) |
| Works across peered VNets | No (subnet-specific) | Yes (with DNS linkage) |
| Cost | Free | Per endpoint/hour + data |
| Hybrid (on-prem) access | No | **Yes** (via VPN/ER + DNS forwarding) |

---

## 🌐 Private DNS Zone with Private Endpoints

### Why DNS Matters
When you create a private endpoint for Storage (e.g., `mystorageaccount.blob.core.windows.net`):
- Without private DNS: DNS resolves to **public IP** → bypasses private endpoint
- With private DNS: DNS resolves to **private IP** → uses private endpoint

### Private DNS Zone Names for Common Services
| Service | Private DNS Zone |
|---------|-----------------|
| **Blob Storage** | `privatelink.blob.core.windows.net` |
| **File Storage** | `privatelink.file.core.windows.net` |
| **SQL Database** | `privatelink.database.windows.net` |
| **Key Vault** | `privatelink.vaultcore.azure.net` |
| **Container Registry** | `privatelink.azurecr.io` |
| **App Service** | `privatelink.azurewebsites.net` |
| **Cosmos DB** | `privatelink.documents.azure.com` |

### Setup Steps for Private Endpoint
1. Create **Private Endpoint** for the service
2. Azure auto-creates a **NIC** with private IP in your subnet
3. Create a **Private DNS Zone** (e.g., `privatelink.blob.core.windows.net`)
4. **Link** the private DNS zone to all VNets that need to resolve
5. Create a **DNS record** in the private zone (auto-created if you select "integrate with private DNS zone")
6. Disable public endpoint on the service (optional but recommended)

```bash
# Create a private endpoint for a storage account
az network private-endpoint create \
  --resource-group myRG \
  --name myStoragePE \
  --vnet-name myVNet \
  --subnet mySubnet \
  --private-connection-resource-id {storage-account-resource-id} \
  --group-id blob \
  --connection-name myStorageConnection

# Create private DNS zone
az network private-dns zone create \
  --resource-group myRG \
  --name "privatelink.blob.core.windows.net"

# Link DNS zone to VNet
az network private-dns link vnet create \
  --resource-group myRG \
  --zone-name "privatelink.blob.core.windows.net" \
  --name myDNSLink \
  --virtual-network myVNet \
  --registration-enabled false

# Create DNS record set (or use --integrate-private-dns-zone on PE creation)
az network private-endpoint dns-zone-group create \
  --resource-group myRG \
  --endpoint-name myStoragePE \
  --name myZoneGroup \
  --private-dns-zone "privatelink.blob.core.windows.net" \
  --zone-name blob
```

---

## 🏗️ Private Link Service (Custom)

- Expose YOUR OWN service privately to other Azure customers or tenants
- Customer creates a Private Endpoint → connects to your Private Link Service
- Traffic never goes over internet
- Use case: SaaS providers offering private connectivity to customers

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| Hub purpose | Shared services: gateway, firewall, DNS |
| Spoke-to-spoke direct | **Not by default** — route through hub |
| Allow gateway transit | Set on **Hub's peering** to share gateway |
| Use remote gateways | Set on **Spoke's peering** to use hub gateway |
| Private endpoint gives | **Private IP** in your VNet |
| Private DNS zone needed | **Yes** for correct DNS resolution |
| Service endpoint | Still public IP (just VNet-routed) |
| Private endpoint blocks public | Can fully disable public endpoint |
| Azure Virtual WAN | Managed hub-spoke (Microsoft managed routing) |
| Private Link Service | Expose YOUR service privately to others |

---

## 🚨 Common Exam Scenarios

**Q: A spoke VNet needs to communicate with an on-premises network through the hub's VPN gateway. What settings do you configure?**
→ On Hub's peering: **Allow gateway transit = true**. On Spoke's peering: **Use remote gateways = true**

**Q: Two spoke VNets need to communicate with each other. They're both peered to the hub. What's needed?**
→ Route traffic through **Azure Firewall in hub** using **UDR** in both spokes — peering is not transitive

**Q: An app in a VNet needs to access Azure SQL Database privately. No traffic should go over the internet. What do you configure?**
→ **Private Endpoint** for the SQL database + **Private DNS Zone** linked to the VNet

**Q: A storage account has a private endpoint. VMs in a peered VNet can't reach it. What's likely missing?**
→ The **Private DNS Zone** must be **linked** to the peered VNet (not just the VNet where PE was created)

**Q: On-premises servers need to access Azure Storage via private endpoint (over ExpressRoute). What DNS configuration is needed?**
→ Configure **DNS forwarding** from on-prem DNS servers to Azure DNS (168.63.129.16) for the privatelink zone, so on-prem resolves the private IP
