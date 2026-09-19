# Load Balancing & Application Gateway

> 🎯 Exam Weight: Part of 25–30% Networking domain — HIGH FREQUENCY!

---

## ⚖️ Azure Load Balancing Services Comparison

| Feature | Azure Load Balancer | Application Gateway | Traffic Manager | Azure Front Door |
|---------|---------------------|---------------------|-----------------|------------------|
| **OSI Layer** | **Layer 4 (TCP/UDP)** | **Layer 7 (HTTP/HTTPS)** | DNS-level | Layer 7 (Global CDN + WAF) |
| **Scope** | Regional | Regional | Global | Global |
| **Routing** | IP / Port | URL path, host header | DNS routing | URL path, latency, CDN |
| **SSL Offloading** | ❌ No | ✅ **Yes** | ❌ No | ✅ Yes |
| **Cookie Affinity** | ❌ No | ✅ **Yes** | ❌ No | ✅ Yes |

---

## 🛠️ Azure Load Balancer (Layer 4)

### Session Persistence (Distribution Modes)
- **None (5-Tuple)**: `(Source IP, Source Port, Dest IP, Dest Port, Protocol)`. Default. Successive requests from the same client may go to different backend VMs.
- **Client IP (2-Tuple)**: `(Source IP, Dest IP)`. Successive requests from the same client IP always route to the **same backend VM**.
- **Client IP and Protocol (3-Tuple)**: `(Source IP, Dest IP, Protocol)`.

> 💡 **Exam Question Pattern**: If a question requires *"visitors to be serviced by the same web server for each request"* on Azure Load Balancer ➔ Set session persistence to **Client IP** (or Client IP and Protocol).

### Basic vs Standard Load Balancer
| Feature | Basic SKU | Standard SKU |
|---------|-----------|--------------|
| **Backend Pool Size** | Up to 300 instances (single AS/VMSS) | Up to **1,000 instances** (any VM/VMSS in VNet) |
| **Security by Default** | Open to internet by default | **Closed by default** (requires NSG to allow traffic) |
| **Availability Zones** | ❌ Zone-unaware | ✅ **Zone-redundant** |
| **SLA** | None | 99.99% |

---

## 🚀 Azure Application Gateway (Layer 7)

### Advanced Routing Features
1. **URL Path-Based Routing**:
   - `http://contoso.com/images/*` ➔ Routes to `ImageBackendPool`
   - `http://contoso.com/video/*` ➔ Routes to `VideoBackendPool`
2. **Multi-Site Hosting**:
   - Hosts multiple web domains on the same gateway (e.g. `app1.contoso.com` and `app2.contoso.com`) using hostname listeners.
3. **Cookie-Based Session Affinity**:
   - Injects a gateway-managed cookie to keep a user's session pinned to the exact same backend server.
4. **Web Application Firewall (WAF)**:
   - Protects against OWASP Top 10 exploits (SQL injection, cross-site scripting).

---

## 📋 Exam-Ready Facts

| Fact | Value / Rule |
|------|--------------|
| Stickiness on Azure Load Balancer | Configure **Session Persistence = Client IP** |
| URL path routing / SSL termination | **Application Gateway** (Layer 7) |
| Standard Load Balancer security | Closed by default (requires NSG) |
| Application Gateway subnet requirement | Must be deployed into a **dedicated subnet** containing ONLY App Gateways |
| Health probe failure action | Automatically removes failed VM from receiving new connections |

---

## 🚨 Common Exam Scenarios (Real Exam MCQs)

**Q: You have an Azure Load Balancer named LB1 servicing a backend pool of web servers. You need to ensure that visitors are serviced by the same web server for each request.**
→ Modify the Load Balancing rule and change **Session Persistence** from None to **Client IP**.

**Q: You need to route requests for `http://contoso.com/cart/*` to one pool of virtual machines, and requests for `http://contoso.com/catalog/*` to a different pool of virtual machines.**
→ Deploy an **Azure Application Gateway** and configure **URL Path-Based Routing rules**.

**Q: You deploy a Standard Load Balancer with an internal frontend IP, but virtual machines in the backend pool cannot receive traffic. What is missing?**
→ Standard Load Balancers are **secure by default**. You must associate a **Network Security Group (NSG)** with the subnet or NICs and add an inbound allow rule for the service port.
