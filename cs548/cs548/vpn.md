# 🔐 VPN Protocol — Deep-Dive Annotated Study Guide
### CS 448/548 Network Security · Lectures 14–16 · Spring 2026
---

> **How to use this guide:** Each slide section is followed by a comprehensive discussion that builds from beginner intuition to expert-level understanding. Workflows are presented as granular tables (modeled after the Kerberos workflow style). Questions and answers follow each topic cluster. A Quick Reference Summary and Integrative Exam Questions appear at the end.

---

## 📋 Table of Contents

1. [Where VPN Fits in the Network Stack](#1-where-vpn-fits-in-the-network-stack)
2. [What is a VPN?](#2-what-is-a-vpn)
3. [VPN in Action — Traffic Flow Diagram](#3-vpn-in-action--traffic-flow-diagram)
4. [IPsec Architecture Overview](#4-ipsec-architecture-overview)
5. [Security Policy Database (SPD)](#5-security-policy-database-spd)
6. [Security Association Database (SAD)](#6-security-association-database-sad)
7. [Authentication Header (AH)](#7-authentication-header-ah)
8. [AH ICV Computation](#8-ah-icv-computation)
9. [Encapsulating Security Payload (ESP)](#9-encapsulating-security-payload-esp)
10. [ESP Packet Structure](#10-esp-packet-structure)
11. [Transport Mode vs. Tunnel Mode](#11-transport-mode-vs-tunnel-mode)
12. [Tunnel Mode vs. Transport Mode — Detailed Comparison Table](#12-tunnel-mode-vs-transport-mode--detailed-comparison-table)
13. [VPN Protocols — IPsec/IKEv2, TLS-based, WireGuard](#13-vpn-protocols--ipsecikev2-tls-based-wireguard)
14. [OpenVPN Architecture — NAT and Multiplexing](#14-openvpn-architecture--nat-and-multiplexing)
15. [Traffic Leakage: Without VPN vs. With VPN](#15-traffic-leakage-without-vpn-vs-with-vpn)
16. [Anti-Replay Service](#16-anti-replay-service)
17. [VPN and Firewall Evasion](#17-vpn-and-firewall-evasion)
18. [Quick Reference Summary Table](#18-quick-reference-summary-table)
19. [Exam Preparation — Integrative Questions](#19-exam-preparation--integrative-questions)

---

## 1. Where VPN Fits in the Network Stack

### 📊 Slide Content

```
Overview — Network Layers Covered in This Course:

Application Layer:   SSH
Transport Layer:     TLS/DTLS (end-to-end solution, User Authentication)
Network Layer:       VPN, IPSec

HTTP  TCP  IP  802.11  UDP
Email SSH Video Gaming
802.3 802.15.1 802.15.4
Ethernet Wi-Fi BT Zigbee  OFDMA 4G(LTE)
```

---

### 🧠 Discussion

#### Key Concepts at a Glance

| Layer | Protocol | Security Goal |
|-------|----------|---------------|
| Application | SSH | Secure remote login; server auth + client auth |
| Transport | TLS / DTLS | End-to-end confidentiality + integrity over TCP (or UDP) |
| Network | IPsec / VPN | Packet-level security; protects ALL traffic regardless of app |

#### Understanding via Simon Sinek's Golden Circle

**WHY does VPN exist at the network layer?**

Every layer of the TCP/IP stack has a different "view" of the data flowing through it. Application-layer security (SSH, HTTPS) only protects one application at a time. If you have dozens of applications sending data — a game, an email client, a background sync tool — each would need its own security. This is expensive, error-prone, and leaves gaps (e.g., DNS queries are unprotected). VPN solves this by pushing security *down* to Layer 3 (the network layer), where *every packet*, regardless of which application created it, gets protected automatically.

**HOW does the network layer achieve this?**

IPsec is the suite of protocols that implements this. It intercepts IP packets and either authenticates them (using AH) or encrypts + authenticates them (using ESP). This happens transparently — applications don't need to be modified.

**WHAT is the practical result?**

A VPN creates a secure "tunnel" between two endpoints. From the outside, an observer sees only encrypted traffic between two VPN endpoints. The actual source/destination of the inner packets, and the application content, are hidden.

#### Beginner-Friendly Deep Dive

Think of the TCP/IP stack as a postal system. The **application layer** is the letter writer — it writes the content. The **transport layer** is the envelope — it handles reliable delivery between sender and receiver ports. The **network layer** is the postal routing system — it decides which road the packet travels on.

- SSH protects the letter *content* for a specific application.
- TLS wraps the envelope in a tamper-evident seal for one connection.
- IPsec/VPN wraps *every envelope leaving your building* in an armored truck, regardless of what letter is inside.

This is why the course covers security at each layer: they complement each other, and understanding which layer provides what protection is essential for designing secure systems.

---

## 2. What is a VPN?

### 📊 Slide Content

```
Virtual Private Network

§ Private Network
§ VPN
  • Connect to a private network
  • Connect to Internet

IPSec provides:
  • Access control: User authentication
  • Data integrity
  • Data origin authentication
  • Rejection of replayed packets
  • Confidentiality (encryption)
  • Limited traffic flow confidentiality

Benefits:
  • Security at Layer 3 ⇒ Applies to all transports/applications
  • Can be implemented in Firewall/router
    ⇒ Security to all traffic crossing the perimeter
  • Transparent to applications and users
  • Can provide security for individual users

IPsec can assure that:
  • A router advertisement comes from an authorized router
  • A routing update is not forged
  • A redirect message comes from the correct router

Applications: VPNs, Branch Offices, Remote Users, Extranets
```

---

### 🧠 Discussion

#### Key Concepts at a Glance

| IPsec Security Service | Mechanism | Protection Against |
|------------------------|-----------|-------------------|
| Access control | Authentication | Unauthorized users |
| Data integrity | HMAC / ICV | In-transit modification |
| Data origin authentication | Cryptographic binding | Source impersonation |
| Anti-replay | Sequence numbers + sliding window | Replay attacks |
| Confidentiality | Encryption (ESP) | Eavesdropping |
| Traffic flow confidentiality | Tunnel mode (hides inner headers) | Traffic analysis |

#### Understanding via Simon Sinek's Golden Circle

**WHY do we need a VPN when we already have TLS?**

TLS is point-to-point between two applications. When you VPN into your company network, you don't just want to protect one HTTPS session — you want your machine to *behave as if it were physically inside the company network*, accessing file servers, printers, internal databases, all secured. VPN tunnels achieve this: your laptop gets a private IP address on the company network and all your traffic routes through that tunnel.

**HOW does IPsec make this work?**

IPsec operates in two modes (tunnel and transport) using two protocols (AH and ESP). For VPN use cases, tunnel mode with ESP is the dominant choice: the entire original IP packet is encapsulated, encrypted, and sent inside a new outer IP packet addressed to the VPN gateway.

**WHAT are the real-world deployments?**

- **Branch office VPN**: Connects two physical offices so employees at both locations share one logical network.
- **Remote access VPN**: A travelling employee connects their laptop to the company network from a hotel.
- **Extranets**: Partners and suppliers get limited access to your internal resources.

#### Expert-Level Insight

IPsec's position at Layer 3 means it can protect infrastructure-level traffic that no application-level protocol ever touches:

- **Routing protocol messages** (BGP, OSPF): An attacker who can forge routing updates can redirect all Internet traffic. IPsec AH authenticates routing updates, preventing route hijacking.
- **ICMP messages**: Forged ICMP redirect messages can silently change a host's routing table. AH authentication prevents this.
- **DHCP**: Without protection, a rogue DHCP server can hand out malicious gateway/DNS assignments. IPsec integration at the gateway level helps.

These infrastructure-protection use cases are invisible to the end user but critical for network operators.

---

## 3. VPN in Action — Traffic Flow Diagram

### 📊 Slide Content

```
VPN Traffic Flow:

10.116.230.2        10.116.230.85
        \               /
         \             /
          VPN Server (10.116.230.1 / 130.166.128.1)
               |
           [Encrypted Tunnel]
               |
         local network (home)
         10.0.0.4  -- 10.0.0/24
               |
          rest of Internet
         130.160.57.1
```

---

### 🧠 Discussion

#### End-to-End VPN Workflow Table

| Step | Actor | Action | What an Observer Sees |
|------|-------|--------|-----------------------|
| 1 | Client (10.0.0.4) | Sends packet destined for internal server (10.116.230.2) | Nothing yet — packet is local |
| 2 | VPN Client Software | Intercepts outbound packet, wraps it in ESP tunnel-mode packet with outer IP src=10.0.0.4, dst=130.166.128.1 (VPN server public IP) | Encrypted blob addressed to VPN server |
| 3 | Internet routers | Route outer packet to VPN server based on outer IP header | Encrypted, unreadable payload; source is client IP |
| 4 | VPN Server (130.166.128.1) | Decrypts ESP packet, extracts original inner IP packet (src=10.0.0.4, dst=10.116.230.2) | Nothing — decryption happens inside the server |
| 5 | VPN Server | Forwards inner packet to internal network as if client were physically present | Internal network sees packet from 10.0.0.4 (or NATted IP) |
| 6 | Internal server response | Reply travels the reverse path back through the tunnel | Same encryption applies in reverse |

#### Understanding via Simon Sinek's Golden Circle

**WHY does tunnel mode hide the destination?**

When you browse from home without a VPN, your ISP (and anyone on the path) can see: "This user is connecting to servers at IP 216.58.x.x (Google)." Over time, this reveals browsing habits. With tunnel mode VPN, all the ISP sees is: "This user is sending encrypted data to the VPN server." The actual destinations are hidden inside the encrypted tunnel.

**HOW does the "tunnel" metaphor work technically?**

The original IP packet (call it the *inner* packet) is the thing you care about. Tunnel mode takes this *entire* packet — inner IP header, transport header, and payload — and encrypts it. Then it adds a brand-new *outer* IP header that routes the encrypted blob to the VPN gateway. At the gateway, the outer header is stripped, the inner packet is decrypted, and forwarded normally. The tunnel is invisible to the inner packet.

**WHAT does "limited traffic flow confidentiality" mean?**

Even with tunnel mode, certain metadata leaks: the *volume* of traffic, the *timing* of packets, and the fact that you're using a VPN at all (since the outer IP header points to a known VPN gateway). IPsec calls this "limited" because while the inner destinations are hidden, aggregate traffic patterns may still reveal information. This is why some users combine VPN with additional anonymization layers.

---

## 4. IPsec Architecture Overview

### 📊 Slide Content

```
IP Security Architecture:

§ Internet Key Exchange (IKE)
§ Security Association Database (SAD)
§ Security Policy Database (SPD)
§ IP Encapsulating Security Payload (ESP) and AH

Processing Models:
  Outbound Packets → [SPD lookup → SA selection → ESP/AH processing → send]
  Inbound Packets  → [strip outer header → SAD lookup → decrypt/verify → deliver]
```

---

### 🧠 Discussion

#### IPsec Architecture Component Table

| Component | What It Is | Analogy |
|-----------|-----------|---------|
| **IKE** (Internet Key Exchange) | Protocol to negotiate and establish Security Associations (SAs); handles key exchange using Diffie-Hellman | The "contract negotiation" before two parties start working together |
| **SPD** (Security Policy Database) | Defines *which* traffic gets protected and *how* (encrypt? authenticate? bypass?) | A rulebook: "For traffic matching these criteria, apply this security policy" |
| **SAD** (Security Association Database) | Stores the actual *parameters* of established secure connections: keys, algorithms, sequence numbers | A phonebook of active secure connections |
| **ESP** | Encrypts and optionally authenticates payload | The "armored container" for data |
| **AH** | Authenticates but does NOT encrypt (integrity + origin auth only) | A tamper-evident seal on the envelope |

#### Data Flow Through IPsec (Outbound)

| Step | Component | Action |
|------|-----------|--------|
| 1 | Application / OS | Generates IP packet, sends to IP layer |
| 2 | SPD Lookup | Check: does this packet match any security policy? (by src/dst IP, port, protocol) |
| 3 | Policy Decision | Three options: **PROTECT** (apply IPsec), **BYPASS** (send unprotected), **DISCARD** |
| 4 | SA Selection | If PROTECT: find the matching SA in SAD (or trigger IKE to create one) |
| 5 | IPsec Processing | Apply AH or ESP according to SA parameters |
| 6 | Transmission | Send the IPsec-processed packet on the wire |

#### Data Flow Through IPsec (Inbound)

| Step | Component | Action |
|------|-----------|--------|
| 1 | IP Layer | Receives packet with protocol = AH (51) or ESP (50) |
| 2 | SPI Extraction | Extract Security Parameters Index (SPI) from AH/ESP header |
| 3 | SAD Lookup | Find SA matching (SPI, destination IP, protocol) |
| 4 | Anti-Replay Check | Verify sequence number is within acceptable window |
| 5 | Integrity/Decrypt | Verify ICV (AH) or decrypt + verify ICV (ESP) |
| 6 | Inner Packet | Extract and deliver inner IP packet to upper layers |
| 7 | SPD Check | Verify inbound packet conforms to expected security policy |

#### Understanding via Simon Sinek's Golden Circle

**WHY have separate SPD and SAD?**

Policy and state are different things. The SPD says *"traffic to the branch office must be encrypted"* — this is a standing rule, set by an administrator, that doesn't change packet by packet. The SAD contains the *current cryptographic state* — the actual session keys, sequence numbers, and algorithm choices that implement that policy right now. Separating them means you can change your policy without disrupting active connections, and active connection state can be updated (rekeyed) without touching policy.

**HOW does IKE fit in?**

IKE is the bootstrap protocol. Before two IPsec endpoints can exchange protected traffic, they need to agree on: what algorithm to use, what keys to use, and for how long. IKE uses Diffie-Hellman to establish a shared secret (so no keys are transmitted in the clear), then uses that secret to derive the actual encryption/authentication keys that go into the SAD.

---

## 5. Security Policy Database (SPD)

### 📊 Slide Content

```
Security Policy Database:

§ Defines how to process different datagrams received by the device
  • Match subset of IP traffic to relevant SA
  • Use selectors to filter outgoing traffic to map

Selectors used for matching:
  • Local & remote IP addresses
  • Next layer protocol (TCP, UDP, ICMP, etc.)
  • Name
  • Local & remote ports
```

---

### 🧠 Discussion

#### SPD Rule Structure

Each SPD entry is conceptually:

```
IF (traffic matches selector) THEN (apply policy action)
```

| Selector Field | Example Values | Purpose |
|----------------|---------------|---------|
| Source IP/range | 10.0.0.0/24 | Match packets from home network |
| Destination IP/range | 192.168.1.0/24 | Match packets to corporate subnet |
| Protocol | TCP, UDP, ICMP | Match specific transport protocols |
| Source port | 0–65535 or specific | Fine-grained control |
| Destination port | 443, 80, any | E.g., only protect HTTPS |
| Policy action | PROTECT / BYPASS / DISCARD | What to do with matching traffic |
| SA pointer | → SAD entry | Which SA parameters to use if PROTECT |

#### Three Policy Actions Explained

| Action | Meaning | Use Case |
|--------|---------|---------|
| **PROTECT** | Apply IPsec (ESP or AH) to this traffic | VPN tunnel traffic, sensitive data |
| **BYPASS** | Forward without IPsec processing | ICMP pings for diagnostics, NTP time sync |
| **DISCARD** | Drop the packet silently | Block unwanted traffic types |

#### Understanding via Simon Sinek's Golden Circle

**WHY doesn't IPsec just encrypt everything?**

Some traffic legitimately shouldn't be encrypted. IKE itself (the key exchange protocol) must be sent *before* the SA is established — you can't encrypt traffic before you have keys. Similarly, certain diagnostic protocols (like ICMP) may need to bypass IPsec for network management. The SPD's BYPASS action handles these cases gracefully.

**HOW does the SPD know which SA to use?**

The SPD entry for PROTECT traffic includes a pointer (or reference) to the SAD. When outbound traffic matches a policy, IPsec follows that pointer to the SAD to retrieve the current session key, algorithm, and sequence number to apply. If no matching SA exists yet, IPsec triggers IKE to negotiate and create one.

---

## 6. Security Association Database (SAD)

### 📊 Slide Content

```
Security Association Database:

§ SA = One-way security relationship between sender & receiver
  Two-way communication may use different security ⇒ Two SAs required

§ Defined by 3 parameters:
  • Security Parameters Index (SPI)
  • IP Destination Address
  • Security Protocol Identifier: AH or ESP

§ Each SA entry contains:
  • SPI
  • Sequence number counter and overflow flag
  • Anti-replay window
  • AH information and ESP information
  • Lifetime of the SA
  • Mode: Transport or Tunnel or Wildcard
  • Path MTU
```

---

### 🧠 Discussion

#### Security Association Deep-Dive Table

| SA Field | Description | Why It Matters |
|----------|-------------|---------------|
| **SPI** (Security Parameters Index) | 32-bit value chosen by the receiver; included in every AH/ESP packet header | Allows the receiver to look up which SA governs an incoming packet — it's like an account number |
| **IP Destination Address** | The endpoint this SA is associated with | Combined with SPI uniquely identifies an SA |
| **Security Protocol** | AH (51) or ESP (50) | Tells the receiver which protocol structure to expect |
| **Sequence Number Counter** | Monotonically increasing; starts at 0 for new SA | Anti-replay: receiver rejects any packet with a number it has already accepted |
| **Overflow Flag** | If counter maxes out (2^32), overflow flag triggers SA renegotiation or block | Prevents counter wrap-around attacks |
| **Anti-Replay Window** | Sliding window of accepted sequence numbers | Allows for out-of-order delivery while still blocking true replays |
| **AH / ESP Info** | Algorithms, keys, IV lengths for authentication and encryption | The actual cryptographic material |
| **Lifetime** | Time-based or byte-based expiry | Limits key exposure; forces periodic renegotiation |
| **Mode** | Transport, Tunnel, or Wildcard | Determines packet encapsulation behavior |
| **Path MTU** | Maximum transmission unit on the path | Prevents unnecessary fragmentation |

#### Why SAs Are One-Way

A VPN tunnel between Alice's laptop and the company gateway consists of **two** SAs:

| SA | Direction | Keys | Managed By |
|----|-----------|------|-----------|
| SA₁ | Alice → Gateway | Encryption key Kₐ, MAC key Mₐ | Alice sends, Gateway receives |
| SA₂ | Gateway → Alice | Encryption key K_g, MAC key M_g | Gateway sends, Alice receives |

This asymmetry exists because:
- Different traffic directions may need different security levels
- The sender controls sequence numbers (one counter per direction)
- Bidirectional SAs would create cryptographic coupling that complicates key management

#### The SPI in Practice

When the VPN gateway receives an IPsec packet, it sees:
```
Outer IP header → ESP header containing SPI (e.g., 0x12345678)
```
The gateway looks up (SPI=0x12345678, dst=gateway-IP, proto=ESP) in its SAD and immediately knows: decrypt with AES-256, verify with SHA-256 HMAC, check sequence number 1024.

The SPI is chosen by the *receiver* (assigned during IKE negotiation) so the receiver controls its own SAD lookup key space.

---

## 7. Authentication Header (AH)

### 📊 Slide Content

```
Authentication Header:

§ Provides:
  • Authenticating data origins
  • Guaranteeing data integrity
  • Optional anti-replay services

§ Header fields:
  • Next Header: TCP=6, UDP=17, IP=4, AH=51 (IPv6 design heritage)
  • Payload Length: Length of AH in 32-bit words − 2 (IPv4)
               = Length in 64-bit words − 1 (IPv6)
  • Reserved: zeroed
  • SPI: Identifies Security Association (0=Local use, 1-255=Reserved)
  • Sequence Number: anti-replay counter
  • Authentication Data: Integrity Check Value (ICV)
```

---

### 🧠 Discussion

#### AH Header Structure

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|  Next Header  |  Payload Len  |          RESERVED             |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                 Security Parameters Index (SPI)               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                    Sequence Number Field                      |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                                                               |
+                Authentication Data (ICV) variable length      |
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

#### AH Field-by-Field Analysis

| Field | Size | Value/Meaning | Exam Note |
|-------|------|--------------|-----------|
| Next Header | 8 bits | Protocol of next header: TCP=6, UDP=17, IP=4 | Tells receiver what follows the AH header |
| Payload Length | 8 bits | AH length in 32-bit words minus 2 (IPv4) | Strange formula — IPv6 heritage |
| Reserved | 16 bits | Must be zero | Sender sets; receiver checks |
| SPI | 32 bits | SA lookup key; 0=local, 1–255=reserved | Combined with dst IP to find SA |
| Sequence Number | 32 bits | Starts at 1; never repeats within SA lifetime | Anti-replay mechanism |
| Authentication Data (ICV) | Variable | HMAC result covering protected fields | The actual integrity proof |

#### AH vs. ESP — Critical Comparison

| Feature | AH | ESP |
|---------|-----|-----|
| Confidentiality (encryption) | ❌ No | ✅ Yes |
| Data integrity | ✅ Yes | ✅ Yes |
| Data origin authentication | ✅ Yes | ✅ Yes |
| Anti-replay | ✅ Optional | ✅ Optional |
| IP header protection | ✅ Partial (mutable fields excluded) | ❌ No (transport mode) / ✅ (tunnel mode) |
| NAT compatibility | ❌ Poor (NAT changes IP header, breaking ICV) | ✅ Better |

#### Understanding via Simon Sinek's Golden Circle

**WHY does AH exist if ESP also provides integrity?**

AH authenticates the *outer IP header* fields as well (those that are immutable in transit). This protects against an attacker modifying the IP source address or other routing information. ESP does not authenticate the outer IP header — only the payload. For use cases where you need to verify that routing information hasn't been tampered with (e.g., protecting routing protocol messages), AH provides coverage that ESP cannot.

**WHY is AH incompatible with NAT?**

NAT modifies the source IP address in the IP header. AH computes its ICV over certain IP header fields, including the source address. When NAT changes that address, the ICV computed by the sender no longer matches what the receiver computes, causing every packet to fail authentication. This is why AH is rarely used in modern Internet deployments (where NAT is ubiquitous) and ESP is preferred.

---

## 8. AH ICV Computation

### 📊 Slide Content

```
AH ICV Computation:

§ HMAC algorithm used for integrity

§ ICV is computed over:
  1. IP header fields that are:
     - Immutable in transit (e.g., source address)
     - OR predictable upon arrival (e.g., destination with source routing)
  2. The AH header itself (with Authentication Data field zeroed)
  3. Explicit padding bytes (if any)
  4. The upper-level protocol data (assumed immutable in transit)

Fields NOT included (mutable, unpredictable):
  - TTL / Hop Limit (decremented at each router)
  - Header Checksum (recalculated after TTL change)
  - TOS / DSCP / ECN (may be changed by QoS mechanisms)
  - Fragmentation Offset and Flags
```

---

### 🧠 Discussion

#### Which IP Header Fields Are Covered?

| IP Header Field | Covered by AH ICV? | Reason |
|----------------|-------------------|--------|
| Version | ✅ Yes (immutable) | Does not change in transit |
| IHL (header length) | ✅ Yes | Fixed structure |
| DSCP/ECN | ❌ No (mutable) | QoS mechanisms may alter |
| Total Length | ✅ Yes | Should not change |
| Identification | ❌ No (mutable) | Fragmentation changes this |
| Flags | ❌ No (partially mutable) | DF bit may be cleared by path |
| Fragment Offset | ❌ No (mutable) | Changes with fragmentation |
| TTL | ❌ No (mutable) | Decremented at every router hop |
| Protocol | ✅ Yes | Identifies AH (=51) |
| Header Checksum | ❌ No (mutable) | Recalculated after TTL changes |
| Source Address | ✅ Yes (immutable) | Should not change in transit |
| Destination Address | ✅ Yes (predictable) | With source routing, predictable at endpoint |

#### ICV Computation Process

| Step | Action |
|------|--------|
| 1 | Zero out mutable IP header fields |
| 2 | Zero out the Authentication Data field in the AH header |
| 3 | Zero out explicit padding fields |
| 4 | Concatenate: [zeroed IP header] + [AH header with zeroed ICV] + [upper-layer data] |
| 5 | Run HMAC (e.g., HMAC-SHA-256) over the concatenated data using the SA's authentication key |
| 6 | Place the resulting HMAC output in the Authentication Data field |

#### Understanding via Simon Sinek's Golden Circle

**WHY zero out mutable fields rather than exclude them?**

This ensures the computation covers the exact same byte positions as the actual packet, preserving byte alignment. If mutable fields were simply omitted, the HMAC input would be shorter and harder to align with the actual packet structure. By zeroing them, the ICV computation treats the packet as a fixed-length byte array where certain positions are known to be zero, making receiver-side verification straightforward.

---

## 9. Encapsulating Security Payload (ESP)

### 📊 Slide Content

```
Encapsulating Security Payload (ESP):

§ Provides:
  • Message content confidentiality
  • Data origin authentication
  • Connectionless integrity
  • Anti-replay service
  • Limited traffic flow confidentiality

§ Services depend on options selected when establishing the Security Association (SA)
§ Can use a variety of encryption & authentication algorithms
```

---

### 🧠 Discussion

#### ESP Service Configuration Matrix

| Configuration | Confidentiality | Integrity | Authentication |
|--------------|-----------------|-----------|----------------|
| ESP encryption only | ✅ Yes | ❌ No | ❌ No |
| ESP authentication only | ❌ No | ✅ Yes | ✅ Yes |
| ESP encryption + authentication | ✅ Yes | ✅ Yes | ✅ Yes |

> **Exam trap**: ESP without authentication provides confidentiality but no integrity. An attacker could *modify* ciphertext in ways that produce garbage plaintext — but the receiver won't know it was tampered with. Best practice: always use ESP with authentication (or use AES-GCM which provides both).

#### ESP Algorithms (Common Choices)

| Algorithm Type | Examples | Notes |
|---------------|----------|-------|
| Symmetric encryption | AES-CBC, AES-CTR, AES-GCM | AES-GCM combines encryption + authentication |
| Authentication (MAC) | HMAC-SHA-256, HMAC-SHA-384 | Used when not using authenticated encryption |
| Deprecated (don't use) | DES, 3DES, HMAC-MD5 | Legacy; weak by modern standards |

#### Understanding via Simon Sinek's Golden Circle

**WHY is ESP preferred over AH in most deployments?**

Three reasons:
1. **ESP provides encryption** — AH does not. Most VPN use cases require confidentiality.
2. **ESP is NAT-friendly** — ESP in tunnel mode places the SPI and sequence number in the ESP header, which is inside the outer IP packet. NAT only changes the outer IP header, leaving ESP intact.
3. **ESP can do everything AH does** (when used with authentication) — so for deployment simplicity, ESP alone suffices.

**HOW does "limited traffic flow confidentiality" work?**

In tunnel mode, ESP hides the inner IP headers (source, destination). An observer on the path can see: outer source IP (VPN client), outer destination IP (VPN gateway), approximate packet sizes, and timing. It cannot see: which internal servers you're connecting to, what protocols you're using internally, or what the content is. "Limited" acknowledges that packet sizes and timing patterns still leak some information about your activity.

---

## 10. ESP Packet Structure

### 📊 Slide Content

```
ESP Packet Fields:

§ SPI: Security Parameters Index (identifies SA)
§ Sequence Number: anti-replay counter
§ [Encrypted Payload begins here]
§ Payload Data: the protected IP/TCP/UDP content
§ Padding: ensures 4-byte alignment
§ Pad Length: number of padding bytes (in bytes)
§ Next Header: type of payload (TCP=6, UDP=17, IP=4)
§ [Encrypted Payload ends here]
§ Authentication Data: ICV over (SPI + Seq# + Encrypted payload)
   [only if authentication selected]
```

---

### 🧠 Discussion

#### ESP Packet Layout (Annotated)

```
UNENCRYPTED REGION:
+---------------------------+
|    SPI (32 bits)          |  ← SA lookup key
+---------------------------+
|  Sequence Number (32 bits)|  ← Anti-replay counter
+===========================+
ENCRYPTED REGION (starts here):
+---------------------------+
|    Payload Data           |  ← The actual inner packet (IP/TCP/data)
|    (variable length)      |
+---------------------------+
|  Padding (0–255 bytes)    |  ← Ensures alignment + may pad for confidentiality
+---------------------------+
|  Pad Length (8 bits)      |  ← How many padding bytes to strip
+---------------------------+
|  Next Header (8 bits)     |  ← What type of data is in Payload Data
+===========================+
ENCRYPTED REGION (ends here)
+---------------------------+
|  Authentication Data      |  ← ICV (if auth selected); covers SPI+Seq#+ciphertext
|  (variable length)        |
+---------------------------+
```

#### Why Padding Exists

| Reason | Explanation |
|--------|-------------|
| Block cipher alignment | AES-CBC requires input to be a multiple of 16 bytes. Padding brings the payload to the next block boundary. |
| 4-byte boundary | The ESP trailer (Pad Length + Next Header) must end on a 4-byte boundary for IP alignment. |
| Traffic analysis mitigation | Padding can be used to make packets appear the same size, hindering traffic analysis. (Rarely implemented in practice.) |

#### Understanding via Simon Sinek's Golden Circle

**WHY is Next Header inside the encrypted region?**

The Next Header field tells the receiver what type of data is in the Payload Data (TCP, UDP, or an inner IP packet). Placing this *inside* the encryption means an on-path observer cannot determine what transport protocol is being used inside the VPN tunnel. This contributes to traffic flow confidentiality. If Next Header were unencrypted (like in AH), the attacker could immediately distinguish TCP sessions from UDP sessions.

**WHY does Authentication Data cover the encrypted payload?**

The ICV is computed over the ciphertext (not the plaintext). This is the "Encrypt-then-MAC" pattern (the correct approach). If the MAC were computed over plaintext, an attacker could modify the ciphertext in transit, and the receiver would only detect the tampering after decrypting — which in some cipher modes leaks information. Encrypt-then-MAC means any ciphertext modification is caught before decryption begins.

---

## 11. Transport Mode vs. Tunnel Mode

### 📊 Slide Content

```
Transport Mode:
§ Provides protection primarily for upper-layer protocols
§ Examples: TCP/UDP segment, ICMP packet
§ Used for end-to-end communication between two HOSTS
§ Does NOT protect or encrypt the original IP header

ESP in Transport Mode:
  → Encrypts and optionally authenticates IP payload (not IP header)

AH in Transport Mode:
  → Authenticates IP payload + selected portions of IP header

────────────────────────────────────────────────────────

Tunnel Mode:
§ Provides protection to the ENTIRE IP packet
§ Used when one or both ends are a SECURITY GATEWAY
§ Hosts behind firewalls can communicate securely
  without implementing IPsec themselves

ESP in Tunnel Mode:
  → Encrypts and optionally authenticates entire inner IP packet
    (including inner IP header)

AH in Tunnel Mode:
  → Authenticates entire inner IP packet + selected portions of outer IP header
```

---

### 🧠 Discussion

#### Transport Mode — Packet Structure

```
ORIGINAL IP PACKET (before IPsec):
[ IP Header | TCP Header | Data ]

AFTER ESP TRANSPORT MODE:
[ IP Header | ESP Header | TCP Header | Data | ESP Trailer | ESP Auth ]
     ↑                       ↑_________________________↑
  unchanged              encrypted region
```

The outer IP header is the *same* as the original. Only the payload (TCP + data) is protected. Source and destination IP addresses remain visible.

#### Tunnel Mode — Packet Structure

```
ORIGINAL IP PACKET (before IPsec):
[ Inner IP Hdr | TCP Header | Data ]

AFTER ESP TUNNEL MODE:
[ Outer IP Hdr | ESP Header | Inner IP Hdr | TCP Header | Data | ESP Trailer | ESP Auth ]
     ↑                       ↑________________________________________________↑
  new header                         encrypted region (entire original packet)
```

The outer IP header is *new*, pointing to the VPN gateway. The inner IP header (with the real source and destination) is hidden inside the encrypted payload.

#### Mode Selection Guide

| Use Case | Recommended Mode | Why |
|----------|-----------------|-----|
| Host-to-host communication (both hosts run IPsec) | Transport Mode | Saves overhead; both parties know each other's IPs |
| Client VPN (laptop connecting to corporate network) | Tunnel Mode | Hides internal IP structure; client gets a virtual IP |
| Site-to-site VPN (branch office to HQ) | Tunnel Mode | Gateway protects all hosts behind it; hosts need not run IPsec |
| Protecting routing protocol messages | Transport Mode (AH) | Authenticates routing updates between routers; IPs are known |
| Evading destination-IP-based egress filtering | Tunnel Mode (ESP) | Inner IP header (with blocked destination) is encrypted and invisible to firewall |

#### Understanding via Simon Sinek's Golden Circle

**WHY does tunnel mode add overhead but transport mode does not?**

Tunnel mode must prepend a completely new outer IP header (20 bytes for IPv4). For every packet, this is 20 bytes of overhead that transport mode avoids. In high-throughput deployments (e.g., 10 Gbps site-to-site links), this overhead adds up. Transport mode is more efficient but requires both endpoints to be IPsec-capable and to know each other's real IP addresses. Tunnel mode trades efficiency for flexibility: the VPN gateway handles all IPsec processing, and hosts behind it need no special configuration.

**HOW does tunnel mode enable firewall evasion (from the exam)?**

If a firewall performs egress filtering based on destination IP address (e.g., blocking traffic to IP 1.2.3.4), tunnel mode ESP defeats this: the packet sent toward the firewall has an outer IP header pointing to the VPN gateway (e.g., IP 10.10.10.1), not the blocked destination. The blocked destination IP is inside the encrypted ESP payload, completely invisible to the firewall. The firewall only sees: "packet to 10.10.10.1" — allowed!

---

## 12. Tunnel Mode vs. Transport Mode — Detailed Comparison Table

### 📊 Slide Content

```
Tunnel Mode vs. Transport Mode Summary:

                    Transport Mode SA          Tunnel Mode SA
────────────────────────────────────────────────────────────────
AH        Authenticates IP payload +         Authenticates entire inner IP packet
          selected portions of IP header      (inner header + payload) +
          + IPv6 extension headers.           selected portions of outer IP header.

ESP       Encrypts IP payload + any IPv6      Encrypts entire inner IP packet.
          extension headers following
          the ESP header.

ESP with  Encrypts IP payload + IPv6         Encrypts entire inner IP packet.
Auth.     extension headers following         Authenticates inner IP packet.
          ESP header. Authenticates IP
          payload but NOT IP header.
```

---

### 🧠 Discussion

#### Complete Comparison Matrix

| Property | AH Transport | AH Tunnel | ESP Transport | ESP Tunnel |
|----------|-------------|-----------|---------------|------------|
| Encrypts payload | ❌ | ❌ | ✅ | ✅ |
| Encrypts inner IP header | N/A | N/A | ❌ | ✅ |
| Authenticates outer IP header | Partial | Partial | ❌ | ❌ |
| Authenticates inner IP header | Partial | ✅ (as payload) | ❌ | ✅ (when auth selected) |
| Authenticates payload | ✅ | ✅ | ✅ (when auth selected) | ✅ (when auth selected) |
| NAT compatible | ❌ | ❌ | ✅ | ✅ |
| Hides internal topology | ❌ | ✅ | ❌ | ✅ |
| Common deployment | Rarely used | Rarely used | Host-to-host | **Most common (VPN gateways)** |

#### Exam Question Targets

The following combinations appear frequently in exams:

**Q: Which combination hides the destination address from an on-path observer?**
A: ESP Tunnel Mode — the inner IP header (with real destination) is inside the encrypted ESP payload. The outer IP header points only to the VPN gateway.

**Q: Which combination can detect modification of the outer IP header?**
A: AH (either mode) — AH authenticates selected outer IP header fields. ESP does NOT authenticate the outer IP header in any mode.

**Q: Which combination provides the most complete protection (encrypt + auth + hides topology)?**
A: ESP Tunnel Mode with Authentication — encrypts the entire inner packet, authenticates the ciphertext, and hides internal addressing behind the VPN gateway.

**Q: Which IPsec mode can encrypt the inner IP header to evade destination-address-based egress filtering in the Firewall?**
A: **Tunnel Mode** (from the 2026 midterm exam answer key).

---

## 13. VPN Protocols — IPsec/IKEv2, TLS-based, WireGuard

### 📊 Slide Content

```
VPN Protocol Families:

§ IPsec/IKEv2 (Usually UDP port 500/4500)
  • Enterprise remote access, site-to-site
  • Common for branch gateways
  • Universally supported by enterprise routers/firewalls (L3 network layer)
  • Concepts: SA, SPI, ESP, AH, etc.

§ TLS-based (Typically UDP/DTLS, sometimes TCP/TLS)
  • OpenVPN
  • Cisco AnyConnect
  • WireGuard
```

---

### 🧠 Discussion

#### VPN Protocol Comparison Table

| Protocol | Transport | Layer | Encryption | Auth | Strengths | Weaknesses |
|----------|-----------|-------|-----------|------|-----------|------------|
| **IPsec/IKEv2** | UDP 500/4500 | L3 (Network) | ESP (AES) | IKE (DH + certificates) | Universal enterprise support; hardware acceleration; L3 coverage | Complex configuration; NAT traversal (NAT-T) needed |
| **OpenVPN** | UDP or TCP | L3/L4 | SSL/TLS (OpenSSL) | Certificate or PSK | Highly configurable; firewall-friendly (uses standard ports) | Software-only (slower); more CPU overhead |
| **WireGuard** | UDP | L3 | ChaCha20-Poly1305 | Static keys + noise protocol | Very fast; simple code base (~4000 lines); modern crypto | Relatively new; no dynamic IP support without wrappers |
| **Cisco AnyConnect** | SSL/DTLS | L3/L4 | TLS/DTLS | Certificate + MFA | Deep enterprise integration; works through most firewalls | Proprietary; expensive |

#### Understanding via Simon Sinek's Golden Circle

**WHY do TLS-based VPNs use UDP/DTLS instead of TCP/TLS?**

TLS runs over TCP, which provides reliable, ordered delivery. But VPN tunnels carry IP packets — and IP itself is unreliable. If you put TCP inside a TCP tunnel, you get "TCP over TCP meltdown": the outer TCP retransmits when the inner TCP times out, but the inner TCP doesn't know about the outer TCP's losses, causing exponential backoff and extremely poor performance. DTLS (Datagram TLS) is TLS running over UDP: it provides encryption and authentication without requiring reliability, avoiding the double-TCP problem.

**HOW does WireGuard achieve its simplicity advantage?**

Traditional IPsec is a committee-designed protocol with over 20 years of backward compatibility requirements. WireGuard makes opinionated choices: ChaCha20-Poly1305 for encryption (no algorithm negotiation), Curve25519 for key exchange (no certificate infrastructure), and Poly1305 for MAC (no algorithm choice). The entire protocol fits in ~4000 lines of code vs. hundreds of thousands for OpenVPN or IPsec. Simplicity means fewer bugs and easier security auditing.

---

## 14. OpenVPN Architecture — NAT and Multiplexing

### 📊 Slide Content

```
OpenVPN Architecture:

Client Side:
  Browser → TCP/IP → tun0 → OpenSSL (TLS auth+encrypt) → OpenVPN (user space)
                                                              → UDP/IP → eth0 → WAN

VPN Server Side:
  eth0 → UDP/IP → OpenVPN → OpenSSL → routing, NAT → tun0 → TCP/IP → webserver

Traffic visible on WAN:
  eth ip udp [ip tcp http payload]   ← outer packet
           ↑______inner packet_____↑ ← encrypted, inside UDP payload

NAT Translation Table:
  WAN side addr           VPN side addr
  138.76.29.7, 5001  ←→  10.0.10.5, 3345
  138.76.29.7, 5002  ←→  10.0.10.5, 3346
  138.76.29.7, 5003  ←→  10.0.10.6, 1245
```

---

### 🧠 Discussion

#### OpenVPN Packet Journey — Step by Step

| Step | Location | What Happens | Packet Content |
|------|----------|--------------|---------------|
| 1 | Browser | Creates HTTP request to webserver | `[HTTP GET /page]` |
| 2 | OS TCP/IP stack | Wraps in TCP+IP | `[IP: src=tun0-IP, dst=webserver] [TCP] [HTTP]` |
| 3 | tun0 interface | Packet intercepted by OpenVPN driver | Same packet |
| 4 | OpenVPN user-space | Encrypts entire inner IP packet using OpenSSL/TLS | `[encrypted blob]` |
| 5 | UDP encapsulation | Wraps encrypted blob in UDP datagram | `[UDP] [encrypted-inner-packet]` |
| 6 | eth0 (real NIC) | Wraps in outer IP header pointing to VPN server | `[IP: src=eth0-IP, dst=vpn-server] [UDP] [encrypted]` |
| 7 | Internet | Routes outer packet to VPN server's public IP | Eavesdropper sees: IP+UDP to VPN server, encrypted payload |
| 8 | VPN Server eth0 | Receives outer UDP packet | Strip outer IP+UDP headers |
| 9 | OpenSSL decryption | Decrypts inner packet | Original `[IP: src=tun0-IP, dst=webserver] [TCP] [HTTP]` |
| 10 | NAT | Replaces tun0-IP with server's public IP + new port | `[IP: src=138.76.29.7:5001, dst=webserver]` |
| 11 | Webserver | Receives request, sends response to 138.76.29.7:5001 | Response |
| 12 | VPN Server NAT | Looks up NAT table: 5001 → 10.0.10.5:3345 | Routes back to correct client |
| 13 | Reverse tunnel | Response encrypted, sent back through tunnel to client | Client receives decrypted response |

#### Why NAT Is Necessary

Multiple VPN clients share the VPN server's single public IP address. Without NAT, when the webserver replies to 138.76.29.7, the VPN server wouldn't know which of its thousands of clients the response belongs to. NAT adds a port mapping that uniquely identifies each client flow, enabling correct demultiplexing.

#### What Wiretapping Reveals

| Observer Location | Can See | Cannot See |
|------------------|---------|------------|
| Between client and VPN server | Client IP, VPN server IP, packet sizes, timing, UDP port | Destination webserver, HTTP content, inner IP headers |
| Between VPN server and webserver | VPN server IP, webserver IP, HTTP content (if no HTTPS) | Client's real IP address |
| VPN server itself | Everything — both sides of the tunnel | Nothing (the server is a trusted party) |

---

## 15. Traffic Leakage: Without VPN vs. With VPN

### 📊 Slide Content

```
Without VPN:
  browser → TCP/IP → eth0 → [ip src=client] [tcp] [http payload] → WAN → webserver
  
  Malicious tcpdump on the path sees:
    ip_src = client (192.168.1.3)
    ip_dst = webserver
    [TCP payload visible if not HTTPS]

With VPN (OpenVPN):
  browser → tun0 → OpenSSL → UDP/IP → eth0 → WAN → VPN server → webserver
  
  Malicious tcpdump on the path between client and VPN server sees:
    ip_src = eth0 IP of client
    ip_dst = vpn server
    [encrypted UDP payload — unreadable]
```

---

### 🧠 Discussion

#### Information Leakage Analysis (From 2026 Midterm Exam)

This analysis directly mirrors Question 6 from the 2026 midterm exam. Master this table.

| Scenario | Observer | Can Observe | Cannot Observe |
|----------|----------|------------|----------------|
| **No VPN** | On-path between C and S | Client IP (a), Server IP (b), timing/volume (d) | Nothing (everything is visible) |
| **No VPN** | Destination server S | Client IP (a), Server IP (b), timing/volume (d) | Nothing relevant |
| **VPN enabled** | On-path between C and V (VPN gateway) | Client IP (a), VPN gateway public IP (c), timing/volume (d) | Destination server IP (b) |
| **VPN enabled** | VPN gateway V | Everything: client IP (a), destination server IP (b), VPN IP (c), timing/volume (d) | Nothing — V is the trusted termination point |
| **VPN enabled** | Destination server S | Destination server IP (b), VPN gateway IP (c), timing/volume (d) | Client's real IP (a) — S sees VPN server as source |

#### Key Insight: VPN Does NOT Provide Anonymity from the VPN Provider

The VPN gateway decrypts all traffic. It sees everything. VPN protects you from:
- Your ISP monitoring your traffic
- On-path attackers between you and the gateway
- The destination server learning your real IP

VPN does NOT protect you from:
- The VPN provider itself
- Traffic analysis based on timing and volume
- Destination-side tracking (cookies, fingerprinting)

#### Can a VPN "Eliminate All Traffic-Flow Metadata"?

**No** — this was a False answer on the 2026 midterm (Q12):

> *"Using a VPN (tunnel mode) can eliminate all traffic-flow metadata (source/destination address, timing, volume) leakage."* → **FALSE**

Why? Even in tunnel mode, the outer IP header reveals: client IP (to ISP and path observers), VPN server IP, packet sizes, and timing. Complete traffic-flow anonymity would require additional techniques like Tor (onion routing with multiple hops and uniform packet sizing).

---

## 16. Anti-Replay Service

### 📊 Slide Content

```
Anti-Replay Service:

§ Uses sequence number + sliding window mechanism

§ Sender:
  • Initializes sequence number to 0 when new SA is established
  • Increments for EVERY packet sent

§ Receiver accepts packets with sequence number within window:
  • Window size W
  • Accept if: (N – W + 1) ≤ sequence# ≤ N   (where N = highest accepted so far)

§ If sequence# > N: advance window, accept (if ICV valid)
§ If sequence# within window: check bitmap, reject if already received
§ If sequence# < left edge of window: reject (too old, assumed replay)
```

---

### 🧠 Discussion

#### Sliding Window Mechanics

```
                          ← W bits wide (e.g., 64 or 1024) →
                          ┌───────────────────────────────────┐
  Already             [reject|  bitmap of accepted/missing  |N]  → future
  received  ←─────────────┘                                  ↑
                                               N = highest sequence # accepted so far
```

| Event | Action | Reason |
|-------|--------|--------|
| Seq# > N (new highest) | Accept (if ICV valid), advance window right | Fresh packet, never seen |
| Seq# ≤ N, within window | Check bitmap: if not set → accept, set bit; if set → reject | Already received this sequence number |
| Seq# < left edge of window | Reject always | Too old — could be a replay |

#### Why Sequence Numbers Alone Are Not Enough

Sequence numbers prove *order* but not *freshness* unless combined with the sliding window. Without the window, an attacker could replay any sequence number that has already been accepted. The window's bitmap tracks which specific sequence numbers within the window have been used, preventing exact replays.

#### Sequence Number Overflow

When the 32-bit sequence number approaches 2^32 - 1 (about 4.3 billion), it must not wrap around (which would reuse sequence numbers and enable replay attacks). IPsec's response: either:
1. The SA expires before overflow (if lifetime is set short enough)
2. Extended Sequence Numbers (ESN) uses 64-bit counters (IPsec RFC 4303)

#### Understanding via Simon Sinek's Golden Circle

**WHY does IPsec need anti-replay when TLS doesn't?**

TLS uses TCP, which already provides ordered, reliable delivery — TCP sequence numbers inherently prevent replays within a connection. IPsec operates at the network layer over IP (which is connectionless and unreliable). IPsec packets can be reordered by the network. Without the anti-replay window, an attacker could capture a valid ESP packet and retransmit it hours later, causing the receiver to process the same authenticated command twice (e.g., "delete file X" executed twice).

The sliding window is the solution: it allows *legitimate* out-of-order delivery (within a reasonable window) while rejecting *malicious* replays of packets received long ago.

---

## 17. VPN and Firewall Evasion

### 📊 Slide Content

```
Evading Firewalls with VPN:

§ Using VPN, one can create a tunnel between a computer inside
  the network and another one outside.

§ IP packets can be sent using this tunnel.

§ Since tunnel traffic is encrypted, firewalls cannot see what is
  inside the tunnel and cannot conduct filtering.

SSH Tunneling (alternative evasion):
§ Scenario: Company blocks telnet to external machine "work"
§ Solution:
  1. SSH tunnel from "home" to "apollo" (SSH traffic allowed)
  2. Forward TCP port 8000 on home → port 23 on work
  3. Telnet to localhost:8000 → traffic travels through SSH tunnel
  4. Firewall sees only: SSH traffic to apollo (allowed)

Dynamic Port Forwarding:
§ SSH -D 9000: creates SOCKS proxy at localhost:9000
§ Browser configured to use localhost:9000 as proxy
§ All HTTP requests tunneled through SSH to "home" machine
```

---

### 🧠 Discussion

#### Firewall Evasion Techniques Comparison

| Technique | How It Works | What Firewall Sees | Limitations |
|-----------|-------------|-------------------|-------------|
| **VPN (Tunnel Mode)** | Encapsulates all IP traffic in encrypted ESP/UDP to VPN gateway | Encrypted UDP to VPN gateway IP | Firewall can block VPN gateway IP; VPN ports (UDP 500/4500) may be blocked |
| **SSH Tunneling (local port forwarding)** | SSH channel carries arbitrary TCP data; `-L local_port:remote:port` | SSH traffic to allowed SSH server | Requires SSH server outside; only TCP (not UDP) |
| **Dynamic Port Forwarding (SOCKS)** | SSH creates SOCKS5 proxy; browser routes all traffic | SSH traffic to allowed SSH server | Client software must support SOCKS; TCP only |
| **TLS Proxy / HTTPS proxy** | HTTP CONNECT method creates tunnel through proxy | HTTPS to proxy server | Works through most firewalls; proxy must be trusted |

#### Understanding via Simon Sinek's Golden Circle

**WHY can't firewalls see inside VPN tunnels?**

A packet-filter or stateful firewall makes decisions based on packet headers — IP addresses, ports, protocol numbers. In ESP tunnel mode, the meaningful headers (inner IP, inner ports) are inside the encrypted ESP payload. The firewall only sees the outer IP header (pointing to the VPN gateway) and the ESP protocol number. Without the decryption key, the firewall cannot inspect the payload and must either: (a) allow all traffic to the VPN gateway, or (b) block VPN entirely.

**HOW does this affect corporate security policies?**

This is a double-edged sword:
- **Defensive use**: Employees working from hotel WiFi use VPN to protect corporate data from the untrusted network.
- **Evasive use**: Employees (or malware) inside a corporate network can use VPN to exfiltrate data to an external server, bypassing egress filters that would normally block certain destinations.

Corporate security solutions: Deep Packet Inspection (DPI) firewalls, application-aware firewalls, and endpoint management tools can detect and block unauthorized VPN clients.

---

## 18. Quick Reference Summary Table

### 🗂️ Full VPN Topic Quick Reference

| Topic | Key Term | Definition | Exam Trigger |
|-------|----------|-----------|--------------|
| VPN | Tunnel | Encrypted end-to-end path between two endpoints | "What does a VPN hide?" |
| VPN | Transport mode | IPsec applied to payload only; original IP header intact | "Which mode for host-to-host?" |
| VPN | Tunnel mode | IPsec applied to entire packet; new outer IP added | "Which mode for VPN gateways?" |
| IPsec | AH | Authentication Header; integrity + auth, NO encryption | "Does AH encrypt?" → No |
| IPsec | ESP | Encapsulating Security Payload; encryption + optional auth | "Most common IPsec protocol" |
| IPsec | SA | Security Association; one-way; indexed by (SPI, dst IP, proto) | "SA is one-way or two-way?" |
| IPsec | SPI | 32-bit identifier chosen by receiver; indexes SA in SAD | "How does receiver find the SA?" |
| IPsec | SPD | Security Policy Database; rules for which traffic to protect | "What decides PROTECT vs. BYPASS?" |
| IPsec | SAD | Security Association Database; current keys, seq#, algorithms | "Where are keys stored?" |
| IPsec | IKE | Internet Key Exchange; negotiates SA parameters using DH | "How are IPsec keys established?" |
| Anti-replay | Sequence number | Per-SA counter; starts at 0; increments every packet | "What prevents replay attacks?" |
| Anti-replay | Sliding window | Bitmap of accepted sequence numbers within window W | "Why sliding window not just counter?" |
| AH | ICV | Integrity Check Value; HMAC over immutable header fields + payload | "What does AH authenticate?" |
| AH | Mutable fields | TTL, checksum, DSCP — excluded from ICV computation | "Why not authenticate TTL?" |
| ESP | Padding | Byte alignment + optional size normalization | "Why is padding in ESP?" |
| ESP | Encrypt-then-MAC | ICV computed over ciphertext, not plaintext | "Correct order: encrypt or MAC first?" |
| NAT | NAT-T | NAT Traversal; ESP encapsulated in UDP for NAT compatibility | "Why does AH break with NAT?" |
| Traffic analysis | Limited confid. | Tunnel mode hides inner headers but not timing/volume | "Does VPN eliminate all metadata?" → No |
| OpenVPN | tun0 | Virtual network interface; captures packets for VPN | "What intercepts traffic in OpenVPN?" |
| Modes | ESP Tunnel | Most common for VPN gateways; encrypts entire original packet | "What to use for site-to-site VPN?" |
| Exam trap | AH + NAT | AH breaks when NAT is present (ICV over src IP, which NAT changes) | Classic exam question |
| Exam trap | ESP no auth | ESP without authentication: confidential but not integrity-protected | "Is ESP always secure?" → No |
| Exam trap | VPN anonymity | VPN hides real IP from destination, but VPN provider sees all | "Is VPN truly anonymous?" → No |

---

## 19. Exam Preparation — Integrative Questions

### ✅ True / False

**Q1.** ESP in transport mode encrypts the original IP header.
> **FALSE.** Transport mode encrypts only the payload (TCP/UDP + data), not the original IP header. Tunnel mode is required to encrypt the inner IP header.

**Q2.** AH provides both confidentiality and integrity.
> **FALSE.** AH provides integrity and data origin authentication but does NOT provide confidentiality (no encryption). Only ESP provides encryption.

**Q3.** A Security Association (SA) is bidirectional — one SA covers both directions of a VPN tunnel.
> **FALSE.** An SA is one-way (unidirectional). A two-way VPN tunnel requires TWO SAs: one for each direction.

**Q4.** IPsec tunnel mode can encrypt the inner IP header, hiding the true destination from a firewall.
> **TRUE.** This is the basis for using tunnel mode to evade destination-IP-based egress filtering.

**Q5.** Using a VPN (tunnel mode) eliminates all traffic-flow metadata leakage (source address, timing, volume).
> **FALSE.** The outer IP header (revealing client IP and VPN gateway IP), packet sizes, and timing are still observable by on-path entities.

**Q6.** The SPI in an IPsec packet is chosen by the sender.
> **FALSE.** The SPI is chosen by the **receiver** during SA negotiation. The receiver controls its own SA lookup key space.

**Q7.** AH is incompatible with NAT because NAT modifies the IP source address, which is included in the AH ICV computation.
> **TRUE.** This is why ESP is preferred in modern deployments; NAT + AH always results in ICV verification failures.

**Q8.** The Security Policy Database (SPD) stores the cryptographic keys used for encryption.
> **FALSE.** The SPD stores *policies* (rules for which traffic to protect and how). Keys are stored in the **Security Association Database (SAD)**.

---

### 🔘 Multiple Choice (Single Answer)

**Q9.** Which IPsec mode can encrypt the inner IP header to evade destination-address-based egress filtering in a firewall?

- A) Transport Mode
- B) AH Mode
- C) **Tunnel Mode ✅**
- D) Neither

> **Explanation:** Only Tunnel Mode encapsulates the entire original IP packet (including its header) inside an encrypted ESP payload. The firewall sees only the outer IP header pointing to the VPN gateway.

---

**Q10.** What uniquely identifies a Security Association on an IPsec receiver?

- A) Source IP address + destination port
- B) **SPI + destination IP address + security protocol ✅**
- C) Sequence number + session key
- D) Timestamp + SPI

> **Explanation:** An SA is defined by the 3-tuple: (SPI, destination IP address, security protocol identifier: AH or ESP).

---

**Q11.** Which of the following statements about ESP without authentication is correct?

- A) It provides both confidentiality and integrity
- B) It provides integrity but not confidentiality
- C) **It provides confidentiality but NOT integrity ✅**
- D) It provides neither confidentiality nor integrity

> **Explanation:** ESP encryption alone provides confidentiality. Without the authentication option enabled, an attacker can modify the ciphertext without detection.

---

**Q12.** In the OpenVPN architecture, what role does the `tun0` virtual interface play?

- A) It encrypts traffic using AES
- B) It performs NAT for multiple VPN clients
- C) **It intercepts outbound IP packets and passes them to the OpenVPN user-space process ✅**
- D) It handles IKE key exchange

> **Explanation:** `tun0` is a virtual network interface. The OS routes outbound packets to it, OpenVPN reads those packets, encrypts them via OpenSSL, and sends them as UDP datagrams through the real `eth0` interface.

---

**Q13.** Why does the sliding window in IPsec anti-replay protection allow out-of-order packets?

- A) Because UDP reorders packets intentionally
- B) Because routers may drop and retransmit packets
- C) **Because network conditions can cause legitimate packets to arrive out of order ✅**
- D) Because the sender always reorders packets

> **Explanation:** IP is connectionless. Packets may take different routes and arrive at the receiver out of order. A strict sequential-only check would reject legitimate late-arriving packets. The window allows packets within W sequence numbers of the highest received to be accepted.

---

### ☑️ Multiple Answer (Select All That Apply)

**Q14.** Which security services does IPsec ESP with authentication provide? (Select all that apply)

- A) ✅ Confidentiality (encryption)
- B) ✅ Data integrity
- C) ✅ Data origin authentication
- D) ✅ Anti-replay service
- E) ❌ Non-repudiation
- F) ✅ Limited traffic flow confidentiality (in tunnel mode)

> **Note:** Non-repudiation requires asymmetric cryptography (digital signatures). IPsec uses symmetric keys shared between two parties — either party could have generated the message.

---

**Q15.** Which of the following are observable by an on-path attacker when VPN (tunnel mode) is enabled between client C and destination server S via VPN gateway V? (Select all that apply)

- A) ✅ Client's real IP address (visible in outer IP header between C and V)
- B) ❌ Destination server IP (hidden inside encrypted ESP payload)
- C) ✅ VPN gateway's public IP address (outer IP destination)
- D) ✅ Traffic metadata: timing and volume (observable from packet sizes and timing)
- E) ❌ Application data (encrypted)

---

**Q16.** Which mechanisms does IPsec use to provide anti-replay protection? (Select all that apply)

- A) ✅ Monotonically increasing sequence numbers
- B) ✅ Sliding window with bitmap of accepted sequence numbers
- C) ❌ Timestamps (not used in IPsec; used in Kerberos)
- D) ❌ Nonces (used in TLS handshake, not IPsec anti-replay)
- E) ✅ Rejection of sequence numbers below the window's left edge

---

### 📝 Short Answer (Open-Ended)

**Q17.** Explain why the TGT in Kerberos and the SPI in IPsec serve analogous functions, yet operate on fundamentally different trust models.

> **Model Answer:** Both serve as lookup identifiers for session state at the receiving end. The Kerberos TGT contains session credentials encrypted for the TGS — it is an opaque blob that the client carries without being able to read it. The SPI is a 32-bit index that points to an SA entry in the SAD at the receiver. The key difference is trust model: Kerberos involves a trusted third party (KDC) that vouches for the session and generates the TGT; the client cannot forge or modify it. IPsec SAs are negotiated directly between two parties using IKE (based on Diffie-Hellman), without a central authority vouching for identity beyond the initial IKE authentication (which typically uses certificates or PSK). Both are tamper-resistant: the TGT by Kc,TGS encryption; the SA by the ICV covering each packet.

---

**Q18.** A company firewall has a rule: "DROP all outbound TCP packets with destination port 443 to IP range 203.0.113.0/24." An employee uses IPsec tunnel mode to connect to a VPN gateway at 10.10.10.1. Explain how the employee can still access a server at 203.0.113.5:443 and whether this evasion is detectable by the firewall.

> **Model Answer:** In IPsec tunnel mode, the employee's packet `[IP: src=client, dst=203.0.113.5] [TCP:dst=443]` is fully encapsulated inside an ESP payload. The outer IP packet has `dst=10.10.10.1` (the VPN gateway). The firewall applies its filter rules to the *outer* IP header only — it sees a packet to 10.10.10.1, which does not match the DROP rule (since the rule targets 203.0.113.0/24). The inner headers are inside the encrypted ESP payload and are completely invisible to the firewall. Therefore the connection succeeds. Detectability: The firewall cannot detect this evasion through packet inspection alone, since the payload is encrypted. Detection requires: (1) blocking all traffic to known VPN gateway IPs, (2) blocking ESP (IP protocol 50) and IKE (UDP 500/4500), or (3) using endpoint agent-based monitoring that inspects traffic before encryption.

---

**Q19.** What is the difference between the SPD and SAD in IPsec? Give a concrete example showing how they interact when a VPN client sends a packet.

> **Model Answer:** The **SPD** (Security Policy Database) contains administrator-defined rules: "IF traffic matches selector X, THEN apply policy Y." It defines *intent*. The **SAD** (Security Association Database) contains the current cryptographic state: actual keys, algorithms, sequence numbers, and SA lifetimes. It defines *implementation*.
> 
> Concrete example: An admin creates SPD rule: "Traffic from 10.0.0.0/24 to 192.168.1.0/24 → PROTECT with ESP, AES-256, tunnel mode." When a client at 10.0.0.5 sends a packet to 192.168.1.10:
> 1. The IP layer consults the SPD and finds the matching rule: PROTECT.
> 2. IPsec looks up the SAD for an active SA matching this policy. If none exists, IKE is triggered to negotiate one.
> 3. The SA entry in the SAD provides: SPI=0xABCD1234, encryption key=K_enc, auth key=K_auth, seq#=42, algorithm=AES-256-GCM.
> 4. ESP processes the packet using those SAD parameters: encrypts the original packet, sets SPI=0xABCD1234, increments seq# to 43, computes ICV.
> 5. The processed packet is sent. The SAD sequence number is updated to 43 for the next packet.

---

### 📊 Fill in the Blank

**Q20.** A Security Association is __________ (one-way/two-way), so a bidirectional VPN tunnel requires __________ SAs.
> **one-way; two**

**Q21.** The __________ field in an ESP or AH packet allows the receiver to look up the correct Security Association in the SAD.
> **SPI (Security Parameters Index)**

**Q22.** AH fails when used with NAT because NAT modifies the __________ field, which is included in the AH ICV computation.
> **source IP address**

**Q23.** IPsec __________ mode is preferred over __________ mode for VPN gateways because it hides the inner IP header, protecting internal network topology.
> **Tunnel; Transport**

**Q24.** The anti-replay sliding window in IPsec rejects packets whose sequence number falls __________ the left edge of the window.
> **below (less than)**

**Q25.** OpenVPN uses a __________ virtual interface to intercept outbound packets from the OS before encrypting them and sending via the real __________ interface.
> **tun0; eth0**

---

### 🎯 Challenge-Level Integrative Question

**Q26.** Design a VPN deployment for the following scenario and justify your choices:

*A hospital has 500 laptops that need to securely access an internal Electronic Health Records (EHR) system from home. The EHR server is at 10.1.1.100. The hospital has a VPN gateway at its network perimeter with public IP 203.0.113.50. Home users have dynamic IP addresses and their ISPs may use NAT.*

Address: (a) choice of IPsec mode, (b) ESP vs. AH, (c) anti-replay configuration, (d) what metadata is still visible to the home ISP, (e) what the hospital's VPN gateway can see.

> **Model Answer:**
> 
> **(a) Mode: ESP Tunnel Mode** — Tunnel mode is required because (1) the home laptops need to appear to be on the internal hospital network, receiving a virtual IP from the 10.x.x.x space; (2) internal EHR server topology (10.1.1.100) must be hidden from the home ISP; (3) tunnel mode enables all hospital traffic to be routed through the gateway regardless of the application.
> 
> **(b) ESP (not AH):** AH is incompatible with home users' NAT routers. Home ISPs frequently use NAT (carrier-grade NAT or home router NAT). AH authenticates the source IP address field; NAT changes this address, breaking the ICV. ESP in tunnel mode places the authentication data over the ESP header and encrypted payload (not the outer IP header), so NAT-modified outer IP headers don't break authentication. Additionally, ESP provides encryption — critical for patient health data (HIPAA compliance). AH alone (no encryption) would be inappropriate.
> 
> **(c) Anti-replay:** Enable IPsec anti-replay with sequence numbers and a sliding window of at least 64 packets (larger windows tolerate more network jitter). Set SA lifetimes to 8 hours (time-based) or 10 GB (byte-based) to force periodic rekeying. This limits the exposure window if a session key is compromised.
> 
> **(d) Visible to home ISP:** The home ISP can see: (1) client's home IP address (outer IP source), (2) VPN gateway public IP 203.0.113.50 (outer IP destination), (3) traffic volume and timing, (4) that the client is using a VPN (UDP port 4500 for NAT-traversed IPsec, or port 443 for SSL VPN). The ISP cannot see: the EHR server IP, HTTP/HTTPS content, which records are accessed.
> 
> **(e) VPN gateway sees:** The VPN gateway decrypts all traffic and can see: client's tunnel IP, EHR server IP, all application data (HTTP requests, HL7 messages, etc.). This is unavoidable with VPN architecture — the gateway is the trusted termination point. To protect against a compromised gateway, end-to-end TLS between laptops and the EHR server should be added as a second layer, so even gateway compromise does not expose plaintext health records.

---

*End of VPN Protocol Deep-Dive Annotated Study Guide*

---
> **Document:** VPN_Protocol_Deep_Dive_Study_Guide.md  
> **Course:** CS 448/548 Network Security, Spring 2026  
> **Coverage:** Lectures 14–16 (IPsec, VPN, Firewalls)  
> **Modeled after:** Kerberos End-to-End Workflow (kerberos_workflow.html)  
> **Framework:** Simon Sinek's Golden Circle (WHY → HOW → WHAT) for all conceptual explanations
