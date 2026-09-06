# Network Watcher

> 🎯 Exam Weight: Part of 25–30% Networking domain

---

## 🔑 What is Network Watcher?

- Suite of **networking diagnostics and monitoring tools**
- Diagnose connectivity issues, capture packets, view topology
- Must be **enabled per region** (auto-enabled when you create a VNet in a region)

---

## 🛠️ Network Watcher Tools

### Monitoring Tools
| Tool | Description |
|------|-------------|
| **Topology** | Visual map of resources and their relationships in a VNet |
| **Connection Monitor** | Monitor connectivity between endpoints over time |
| **Network Performance Monitor** | Hybrid connectivity monitoring |

### Diagnostic Tools
| Tool | Description |
|------|-------------|
| **IP flow verify** | Check if a packet is allowed or denied based on NSG rules |
| **Next hop** | Determine the next hop for a packet (routing) |
| **Effective security rules** | View all NSG rules applied to a NIC (all NSGs combined) |
| **VPN troubleshoot** | Diagnose VPN gateway and connection issues |
| **Packet capture** | Capture network packets from a VM |
| **Connection troubleshoot** | One-time connectivity check between source and destination |

---

## 🔍 Key Diagnostic Tools — Details

### IP Flow Verify
- Checks if a packet will be **allowed or denied** by NSG rules
- Input: VM, direction (inbound/outbound), protocol, local/remote IP, local/remote port
- Output: Allow/Deny + which NSG rule caused it

> 💡 **Use when**: "Why is traffic being blocked?" — quickly find which NSG rule is causing the issue

```bash
# Test if TCP port 80 is allowed inbound to a VM
az network watcher test-ip-flow \
  --resource-group myRG \
  --vm myVM \
  --direction Inbound \
  --protocol TCP \
  --local 10.0.0.4:80 \
  --remote 1.2.3.4:1234 \
  --nic myVM-NIC
```

### Next Hop
- Determines the **next hop** for traffic from a VM
- Input: Source VM NIC, destination IP
- Output: Next hop type and IP (Internet, VirtualAppliance, VNetLocal, None, etc.)

> 💡 **Use when**: "Why is traffic not reaching the destination?" — check if routing is correct

```bash
# Check next hop
az network watcher show-next-hop \
  --resource-group myRG \
  --vm myVM \
  --source-ip 10.0.0.4 \
  --dest-ip 10.1.0.4 \
  --nic myVM-NIC
```

### Effective Security Rules
- Shows the **combined, effective NSG rules** for a NIC
- Merges all NSG rules from both subnet-level and NIC-level NSGs
- Shows rules in priority order with final action

> 💡 **Use when**: You have multiple NSGs and need to see exactly what rules apply

### Packet Capture
- Captures **raw network packets** from a VM's NIC
- Saves to: Storage Account or local VM disk
- Filter by IP, port, protocol
- Useful for deep network troubleshooting

```bash
# Start a packet capture
az network watcher packet-capture create \
  --resource-group myRG \
  --vm myVM \
  --name myCapture \
  --storage-account myStorageAccount \
  --time-limit 60  # seconds
```

### Connection Troubleshoot
- One-time connectivity check between source and destination
- Checks: Reachability, latency, hop-by-hop path
- Tests: VM → IP, VM → VM, VM → URI, etc.

```bash
# Test connectivity from VM to external website
az network watcher test-connectivity \
  --resource-group myRG \
  --source-resource myVM \
  --dest-address www.microsoft.com \
  --dest-port 80
```

### Connection Monitor
- **Continuous** monitoring (unlike Connection Troubleshoot which is one-time)
- Monitor between: VMs, Azure services, on-premises endpoints
- Tracks: Latency, packet loss, reachability over time
- Sends alerts if connectivity degrades

### VPN Troubleshoot
- Diagnose issues with:
  - VPN Gateway health
  - VPN Connection status
  - On-premises VPN device connectivity
- Output: Detailed logs in Storage Account

```bash
# Troubleshoot VPN Gateway
az network watcher troubleshooting start \
  --resource-group myRG \
  --resource myVPNGateway \
  --resource-type vnetGateway \
  --storage-account myStorageAccount \
  --storage-path "https://mystorageaccount.blob.core.windows.net/logs"
```

---

## 📊 Network Watcher — Resource Groups

- Network Watcher resources are stored in a resource group named **NetworkWatcherRG**
- Auto-created when you enable Network Watcher
- One Network Watcher instance per **subscription per region**

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| Network Watcher scope | **Per region** |
| Stored in | **NetworkWatcherRG** |
| IP flow verify | Tests if NSG **allows or denies** traffic |
| Next hop | Tests **routing** path for traffic |
| Effective security rules | Shows combined NSG rules for a NIC |
| Packet capture stores to | **Storage Account** or local VM disk |
| Connection Monitor | **Continuous** monitoring |
| Connection Troubleshoot | **One-time** check |
| VPN Troubleshoot logs | Saved to **Storage Account** |
| NSG Flow Logs | Log all traffic through NSG (requires Network Watcher + Storage) |

---

## 🔄 NSG Flow Logs

- Record all IP traffic flowing through an NSG
- Stored in a **Storage Account**
- Enable with **Network Watcher**
- Use **Traffic Analytics** (Log Analytics) for visualization

```bash
# Enable NSG flow logs
az network watcher flow-log create \
  --resource-group myRG \
  --name myFlowLog \
  --nsg myNSG \
  --storage-account myStorageAccount \
  --enabled true \
  --retention 30  # days
```

---

## 🚨 Common Exam Scenarios

**Q: A developer says their application cannot connect to port 443 on a VM. You suspect an NSG rule is blocking it. What tool do you use?**
→ **IP flow verify** in Network Watcher — input the VM, direction, port, and it tells you which rule is allowing/denying

**Q: Traffic from a VM is not reaching a resource in a peered VNet. How do you identify the routing issue?**
→ **Next hop** in Network Watcher — check the routing path from source VM

**Q: You need to monitor connectivity between Azure VMs and on-premises servers over time and alert on failures. What tool?**
→ **Connection Monitor** (continuous monitoring, not one-time troubleshoot)

**Q: You need to capture raw packets from a VM to diagnose an intermittent connection issue. What do you use?**
→ **Packet capture** in Network Watcher

**Q: You want to see all effective NSG rules applied to a specific VM's NIC (from both subnet and NIC-level NSGs combined). What tool?**
→ **Effective security rules** in Network Watcher
