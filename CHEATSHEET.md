# AZ-104 Master Cheat Sheet 🚀

> One-page rapid-review before the exam. Read this last!

---

## 🔐 Domain 1: Identity & Governance

| Topic | Key Facts |
|-------|-----------|
| Azure AD (Entra ID) | Cloud identity service — NOT Windows Server AD |
| Tenant | One Azure AD instance = one organization |
| Subscription | Billing + access boundary; tied to ONE tenant |
| Dynamic Groups | Require **Azure AD Premium P1** |
| SSPR | Requires **Azure AD Premium P1** |
| Conditional Access | Requires **Azure AD Premium P1** |
| PIM | Requires **Azure AD Premium P2** — JIT privileged access |
| **Owner** | Full access + **can assign roles** |
| **Contributor** | Full access — **CANNOT assign roles** |
| **Reader** | View only |
| **User Access Admin** | Manage access, **CANNOT manage resources** |
| RBAC scope | Inherits DOWN: Management Group → Sub → RG → Resource |
| Custom roles | No special license needed |
| Management Groups | Max **6 levels** deep, **10,000** per directory |
| Azure Policy Deny | Prevents creation of non-compliant resources |
| Azure Policy Audit | Allows but logs non-compliance |
| Azure Policy DeployIfNotExists | Auto-deploys missing resources (remediation task for existing) |
| Resource Locks | **CanNotDelete** or **ReadOnly**; override Owner role |
| ReadOnly lock | Acts like Reader for ALL — even Owners blocked |
| Tags | Max **50** per resource; do NOT inherit automatically |

---

## 💾 Domain 2: Storage

| Topic | Key Facts |
|-------|-----------|
| Storage account name | **3–24 chars**, globally unique, lowercase + numbers |
| Default storage kind | **GPv2** |
| LRS | 3 copies, same datacenter |
| ZRS | 3 copies, 3 AZs, same region |
| GRS | 6 copies, primary + secondary region |
| RA-GRS | GRS + **read access** to secondary |
| GRS readable by default | **NO** — need RA-GRS |
| Hot tier | Frequently accessed |
| Cool tier | Min **30 days** storage |
| Cold tier | Min **90 days** storage |
| Archive tier | Min **180 days**, must **rehydrate** before access (up to 15 hrs) |
| Blob types | **Block** (files), **Append** (logs), **Page** (VM disks) |
| Azure Files protocol | **SMB** (port 445) / **NFS** |
| File Sync components | Storage Sync Service, Sync Group, Cloud Endpoint, Server Endpoint |
| Cloud tiering | Stubs on-prem, full data in Azure |
| SAS revocation | Requires **Stored Access Policy** — otherwise cannot revoke |
| Most secure SAS | **User Delegation SAS** |
| Storage encryption | **AES-256**, always on |
| AzCopy | Best tool for large data migration |

---

## 💻 Domain 3: Compute

| Topic | Key Facts |
|-------|-----------|
| RDP port | **3389** |
| SSH port | **22** |
| Temp disk | **Ephemeral** — data lost on resize/reboot |
| Stopped (OS) | Still **billed** for compute |
| Deallocated | **NOT billed** for compute |
| Premium SSD requires | VM size with **'s'** (e.g., D2sv3) |
| Azure Bastion | Secure RDP/SSH without public IP, needs **AzureBastionSubnet /26** |
| Availability Set SLA | **99.95%** |
| Availability Zone SLA | **99.99%** |
| Fault Domains | Max **3** (per rack failures) |
| Update Domains | Max **20** (planned maintenance) |
| VMSS | Auto-scale group of identical VMs |
| Scale Out/In | **No restart** needed (horizontal) |
| Scale Up/Down | Requires **restart** (vertical) |
| Spot VMs | Up to 90% discount, **can be evicted** (30-sec notice) |
| App Service slots | Require **Standard** tier; max 5 (Standard), 20 (Premium) |
| Slot swap | Zero-downtime deployment |
| Sticky settings | Don't swap between slots |
| ACI | Serverless containers, billed per-second |
| AKS | Managed K8s; control plane **free** |
| Azure CNI | Pods get VNet IPs |
| Recovery Services Vault | Default redundancy **GRS** |
| Soft delete (backup) | **14 days** retention |
| ASR | Disaster Recovery (NOT backup); ~30 sec RPO |

---

## 🌐 Domain 4: Networking

| Topic | Key Facts |
|-------|-----------|
| VNet scope | **Single region** |
| Reserved IPs per subnet | **5** (first 4 + broadcast) |
| /29 usable IPs | **3** (8 - 5 reserved) |
| GatewaySubnet | Exact name required for VPN/ER gateways |
| AzureBastionSubnet | Minimum **/26** |
| VNet peering | NOT transitive; create in **both directions** |
| NSG priority | **Lower number = processed first** |
| Default inbound internet | **Denied** |
| Default outbound internet | **Allowed** |
| Service Tags | Pre-defined IP groups, managed by Microsoft |
| ASG | Group VMs by role, use in NSG rules |
| Azure Firewall vs NSG | Firewall: FQDN filtering, threat intel, centralized |
| Load Balancer | Layer **4**, regional |
| Application Gateway | Layer **7**, regional, WAF |
| Traffic Manager | **DNS-based**, global |
| Front Door | Layer **7**, global, CDN |
| Site-to-Site VPN | IPSec over internet, entire network |
| Point-to-Site VPN | Individual client, needs route-based VPN |
| VPN Gateway creation | Takes **30–45 minutes** |
| ExpressRoute | Private circuit, NOT over internet, up to **100 Gbps** |
| Policy-based VPN | Max **1 tunnel**, legacy |
| Route-based VPN | Multiple tunnels, modern |
| IP Flow Verify | Test NSG **allow/deny** |
| Next Hop | Test **routing** path |
| Connection Monitor | **Continuous** connectivity monitoring |
| NSG Flow Logs | Log all traffic through NSG |

---

## 📊 Domain 5: Monitoring

| Topic | Key Facts |
|-------|-----------|
| Azure Monitor | Central monitoring platform |
| Metrics retention | **93 days** |
| Activity Log retention | **90 days** default |
| Activity Log captures | Control plane — **who did what, when** |
| Diagnostic Settings | Configure where resource logs go |
| Log Analytics | Log store + KQL query engine |
| Log retention default | **30 days** (free) |
| Log retention max | **730 days** (2 years) |
| AMA (Azure Monitor Agent) | New recommended agent, uses **DCR** |
| KQL for logs | Used in Log Analytics |
| Application Insights | App-level monitoring (requests, deps, exceptions) |
| Alert severity | 0 (Critical) → 4 (Verbose) |
| Action Group | What to do when alert fires (email, runbook, webhook) |
| Dynamic threshold alerts | ML-based, adapts to patterns |
| Activity Log Alert | Alert on operations (delete, stop, etc.) |
| Alert Processing Rules | Suppress alerts during maintenance |

---

## ⚡ Last-Minute Power Facts

### Subnet Math
| CIDR | Total IPs | Usable |
|------|-----------|--------|
| /29 | 8 | **3** |
| /28 | 16 | **11** |
| /27 | 32 | **27** |
| /26 | 64 | **59** |
| /25 | 128 | **123** |
| /24 | 256 | **251** |

### License Requirements
| Feature | Requires |
|---------|---------|
| Dynamic groups | Azure AD **Premium P1** |
| SSPR | Azure AD **Premium P1** |
| Conditional Access | Azure AD **Premium P1** |
| PIM | Azure AD **Premium P2** |
| Custom roles | **No special license** |
| RBAC | **No special license** |

### SLAs
| Config | SLA |
|--------|-----|
| Single VM + Premium SSD | 99.9% |
| Availability Set | 99.95% |
| Availability Zones | **99.99%** |
| App Service (Standard+) | 99.95% |
| Azure SQL | 99.99% |

### Key "Gotchas"
1. **OS stop ≠ deallocate** — still billed after OS shutdown
2. **GRS ≠ readable** — need RA-GRS for read access to secondary
3. **RBAC Contributor can't assign roles** — needs Owner
4. **Policy Deny doesn't fix existing** — need remediation task
5. **Tags don't inherit** — need Azure Policy (Modify effect)
6. **VNet peering not transitive** — direct peering needed for all pairs
7. **NSG both directions** — subnet NSG AND NIC NSG must both allow
8. **ReadOnly lock blocks everyone** — including Owners
9. **Archive = offline** — must rehydrate before reading (up to 15 hrs)
10. **VPN Gateway takes 30-45 min**

## 🆕 Additional Topics (Added Coverage)

| Topic | Key Facts |
|-------|-----------|
| System-assigned MI | Tied to ONE resource, **deleted with resource** |
| User-assigned MI | Independent, assignable to **many resources** |
| MI credentials | Managed by **Azure** — no passwords, no rotation |
| IMDS endpoint | **169.254.169.254** — internal metadata endpoint |
| Key Vault tiers | Standard (software) / **Premium (HSM-protected)** |
| Key Vault soft delete | **Enabled by default**, 90-day retention |
| Purge protection | Prevents purge during retention; **cannot disable once enabled** |
| Key Vault RBAC | Recommended over Access Policies |
| Key Vault Secrets User | Read secrets only (assign to apps/MIs) |
| App Service KV ref | `@Microsoft.KeyVault(VaultName=...;SecretName=...)` |
| ARM template deployment | **Incremental** (default) or **Complete** (deletes extras) |
| ARM Complete mode | **DELETES** resources in RG not in template — dangerous! |
| ARM What-If | Preview changes without deploying |
| Bicep | Simpler syntax, compiles to ARM, no state file |
| Template Specs | Store templates in Azure with versioning |
| Hub-Spoke | Hub = shared services (firewall, VPN gateway) |
| Spoke-to-spoke | NOT direct — route through **hub firewall + UDR** |
| Allow gateway transit | Set on **Hub's peering** |
| Use remote gateways | Set on **Spoke's peering** |
| Azure Virtual WAN | Microsoft-managed hub-spoke |
| Private Endpoint | Private IP in VNet for Azure PaaS services |
| Private DNS Zone | **Required** for private endpoint DNS resolution |
| DNS zone must be | Linked to every VNet that needs to resolve |
| Service endpoint | VNet-routed but still public IP |
| Azure Automation | Runbooks, Update Management, DSC, Change Tracking |
| Hybrid Runbook Worker | Run runbooks against on-prem resources |
| Update Management | Patch VMs; requires Log Analytics workspace |
| DSC ApplyAndAutoCorrect | **Auto-fixes** configuration drift |
| Azure Advisor | FREE recommendations: Cost, Security, Reliability, Performance, OpEx |
| Secure Score | **0–100** in Defender for Cloud |
| JIT VM Access | Requires **Defender for Servers**; ports closed by default |
| Defender Plans | Paid, per-workload protection (Servers, Storage, SQL, etc.) |

---

## ⚡ Quick Tips for Exam Day!

---

**Good luck on the exam! You've got this! 💪🎯**
