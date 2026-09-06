# VPN Gateway & ExpressRoute

> 🎯 Exam Weight: Part of 25–30% Networking domain

---

## 🔑 Hybrid Connectivity Overview

Connect your on-premises network to Azure using:
| Service | Medium | Speed | Encryption | Cost |
|---------|--------|-------|------------|------|
| **Site-to-Site VPN** | Public internet | Up to 1.25 Gbps | Yes (IPSec/IKE) | Low |
| **Point-to-Site VPN** | Public internet | Limited | Yes | Low |
| **ExpressRoute** | Private circuit | Up to 100 Gbps | No (but private) | High |
| **ExpressRoute + VPN** | Private + backup | High | Yes | Highest |

---

## 🔒 Azure VPN Gateway

### What It Is
- Sends **encrypted traffic** between Azure VNet and on-premises over the **public internet**
- Uses **IPSec/IKE** VPN protocols
- Deployed in a **GatewaySubnet** (must be named exactly `GatewaySubnet`)

### VPN Gateway SKUs
| SKU | Throughput | VPN Connections | BGP |
|-----|-----------|----------------|-----|
| **Basic** | 100 Mbps | 10 | No |
| **VpnGw1** | 650 Mbps | 30 | Yes |
| **VpnGw2** | 1 Gbps | 30 | Yes |
| **VpnGw3** | 1.25 Gbps | 30 | Yes |
| **VpnGw4/5** | Up to 5 Gbps | 100 | Yes |

> ⚠️ **Basic SKU does NOT support BGP, zone redundancy, or Active-Active mode**. Don't use for production.

### VPN Gateway Types
| Type | Description |
|------|-------------|
| **Route-based** | Modern, supports more configurations, required for Point-to-Site |
| **Policy-based** | Legacy, static routing, IKEv1 only, limited to one tunnel |

> 💡 Always use **Route-based** VPN gateway unless there's a legacy requirement.

---

## 🏠 Site-to-Site (S2S) VPN

### What It Is
- Connects your **entire on-premises network** to Azure VNet
- Requires a **VPN device** (hardware or software) at your on-premises location
- Always-on IPSec tunnel

### Required Components
| Component | Description |
|-----------|-------------|
| **VPN Gateway** | Azure-side (in GatewaySubnet) |
| **Local Network Gateway** | Azure resource representing your on-prem VPN device (IP + address space) |
| **Connection** | Links VPN Gateway + Local Network Gateway |
| **On-premises VPN device** | Hardware/software at your location |

### Setup Steps
1. Create **GatewaySubnet** in your VNet
2. Create **VPN Gateway** (can take 30-45 minutes!)
3. Create **Local Network Gateway** (represents on-prem VPN device)
4. Create **VPN Connection** between the two gateways
5. Configure your **on-premises VPN device**

```bash
# Create GatewaySubnet
az network vnet subnet create \
  --resource-group myRG \
  --vnet-name myVNet \
  --name GatewaySubnet \
  --address-prefix 10.0.255.0/27

# Create VPN Gateway (takes 30-45 min)
az network vnet-gateway create \
  --resource-group myRG \
  --name myVPNGateway \
  --location eastus \
  --vnet myVNet \
  --gateway-type Vpn \
  --vpn-type RouteBased \
  --sku VpnGw1 \
  --public-ip-address myGatewayPublicIP

# Create Local Network Gateway (your on-prem VPN device)
az network local-gateway create \
  --resource-group myRG \
  --name myLocalGateway \
  --gateway-ip-address 203.0.113.1 \
  --local-address-prefixes 192.168.0.0/24

# Create the connection
az network vpn-connection create \
  --resource-group myRG \
  --name myVPNConnection \
  --vnet-gateway1 myVPNGateway \
  --local-gateway2 myLocalGateway \
  --shared-key "YourSharedKey123!"
```

---

## 👤 Point-to-Site (P2S) VPN

### What It Is
- Individual **client computers** connect to Azure VNet via VPN
- No dedicated hardware required at user location
- Supports: Windows, Mac, Linux clients

### Authentication Methods
| Method | Description |
|--------|-------------|
| **Certificate** | Client/server certificates |
| **Azure AD** | Azure Active Directory auth |
| **RADIUS** | On-premises RADIUS server |

### VPN Client Protocols
| Protocol | Use Case |
|----------|---------|
| **OpenVPN** | Cross-platform (Windows, Mac, Linux, mobile) |
| **IKEv2** | Fast, native on Windows 10+, Mac |
| **SSTP** | Windows only, uses port 443 (through firewalls) |

> ⚠️ P2S VPN does NOT require route-based VPN gateway — however Basic SKU only supports SSTP.

---

## 🔌 Azure ExpressRoute

### What It Is
- **Private, dedicated connection** between on-premises and Azure
- Does NOT go over the public internet
- Provided by a **connectivity provider** (ISP or Exchange provider)
- Lower latency, higher reliability, higher security than VPN

### Connection Models
| Model | Description |
|-------|-------------|
| **CloudExchange co-location** | In a facility where Microsoft has presence |
| **Point-to-point Ethernet** | Direct link from your site to Azure |
| **Any-to-any (IPVPN)** | MPLS integration — extend corporate WAN to Azure |
| **ExpressRoute Direct** | Direct fiber connection to Microsoft (10 Gbps, 100 Gbps) |

### ExpressRoute Circuit SKUs
| SKU | Connectivity |
|-----|-------------|
| **Local** | One Azure region only |
| **Standard** | All regions in one geopolitical region |
| **Premium** | All regions globally |

### ExpressRoute Features
| Feature | Description |
|---------|-------------|
| **BGP routing** | Dynamic route exchange |
| **Redundancy** | Built-in (2 connections) — 99.95% SLA |
| **Bandwidth** | 50 Mbps to 10 Gbps (100 Gbps with Direct) |
| **Private peering** | Access Azure IaaS (VNets) |
| **Microsoft peering** | Access Microsoft 365, Dynamics 365, Azure PaaS |
| **FastPath** | Bypass gateway for lower latency |
| **Global Reach** | Connect two on-prem sites via Azure |

### ExpressRoute vs VPN

| Feature | VPN Gateway | ExpressRoute |
|---------|------------|-------------|
| Connection | Over internet | Private circuit |
| Encryption | Yes (IPSec) | No (but private) |
| Bandwidth | Up to 1.25 Gbps | Up to 100 Gbps |
| Latency | Variable | Consistent/low |
| SLA | 99.9% | **99.95%** |
| Setup time | Hours | Weeks/months |
| Cost | Low | High |
| Failover option | Yes | Use VPN as backup |

---

## 🔄 VPN + ExpressRoute Coexistence

- Use **ExpressRoute as primary** connection
- Use **Site-to-Site VPN as backup/failover**
- Requires specific gateway configurations (VPN Gateway + ExpressRoute Gateway)

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| VPN Gateway subnet name | **GatewaySubnet** (exact) |
| VPN Gateway creation time | **30–45 minutes** |
| Site-to-Site VPN encryption | **IPSec/IKE** |
| Point-to-Site authentication | Certificate, Azure AD, RADIUS |
| ExpressRoute over internet | **No** — private circuit |
| ExpressRoute SLA | **99.95%** |
| ExpressRoute max bandwidth | **100 Gbps** (ExpressRoute Direct) |
| BGP support | VpnGw1+ (not Basic) |
| Policy-based VPN | Legacy, max **1 tunnel** |
| Route-based VPN | Modern, multiple tunnels |

---

## 🚨 Common Exam Scenarios

**Q: A company needs to connect their on-premises network to Azure. The connection must be private, not over the internet. What do they use?**
→ **Azure ExpressRoute**

**Q: Remote employees need to VPN into Azure from their laptops. What do you configure?**
→ **Point-to-Site VPN** on VPN Gateway

**Q: A VPN Gateway deployment takes too long. What can cause this?**
→ VPN Gateway deployment takes **30–45 minutes** — this is normal

**Q: An organization needs 10 Gbps bandwidth with consistent low latency to Azure. What's the best solution?**
→ **Azure ExpressRoute** (VPN can't match this bandwidth or consistency)

**Q: Which VPN type is required for Point-to-Site VPN?**
→ **Route-based** VPN gateway (Policy-based does not support P2S)

**Q: GatewaySubnet is accidentally named "VPNSubnet". Can the VPN Gateway be deployed?**
→ **No** — the subnet must be named exactly **GatewaySubnet**
