# VPN Gateway & ExpressRoute

> 🎯 Exam Weight: Part of 25–30% Networking domain

---

## 🔑 Hybrid Connectivity Options

```
On-Premises / Remote Users ───> Azure Virtual Network
  ├── Point-to-Site (P2S) VPN ─── Single remote user over internet
  ├── Site-to-Site (S2S) VPN ─── Corporate office over encrypted IPsec/IKE tunnel
  └── ExpressRoute ───────────── Dedicated private fiber connection (bypasses internet)
```

---

## 📱 Point-to-Site (P2S) VPN

Connects individual client devices (laptops, home workstations) securely to an Azure VNet:
- **Protocols**: OpenVPN, SSTP, IKEv2
- **Authentication**:
  - **Azure Certificate Authentication**: Upload root certificate (`.cer`) public key to Azure VPN Gateway; install client certificate (`.pfx`) on remote PCs.
  - **Microsoft Entra ID (Azure AD)**: Modern SSO with MFA support.
  - **RADIUS**: Integrates with on-premise Active Directory.

---

## 🏢 Site-to-Site (S2S) VPN

Connects an entire on-premises network to an Azure VNet:
- **GatewaySubnet Requirement**:
  - Must be named exactly **`GatewaySubnet`**
  - Minimum size: `/29` (Recommended: `/27` or larger)
  - **CRITICAL RULE**: Do **NOT** assign a Network Security Group (NSG) to the `GatewaySubnet`!
- **Local Network Gateway**:
  - Represents the on-premises VPN device in Azure
  - Contains on-prem public IP address and on-prem address spaces

---

## 🚄 ExpressRoute

- **Private, dedicated, high-speed connection** provided by an ExpressRoute connectivity provider
- **Does NOT traverse the public internet**; provides ultra-low latency and up to 100 Gbps speeds

### ExpressRoute Peering Types
| Peering Type | Connected Services |
|--------------|-------------------|
| **Azure Private Peering** | Private VNets, VMs, database instances |
| **Microsoft Peering** | Microsoft 365, Azure public PaaS (Storage, SQL) |

> 💡 **ExpressRoute FastPath**: Bypasses the VPN Gateway CPU bottleneck to send network traffic directly to VMs in the VNet, significantly improving data throughput.

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Gateway subnet name | Must be named **`GatewaySubnet`** |
| Gateway subnet NSG restriction | **Never** associate an NSG with GatewaySubnet |
| P2S certificate configuration | Upload root `.cer` to Azure; install client `.pfx` on PCs |
| ExpressRoute internet traversal | Does **not** traverse public internet (private connection) |
| Local Network Gateway definition | Represents on-premises VPN hardware and on-prem IP ranges |

---

## 🚨 Common Exam Scenarios (Real Exam MCQs)

**Q: A remote developer needs to connect their Windows 10 laptop to an Azure VNet using a Point-to-Site VPN with certificate authentication. What must you install on the laptop?**
→ Download and install the **Azure VPN client configuration package**, and install a valid **client certificate** with its private key.

**Q: You are planning a Site-to-Site VPN. You need to create a dedicated subnet for the Virtual Network Gateway. What constraint must you follow?**
→ Name the subnet **GatewaySubnet**, use at least a `/27` prefix, and **do not attach an NSG** to it.

**Q: An organization requires a dedicated 10 Gbps connection between their on-premises datacenter and Azure that guarantees predictable performance without traversing the public internet.**
→ Deploy **Azure ExpressRoute**.
