# Azure Advisor & Defender for Cloud

> 🎯 Exam Weight: Part of 10–15% Monitoring domain

---

## 💡 Azure Advisor: The 5 Pillars

Azure Advisor analyzes resource telemetry and configurations to provide personalized, actionable recommendations across 5 pillars:

| Pillar | Example Recommendations Tested on Exam |
|--------|----------------------------------------|
| **Cost** | Shut down or resize **underutilized virtual machines** (CPU <= 5% and network <= 2% over 7 days), buy Reserved Instances |
| **Security** | Integrate with Microsoft Defender for Cloud recommendations |
| **Reliability (HA)**| Deploy VMs across Availability Zones, add backup to VMs, configure gateway redundancy |
| **Performance** | Improve database query performance, resize choked disks, scale out App Services |
| **Operational Excellence**| Enforce Azure Policy, resolve invalid service health alerts |

---

## 🛡️ Microsoft Defender for Cloud

- **Cloud Security Posture Management (CSPM)** and **Cloud Workload Protection (CWPP)**
- **Secure Score**: Single unified measurement of organizational security hygiene (higher score = lower risk)
- Provides automatic remediation steps and regulatory compliance mapping (NIST, CIS, PCI-DSS)

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Identify underutilized VMs to reduce cost | **Azure Advisor (Cost recommendations)** |
| 5 Advisor categories | Cost, Security, Reliability, Performance, Operational Excellence |
| Single metric for cloud security posture | **Secure Score** in Defender for Cloud |

---

## 🚨 Common Exam Scenarios (Real Exam MCQs)

**Q: A company wants to quickly identify underutilized virtual machines across 10 subscriptions that can be resized or shut down to minimize monthly billing.**
→ In the Azure portal, open **Azure Advisor** and review the **Cost** recommendations.
