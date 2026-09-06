# AZ-104 Practice Exam — 50 Questions

> ⏱️ **Exam format**: 50 questions, allow 90 minutes (real exam is ~60 questions, 120 min)
> 📝 **Instructions**: Answer all questions, then check answers at the bottom
> 🎯 **Pass mark**: 36/50 (72%) — aim for 40+ to be safe

---

## 📋 Questions

---

### Domain 1: Identity & Governance (Q1–Q15)

**Q1.** A company has 500 users in Azure AD. They want users in the Sales department to automatically be added to the "SalesTeam" security group. What is required?

- A) Azure AD Basic
- B) Azure AD Free
- C) Azure AD Premium P1
- D) Azure AD Premium P2

---

**Q2.** A user has the Contributor role on a resource group. They try to assign the Reader role to another user on the same resource group. What happens?

- A) The role assignment succeeds
- B) The action is blocked — Contributor cannot assign roles
- C) The action succeeds but requires MFA
- D) The action is logged but allowed

---

**Q3.** Your company uses Azure AD Connect with Password Hash Sync. The on-premises Active Directory goes offline. What happens to Azure AD authentication?

- A) All authentication fails immediately
- B) Authentication continues using the synced password hashes
- C) Users are redirected to the on-premises domain controller
- D) Authentication requires admin intervention to continue

---

**Q4.** A management group contains 3 subscriptions. You assign the Reader role at the management group level. What is the effect?

- A) Only the management group itself gets Reader access
- B) Each subscription admin must individually apply the Reader role
- C) All users in the subscriptions get Reader role automatically
- D) The Reader role is inherited by all subscriptions and their resources

---

**Q5.** You apply an Azure Policy with "Deny" effect requiring the tag "Environment" on all resources. You then deploy a VM without this tag. What happens?

- A) The VM deploys successfully and a compliance report is generated
- B) The VM deployment is blocked
- C) The VM deploys but is flagged as non-compliant
- D) The tag "Environment" is automatically added with value "Unknown"

---

**Q6.** An administrator applies a ReadOnly lock to a storage account. A user with Owner role tries to upload a blob. What happens?

- A) Upload succeeds because Owner overrides locks
- B) Upload fails — ReadOnly lock prevents all write operations
- C) Upload succeeds but is logged for audit
- D) User must request temporary lock removal via PIM

---

**Q7.** You need users to access elevated permissions only when needed, with approval required and a time limit. What do you configure?

- A) Azure AD Conditional Access
- B) Azure RBAC with custom roles
- C) Azure AD Privileged Identity Management (PIM)
- D) Azure AD Identity Protection

---

**Q8.** An organization wants to ensure all new resources in a subscription are deployed only in East US or West US regions. What is the most efficient approach?

- A) Configure NSG rules to block other regions
- B) Apply an Azure Policy with "Allowed Locations" and Deny effect
- C) Set the subscription default region to East US
- D) Create a custom RBAC role that restricts region selection

---

**Q9.** A VM needs to access Azure Key Vault without storing any credentials in code. What is the best solution?

- A) Store the Key Vault access key in an environment variable
- B) Use a shared access signature (SAS) token stored in config
- C) Assign a system-assigned managed identity to the VM and grant it Key Vault access
- D) Create a service principal with a client secret and embed it in code

---

**Q10.** Which Azure AD license is required for Azure AD Privileged Identity Management (PIM)?

- A) Azure AD Free
- B) Azure AD Premium P1
- C) Azure AD Premium P2
- D) Microsoft 365 E3

---

**Q11.** A Key Vault secret was accidentally deleted. Soft delete is enabled with a 90-day retention. What can you do?

- A) The secret is permanently deleted and cannot be recovered
- B) Recover the secret within the 90-day retention period
- C) Only Microsoft support can recover the secret
- D) Restore from the last backup taken before deletion

---

**Q12.** You have 3 subscriptions. You want to apply the same Azure Policy to all 3 with minimum effort. What do you use?

- A) Apply the policy to each subscription individually
- B) Create a management group containing all 3 subscriptions and apply the policy there
- C) Use Azure Blueprints to apply policies
- D) Create a policy initiative for each subscription

---

**Q13.** A user-assigned managed identity is assigned to a VM. The VM is deleted. What happens to the managed identity?

- A) It is automatically deleted with the VM
- B) It remains and can be reassigned to other resources
- C) It is disabled but not deleted
- D) It becomes unmanaged and must be manually cleaned up within 30 days

---

**Q14.** Tags on a resource group are NOT automatically inherited by resources inside the group. How do you enforce tag inheritance?

- A) Enable the "Inherit tags" option in the resource group settings
- B) Use an Azure Policy with the Modify effect to copy tags from resource group to resources
- C) Use RBAC to require users to set tags on resource creation
- D) Configure tag inheritance in Azure Cost Management

---

**Q15.** Your subscription has a resource group with a CanNotDelete lock. An admin tries to delete the resource group. What happens?

- A) The deletion succeeds because admins bypass locks
- B) The deletion is blocked — the lock must be removed first
- C) Only the resources inside are protected; the empty group can be deleted
- D) The deletion requires MFA approval

---

### Domain 2: Storage (Q16–Q22)

**Q16.** A company stores compliance data that must be readable within minutes but is rarely accessed. The data must be stored for 10 years at minimum cost. Which blob access tier should they start with?

- A) Hot
- B) Cool
- C) Cold
- D) Archive

---

**Q17.** You created a SAS token for a contractor with 30-day access to a storage container. After 5 days, the contractor leaves. How do you immediately revoke access?

- A) Change the storage account access key
- B) Delete the container and recreate it
- C) Modify or delete the Stored Access Policy the SAS was based on
- D) Set the container to private access

---

**Q18.** A storage account is configured with RA-GRS. The primary region goes down. What can clients do?

- A) Nothing — data is unavailable until primary recovers
- B) Read and write to the secondary endpoint
- C) Read from the secondary endpoint (read-only)
- D) Automatically failover to secondary for read/write

---

**Q19.** You need to automatically move blobs that haven't been accessed for 60 days to the Archive tier. What do you configure?

- A) Azure Automation runbook to manually move blobs
- B) Blob storage lifecycle management policy
- C) Azure Policy with DeployIfNotExists effect
- D) Storage account replication settings

---

**Q20.** An on-premises team needs to mount a file share on their Windows servers and access files as a network drive. The port 445 is open. What Azure service do you use?

- A) Azure Blob Storage
- B) Azure Table Storage
- C) Azure Files with SMB
- D) Azure Data Lake Storage

---

**Q21.** You need to copy 5 TB of data from on-premises to Azure Blob Storage as quickly as possible. What tool is most appropriate?

- A) Azure Portal (drag and drop)
- B) Azure Storage Explorer
- C) AzCopy
- D) Azure Import/Export Service

---

**Q22.** A developer requests temporary read access to a specific blob for exactly 2 hours. What is the most secure way to provide this?

- A) Share the storage account access key
- B) Set the blob container to public (blob) access
- C) Generate a SAS token with read permission and 2-hour expiry
- D) Add the developer as a Storage Account Contributor

---

### Domain 3: Compute (Q23–Q32)

**Q23.** A VM is stopped from within the Windows operating system using the Shutdown command. Is the customer still charged for compute?

- A) No — the VM is stopped so no compute charges apply
- B) Yes — the VM must be deallocated from Azure to stop compute charges
- C) No — Windows shutdown automatically deallocates the VM in Azure
- D) Yes — for 1 hour after shutdown, then charges stop

---

**Q24.** You need 99.99% SLA for your web application running on VMs. What configuration is required?

- A) Single VM with Premium SSD
- B) Two VMs in the same availability set
- C) Two VMs each in different availability zones
- D) Three VMs in the same region

---

**Q25.** A VM scale set needs to scale out when CPU exceeds 75% and scale in when CPU drops below 25%. What do you configure?

- A) Schedule-based scaling rules
- B) Metric-based autoscale rules
- C) Manual scaling with Azure Automation
- D) Azure Load Balancer health probe-based scaling

---

**Q26.** An App Service web app uses a staging deployment slot. The staging slot uses a staging database connection string. After a slot swap to production, which database should the production slot use?

- A) The staging database (connection string swapped with code)
- B) The production database (if the connection string is marked as slot-specific/sticky)
- C) The production database automatically
- D) No database until manually reconfigured

---

**Q27.** You need to run a batch processing job in a container that should run once and exit. No servers should be managed. What service and restart policy?

- A) AKS with Always restart policy
- B) ACI with Never restart policy
- C) App Service with Docker container
- D) Azure Functions with container trigger

---

**Q28.** An ARM template is deployed to a resource group in Complete mode. The resource group previously had 5 resources, but the template only defines 3. What happens?

- A) Only the 3 resources in the template are deployed; the 2 extras are left unchanged
- B) The deployment fails because of missing resources
- C) The 3 resources are deployed and the 2 resources NOT in the template are deleted
- D) All 5 resources are redeployed with the template settings

---

**Q29.** A VM needs to process unpredictable workloads and cost must be minimized. It's acceptable for the VM to be evicted with 30 seconds notice. What VM type?

- A) Reserved VM instance
- B) On-demand (pay-as-you-go) VM
- C) Azure Spot VM
- D) Low-priority VM in Batch

---

**Q30.** You need to back up Azure VMs to be able to restore individual files. What restore type in Azure Backup allows this?

- A) Create new VM
- B) Restore disk
- C) File recovery
- D) Replace existing disk

---

**Q31.** A company needs disaster recovery for their Azure VMs with an RTO of 2 hours and RPO near-zero. What service?

- A) Azure Backup with GRS vault
- B) Azure Site Recovery
- C) Azure VM snapshots
- D) Manual VM copy to secondary region

---

**Q32.** Which AKS networking mode gives each pod an IP address from the VNet's address space, enabling direct communication with other Azure resources?

- A) Kubenet
- B) Azure CNI
- C) Azure CNI Overlay
- D) Calico

---

### Domain 4: Networking (Q33–Q44)

**Q33.** A /26 subnet is created. How many IP addresses are available for Azure resources?

- A) 62
- B) 64
- C) 59
- D) 58

---

**Q34.** VNetA is peered with VNetB. VNetB is peered with VNetC. A VM in VNetA tries to reach a VM in VNetC. What happens?

- A) Connection succeeds because peering is transitive
- B) Connection fails — VNet peering is not transitive
- C) Connection succeeds only if all VNets are in the same region
- D) Connection succeeds after enabling "Allow forwarded traffic"

---

**Q35.** An NSG has these inbound rules:
- Priority 100: Allow TCP 80 from Any
- Priority 200: Deny TCP 80 from 10.0.0.5
- Priority 300: Allow Any from Any

A request comes from 10.0.0.5 on port 80. What happens?

- A) Request is denied (priority 200)
- B) Request is allowed (priority 100 matches first)
- C) Request is denied (priority 300 overrides)
- D) Request is allowed (allow rules override deny rules)

---

**Q36.** You need to route all internet-bound traffic from a subnet through Azure Firewall. What do you configure?

- A) Update the NSG to redirect traffic to Azure Firewall
- B) Add a firewall rule in Azure Firewall to capture all traffic
- C) Create a User-Defined Route (UDR) with 0.0.0.0/0 → Azure Firewall private IP
- D) Configure DNS to resolve all domains through the firewall

---

**Q37.** A web application receives traffic from the internet and needs URL-based routing (/api/* → API servers, /web/* → web servers). It must also protect against SQL injection. What service?

- A) Azure Load Balancer with NAT rules
- B) Azure Traffic Manager with performance routing
- C) Azure Application Gateway with WAF
- D) Azure Front Door with custom routing rules

---

**Q38.** Users in Europe must connect to the nearest Azure region for the lowest latency. The application runs in West Europe and East US. What Traffic Manager routing method?

- A) Priority
- B) Weighted
- C) Geographic
- D) Performance

---

**Q39.** Your company needs to connect the on-premises network to Azure with 5 Gbps bandwidth, consistent latency, and without using the public internet. What do you use?

- A) Site-to-Site VPN with VpnGw3
- B) Azure ExpressRoute
- C) Point-to-Site VPN
- D) Azure Virtual WAN with S2S VPN

---

**Q40.** You deployed a VPN Gateway but forgot to use the exact name for the gateway subnet. What issue will you face?

- A) The VPN Gateway deploys but has limited functionality
- B) The VPN Gateway deployment fails — subnet must be named exactly "GatewaySubnet"
- C) Azure automatically renames the subnet
- D) The gateway deploys but on-premises connectivity is unavailable

---

**Q41.** A storage account has a private endpoint. VMs in VNetA can access it. VMs in VNetB (peered to VNetA) cannot resolve the storage hostname to the private IP. What is missing?

- A) VNet peering needs to be re-created
- B) A service endpoint must be enabled on VNetB
- C) The private DNS zone must be linked to VNetB
- D) The private endpoint must be recreated in VNetB

---

**Q42.** You need to diagnose why traffic is being blocked between two VMs. You want to quickly identify which NSG rule is causing the issue. What Network Watcher tool do you use?

- A) Next hop
- B) Packet capture
- C) IP flow verify
- D) Connection Monitor

---

**Q43.** A spoke VNet needs to communicate with on-premises resources through the VPN gateway in the hub VNet. What settings must be configured?

- A) Create a new VPN gateway in the spoke VNet
- B) Hub peering: Allow gateway transit = true. Spoke peering: Use remote gateways = true
- C) Hub peering: Use remote gateways = true. Spoke peering: Allow gateway transit = true
- D) Enable BGP on both VNets

---

**Q44.** Azure DNS is used to host `contoso.com`. You want to create a record for the root domain (`@`) that points to an Azure Traffic Manager profile. What record type do you create?

- A) CNAME record at @
- B) A record at @ pointing to Traffic Manager IP
- C) Alias record at @ pointing to Traffic Manager profile
- D) NS record at @ pointing to Traffic Manager

---

### Domain 5: Monitoring (Q45–Q50)

**Q45.** An administrator deleted a VM. You need to find out who deleted it and when. What do you check?

- A) VM diagnostic logs
- B) Azure Monitor Metrics
- C) Azure Activity Log
- D) Log Analytics Performance table

---

**Q46.** Azure Monitor stores metrics for how long by default?

- A) 30 days
- B) 90 days
- C) 93 days
- D) 730 days

---

**Q47.** You want an alert that fires when more than 10 login failures occur within 5 minutes. What type of alert do you create?

- A) Metric alert with static threshold
- B) Log alert using a KQL query on SecurityEvent table
- C) Activity log alert
- D) Resource health alert

---

**Q48.** An organization wants to automatically restart a VM when a CPU alert fires. What action group action type do you configure?

- A) Email notification
- B) Logic App
- C) Automation Runbook
- D) Webhook to ITSM

---

**Q49.** Azure Advisor shows a recommendation to enable MFA for admin accounts. Under which Advisor category does this appear?

- A) Cost
- B) Performance
- C) Operational Excellence
- D) Security

---

**Q50.** Microsoft Defender for Cloud provides a numeric score that represents your overall security posture. What is this called, and what is its range?

- A) Security Rating, 0–10
- B) Secure Score, 0–100
- C) Compliance Score, 0–1000
- D) Risk Score, A–F

---

---

## ✅ Answers & Explanations

| Q | Answer | Key Explanation |
|---|--------|----------------|
| 1 | **C** | Dynamic groups require **Azure AD Premium P1** |
| 2 | **B** | Contributor can manage resources but **cannot assign roles** — only Owner can |
| 3 | **B** | Password Hash Sync stores hash in Azure AD — works even if on-prem AD is down |
| 4 | **D** | RBAC at management group **inherits down** to all subscriptions and their resources |
| 5 | **B** | Policy with **Deny** effect **blocks** non-compliant resource creation |
| 6 | **B** | **ReadOnly lock** prevents ALL write operations — even for Owners |
| 7 | **C** | **PIM** provides JIT access with approval and time limits — requires Premium P2 |
| 8 | **B** | **Azure Policy** with Allowed Locations + **Deny** effect is the most efficient approach |
| 9 | **C** | **Managed Identity** — no credentials needed, Azure manages authentication |
| 10 | **C** | PIM requires **Azure AD Premium P2** |
| 11 | **B** | Soft delete retains secrets — **recover within retention period** |
| 12 | **B** | **Management group** lets you apply policy once and it inherits to all subscriptions |
| 13 | **B** | User-assigned MI is **independent** — lives beyond the resource it's assigned to |
| 14 | **B** | **Azure Policy with Modify** effect is used to inherit/copy tags from RG to resources |
| 15 | **B** | **CanNotDelete lock** blocks deletion — lock must be removed first |
| 16 | **C** | **Cold** tier — lower cost than Hot/Cool, accessible within minutes (not offline like Archive) |
| 17 | **C** | **Stored Access Policy** allows SAS revocation by modifying/deleting the policy |
| 18 | **C** | **RA-GRS** provides **read-only** access to secondary — NOT read/write |
| 19 | **B** | **Lifecycle management policy** automates tier transitions based on last-modified date |
| 20 | **C** | **Azure Files with SMB** — mounts as network drive via port 445 |
| 21 | **C** | **AzCopy** — optimized for large-scale, high-speed data transfers |
| 22 | **C** | **SAS token** with read permission and 2-hour expiry — least privilege, time-limited |
| 23 | **B** | OS Shutdown = **Stopped state** — still billed. Must **Deallocate** from Azure to stop billing |
| 24 | **C** | **Availability Zones** = 99.99% SLA. Availability Sets only give 99.95% |
| 25 | **B** | **Metric-based autoscale** triggers scale out/in based on CPU percentage |
| 26 | **B** | **Sticky (slot-specific)** connection strings don't swap — production slot keeps production DB |
| 27 | **B** | **ACI with Never** restart policy — runs once and exits, fully serverless |
| 28 | **C** | **Complete mode deletes** resources in the RG that are NOT in the template |
| 29 | **C** | **Azure Spot VMs** — cheapest option, can be evicted with 30-sec notice |
| 30 | **C** | **File recovery** — mount recovery point and copy individual files/folders |
| 31 | **B** | **Azure Site Recovery** — for DR/failover, ~30 sec RPO, 2hr RTO target |
| 32 | **B** | **Azure CNI** — each pod gets a VNet IP, enabling direct Azure resource communication |
| 33 | **C** | /26 = 64 total − 5 reserved = **59 usable** |
| 34 | **B** | VNet peering is **NOT transitive** — VNetA cannot reach VNetC through VNetB |
| 35 | **B** | Priority 100 matches first (Allow TCP 80) — **first matching rule wins** |
| 36 | **C** | **UDR** with 0.0.0.0/0 → Azure Firewall IP forces all internet traffic through firewall |
| 37 | **C** | **Application Gateway with WAF** — Layer 7, URL-based routing, SQL injection protection |
| 38 | **D** | **Performance** routing sends users to the lowest-latency endpoint |
| 39 | **B** | **Azure ExpressRoute** — private circuit, 5+ Gbps, consistent latency, no public internet |
| 40 | **B** | Subnet must be named exactly **"GatewaySubnet"** — deployment fails otherwise |
| 41 | **C** | **Private DNS Zone must be linked** to VNetB for DNS to resolve to private IP |
| 42 | **C** | **IP flow verify** — tests which NSG rule allows/denies a specific traffic flow |
| 43 | **B** | Hub: **Allow gateway transit = true**. Spoke: **Use remote gateways = true** |
| 44 | **C** | **Alias record** — CNAME not allowed at zone root; alias records support Traffic Manager |
| 45 | **C** | **Activity Log** — records all control-plane operations including who deleted what |
| 46 | **C** | Azure Monitor metrics retained for **93 days** |
| 47 | **B** | **Log alert with KQL query** on SecurityEvent table — count login failures over time |
| 48 | **C** | **Automation Runbook** — triggered by alert to automatically restart the VM |
| 49 | **D** | MFA recommendations appear under **Security** category in Azure Advisor |
| 50 | **B** | **Secure Score, 0–100** — higher is better security posture |

---

## 📊 Your Score

| Score | Result | Action |
|-------|--------|--------|
| 45–50 | 🏆 Excellent — Ready! | Book your exam! |
| 40–44 | ✅ Good — Almost there | Review wrong answers, 1 more day |
| 36–39 | ⚠️ Borderline — Need work | Focus on weak domains, retake practice |
| < 36 | ❌ Not ready | Review all study files thoroughly |

---

## 🎯 Review Focus Areas

After taking the test, identify which domain you got wrong and review:
- Mostly Domain 1 wrong → Re-read: RBAC, Policy, Managed Identities, Key Vault
- Mostly Domain 2 wrong → Re-read: Redundancy tiers, SAS, Archive tier
- Mostly Domain 3 wrong → Re-read: VM states/billing, Availability Zones, ACI vs AKS
- Mostly Domain 4 wrong → Re-read: NSG rules, Peering, Load balancer types, VPN vs ER
- Mostly Domain 5 wrong → Re-read: Activity Log, Alert types, Secure Score
