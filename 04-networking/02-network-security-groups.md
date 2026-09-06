# Network Security Groups (NSG)

> 🎯 Exam Weight: Part of 25–30% Networking domain

---

## 🔑 What is an NSG?

- Acts as a **virtual firewall** for Azure resources
- Contains **security rules** that allow or deny inbound/outbound traffic
- Can be associated with:
  - **Subnets** (applies to all resources in the subnet)
  - **Network Interface Cards (NICs)** (applies to that specific VM)

---

## 📋 NSG Rules

### Rule Properties
| Property | Description |
|----------|-------------|
| **Priority** | Number 100–4096. **Lower = higher priority**. First match wins |
| **Source/Destination** | IP, IP range, service tag, or application security group |
| **Protocol** | TCP, UDP, ICMP, Any |
| **Port range** | Single port, range (80-443), or * (all) |
| **Direction** | Inbound or Outbound |
| **Action** | Allow or Deny |

> ⚠️ **First matching rule wins** — once a rule matches, subsequent rules are not evaluated.

### Default Rules (Cannot be deleted, priority 65000+)
#### Inbound
| Priority | Rule Name | Source | Destination | Port | Action |
|----------|-----------|--------|-------------|------|--------|
| 65000 | AllowVnetInBound | VirtualNetwork | VirtualNetwork | Any | Allow |
| 65001 | AllowAzureLoadBalancerInBound | AzureLoadBalancer | Any | Any | Allow |
| 65500 | DenyAllInBound | Any | Any | Any | **Deny** |

#### Outbound
| Priority | Rule Name | Source | Destination | Port | Action |
|----------|-----------|--------|-------------|------|--------|
| 65000 | AllowVnetOutBound | VirtualNetwork | VirtualNetwork | Any | Allow |
| 65001 | AllowInternetOutBound | Any | Internet | Any | Allow |
| 65500 | DenyAllOutBound | Any | Any | Any | **Deny** |

> 💡 By default, all **inbound internet traffic is denied**. All **outbound internet traffic is allowed**.

---

## 🏷️ Service Tags

- Pre-defined **groups of IP address ranges** for Azure services
- Simplify NSG rules — no need to know actual IP ranges
- Microsoft manages and updates service tags automatically

| Service Tag | Represents |
|------------|-----------|
| **VirtualNetwork** | All VNet address ranges |
| **Internet** | Public internet |
| **AzureLoadBalancer** | Azure infrastructure load balancer |
| **Storage** | Azure Storage IPs |
| **SQL** | Azure SQL database IPs |
| **AppService** | Azure App Service IPs |
| **AzureCloud** | All Azure datacenter IPs |
| **AzureMonitor** | Azure Monitor IPs |

---

## 🎯 Application Security Groups (ASG)

- Group VMs **logically** by application role (instead of managing IP addresses)
- Reference ASGs in NSG rules instead of IPs
- Automatically updates when VMs are added/removed from ASG

### Example Use Case
```
ASGs:
    WebServers ASG = {VM1, VM2, VM3}
    DatabaseServers ASG = {VM4, VM5}

NSG Rules:
    Allow: Internet → WebServers on port 80, 443
    Allow: WebServers → DatabaseServers on port 1433
    Deny: Internet → DatabaseServers (everything else)
```

### Creating ASGs
```bash
# Create ASGs
az network asg create --resource-group myRG --name WebServersASG
az network asg create --resource-group myRG --name DatabaseASG

# Add VM NIC to ASG
az network nic update \
  --resource-group myRG \
  --name myVM-NIC \
  --application-security-groups WebServersASG
```

---

## 🔗 NSG Association

### Subnet-level NSG
- Rules apply to **all resources** in the subnet
- Applied first (before NIC-level NSG)

### NIC-level NSG
- Rules apply to that **specific VM only**
- Applied after subnet-level NSG

### Traffic Evaluation Order
```
INBOUND TRAFFIC:
Internet → [Subnet NSG] → [NIC NSG] → VM

OUTBOUND TRAFFIC:
VM → [NIC NSG] → [Subnet NSG] → Internet
```

> ⚠️ Both subnet NSG AND NIC NSG must allow traffic for it to pass. If **either** denies, traffic is blocked.

---

## 🛠️ Creating NSG Rules

```bash
# Create an NSG
az network nsg create --resource-group myRG --name myNSG

# Add inbound rule to allow HTTP
az network nsg rule create \
  --resource-group myRG \
  --nsg-name myNSG \
  --name AllowHTTP \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 80

# Add rule to block specific IP
az network nsg rule create \
  --resource-group myRG \
  --nsg-name myNSG \
  --name DenyBadIP \
  --priority 200 \
  --direction Inbound \
  --access Deny \
  --protocol '*' \
  --source-address-prefixes '1.2.3.4' \
  --destination-port-ranges '*'

# Associate NSG to subnet
az network vnet subnet update \
  --resource-group myRG \
  --vnet-name myVNet \
  --name mySubnet \
  --network-security-group myNSG
```

---

## 🔒 Azure Firewall

### What is Azure Firewall?
- Managed, **stateful firewall** service (vs NSG which is stateless-ish)
- Central hub for traffic inspection across VNets
- **FQDN filtering** (domain names, not just IPs)
- **Threat intelligence** — block known malicious IPs/domains
- Deployed in its own subnet: **AzureFirewallSubnet** (/26 minimum)

### Azure Firewall vs NSG
| Feature | NSG | Azure Firewall |
|---------|-----|---------------|
| Type | Basic packet filter | Full stateful firewall |
| FQDN filtering | No | **Yes** |
| Threat intelligence | No | **Yes** |
| Centralized management | No | **Yes** |
| Cost | Free | Hourly + data processing |
| Scope | Subnet or NIC | Central hub |

### Forced Tunneling
- Force all internet-bound traffic through Azure Firewall
- Use **UDR** to route 0.0.0.0/0 → Azure Firewall
- Azure Firewall inspects and allows/denies based on rules

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| NSG rule evaluation | **Lower priority number = processed first** |
| Default inbound internet | **Denied** |
| Default outbound internet | **Allowed** |
| Default VNet-to-VNet | **Allowed** |
| NSG can attach to | **Subnet** or **NIC** |
| Both NSGs must allow | Yes — if subnet NSG denies, NIC NSG doesn't matter |
| Service tags managed by | **Microsoft** (auto-updated) |
| ASG purpose | Group VMs by role, simplify NSG rules |
| Azure Firewall subnet | **AzureFirewallSubnet** (/26 min) |
| Azure Firewall feature vs NSG | FQDN filtering, threat intel |

---

## 🚨 Common Exam Scenarios

**Q: You have an NSG with a rule at priority 100 (Allow port 80) and priority 200 (Deny all). A request comes in on port 80. What happens?**
→ **Allowed** — priority 100 matches first and allows it

**Q: You need to block traffic from a specific country to your VMs. What's the best approach?**
→ **Azure Firewall with threat intelligence** or **NSG with IP ranges** (or Azure Front Door with WAF for web traffic)

**Q: A VM in a subnet has both a subnet NSG (allows HTTP) and a NIC NSG (denies HTTP). Can HTTP traffic reach the VM?**
→ **No** — NIC NSG denies it. Both NSGs must allow for traffic to pass.

**Q: You want to filter outbound traffic from 100 VMs to the internet using domain names (FQDNs). What service?**
→ **Azure Firewall** — NSG cannot filter by FQDN, only IP

**Q: How do you allow multiple web servers to access only the database VMs on port 1433 without managing individual IPs?**
→ Use **Application Security Groups** — put web VMs in WebASG, DB VMs in DBASG, create NSG rule: allow WebASG → DBASG on 1433
