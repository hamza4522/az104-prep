# Azure Advisor & Microsoft Defender for Cloud

> 🎯 Exam Weight: Part of 10–15% Monitoring domain

---

## 🧠 Azure Advisor

### What is Azure Advisor?
- **Free** personalized recommendation engine for Azure resources
- Analyzes your resource configuration and usage telemetry
- Provides actionable recommendations to optimize your Azure deployments

### Recommendation Categories

| Category | What It Analyzes | Examples |
|----------|-----------------|---------|
| **Cost** | Spending optimization | Right-size underused VMs, delete idle resources, use reservations |
| **Security** | Security posture | Enable MFA, apply disk encryption, update NSG rules |
| **Reliability** | High availability | Add redundancy, enable backup, use Availability Zones |
| **Operational Excellence** | Management | Apply tags, enable diagnostics, fix deployment issues |
| **Performance** | Speed & responsiveness | Upgrade VM SKU, use Premium SSD, CDN for static content |

> 💡 **Advisor aggregates** recommendations from multiple services: Cost Management, Defender for Cloud, Monitor, etc.

### Advisor Score
- Overall score (0–100) across all categories
- Track improvement over time
- Identify the highest-impact changes

### Advisor Alerts
- Get notified when new recommendations appear
- Set up alerts for specific recommendation categories

### Suppressing Recommendations
- Dismiss (forever) or snooze (temporary) recommendations you don't want to act on
- Document reason for dismissal

```bash
# View Advisor recommendations via CLI
az advisor recommendation list --output table

# View by category
az advisor recommendation list --category Cost --output table
```

---

## 🛡️ Microsoft Defender for Cloud

### What is Defender for Cloud?
- **Cloud Security Posture Management (CSPM)** + **Cloud Workload Protection Platform (CWPP)**
- Continuously assesses security configuration and provides recommendations
- Protects Azure, hybrid (on-prem), and multi-cloud (AWS, GCP) resources

### Two Main Functions

| Function | Description |
|----------|-------------|
| **CSPM** (free) | Security recommendations, Secure Score, compliance assessment |
| **CWPP** (paid — Defender Plans) | Threat detection, advanced protection per workload type |

---

## 📊 Secure Score

- **Numeric score** (0–100) representing your overall security posture
- Each recommendation has a score impact
- Higher score = better security
- Track improvement as you remediate issues

### Secure Score Calculation
```
Secure Score = (Points achieved / Max possible points) × 100
```

---

## 🔐 Defender Plans (Paid Protection)

| Plan | Protects |
|------|---------|
| **Defender for Servers** | VMs — vulnerability assessment, JIT VM access, file integrity monitoring |
| **Defender for Storage** | Storage accounts — malware scanning, sensitive data discovery |
| **Defender for SQL** | SQL databases — SQL injection detection, anomaly detection |
| **Defender for Containers** | AKS, container registries — vulnerability scanning, runtime protection |
| **Defender for App Service** | App Service — detect web attacks |
| **Defender for Key Vault** | Unusual access pattern detection |
| **Defender for DNS** | DNS layer anomaly detection |

> ⚠️ Each plan is **priced separately** — you can enable only what you need.

---

## 🚨 Security Alerts

- Detect **active threats** against your resources
- Alert types: suspicious activity, malware, credential attacks, lateral movement
- Alerts have severity: High, Medium, Low, Informational
- Can trigger **Logic Apps** or **Automation** for automated response

### Workflow Automation
- Automatically respond to alerts and recommendations using **Logic Apps** or **Automation Runbooks**
- Trigger: new security alert or recommendation
- Action: notify team, remediate automatically, create ticket

---

## ✅ Regulatory Compliance

- Assess resources against **compliance standards**:
  - Azure Security Benchmark (ASB)
  - PCI DSS
  - ISO 27001
  - NIST SP 800-53
  - SOC 2
  - HIPAA/HITRUST
- View compliance status and which controls are failing

---

## 🔑 Just-in-Time (JIT) VM Access

- Opens RDP/SSH ports **only when needed** for a specified IP and time period
- Requires **Defender for Servers** plan
- Reduces attack surface — ports are closed by default
- Admin requests access → JIT opens port for specified duration → auto-closes

### How JIT Works
1. Admin enables JIT on a VM
2. NSG rules default to **deny** for RDP/SSH
3. Admin requests access (from portal or CLI)
4. JIT **temporarily opens** port for specified IP and time
5. After time expires, port **automatically closed**

---

## 🔍 Vulnerability Assessment

- Powered by **Qualys** (integrated) or **Microsoft Defender Vulnerability Management**
- Scans VMs for OS and software vulnerabilities
- Requires **Defender for Servers** plan
- Results appear in Defender for Cloud recommendations

---

## 🌐 Cloud Security Posture (Multi-Cloud)

- Connect **AWS** and **GCP** accounts to Defender for Cloud
- Unified security posture across multiple clouds
- Recommendations for AWS/GCP resources

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| Azure Advisor cost | **Free** |
| Advisor categories | Cost, Security, Reliability, Operational Excellence, Performance |
| Defender for Cloud free tier | **CSPM** + basic recommendations |
| Defender for Cloud paid | **Defender Plans** (per workload) |
| Secure Score range | **0–100** |
| JIT VM Access requires | **Defender for Servers** |
| JIT default NSG rule | **Deny** RDP/SSH |
| Compliance standards | PCI DSS, ISO 27001, NIST, SOC 2, HIPAA |
| Multi-cloud support | AWS, GCP, on-premises (via Arc) |
| Workflow automation | Logic Apps or Automation Runbooks |

---

## 🚨 Common Exam Scenarios

**Q: An organization wants to reduce Azure costs. Which free Azure service provides recommendations for right-sizing VMs?**
→ **Azure Advisor** — Cost recommendations category

**Q: You need to ensure port 3389 (RDP) is only open when administrators explicitly need it and automatically closes. What do you configure?**
→ **JIT (Just-in-Time) VM Access** in Microsoft Defender for Cloud

**Q: A company wants to check if their Azure environment complies with PCI DSS. What service provides this assessment?**
→ **Microsoft Defender for Cloud** — Regulatory Compliance dashboard

**Q: You want a single number that represents your organization's overall Azure security posture. What metric does Defender for Cloud provide?**
→ **Secure Score** (0–100)

**Q: Azure Advisor shows a recommendation to add availability zones to your VMs. Under which category does this appear?**
→ **Reliability** (high availability recommendations)
