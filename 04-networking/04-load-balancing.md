# Load Balancing in Azure

> 🎯 Exam Weight: Part of 25–30% Networking domain — KEY EXAM TOPIC!

---

## 🔑 Load Balancing Overview

Azure has **4 load balancing services** — knowing WHICH to use is critical for the exam:

| Service | OSI Layer | Scope | Traffic Type | Use Case |
|---------|-----------|-------|-------------|---------|
| **Azure Load Balancer** | Layer 4 | Regional | TCP/UDP | Internal/external VM load balancing |
| **Application Gateway** | Layer 7 | Regional | HTTP/HTTPS | Web app load balancing with WAF |
| **Azure Traffic Manager** | DNS | Global | Any | DNS-based global routing |
| **Azure Front Door** | Layer 7 | Global | HTTP/HTTPS | Global web app delivery with WAF |

> 💡 **Cheat Sheet**: 
> - Layer 4 + Regional → **Load Balancer**
> - Layer 7 + Regional → **Application Gateway**
> - DNS + Global → **Traffic Manager**
> - Layer 7 + Global → **Front Door**

---

## ⚖️ Azure Load Balancer (ALB)

### What It Is
- **Layer 4** (TCP/UDP) load balancer
- Distributes traffic to VMs or VM scale sets
- Operates within a **single region**

### SKUs
| SKU | Features | SLA |
|-----|---------|-----|
| **Basic** | Limited features, no zone redundancy, no SLA for single VM | None |
| **Standard** | Zone redundancy, better security, SLA 99.99% | 99.99% |
| **Gateway** | For network virtual appliances | - |

> ⚠️ **Basic SKU is being deprecated.** Use **Standard SKU** for new deployments.

### Types
| Type | Description |
|------|-------------|
| **Public (External)** | Public IP, distribute internet traffic to VMs |
| **Internal (Private)** | Private IP, distribute traffic within VNet (e.g., between tiers) |

### Key Components
| Component | Description |
|-----------|-------------|
| **Frontend IP** | The IP address users connect to |
| **Backend pool** | Group of VMs/NICs receiving traffic |
| **Load balancing rules** | How traffic is distributed (port mapping) |
| **Health probe** | Checks if backend VMs are healthy |
| **NAT rules** | Direct traffic to a specific VM (not distributed) |

### Health Probes
| Protocol | Port | Use Case |
|----------|------|---------|
| **TCP** | Any | Basic connectivity check |
| **HTTP** | 80 | Check HTTP response (200 OK) |
| **HTTPS** | 443 | Check HTTPS response |

> ⚠️ If a VM fails the health probe → **removed from rotation** (traffic no longer sent to it).

### Load Balancing Algorithms
- **5-tuple hash** (default): Source IP, Source port, Destination IP, Destination port, Protocol
- **Session persistence**: Keep client sessions on same backend VM
  - None (default): Any VM can serve each request
  - Client IP: Same client always goes to same VM
  - Client IP + Protocol: Same client + protocol always goes to same VM

---

## 🌐 Application Gateway (AGW)

### What It Is
- **Layer 7** (HTTP/HTTPS/WebSocket) load balancer
- URL-based routing, SSL termination, WAF (Web Application Firewall)
- Regional service — VMs must be in the same region

### Key Features
| Feature | Description |
|---------|-------------|
| **URL-based routing** | Route /images → Image servers, /api → API servers |
| **Multi-site hosting** | Multiple websites on same App Gateway |
| **SSL termination** | Decrypt SSL at gateway, backend uses HTTP |
| **End-to-end SSL** | Re-encrypt traffic to backend |
| **WAF** | Web Application Firewall — OWASP 3.x protection |
| **Autoscaling** | Scale based on traffic (v2 SKU) |
| **Cookie-based affinity** | Session stickiness using cookies |
| **Redirection** | HTTP to HTTPS redirect |
| **Custom error pages** | Return custom pages for 403, 502 |

### Application Gateway SKUs
| SKU | Features |
|-----|---------|
| **Standard v2** | All features except WAF |
| **WAF v2** | All features including WAF |

### Application Gateway Components
```
Client Request → Frontend IP → Listener → Rules → Backend Pool
                                  ↓
                             WAF Policy (if WAF enabled)
```

| Component | Description |
|-----------|-------------|
| **Listener** | Port + protocol + hostname it listens on |
| **Rule** | Binds listener to backend pool |
| **Backend pool** | Target VMs, App Service, IP addresses, FQDNs |
| **HTTP Settings** | Backend protocol, port, timeout, affinity |
| **Health probe** | Custom probe for backend health |

---

## 🌍 Azure Traffic Manager

### What It Is
- **DNS-based** global load balancer
- Operates at DNS level — returns the IP of the best endpoint
- Does NOT process actual traffic — just DNS resolution
- Works with **any internet-facing endpoint** (Azure or non-Azure)

### Routing Methods
| Method | How It Routes |
|--------|--------------|
| **Performance** | Routes to endpoint with lowest latency for the client |
| **Priority** | Primary endpoint first, failover if unhealthy |
| **Weighted** | Distribute traffic by percentage weight |
| **Geographic** | Route based on client's geographic location |
| **Multivalue** | Return multiple endpoints (for A records only) |
| **Subnet** | Route based on client's IP subnet |

### Key Facts
- Health checks determine endpoint availability
- TTL controls how often clients re-resolve DNS
- Can be nested (Traffic Manager within Traffic Manager)
- Endpoints can be: Azure services, external IPs, nested profiles

---

## 🚀 Azure Front Door

### What It Is
- **Global Layer 7** load balancer and CDN
- HTTP/HTTPS traffic routing
- Built-in WAF, SSL offload, URL rewriting
- Uses **anycast** for optimal routing

### When to Use Front Door vs Application Gateway
| Feature | Application Gateway | Azure Front Door |
|---------|--------------------|--------------------|
| Scope | Regional | **Global** |
| Protocol | HTTP/HTTPS | HTTP/HTTPS |
| WAF | Yes | **Yes (global)** |
| SSL termination | Yes | Yes |
| CDN | No | **Yes** |
| Multi-region | No | **Yes** |
| Backend location | Azure VMs/services | Any (Azure, on-prem, other cloud) |

---

## 📋 Exam Decision Tree

```
Need to load balance HTTP traffic?
├── Yes → Is it global or regional?
│   ├── Global → Azure Front Door
│   └── Regional → Application Gateway
└── No → TCP/UDP traffic?
    ├── Yes → Azure Load Balancer
    └── DNS routing needed globally → Traffic Manager
```

---

## 📋 Exam-Ready Facts

| Fact | Value |
|------|-------|
| Load Balancer OSI layer | **Layer 4** |
| Application Gateway OSI layer | **Layer 7** |
| Traffic Manager method | **DNS-based** |
| Front Door scope | **Global** |
| ALB Standard SLA | **99.99%** |
| ALB health probe fail | VM removed from rotation |
| AGW WAF OWASP version | **3.x** |
| Traffic Manager processes traffic | **No** (DNS only) |
| ALB session persistence | None, Client IP, Client IP + Protocol |
| AGW cookie affinity | **Yes** (per-session stickiness) |

---

## 🚨 Common Exam Scenarios

**Q: A web application spans multiple Azure regions. Users should be routed to the closest region. What do you use?**
→ **Azure Traffic Manager** with **Performance** routing (or Azure Front Door for L7)

**Q: You need to route `/api/*` traffic to API servers and `/images/*` to image servers within the same region. What service?**
→ **Application Gateway** with URL-based routing rules

**Q: An application has a primary region and a disaster recovery region. Only if the primary fails should traffic go to DR. What routing method?**
→ **Traffic Manager** with **Priority** routing

**Q: You need to protect a web application from SQL injection and XSS attacks. What do you enable?**
→ **WAF (Web Application Firewall)** on Application Gateway or Azure Front Door

**Q: VMs in a backend pool need to receive traffic, but one VM is unhealthy. How does the load balancer handle this?**
→ Health probes detect the failure and **remove the unhealthy VM** from the rotation automatically
