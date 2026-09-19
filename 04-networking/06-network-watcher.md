# Azure Network Watcher

> 🎯 Exam Weight: Part of 25–30% Networking domain — HIGH FREQUENCY DIAGNOSTICS!

---

## 🔑 What is Network Watcher?

- Regional service providing network **monitoring, diagnostic, and analytics tools** for Azure IaaS resources
- Automatically enabled in each region when a VNet is created

---

## 🛠️ Diagnostic Tools Matrix (Tested on Exam!)

| Tool | What It Does | Tested Exam Scenario |
|------|--------------|----------------------|
| **IP Flow Verify** | Checks if a packet is allowed or denied based on 5-tuple (source/dest IP, port, protocol) | **Diagnose why traffic is blocked and identify the exact NSG rule responsible** |
| **Next Hop** | Determines the routing path and next hop type for a destination IP | **Troubleshoot UDR routing issues or verify traffic routes to a firewall/NVA** |
| **Connection Troubleshoot** | Tests end-to-end TCP connectivity and latency from a VM to an IP, FQDN, or URI | Verify if a VM can connect to an external API or database |
| **Packet Capture** | Records network traffic packets (.cap) directly on the VM NIC | Deep inspection of network payloads using Wireshark |
| **NSG Flow Logs** | Logs 5-tuple IP traffic traversing an NSG into a storage account | Audit traffic, analyze patterns with **Traffic Analytics** |
| **Effective Security Rules** | Displays all aggregated NSG rules applied to a specific NIC | View combined Subnet + NIC rule results |

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Find which NSG rule blocked a packet | **IP Flow Verify** |
| Check if a VM route goes to virtual appliance | **Next Hop** |
| Diagnose end-to-end latency & reachability | **Connection Troubleshoot** |
| Packet capture file format | `.cap` (stored in Azure Storage Account) |
| Visualize NSG flow trends | **Traffic Analytics** (integrated with Log Analytics) |

---

## 🚨 Common Exam Scenarios (Real Exam MCQs)

**Q: Users report that connections to a web server on VM1 over port 443 fail intermittently. You need to identify which Network Security Group rule is blocking the traffic.**
→ In Network Watcher, run **IP Flow Verify**, specifying the source IP, destination IP of VM1, port 443, and protocol TCP. The tool will return `Deny` and display the name of the blocking rule.

**Q: You configured a user-defined route table on Subnet1 to route all internet traffic through an Azure Firewall. You need to verify that outbound packets from VM1 are indeed routing to the firewall.**
→ Run the **Next Hop** diagnostic tool from Network Watcher. It will return the next hop type (`VirtualAppliance`) and the IP address of the firewall.
