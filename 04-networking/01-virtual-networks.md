# Azure Virtual Networks (VNets)

> 🎯 Exam Weight: Part of 25–30% Networking domain — HIGHEST EXAM WEIGHT!

---

## 🔑 Core VNet Architecture

- Isolated private network in Azure, scoped to a single **Region** and **Subscription**
- Uses private IPv4 and IPv6 address spaces (RFC 1918: `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`)
- Subdivided into **Subnets** to organize and isolate workloads

---

## 🔢 Azure Reserved IP Addresses (CRITICAL Calculation!)

Azure reserves **5 IP addresses** in EVERY subnet:
- **x.x.x.0**: Network address
- **x.x.x.1**: Default Gateway address
- **x.x.x.2 & x.x.x.3**: Azure DNS mapping addresses
- **x.x.x.255**: Network broadcast address

| Subnet Prefix | Total IPs | Azure Reserved | Usable Host IPs |
|---------------|-----------|----------------|-----------------|
| `/29` | 8 | 5 | **3** |
| `/28` | 16 | 5 | **11** |
| `/27` | 32 | 5 | **27** |
| `/26` | 64 | 5 | **59** |
| `/24` | 256 | 5 | **251** |

> ⚠️ **Exam Gotcha**: When planning subnet sizes for VMs, container pods, or gateways, always remember: **Usable IPs = Total IPs (2^(32 - prefix)) - 5**!

---

## 🔗 Virtual Network Peering

Connects two VNets directly over the Microsoft private backbone network:
- **Low latency, high bandwidth**: Traffic stays entirely within the private Azure backbone (no public internet).
- **Global VNet Peering**: Peers VNets across different Azure regions and different subscriptions/tenants.

### Key Peering Rules & Options
1. **Non-Transitive Peering**:
   ```
   [VNet1] <── Peered ──> [VNet2] <── Peered ──> [VNet3]
      ❌ VNet1 CANNOT communicate with VNet3 directly!
   ```
   To route traffic between VNet1 and VNet3, VNet2 must host a router/firewall (NVA) and User Defined Routes (UDRs) must be configured.
2. **Gateway Transit**:
   - `Allow Gateway Transit` on Hub VNet (which hosts the VPN Gateway).
   - `Use Remote Gateways` on Spoke VNet (allows spoke VMs to use Hub's gateway to reach on-prem).
3. **Overlapping Address Spaces**: Peering **fails** if address spaces overlap.
4. **Resyncing Peering**: If you add or alter an address space on a peered VNet, you must **sync the peering connection**.

---

## 🌐 Service Endpoints vs Private Endpoints

| Feature | Service Endpoints | Private Endpoints (Private Link) |
|---------|-------------------|----------------------------------|
| **IP Address** | PaaS remains on public IP (traffic routed over Azure backbone) | Allocates a **Private IP** from your subnet |
| **DNS Configuration** | Standard public DNS | Requires **Private DNS Zone** |
| **Cross-Tenant Access** | Allowed | Can restrict to specific authorized resources |
| **On-Premises Access** | ❌ Cannot access over VPN / ExpressRoute | ✅ Can access over VPN / ExpressRoute |

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Azure reserved IPs per subnet | **5 IPs** (.0, .1, .2, .3, .255) |
| VNet Peering transit nature | **Non-transitive** by default |
| Sharing VPN Gateway across peered VNets | Enable **Allow Gateway Transit** and **Use Remote Gateways** |
| Adding address space to peered VNet | Supported, but requires **Sync** action on peering |
| Max VNets per subscription | 1,000 (soft limit) |
| Subnet minimum size | `/29` (3 usable host IPs) |

---

**Q: VNet1 is peered with VNet2. VNet2 is peered with VNet3. Virtual machines in VNet1 cannot communicate with virtual machines in VNet3. Why?**
→ Virtual Network Peering is **non-transitive**. VNet1 cannot communicate with VNet3 through VNet2 without a Network Virtual Appliance (NVA) and User Defined Routes.

**Q: You need to allow branch office users connected to Azure via a Site-to-Site VPN in VNet-Hub to access virtual machines in a peered VNet named VNet-Spoke1.**
→ In VNet-Hub peering settings, enable **Allow gateway transit**. In VNet-Spoke1 peering settings, enable **Use remote gateways**.

---

## 🔀 IP Forwarding (NVA Configuration)

For a virtual machine acting as a **Network Virtual Appliance (NVA)** — such as a router or firewall — you must enable **IP Forwarding** on its network interface.

| Setting | Location | Purpose |
|---------|----------|---------|
| **IP Forwarding on NIC** | VM Network Interface | Allows NIC to receive traffic NOT destined for its own IP and forward it to other destinations |

> ⚠️ **Exam Gotcha**: IP Forwarding must be enabled on **every NIC** that the NVA uses to forward traffic. Without it, Azure will drop packets not addressed to the NIC's own IPs.

---

## 🌐 Azure Virtual WAN

Azure Virtual WAN provides **optimized, automated branch connectivity** to Azure and through Azure across multiple datacenters.

| Use Case | Architecture |
|----------|-------------|
| Connect multiple on-premises datacenters to Azure | Create **one Virtual WAN** + **multiple Virtual Hubs** (one per region/datacenter) |
| Minimize latency between datacenters | Virtual WAN uses Microsoft global backbone for routing |

> 💡 **Exam Tip (Q9)**: To connect 3 on-premises datacenters (Miami, Los Angeles, New York) to Azure with minimal latency → Create **3 Virtual WANs and 1 virtual hub** OR **3 virtual hubs and 1 virtual WAN**.

---

## 📋 Exam-Ready Facts (Supplemental)

| Fact | Value / Rule |
|------|--------------| 
| Public + Private IP on same NIC | ✅ **Yes** — Both can be assigned to a single NIC |
| Same NSG applied to multiple subnets | ✅ **Yes** — One NSG can be associated to many subnets/NICs |
| IP Forwarding requirement for NVA | Must enable **IP Forwarding** on the NVA's NIC |
| P2S VPN config after new peering | Must **re-download and re-install** VPN client config package |
| VNet Peering address space restriction | Address spaces must **NOT overlap** |
| VNet scope | Single **Region** and **Subscription** |

---

## 🚨 Common Exam Scenarios (Real Exam MCQs — Supplemental)

**Q: A VM (VM3) acting as a router is not forwarding traffic between Subnet1 and Subnet2 even though a route table is configured.**
→ Enable **IP Forwarding** on VM3's network interface (NIC3). Without this, Azure drops packets not addressed to the VM's own IPs.

**Q: You add VNet peering between VNet1 and VNet2. A Point-to-Site VPN client (Client1) connected to VNet1 cannot reach VNet2.**
→ Download and **re-install the VPN client configuration package** on Client1. The P2S config must be regenerated to include the new peering routes.

**Q: Five VMs each need a public and private IP address. What is the minimum number of network interfaces needed?**
→ **5 NICs** (one per VM — each NIC can have both a public and private IP address).

**Q: Five VMs each need the same inbound/outbound security rules. What is the minimum number of NSGs needed?**
→ **1 NSG** — The same NSG can be associated with multiple subnets or network interfaces.
