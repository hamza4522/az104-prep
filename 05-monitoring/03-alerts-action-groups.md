# Alerts & Action Groups

> 🎯 Exam Weight: Part of 10–15% Monitoring domain

---

## 🚨 Alert Rules Architecture

```
[Signal: Metric / Log / Activity Log] ──➔ [Condition Evaluated] ──➔ [Action Group Triggered]
                                                                        ├── Email / SMS / Push
                                                                        ├── Azure Function
                                                                        └── Automation Runbook
```

### Alert Types Comparison
| Alert Type | Latency | Stateful? | Use Case |
|------------|---------|-----------|----------|
| **Metric Alert** | Low (under 1 min) | ✅ **Yes** (resolves automatically when metric normalizes) | High CPU (> 85%), Low memory, Network bandwidth |
| **Log Search Alert** | Medium (1–15 min) | ❌ No (stateless) | Failed login spikes, specific error event in logs |
| **Activity Log Alert** | Immediate | ❌ No | VM stopped, NSG deleted, service health incident |

---

## 📢 Action Groups

- Reusable notification and automation templates triggered by alert rules:
  - **Notification Actions**: Email (to Entra ID roles or custom emails), SMS, Azure mobile app push, Voice call.
  - **Automation Actions**: Azure Automation Runbook (e.g. restart VM), Azure Function, Logic App, Webhook, Secure Webhook, ITSM integration.

---

## 🛑 Alert Processing Rules (Action Rules)

- Allows applying processing logic to fired alerts across subscriptions or resource groups
- **Primary Use Case**: **Suppress notifications during scheduled maintenance windows** (e.g. *Suppress all email notifications for VM updates every Saturday between 02:00 and 06:00*) without disabling the underlying alert rules!

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Stateful alerts with auto-resolve | **Metric alerts** |
| Suppress alerts during maintenance | **Alert Processing Rules** (Suppression) |
| Immediate alert on resource deletion | **Activity Log Alert** |
| Email notifications target | Azure AD role members or specific email addresses |

---

## 🚨 Common Exam Scenarios (Real Exam MCQs)

**Q: You have 50 virtual machines that undergo scheduled OS patching every Sunday morning. Alerts trigger emails to the on-call team during this window. You want to stop email notifications during patching without modifying or turning off the 50 alert rules.**
→ Create an **Alert Processing Rule** with the rule action set to **Suppress notifications**, scheduled to recur weekly during the Sunday patch window.

**Q: You need to receive an immediate email notification whenever any administrator deletes a network security group in Subscription1.**
→ Create an **Activity Log Alert** with the event name "Delete Network Security Group".
