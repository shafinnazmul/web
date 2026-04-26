# IP Security (IPSec) Protocol — Deep-Dive Annotated Study Guide
**CS 448/548 Network Security · All Components, Modes & Message Flows**

---

> **How to use this guide:** Each slide section is presented first as a concise key-concept block, then followed by a deep-dive discussion using Simon Sinek's Golden Circle (WHY → HOW → WHAT), beginner-friendly analogies, expert-level reasoning, and protocol tables where relevant. Practice questions (Multiple Choice, True/False, Short Answer, Fill in the Blank) follow each topic cluster. A Quick Reference Summary and Exam Integrative Questions close the guide.

---

## Reading Legend

| Symbol / Label | Meaning |
|---|---|
| `SPI` | Security Parameters Index — unique identifier for a Security Association |
| `SA` | Security Association — one-way secure relationship; two SAs needed for bidirectional traffic |
| `AH` | Authentication Header — provides integrity + data origin auth, NO encryption |
| `ESP` | Encapsulating Security Payload — provides integrity + auth + confidentiality |
| `IKE` | Internet Key Exchange — automated key negotiation protocol |
| `ICV` | Integrity Check Value — the HMAC-based authentication tag |
| `SPD` | Security Policy Database — what to do with each packet |
| `SAD` | Security Association Database — how to do it |
| **field** | Protocol field name (SPI, SeqNum, NextHeader, etc.) |
| ⚠️ | Security warning or attack surface |
| 💡 | Design insight |
| 🎯 | Analogy |

---

# Slide 1 — What is IPSec and Why Does it Exist?

## 📌 Key Concepts at a Glance
- IPSec is a **suite of protocols** operating at **Layer 3 (Network Layer)** to secure IP packets
- Provides: access control, data integrity, data origin authentication, anti-replay, confidentiality, limited traffic-flow confidentiality
- Because it operates at Layer 3, it protects **all traffic from all applications transparently**
- Can be implemented in routers/firewalls → security for all traffic crossing a network perimeter
- Transparent to end-user applications — apps do not need to be rewritten

---

## 📖 Discussion

### 🔴 WHY — The Fundamental Problem

The Internet Protocol (IP) was designed for reliability and connectivity — not security. An IP packet carries a source address, a destination address, and a payload. By design:

- **Anyone on the path can read the payload** — IP provides no confidentiality
- **Anyone can forge the source address** — IP provides no origin authentication
- **Anyone can modify packets in transit** — IP provides no integrity checking
- **Replaying old packets is trivial** — IP provides no anti-replay mechanism

Every router between Alice and Bob sees every packet in the clear. A compromised router can read, modify, or silently drop packets. This is not a theoretical concern — real-world BGP hijacking incidents have redirected entire nations' Internet traffic through malicious infrastructure.

IPSec exists to answer a specific question: **can we add security to IP itself**, so that all traffic — regardless of which application sent it — gets protected?

### 🟡 HOW — The Network-Layer Approach

IPSec works by augmenting or replacing the IP header processing with cryptographic operations:

- **Authentication Header (AH):** Adds a cryptographic signature over the IP packet to prove who sent it and that it wasn't modified
- **Encapsulating Security Payload (ESP):** Encrypts the payload (and optionally the original IP header) and adds authentication
- **Internet Key Exchange (IKE):** Automates the negotiation of what algorithms and keys to use before encrypted communication begins
- **Security Associations (SAs):** Database entries describing the parameters of each secure channel

IPSec can run in two modes:
- **Transport Mode:** Protects the payload; original IP header is left intact (used between two hosts)
- **Tunnel Mode:** Wraps the entire original IP packet in a new IP packet (used for VPNs between gateways)

### 🟢 WHAT — The Result

Once IPSec is configured between two endpoints (or two gateways), every IP packet between them benefits from:
- **Confidentiality** (ESP): no eavesdropper can read the payload
- **Integrity** (AH or ESP): no middleman can alter the packet undetected
- **Data Origin Authentication** (AH or ESP): receiver can verify who sent the packet
- **Anti-Replay** (sequence numbers): old captured packets cannot be replayed later

Crucially, a web browser, email client, or any legacy application that has zero awareness of IPSec automatically gets these protections. This is the defining advantage of network-layer security over application-layer security (like TLS).

### 🎯 Analogy — The Armored Van vs. Individual Briefcases

TLS (application-layer security) is like each person in your office putting their own documents in a locked briefcase. Each person has to remember to use the briefcase. If someone forgets, their documents travel unprotected.

IPSec is like putting the entire office into an armored van for the commute. Every person, every document, every coffee thermos — all protected simultaneously, whether anyone thought about security or not. The van handles security. No individual needs to do anything.

### 💡 Key Benefits Elaborated

| Benefit | Explanation |
|---|---|
| Security at Layer 3 | Applies to ALL transports (TCP, UDP, ICMP) and ALL applications equally |
| Implemented in Firewall/Router | Can protect all traffic crossing the network perimeter — even from legacy apps |
| Transparent to applications | No code changes required in existing software |
| Can protect individual users | End-to-end mode between hosts is possible, not just gateway-to-gateway |
| Protects routing infrastructure | IPSec can authenticate router advertisements, preventing BGP/OSPF attacks |

---

## 🧪 Practice Questions — Topic 1

**[Multiple Choice]** At which layer of the TCP/IP model does IPSec operate?

A) Application Layer  
B) Transport Layer  
C) Network Layer  
D) Data Link Layer

✔ **Answer: C** — IPSec operates at the Network Layer (Layer 3), securing IP packets regardless of which application or transport protocol is being used above it.

---

**[True/False]** IPSec requires each application (web browser, email client) to be specifically coded to use it.

✔ **Answer: False** — IPSec operates at the network layer, below the application layer. Applications are completely unaware of IPSec and do not need to be modified. This is a key advantage over application-layer security like TLS.

---

**[Short Answer]** Name four security services provided by IPSec and briefly describe each.

✔ **Answer:**
1. **Data Integrity** — HMAC-based ICV detects any modification to packets in transit
2. **Data Origin Authentication** — Verifies that a packet came from the claimed sender
3. **Confidentiality** — ESP encryption ensures only the intended recipient can read the payload
4. **Anti-Replay** — Sequence numbers and a sliding window prevent old captured packets from being replayed

---

**[Fill in the Blank]** IPSec provides security at Layer _____, which means it can protect traffic regardless of the _____ or _____ protocol being used.

✔ **Answer:** 3 (Network); transport; application

---

# Slide 2 — IPSec Architecture Overview

## 📌 Key Concepts at a Glance
- IPSec is a **framework**, not a single protocol
- Four major architectural components: **IKE, SAD (Security Association Database), SPD (Security Policy Database), ESP/AH protocols**
- **Security Association (SA):** One-way, defined by three parameters: SPI + Destination IP + Security Protocol (AH or ESP)
- **SA is unidirectional** — bidirectional communication requires **two SAs**
- The SPD answers: *"What should we do with this packet?"* (protect, bypass, or discard)
- The SAD answers: *"How do we do it?"* (which keys, algorithms, parameters)

---

## 📖 Discussion

### 🔴 WHY — Why an Architecture, Not a Single Protocol?

Different communication scenarios require different security trade-offs. Sometimes you need encryption but not authentication (rare); sometimes you need authentication but not encryption (e.g., routing protocol protection); sometimes you need both. Sometimes you're securing a single host-to-host link; sometimes an entire VPN tunnel between offices.

A monolithic "one-size-fits-all" approach would be inflexible and inefficient. IPSec's architecture separates **policy** (what to do), **state** (how to do it), and **execution** (actually doing it) into distinct components.

### 🟡 HOW — The Four Architectural Pillars

**1. Internet Key Exchange (IKE)**
Before two systems can protect traffic, they need to agree on shared secret keys and algorithms. IKE is the negotiation protocol that handles this automatically. Without IKE, administrators would have to manually configure matching keys on every pair of communicating devices — practically impossible at scale.

**2. Security Policy Database (SPD)**
The SPD is the decision engine. For every outgoing or incoming packet, the SPD is consulted first. It contains rules (like a firewall ruleset) that say:
- *"Traffic between 10.0.0.0/24 and 192.168.1.0/24 using TCP → PROTECT with ESP"*
- *"ICMP traffic to network management host → BYPASS (no IPSec)"*
- *"All other traffic from unknown sources → DISCARD"*

**3. Security Association Database (SAD)**
Once the SPD says "protect this packet," the SAD provides the specifics: which encryption algorithm, which key, which authentication algorithm, the sequence number counter, anti-replay window state. Each SA entry is uniquely identified by the SPI (Security Parameters Index), a 32-bit number that the receiver uses to look up the correct SA when a packet arrives.

**4. AH and ESP Protocols**
These are the actual packet-processing protocols. AH adds an authentication header. ESP adds an ESP header, encrypted payload, and authentication trailer. Both are described in their own slides below.

### 🟢 WHAT — The Result

The four components work together as a complete security framework:

```
Outgoing Packet:
  SPD lookup → "which SA applies?" → SAD lookup → "apply ESP with AES-256, HMAC-SHA256, seq=1042" → protected packet sent

Incoming Packet:
  Extract SPI from AH/ESP header → SAD lookup → verify ICV → decrypt → SPD check → deliver to application
```

### 🎯 Analogy — Airport Security System

- **SPD** = The airport's security policy rulebook: "All passengers go through screening; VIP diplomatic couriers get bypassed; unknown entrants are denied"
- **SAD** = The specific screener assigned to Gate 7: "Use X-ray scanner model X3000, frequency band Y, calibrated today at 9am"
- **IKE** = The process of training and deploying the screener before the airport opens
- **AH/ESP** = The actual scanning equipment being operated

---

## 🧪 Practice Questions — Topic 2

**[Multiple Choice]** A Security Association (SA) in IPSec is best described as:

A) A bidirectional encrypted channel between two hosts  
B) A one-way security relationship described by SPI, Destination IP, and Security Protocol  
C) The set of firewall rules governing packet filtering  
D) The database of all active user sessions

✔ **Answer: B** — An SA is explicitly one-way. A full bidirectional communication (e.g., Alice and Bob exchanging packets) requires two SAs: one for Alice→Bob and one for Bob→Alice, each with its own SPI.

---

**[True/False]** The Security Policy Database (SPD) and Security Association Database (SAD) serve the same function in IPSec.

✔ **Answer: False** — They serve distinct functions. The SPD is the *policy decision point* — it determines what action to take on a packet (protect/bypass/discard) and which SA type to use. The SAD is the *operational state store* — it holds the specific keys, algorithms, sequence counters, and parameters for each active SA.

---

**[Short Answer]** What are the three parameters that uniquely define a Security Association (SA)?

✔ **Answer:**
1. **SPI (Security Parameters Index)** — a 32-bit value in the AH/ESP header that lets the receiver look up the correct SA
2. **IP Destination Address** — the unicast or multicast address of the destination endpoint of the SA
3. **Security Protocol Identifier** — either AH or ESP; specifies which protocol this SA uses

---

**[Fill in the Blank]** Because an SA is __________, two SAs are required for a full __________ communication session between two hosts.

✔ **Answer:** unidirectional (one-way); bidirectional

---

# Slide 3 — Security Association Database (SAD) in Depth

## 📌 Key Concepts at a Glance
- Each SA entry in the SAD contains: SPI, sequence number counter, anti-replay window, AH information, ESP information, SA lifetime, mode (Transport/Tunnel/Wildcard), path MTU
- **Sequence number counter:** 32-bit counter, incremented for every packet sent; receiver checks for duplicates
- **Anti-replay window:** A sliding window (typically 64 packets wide) that defines which sequence numbers are currently valid
- **SA Lifetime:** When the lifetime expires (by time or byte count), the SA is renegotiated via IKE
- **Mode field:** Transport, Tunnel, or Wildcard

---

## 📖 Discussion

### 🔴 WHY — Why Keep All This State Per-SA?

IPSec's security guarantees are only as strong as its state management. Without a sequence number counter, an attacker who captures a valid encrypted packet can replay it later — the receiver would decrypt it successfully and think it was a legitimate new message. Without an anti-replay window, the receiver cannot detect duplicates. Without an SA lifetime, stale keys would be used indefinitely, giving an attacker unlimited time to perform offline cryptanalysis.

Each piece of state in the SAD exists to close a specific attack vector.

### 🟡 HOW — The SAD Entry Fields in Detail

| SAD Field | Purpose | What Happens Without It |
|---|---|---|
| **SPI** | Receiver looks up the correct SA when a packet arrives | Cannot map incoming encrypted packets to decryption keys |
| **Sequence Number Counter** | Increments with each sent packet; prevents replay | Old captured packets can be replayed indefinitely |
| **Anti-Replay Window** | Tracks received sequence numbers in a sliding window | Even with sequence numbers, parallel replay within the window succeeds |
| **AH Information** | HMAC algorithm + key for integrity; ICV length | Cannot compute or verify the authentication tag |
| **ESP Information** | Encryption algorithm + key; IV; authentication algorithm + key | Cannot encrypt/decrypt payload |
| **SA Lifetime** | Time/byte limit triggering renegotiation | Stale keys remain in use; weakens security over time |
| **Mode** | Transport vs. Tunnel — determines packet structure | Incorrect encapsulation breaks routing |
| **Path MTU** | Maximum packet size for this SA | Oversized IPSec packets fragment incorrectly |

### Anti-Replay Window Explained

The anti-replay window works like this: when receiver's expected sequence number is N, packets with sequence numbers in [N-W, N] (where W is the window size, typically 64) are accepted if not already seen. Packets below N-W are rejected as too old. Packets above N advance the window. A bitmap tracks which sequence numbers within the window have been received, preventing duplicate acceptance.

```
Window (W=8): [    N-7    N-6    N-5    N-4    N-3    N-2    N-1    N    ]
                                  1      0      1      1      0      1
                                seen  unseen  seen   seen  unseen  seen(expected)

Packet with seq < N-7 → REJECT (too old)
Packet with seq = N-5 → REJECT (already received, bit=1)
Packet with seq = N+3 → ACCEPT, advance window to N+3
```

### 🎯 Analogy — Airline Boarding Pass

Each SA is like an airline's boarding record for a specific flight. The SPI is the flight number. The sequence counter is the seat assignment tracker (no two passengers get the same seat). The anti-replay window is the boarding gate scanner that rejects already-scanned passes. The SA lifetime is the flight itself — it expires when the flight closes and new boarding starts for the next flight.

---

## 🧪 Practice Questions — Topic 3

**[Multiple Choice]** What is the purpose of the anti-replay window in IPSec's SAD?

A) To limit the number of concurrent users on a VPN  
B) To prevent an attacker from replaying captured packets by tracking received sequence numbers  
C) To specify which applications are allowed to use IPSec  
D) To control the lifetime of the SA before renegotiation

✔ **Answer: B** — The anti-replay window maintains a sliding window of recently seen sequence numbers. Any incoming packet with a sequence number already marked as received (or too old to fall in the window) is rejected, preventing replay attacks.

---

**[True/False]** An SA lifetime is measured only in units of time (e.g., hours).

✔ **Answer: False** — SA lifetime can be measured in time (e.g., 24 hours) OR in bytes transferred (e.g., 100 MB of data). When either limit is reached, the SA expires and IKE renegotiates a new SA with fresh keys. Using byte-count limits prevents a single key from protecting too much data.

---

**[Short Answer]** Why does the SAD store a sequence number counter, and what specific attack does it prevent?

✔ **Answer:** The sequence number counter in the SAD increments by 1 for every packet sent. The receiver maintains the anti-replay window tracking which sequence numbers have been seen. This prevents the **replay attack**: an attacker who captures a legitimate IPSec-protected packet cannot resend it later, because the receiver would detect the duplicate (or out-of-window) sequence number and reject it. Without this mechanism, capturing one valid encrypted packet would be sufficient to replay that action indefinitely.

---

**[Fill in the Blank]** The __________ in the SAD acts as a 32-bit identifier that allows the receiving host to look up the correct SA when an incoming IPSec-protected packet arrives.

✔ **Answer:** SPI (Security Parameters Index)

---

# Slide 4 — Security Policy Database (SPD)

## 📌 Key Concepts at a Glance
- The SPD governs **how to process different datagrams** received or sent by the device
- Uses **selectors** to match packets to policies: local & remote IP addresses, next-layer protocol, local & remote ports, name
- Three possible actions for matched traffic: **PROTECT** (apply IPSec), **BYPASS** (no IPSec), **DISCARD** (drop)
- SPD is consulted for **both outgoing and incoming** traffic
- SPD entries point to SA entries (or SA bundles) in the SAD

---

## 📖 Discussion

### 🔴 WHY — Policy Separation from Mechanism

A corporate network might need different security treatment for different traffic types:
- Web traffic between offices: **full ESP encryption** (confidential business data)
- Network management ICMP (ping): **bypass IPSec** (internal trusted hosts, no overhead needed)
- Unknown external traffic: **discard** (not part of any defined SA)

Without a policy database, you'd have to apply the same security treatment to all traffic — either all encrypted (inefficient) or none encrypted (insecure). The SPD provides fine-grained control.

### 🟡 HOW — Selectors and Actions

**Selectors** are the matching criteria — the SPD works like a firewall ruleset with cryptographic action outcomes:

| Selector Field | Example Values | Purpose |
|---|---|---|
| **Local IP Address** | 10.0.0.0/24 | Match packets from this source network |
| **Remote IP Address** | 192.168.1.0/24 | Match packets to this destination network |
| **Next Layer Protocol** | TCP (6), UDP (17), ICMP (1) | Match by transport protocol |
| **Local Port** | 443, 80, any | Match by source port |
| **Remote Port** | 443, any | Match by destination port |
| **User/System Name** | alice@company.com | Match by authenticated identity |

**Actions upon match:**
- **PROTECT** → find/create the SA from the SAD and apply AH or ESP
- **BYPASS** → send/receive without IPSec processing (e.g., IKE traffic itself)
- **DISCARD** → drop the packet silently

### Processing Order (Critical)

**Outgoing traffic:**
1. SPD lookup using packet selectors
2. If PROTECT: find matching SA in SAD (or trigger IKE to create one)
3. Apply AH/ESP processing
4. Transmit

**Incoming traffic:**
1. Extract SPI from AH/ESP header
2. Look up SA in SAD using (SPI, Destination IP, Protocol)
3. Apply inverse processing (verify ICV, decrypt)
4. **Second SPD check:** Verify that the now-decrypted inner packet matches the SPD policy that should have governed it

This second SPD check for incoming traffic is important: it ensures that an attacker cannot smuggle unauthorized traffic inside a legitimate SA.

### 🎯 Analogy — Corporate Security Desk

The SPD is like the security desk policy manual at a corporate building. "Employees with badge Level 3 going to Floors 5–10: require escort." "HVAC technicians with pre-approved work orders: bypass lobby check-in, direct to basement." "Any visitor without prior registration: turn away immediately." The security desk (SPD) decides the treatment; the escort procedure (SAD + AH/ESP) implements it.

---

## 🧪 Practice Questions — Topic 4

**[Multiple Choice]** Which of the following is NOT a valid selector field in the SPD?

A) Source and destination IP addresses  
B) Transport protocol (TCP, UDP)  
C) The content of the HTTP request body  
D) Local and remote port numbers

✔ **Answer: C** — The SPD operates at the network and transport layer, using IP addresses, protocol numbers, and port numbers as selectors. It does not inspect application-layer payload content (that would be deep packet inspection, not IPSec's role).

---

**[True/False]** The SPD is only consulted for outgoing traffic; incoming IPSec packets are processed solely based on the SA found using the SPI.

✔ **Answer: False** — The SPD is consulted for both outgoing and incoming traffic. For incoming traffic, after the IPSec processing (ICV verification and decryption), a second SPD lookup is performed on the inner (decrypted) packet to verify it matches the expected policy. This prevents traffic smuggling through established SAs.

---

**[Short Answer]** What are the three possible actions the SPD can specify for a matched packet, and when would you use each?

✔ **Answer:**
1. **PROTECT** — Apply IPSec processing (AH and/or ESP). Used for sensitive traffic between trusted endpoints that need confidentiality, integrity, or authentication.
2. **BYPASS** — Send/receive the packet without any IPSec processing. Used for traffic that is already trusted (e.g., loopback traffic), traffic that cannot be IPSec-protected (e.g., IKE negotiation itself), or traffic where overhead is unacceptable.
3. **DISCARD** — Drop the packet. Used for traffic that matches no legitimate policy or comes from untrusted/unknown sources.

---

**[Fill in the Blank]** The SPD uses __________ to match packets to policies, including fields such as local and remote __________ and __________ numbers.

✔ **Answer:** selectors; IP address; port

---

# Slide 5 — Authentication Header (AH)

## 📌 Key Concepts at a Glance
- AH provides: **data origin authentication, data integrity, optional anti-replay** — but **NO confidentiality**
- AH covers: immutable IP header fields + AH header + upper-layer payload (the ICV is computed over all of these)
- Header fields: **Next Header** (TCP=6, UDP=17, IP=4, AH=51), **Payload Length**, **SPI**, **Sequence Number**, **Authentication Data (ICV)**
- AH protocol number: **51**
- ICV computed using **HMAC** (Hash-based MAC)
- Mutable IP fields (TTL, checksum) are **zeroed** before ICV computation and **not protected**
- In **Transport Mode:** AH inserted between IP header and payload
- In **Tunnel Mode:** AH inserted after new outer IP header; protects entire inner packet + selected outer header fields

---

## 📖 Discussion

### 🔴 WHY — Authentication Without Encryption

Sometimes you need to prove that a packet came from a legitimate router or host and was not modified in transit — but you don't need to hide the content. Example: protecting OSPF routing updates. A rogue router injecting false routing advertisements is a serious attack. AH lets routers verify that routing updates are authentic without the overhead of encryption.

AH is also historically significant: it was designed in an era when strong encryption was subject to US export controls, so a protocol that provided integrity without encryption was politically viable for international deployment.

### 🟡 HOW — The AH Header Structure

```
 0               1               2               3
 0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
| Next Header   |  Payload Len  |          RESERVED             |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                 Security Parameters Index (SPI)               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                    Sequence Number Field                      |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                                                               |
+                Authentication Data (variable)                 |
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

| Field | Size | Description |
|---|---|---|
| **Next Header** | 8 bits | Protocol of the payload: TCP=6, UDP=17, IP=4 (tunnel), AH=51 |
| **Payload Length** | 8 bits | Length of AH in 32-bit words minus 2 (IPv4) |
| **Reserved** | 16 bits | Must be zero |
| **SPI** | 32 bits | Identifies the SA (0=local use, 1–255=reserved) |
| **Sequence Number** | 32 bits | Anti-replay counter; starts at 1, never wraps (new SA before overflow) |
| **Authentication Data (ICV)** | Variable | HMAC output; size depends on algorithm (e.g., 96 bits for HMAC-SHA1) |

### What AH Covers (ICV Computation)

AH's ICV is computed over:
1. **Immutable IP header fields** (Source IP, Destination IP, Protocol, etc.) — fields that don't change in transit
2. **Mutable but predictable IP header fields** (e.g., Destination IP with source routing) — computed with their expected final value
3. **Mutable IP header fields** (TTL, Header Checksum, DSCP) — **zeroed** before ICV computation; NOT protected
4. **The entire AH header** (with Authentication Data field set to zero)
5. **The entire upper-layer payload** (TCP/UDP segment, etc.)

⚠️ **Critical Detail:** TTL and IP checksum change at every hop (TTL decremented, checksum recalculated). AH cannot protect these mutable fields — they are zeroed before HMAC computation and not included in the integrity guarantee. An attacker cannot modify the payload or source/destination addresses, but CAN modify TTL freely.

### 🎯 Analogy — The Notarized Document

AH is like a notarized document. A notary (HMAC key) stamps the document (IP packet). Anyone receiving the document can verify the stamp is authentic and that the content hasn't been altered since notarization. But the document's content is still fully readable by anyone — there's no envelope (no encryption). You've proved who wrote it and that it's unmodified; you haven't made it private.

### ⚠️ AH's Limitation with NAT

AH is **incompatible with NAT**. NAT modifies the source IP address in the IP header. AH's ICV is computed over the source IP address (an immutable field). Therefore, NAT modification of the source IP invalidates the AH ICV — the receiver's verification fails.

This is one practical reason ESP (which places auth data only over the ESP header/payload, not the outer IP header in transport mode) is far more common in NAT-heavy environments like corporate remote access VPNs.

---

## 🧪 Practice Questions — Topic 5

**[Multiple Choice]** Which security service does AH NOT provide?

A) Data origin authentication  
B) Data integrity  
C) Confidentiality  
D) Anti-replay protection

✔ **Answer: C** — AH provides authentication, integrity, and anti-replay. It does NOT provide confidentiality (encryption). AH does not encrypt any part of the packet — the payload is fully readable by anyone who intercepts it.

---

**[True/False]** AH's Integrity Check Value (ICV) covers all fields in the IP header, including TTL and the IP checksum.

✔ **Answer: False** — AH cannot protect mutable fields that legitimately change in transit (like TTL, which is decremented at each router hop, and the IP checksum, which changes when TTL changes). These fields are zeroed before ICV computation and are NOT protected by AH. Only immutable or predictable fields are included.

---

**[Short Answer]** Why is AH incompatible with NAT, and what alternative is typically used in NAT environments?

✔ **Answer:** AH computes its ICV over the source IP address in the IP header (treating it as an immutable field). When a packet passes through a NAT device, the source IP address is changed from the private address to the public address. This modification invalidates the ICV — the receiver's HMAC verification fails, and the packet is rejected. In NAT environments, **ESP** is used instead. ESP in tunnel mode wraps the entire original packet (including original IP header) in a new outer IP packet; NAT modifies only the outer IP header, which is not covered by ESP's authentication. For additional NAT compatibility, **NAT Traversal (NAT-T)** encapsulates ESP inside UDP port 4500.

---

**[Fill in the Blank]** AH uses a __________ algorithm to compute the ICV, which provides integrity and __________ for the IP packet.

✔ **Answer:** HMAC; data origin authentication

---

# Slide 6 — Encapsulating Security Payload (ESP)

## 📌 Key Concepts at a Glance
- ESP provides: **confidentiality, data origin authentication, connectionless integrity, anti-replay, limited traffic-flow confidentiality**
- ESP protocol number: **50**
- ESP Header: **SPI + Sequence Number**
- ESP Trailer: **Padding + Pad Length + Next Header**
- ESP Auth: **Authentication Data (ICV)** — optional but almost always used
- **Encryption** covers: ESP header through ESP trailer (NOT the outer IP header in transport mode)
- **Authentication** covers: ESP header + encrypted payload + ESP trailer (NOT the outer IP header)
- Padding ensures data terminates on a 4-byte boundary and can obscure payload length (limited traffic-flow confidentiality)

---

## 📖 Discussion

### 🔴 WHY — ESP is the Workhorse of IPSec

AH gives integrity without privacy. Most real-world security requirements include both — you want to verify the source AND keep the content private. ESP provides the complete package. It is by far the most commonly deployed IPSec component. In modern deployments, "use IPSec" almost universally means "use ESP with authentication."

### 🟡 HOW — The ESP Packet Structure

```
TRANSPORT MODE ESP:
+------------------+----------+------------------------------+----------+----------+
| Original IP Hdr  | ESP Hdr  | Encrypted Payload (TCP/UDP)  | ESP Trlr | ESP Auth |
+------------------+----------+------------------------------+----------+----------+
                   |<------- Authentication covers -------->|
                             |<----- Encryption covers ----->|

TUNNEL MODE ESP:
+------------------+----------+------------------------------------------+----------+----------+
| New Outer IP Hdr | ESP Hdr  | Encrypted: [Inner IP Hdr + TCP/UDP Data] | ESP Trlr | ESP Auth |
+------------------+----------+------------------------------------------+----------+----------+
                   |<-------------- Authentication covers --------------->|
                             |<-------------- Encryption covers ---------->|
```

**ESP Header Fields:**

| Field | Size | Description |
|---|---|---|
| **SPI** | 32 bits | Identifies the SA; receiver uses this to look up decryption keys |
| **Sequence Number** | 32 bits | Anti-replay counter; same mechanism as AH |

**ESP Trailer Fields:**

| Field | Size | Description |
|---|---|---|
| **Padding** | 0–255 bytes | Aligns payload to cipher block boundary; obscures actual payload length |
| **Pad Length** | 8 bits | Number of padding bytes; receiver uses this to strip padding |
| **Next Header** | 8 bits | Type of payload: TCP=6, UDP=17, IP=4 (tunnel), etc. |

**ESP Authentication Data:**

| Field | Size | Description |
|---|---|---|
| **Authentication Data (ICV)** | Variable | HMAC computed over ESP header + encrypted payload + ESP trailer |

### 💡 The Encrypt-Then-Authenticate Order

ESP uses **Encrypt-then-Authenticate**: the payload is encrypted first, then the HMAC is computed over the ciphertext. This is the cryptographically correct order:

- **Why not Authenticate-then-Encrypt?** Computing a MAC over plaintext and then encrypting both could leak information about the plaintext through the MAC value. AES-GCM (Galois/Counter Mode) handles both simultaneously.
- **Why not Encrypt-then-MAC-over-plaintext?** The MAC wouldn't cover the ciphertext, allowing an attacker to modify the ciphertext without detection.

Encrypt-then-Authenticate is provably secure: the ICV is over the ciphertext, so any modification to the ciphertext is detected before decryption is attempted. This prevents "oracle attacks" where the receiver's decryption behavior leaks information.

### 💡 Limited Traffic-Flow Confidentiality

Even when payload content is encrypted, an eavesdropper can analyze packet sizes, timing, and frequency to infer information. ESP's padding field provides *limited* traffic-flow confidentiality by allowing padding to obscure the actual payload size — making it harder to determine the application being used based on packet sizes alone. However, this is only partial protection; full traffic-flow confidentiality requires generating dummy traffic to mask communication patterns.

### 🎯 Analogy — The Sealed Opaque Envelope with a Wax Seal

AH was like a notarized document (visible, authenticated). ESP is like putting that document in a **sealed opaque envelope** (encrypted = you can't read it), with a **wax seal** (authentication = you can verify it hasn't been opened or tampered with). An attacker who intercepts the envelope sees: (1) an opaque package — cannot read the content; (2) an intact wax seal they cannot replicate without the key — cannot modify content undetected.

---

## AH vs. ESP Comparison Table

| Feature | AH | ESP | ESP with Auth |
|---|---|---|---|
| **Confidentiality** | ✗ None | ✔ Yes | ✔ Yes |
| **Data Integrity** | ✔ Yes | ✗ (without auth) | ✔ Yes |
| **Data Origin Auth** | ✔ Yes | ✗ (without auth) | ✔ Yes |
| **Anti-Replay** | ✔ Yes | ✔ Yes | ✔ Yes |
| **Covers IP Header** | ✔ Partial (immutable fields) | ✗ No | ✗ No |
| **NAT Compatible** | ✗ No | ✔ Yes | ✔ Yes |
| **Practical Use** | Rarely (routing integrity) | Almost never alone | Primary deployment |

---

## 🧪 Practice Questions — Topic 6

**[Multiple Choice]** In ESP with authentication, which fields does the ICV (Authentication Data) cover?

A) The original outer IP header + ESP header + encrypted payload + ESP trailer  
B) Only the encrypted payload  
C) ESP header + encrypted payload + ESP trailer (NOT the outer IP header)  
D) The entire packet from IP header to ESP auth

✔ **Answer: C** — ESP authentication covers the ESP header, the encrypted payload, and the ESP trailer. It does NOT cover the outer IP header. This is why ESP is compatible with NAT (NAT modifies the outer IP header, which is outside ESP's authentication scope).

---

**[True/False]** ESP's padding field serves only to ensure 4-byte alignment and has no security function.

✔ **Answer: False** — Padding serves two purposes: (1) algorithmic alignment — block ciphers require input to be a multiple of the block size; (2) limited traffic-flow confidentiality — padding can obscure the actual payload length, making it harder for an eavesdropper to identify the application from packet sizes.

---

**[Short Answer]** Explain why ESP uses "Encrypt-then-Authenticate" rather than "Authenticate-then-Encrypt."

✔ **Answer:** Encrypt-then-Authenticate means the HMAC (ICV) is computed over the **ciphertext**, not the plaintext. This provides two critical security properties:
1. **Tamper detection before decryption:** The receiver verifies the ICV first. Any modification to the ciphertext produces an ICV mismatch and the packet is discarded *before* the decryption engine even processes it. This prevents "padding oracle attacks" and other attacks where the receiver's decryption behavior leaks information.
2. **Covers the actual transmitted bytes:** The ICV authenticates exactly what was sent over the wire — if the ciphertext was altered, detection is guaranteed.

Authenticate-then-Encrypt would mean the MAC is computed over plaintext, then both are encrypted. This can lead to vulnerabilities where the MAC leaks information about the plaintext, and certain cipher-mode interactions have been exploited (e.g., CBC mode attacks like BEAST).

---

**[Fill in the Blank]** ESP's **Next Header** field, found in the __________, identifies the type of data in the payload (e.g., TCP=6, UDP=17), and is located in the __________ rather than the ESP header.

✔ **Answer:** ESP trailer; trailer (ESP trailer)

---

# Slide 7 — Transport Mode vs. Tunnel Mode

## 📌 Key Concepts at a Glance
- **Transport Mode:** Protects the IP payload (upper-layer protocol data); original IP header is preserved and visible
  - Used for end-to-end host-to-host communication
  - Original IP header NOT encrypted
  - Less overhead (no additional IP header added)
- **Tunnel Mode:** Wraps the ENTIRE original IP packet (original IP header + payload) inside a new IP packet
  - Used when one or both ends are security gateways (firewalls, VPN routers)
  - Original IP header IS encrypted (inside the tunnel)
  - Hides internal network topology from external observers
  - Used for: site-to-site VPNs, remote access VPNs, hosts accessing services through a gateway

---

## 📖 Discussion

### 🔴 WHY — Two Modes for Different Deployment Scenarios

The fundamental question is: **who is the IPSec endpoint?**

- If Alice's laptop directly communicates with Bob's laptop, and both have IPSec software, they can use **Transport Mode** — they are the actual endpoints, and only the payload needs protection
- If Alice's entire office network communicates securely with Bob's office, a VPN gateway at each site acts as the IPSec endpoint — but the gateways are not the actual sources/destinations of the application data. The **original IP packet** (with Alice's internal private IP as source) must be carried inside an encrypted tunnel. This requires **Tunnel Mode**

### 🟡 HOW — Packet Structure Comparison

**AH in Transport Mode:**
```
[ Original IP Header | AH Header | TCP/UDP/Data ]
         ↑                  ↑              ↑
   Not encrypted      Auth covers:    Auth covers
                      selected hdr    all of this
                      fields
```

**AH in Tunnel Mode:**
```
[ New Outer IP Header | AH Header | Original IP Header | TCP/UDP/Data ]
          ↑                  ↑              ↑                  ↑
  Not encrypted (NAT here) Auth:    Auth covers:          Auth covers
                            selected  inner IP hdr +       all of this
                            outer hdr  all of inner
                            fields    packet
```

**ESP in Transport Mode:**
```
[ Original IP Header | ESP Header | [Encrypted: TCP/UDP/Data] | ESP Trailer | ESP Auth ]
         ↑                 ↑               ↑                         ↑              ↑
   Not encrypted      SPI+SeqNum     Encrypted                  Padding+NH    HMAC over
   (NAT visible here)                payload                                  ESP Hdr+
                                                                               Enc payload+
                                                                               ESP Trailer
```

**ESP in Tunnel Mode:**
```
[ New Outer IP Header | ESP Header | [Encrypted: Inner IP Header + TCP/UDP/Data] | ESP Trailer | ESP Auth ]
          ↑                 ↑                           ↑                               ↑               ↑
   Not encrypted        SPI+SeqNum            Entire original packet                Padding         HMAC
   (VPN gateway IPs     (SA lookup)           including inner IP header              +NH
    visible to outside)                       is encrypted — internal
                                              topology hidden
```

### 📊 Mode Selection Matrix

| Scenario | Recommended Mode | Why |
|---|---|---|
| Host A ↔ Host B (both have IPSec software) | Transport Mode | Direct endpoint-to-endpoint; minimal overhead; original IP header not needed hidden |
| Office Network A ↔ Office Network B via VPN Gateways | Tunnel Mode | Gateways encapsulate/decapsulate; internal addresses hidden from Internet |
| Remote user → Corporate VPN Gateway | Tunnel Mode | Remote user's client acts as one endpoint; gateway is the other; internal addresses protected |
| Host A → Security Gateway (protecting server B) | Tunnel Mode | Gateway represents server B; must carry inner IP header with B's address |
| IPSec between two routers protecting traffic in transit | Transport or Tunnel | Transport if routers are actual endpoints; Tunnel if representing other hosts |

### Tunnel Mode and Egress Filtering

💡 **Key exam insight:** Tunnel mode (specifically ESP in tunnel mode) can be used to **evade destination-IP-based egress filtering at a firewall**. Here's why:

When ESP tunnel mode is active:
- The outer IP header shows the VPN gateway as the destination
- The inner IP header (with the actual destination — possibly a blocked site) is encrypted inside
- The firewall only sees the outer IP header (VPN gateway destination) and cannot determine the actual inner destination without decryption

This is why IPSec/VPN is both a security tool and potentially a bypass technique — it's the same technology used for both legitimate corporate VPNs and circumventing censorship.

### 🎯 Analogy — Letters vs. Packages

**Transport Mode** is like mailing a letter in a tamper-evident envelope. The envelope shows Alice's address and Bob's address — everyone on the route can see who's writing to whom. The contents are protected (sealed), but the addressing is visible.

**Tunnel Mode** is like putting that letter inside a shipping box addressed to a courier company (VPN gateway). The courier receives the box, opens it, finds the inner letter, and delivers it locally. People watching the postal route only see "Alice → Courier Company" — they have no idea the actual letter was intended for Bob.

---

## AH and ESP in Each Mode — Complete Comparison Table

| | Transport Mode SA | Tunnel Mode SA |
|---|---|---|
| **AH** | Authenticates IP payload and selected portions of IP header and IPv6 extension headers | Authenticates entire inner IP packet (inner header + payload) plus selected portions of outer IP header |
| **ESP** | Encrypts IP payload and any IPv6 extension headers following the ESP header | Encrypts entire inner IP packet (inner header + payload) |
| **ESP with Auth** | Encrypts IP payload; authenticates IP payload but NOT the IP header | Encrypts entire inner IP packet; authenticates inner IP packet |
| **Overhead** | Lower — one IP header only | Higher — additional outer IP header added |
| **Source address visible?** | Yes (original source IP in IP header) | No (only VPN gateway IP in outer header) |
| **Protects internal topology?** | No | Yes (inner IP header encrypted) |
| **NAT compatible?** | AH: No; ESP: Yes | AH: No (outer header modified); ESP: Yes |

---

## 🧪 Practice Questions — Topic 7

**[Multiple Choice]** Which IPSec mode can encrypt the inner IP header, thereby hiding the internal network topology from external observers?

A) Transport Mode  
B) Tunnel Mode  
C) Both Transport and Tunnel Mode  
D) Neither

✔ **Answer: B** — Tunnel Mode. In tunnel mode, the entire original IP packet (including the inner IP header with the actual source and destination addresses) is encrypted. An external observer sees only the outer IP header (VPN gateway addresses), not the internal addresses.

---

**[Multiple Choice]** Which IPSec configuration is most appropriate for a site-to-site VPN connecting two corporate office networks?

A) AH in Transport Mode  
B) ESP in Transport Mode  
C) AH in Tunnel Mode  
D) ESP in Tunnel Mode

✔ **Answer: D** — ESP in Tunnel Mode. Site-to-site VPNs use Tunnel Mode because the IPSec endpoints (VPN gateways) are not the actual sources/destinations of the application data. The entire original packet must be encapsulated. ESP is used (not AH alone) because confidentiality is required to protect business data traversing the public Internet.

---

**[True/False]** AH in Tunnel Mode protects the entire inner IP packet, including the inner IP header and payload.

✔ **Answer: True** — In Tunnel Mode, AH authenticates the entire inner IP packet (inner header plus payload) plus selected portions of the outer IP header. The inner IP header — including source and destination IP addresses — is covered by AH's ICV.

---

**[Short Answer]** Explain how ESP in Tunnel Mode can be used to evade destination-IP-based egress filtering at a firewall.

✔ **Answer:** In ESP Tunnel Mode, the original IP packet (with the actual destination IP) becomes the **inner packet** and is completely encrypted. A new outer IP packet is created with the VPN gateway's IP as the destination. When the firewall inspects the packet:
- It sees only the outer IP header (destination = VPN gateway IP, which may be allowed)
- The actual inner destination IP is encrypted and invisible to the firewall
- The firewall cannot apply its destination-IP blocking rules to the hidden inner IP
The packet passes through the firewall as "traffic to the VPN gateway" and the VPN gateway decapsulates and forwards it to the actual destination. This makes VPN tunnels a common method for circumventing egress filtering.

---

**[Fill in the Blank]** Transport Mode is typically used for __________ communication between two hosts, while Tunnel Mode is used when one or both ends of the SA are a __________.

✔ **Answer:** end-to-end; security gateway (VPN gateway or firewall)

---

# Slide 8 — Internet Key Exchange (IKE)

## 📌 Key Concepts at a Glance
- IKE is the **automated key negotiation protocol** for IPSec
- Operates in **two phases:**
  - **IKE Phase 1:** Establishes a secure, authenticated channel (IKE SA) between the two IPSec peers
  - **IKE Phase 2:** Uses the Phase 1 channel to negotiate IPSec SAs (AH and/or ESP SAs)
- Phase 1 modes: **Main Mode** (6 messages, identity protection) and **Aggressive Mode** (3 messages, identity revealed)
- Authentication methods: pre-shared key (PSK), digital certificates (RSA/ECC), or public-key encryption
- IKEv2 is the current version (simplified, more efficient, NAT traversal built-in)
- Without IKE: keys must be manually configured (**manual keying**) — impractical at scale

---

## 📖 Discussion

### 🔴 WHY — The Key Distribution Problem

Before two systems can protect traffic with IPSec, they need to agree on:
1. Which encryption algorithm to use (AES-256? 3DES?)
2. Which authentication algorithm (HMAC-SHA256? HMAC-SHA1?)
3. What the actual secret keys are
4. How long the SAs should last
5. Which mode to use (Transport? Tunnel?)

If this is done manually (manual keying), an administrator must:
- Configure matching entries on both sides
- Distribute the shared secret keys out-of-band
- Repeat this for every pair of communicating systems
- Manually rotate keys periodically

In an enterprise with hundreds of sites and thousands of communicating pairs, this is impossible. IKE automates the entire negotiation.

### 🟡 HOW — IKE Two-Phase Architecture

**IKE Phase 1 — Establishing the IKE SA**

Phase 1 creates a protected management channel — the IKE SA — that will be used to negotiate IPSec SAs in Phase 2. Think of Phase 1 as "setting up a secure conference room before discussing the sensitive business deal."

Key steps in Phase 1:
1. **Algorithm negotiation:** Each peer proposes a list of acceptable algorithms (DH group, encryption, integrity, PRF). They select the strongest mutually acceptable option.
2. **Diffie-Hellman exchange:** Both sides perform a DH key exchange to generate a shared master secret without transmitting it. This provides **Perfect Forward Secrecy (PFS)** — even if long-term keys are later compromised, past session keys are secure.
3. **Authentication:** Each peer authenticates itself to the other using one of: pre-shared key (symmetric), RSA signature + certificate (asymmetric), or ECC signature + certificate.
4. **IKE SA established:** The result is a bidirectional secure channel protected by the negotiated keys.

**IKE Phase 2 — Negotiating IPSec SAs**

Phase 2 uses the secure IKE SA from Phase 1 to negotiate the actual IPSec SAs. This is "Quick Mode" in IKEv1:
1. **Propose SA parameters:** Initiator proposes acceptable combinations of AH/ESP algorithms, modes, lifetimes.
2. **Responder selects:** Responder chooses from the proposals.
3. **Key material generated:** Fresh keying material is derived (optionally with a new DH exchange for additional PFS).
4. **Two IPSec SAs created:** One for each direction (inbound and outbound).

### IKE Phase 1: Main Mode vs. Aggressive Mode

| | Main Mode | Aggressive Mode |
|---|---|---|
| **Messages** | 6 messages | 3 messages |
| **Identity protection** | Identity encrypted — hidden from eavesdroppers | Identity sent in clear — eavesdroppers learn peer identities |
| **Performance** | Slower (more round-trips) | Faster |
| **Security** | Higher | Lower (vulnerable to offline dictionary attacks on PSK) |
| **Use case** | Static IP endpoints | Dynamic IP endpoints (road warriors) |

### 🎯 Analogy — Contract Negotiation via Secure Courier

**Phase 1** is like hiring a secure, trusted courier service to establish a private communication line. First you both agree on the courier (trusted third party), verify each other's identities, and set up an encrypted phone line.

**Phase 2** is like using that encrypted phone line to negotiate the actual contract terms (IPSec SA parameters: which cipher, which key, how long). The contract itself (the IPSec SA) specifies how all future shipments (IP packets) will be handled.

### Diffie-Hellman in IKE

IKE relies on DH key exchange. Both sides contribute random values; the exchange produces a shared secret that neither transmitted. The elliptic curve variant (ECDH) is now preferred for equivalent security at smaller key sizes.

The DH group determines the mathematical parameters used — higher group numbers use larger primes or better elliptic curves and provide stronger security. IKEv2 supports DH groups 14–21 (2048-bit+ or ECC).

---

## 🧪 Practice Questions — Topic 8

**[Multiple Choice]** What is the primary purpose of IKE Phase 1?

A) Negotiate the IPSec SA parameters (encryption algorithm, mode, lifetime) for protecting application traffic  
B) Establish a secure, authenticated IKE SA channel that Phase 2 will use to negotiate IPSec SAs  
C) Perform the actual packet encryption and decryption  
D) Configure the Security Policy Database on both peers

✔ **Answer: B** — IKE Phase 1 establishes the IKE SA — a secure management channel between the two peers. This channel is then used in Phase 2 to safely negotiate the actual IPSec SAs that will protect application traffic.

---

**[True/False]** Aggressive Mode in IKE Phase 1 is more secure than Main Mode because it uses fewer messages.

✔ **Answer: False** — Aggressive Mode is LESS secure. It reveals peer identities in cleartext (no identity protection), making it vulnerable to offline dictionary attacks when pre-shared keys are used. Main Mode protects identities by encrypting identity information in the later messages. Aggressive Mode is faster (3 messages vs. 6) but trades security for speed.

---

**[Short Answer]** What is Perfect Forward Secrecy (PFS) in the context of IKE, and why is it valuable?

✔ **Answer:** Perfect Forward Secrecy (PFS) means that the compromise of long-term key material (e.g., the pre-shared key or private key used for authentication) does NOT enable an attacker to decrypt previously recorded session traffic. In IKE, PFS is achieved by performing a fresh Diffie-Hellman exchange for each Phase 2 negotiation, generating independent session keys that are never stored and cannot be derived from long-term keys. Value: if an attacker records encrypted IPSec traffic today and later obtains the long-term keys (e.g., through a breach), they still cannot decrypt the previously recorded sessions. Each session's keys die with that session.

---

**[Fill in the Blank]** IKE Phase 1 produces a(n) __________, while IKE Phase 2 produces the actual __________ that will be used to protect IPSec traffic.

✔ **Answer:** IKE SA (IKE Security Association); IPSec SAs (AH SA and/or ESP SA)

---

# Slide 9 — IPSec Applications: VPN

## 📌 Key Concepts at a Glance
- **VPN (Virtual Private Network):** Creates a private encrypted network over a public (Internet) infrastructure
- IPSec is the primary underlying technology for enterprise VPNs
- **Site-to-site VPN:** Two gateways create an IPSec tunnel; internal hosts communicate transparently
- **Remote access VPN:** Individual client (road warrior) connects to corporate gateway
- VPN hides internal addresses from the public Internet (tunnel mode)
- On-path observer between client (C) and VPN gateway (V) can see: client IP, VPN gateway IP, traffic metadata (timing, volume) — but NOT destination server IP or payload content
- VPN gateway (V) can see everything: client IP, destination server IP, VPN gateway IP, traffic metadata

---

## 📖 Discussion

### 🔴 WHY — The VPN Use Case

An enterprise has offices in New York, London, and Tokyo. Each office has an internal network with private IP addresses. Employees need to:
1. Access shared file servers, databases, and applications across offices
2. Do this securely over the public Internet (untrusted)
3. Have the internal IP structure remain private

Without VPN: all inter-office traffic would be in cleartext across the Internet, revealing internal addresses, traffic patterns, and content.

With IPSec VPN: a gateway at each office becomes the IPSec endpoint. Traffic between offices travels in encrypted ESP tunnels. The Internet sees only gateway-to-gateway traffic with encrypted payloads.

### 🟡 HOW — VPN Traffic Flow

```
New York Office                Internet                London Office
Internal hosts →  NY Gateway ←────────────────────────→ London Gateway → Internal hosts
[192.168.1.0/24]  [10.9.0.11]   [ESP Tunnel Mode]       [10.9.0.85]    [192.168.2.0/24]
                   ↑                                         ↑
            IPSec endpoint                           IPSec endpoint
            (gateway IP visible                      (gateway IP visible
             on Internet)                             on Internet)
```

**What an on-path observer (between NY and London gateways) can see:**
- NY gateway public IP (source of outer packet)
- London gateway public IP (destination of outer packet)
- Traffic metadata: packet sizes, timing, frequency, total volume
- **Cannot see:** actual source (192.168.1.x), actual destination (192.168.2.x), any payload content

**What the VPN gateway sees:**
After decapsulation — everything: inner source IP, inner destination IP, payload content (if not additionally encrypted by TLS at the application layer)

### VPN Metadata Leakage Table (Exam-Critical)

| Scenario | What On-Path Observer (C→V) Sees | What VPN Gateway V Sees | What Destination Server S Sees |
|---|---|---|---|
| **No VPN** | Client IP, Server IP, metadata, payload (if no TLS) | N/A | Client IP, metadata |
| **VPN Enabled** | Client IP (a), VPN Gateway IP (c), metadata (d) | Client IP (a), Server IP (b), VPN Gateway IP (c), metadata (d) | Server IP (b), VPN Gateway IP (c), metadata (d) |

*Note: Letters (a)–(d) refer to exam question format: (a) client IP, (b) destination IP, (c) VPN gateway public IP, (d) traffic metadata*

### ⚠️ What VPN Does NOT Protect

💡 Common misconception: "VPN makes me anonymous." What VPN actually does:

| What VPN Protects | What VPN Does NOT Protect |
|---|---|
| Content of traffic from on-path observer | Your identity from the VPN provider (they see your real IP) |
| Destination IP from on-path observer | Traffic metadata (timing, volume — still visible) |
| Internal network topology | Your activities after traffic exits the VPN gateway |
| Traffic from local network eavesdroppers | DNS leaks (if DNS queries bypass the tunnel) |

The midterm exam specifically tests this. VPN using tunnel mode cannot eliminate **all** traffic-flow metadata — on-path observers between client and VPN gateway still see packet timing, sizes, and total bytes transferred.

---

## 🧪 Practice Questions — Topic 9

**[Multiple Choice]** In a VPN scenario where client C connects to VPN gateway V to reach server S, what can an on-path observer between C and V observe?

A) Client IP, Server IP, VPN gateway IP, and traffic metadata  
B) Only the VPN gateway IP and traffic metadata (client IP hidden by VPN)  
C) Client IP, VPN gateway IP, and traffic metadata (NOT server IP)  
D) Nothing — all information is encrypted end-to-end

✔ **Answer: C** — An on-path observer between C and V sees the outer packet headers: client IP (source), VPN gateway IP (destination), and traffic metadata (packet sizes, timing). The server IP is hidden inside the encrypted tunnel. The observer cannot see the payload content.

---

**[True/False]** Using a VPN in tunnel mode eliminates all traffic-flow metadata leakage, making it impossible for any observer to determine communication patterns.

✔ **Answer: False** — VPN tunnel mode hides source/destination IPs and payload content from on-path observers. However, it does NOT eliminate metadata: packet timing, sizes, frequency, and total volume are still observable by an on-path observer between the client and VPN gateway. This metadata can reveal communication patterns even without revealing content.

---

**[Short Answer]** A client C (IP: 10.0.0.4) connects through VPN gateway V (IP: 130.166.128.1) to reach server S (IP: 130.160.57.1). When VPN is enabled, list what each of these parties can observe: (1) an on-path observer between C and V, (2) the VPN gateway V, (3) the destination server S.

✔ **Answer:**
1. **On-path observer between C and V:** Sees client IP (10.0.0.4), VPN gateway IP (130.166.128.1), traffic metadata (packet sizes, timing, volume). Does NOT see server IP or payload content.
2. **VPN gateway V:** Sees everything after decapsulation — client IP (10.0.0.4), server IP (130.160.57.1), VPN gateway own IP (130.166.128.1), traffic metadata. V is the decapsulation point, so it processes the inner packet.
3. **Destination server S:** Sees VPN gateway IP (130.166.128.1) as the source (NAT or forwarding), server's own IP, traffic metadata. Does NOT see the original client IP (unless the VPN gateway passes it through).

---

**[Fill in the Blank]** A VPN in tunnel mode hides the __________ IP address from on-path observers between the client and gateway, but the __________ and __________ remain observable.

✔ **Answer:** destination server's (inner); client IP address; traffic metadata (timing/volume)

---

# Slide 10 — IPSec Protections for Routing Infrastructure

## 📌 Key Concepts at a Glance
- IPSec can protect **routing protocol communications**, not just user data
- Can authenticate: router advertisements, neighbor relationships, redirect messages, routing updates
- Prevents **BGP hijacking** (false route announcements), **OSPF injection** (false routing updates), and **router impersonation**
- IPSec assures that routing updates come from **authorized routers** in the correct autonomous system
- Applications beyond VPN: Branch Offices, Remote Users, Extranets, Internet infrastructure protection

---

## 📖 Discussion

### 🔴 WHY — Routing Infrastructure is Critical and Vulnerable

Routing protocols (BGP, OSPF, RIP) were designed for a trusted environment — routers were assumed to be operated by cooperative parties. This assumption has repeatedly proven false:

- **2008 Pakistan Telecom BGP Hijack:** Pakistan Telecom announced a more specific route to YouTube's IP blocks. For ~2 hours, YouTube was unreachable globally.
- **2010 China Telecom BGP Hijack:** Approximately 15% of Internet traffic was briefly rerouted through Chinese routers.
- **OSPF injection attacks:** A compromised router inside an enterprise can inject false OSPF link-state advertisements, redirecting internal traffic through attacker-controlled paths.

IPSec applied to routing protocol communications can cryptographically authenticate every routing update, ensuring only legitimate authorized routers can influence routing decisions.

### 🟡 HOW — IPSec for Routing Protection

IPSec can be applied to routing protocol traffic in several ways:

1. **BGP over IPSec:** BGP peering sessions between ASes run over IPSec-protected TCP connections. Even if an attacker captures or injects BGP UPDATE messages, without the correct IPSec keys, the receiver will reject them.

2. **OSPF with IPSec:** OSPF has its own cryptographic authentication extension, but IPSec provides a stronger, standardized alternative. OSPF packets between routers in an area are protected by an IPSec SA.

3. **Router Advertisement Protection:** IPv6 Neighbor Discovery Protocol (NDP) router advertisements can be authenticated with IPSec (SEcure Neighbor Discovery — SEND protocol).

### IPSec Routing Assurances

| IPSec Can Assure That... | Attack Prevented |
|---|---|
| A router advertisement comes from an authorized router | Rogue router injecting false default gateway info |
| A neighbor relationship is with an authorized router in the correct AS | BGP peer impersonation |
| A redirect message comes from the actual router that handles the initial packet | ICMP redirect attacks (redirecting traffic through attacker) |
| A routing update is not forged | BGP hijacking, OSPF injection |

### 🎯 Analogy — Chain of Custody for Court Evidence

Routing information is like evidence submitted to a court. Without authentication, anyone could tamper with evidence (routing tables) before it reaches the judge (the routers making forwarding decisions). IPSec provides a cryptographic chain of custody — only evidence submitted with a verified signature from an authorized officer (authenticated router) is admissible.

---

## 🧪 Practice Questions — Topic 10

**[Multiple Choice]** How does IPSec help protect against BGP hijacking?

A) By encrypting all BGP UPDATE messages so they can't be read by unauthorized parties  
B) By cryptographically authenticating BGP sessions, ensuring routing updates come from authorized routers  
C) By blocking all BGP traffic that doesn't originate from known IP address ranges  
D) By encrypting the routing table on each router

✔ **Answer: B** — IPSec protects routing by authenticating BGP session traffic, ensuring that only routers with the correct IPSec keys can participate in BGP peering sessions and that routing updates cannot be forged or injected by unauthorized parties. The protection is authentication-based (not just encryption).

---

**[True/False]** IPSec can only be used to protect end-user application traffic and cannot protect routing protocol communications.

✔ **Answer: False** — IPSec can be applied to any IP traffic, including routing protocol traffic (BGP, OSPF, NDP). When applied to routing communications, IPSec authenticates routing updates and neighbor relationships, preventing rogue routers from injecting false routing information.

---

**[Short Answer]** List three specific routing-level attacks that IPSec can help prevent, and briefly explain each.

✔ **Answer:**
1. **BGP Hijacking:** An unauthorized AS falsely announces routes to IP prefixes it doesn't own, redirecting Internet traffic. IPSec authentication ensures BGP peers are legitimate, rejecting unsigned/incorrectly-keyed updates.
2. **OSPF Injection:** A compromised internal router injects false link-state advertisements, causing other routers to use suboptimal or attacker-controlled paths. IPSec-authenticated OSPF ensures only authorized routers can inject LSAs.
3. **ICMP Redirect Attacks:** Forged ICMP redirect messages instruct hosts to use a different (attacker-controlled) gateway. IPSec authentication of redirect messages ensures they come from the legitimate router that originally handled the packet.

---

**[Fill in the Blank]** IPSec applied to routing protocol communications can assure that routing updates are not __________ and that only __________ routers can establish neighbor relationships.

✔ **Answer:** forged; authorized

---

# Quick Reference Summary

| Concept | What It Is | Key Security Property | Exam Tip |
|---|---|---|---|
| **IPSec** | Suite of Layer-3 protocols securing IP packets | Transparent to applications; protects all traffic | "Security at Layer 3" → all apps protected |
| **AH** | Authentication Header — integrity + origin auth | NO confidentiality; covers immutable IP header fields; ICV via HMAC | AH ≠ encryption; AH incompatible with NAT |
| **ESP** | Encapsulating Security Payload — integrity + auth + encryption | Encrypt-then-Authenticate; does NOT cover outer IP header | Primary real-world IPSec protocol |
| **Transport Mode** | Protects IP payload only; original IP header intact | Source/destination IPs visible to observers | Host-to-host; lower overhead |
| **Tunnel Mode** | Wraps entire packet in new IP packet | Inner IP header encrypted; internal topology hidden | VPN gateway use; evades egress filtering |
| **SA (Security Association)** | One-way security relationship | Identified by SPI + Destination IP + Protocol | Two SAs needed for bidirectional traffic |
| **SPI** | 32-bit Security Parameters Index | Receiver uses SPI to look up correct SA in SAD | Always in AH/ESP header |
| **SPD** | Security Policy Database — what to do | Three actions: PROTECT / BYPASS / DISCARD | Policy decision; consulted for both in/out traffic |
| **SAD** | Security Association Database — how to do it | Stores keys, algorithms, sequence counters | Operational state; SPI is the lookup key |
| **IKE Phase 1** | Establishes secure IKE SA for management | DH key exchange; peer authentication | Main Mode (secure) vs. Aggressive Mode (fast, less secure) |
| **IKE Phase 2** | Negotiates IPSec SAs using Phase 1 channel | PFS via fresh DH exchange | "Quick Mode" in IKEv1 |
| **Anti-Replay Window** | Sliding window tracking received sequence numbers | Prevents replay of captured packets | Bounded window; bitmap of seen sequence numbers |
| **ICV** | Integrity Check Value — HMAC output in AH/ESP | Detects any modification to protected fields | AH covers IP header fields; ESP covers ESP header + payload |
| **PFS (Perfect Forward Secrecy)** | Session keys independent of long-term keys | Past sessions secure even if long-term keys later compromised | Fresh DH exchange per Phase 2 |
| **VPN** | Virtual Private Network over public Internet | Hides internal topology; encrypts content | VPN does NOT hide metadata (timing, volume) from C→V observer |
| **IPSec + Routing** | Authenticating routing protocol traffic | Prevents BGP hijacking, OSPF injection | IPSec authenticates routing updates |
| **NAT + AH** | AH covers source IP → incompatible with NAT | NAT changes source IP → AH ICV invalid | Use ESP (not AH) in NAT environments |

---

# Exam Preparation — Integrative Questions

**[Short Answer]** Compare AH and ESP across five dimensions: (1) what they protect, (2) which header fields are covered by their ICV, (3) whether they provide confidentiality, (4) NAT compatibility, and (5) real-world deployment frequency.

✔ **Answer:**

| Dimension | AH | ESP (with Auth) |
|---|---|---|
| **What protected** | Integrity + data origin auth only | Integrity + data origin auth + confidentiality |
| **ICV covers** | Immutable IP header fields + AH header + payload | ESP header + encrypted payload + ESP trailer (NOT outer IP header) |
| **Confidentiality** | None — payload is cleartext | Yes — payload is encrypted |
| **NAT compatible** | No — NAT changes source IP, invalidating ICV | Yes — NAT modifies outer IP header not covered by ICV |
| **Real-world use** | Rare (routing protocol authentication only) | Primary IPSec protocol in almost all deployments |

---

**[Short Answer]** Trace an outgoing packet from Alice's laptop (internal IP 192.168.1.100) through a corporate VPN gateway (public IP 130.166.128.1) to a web server (130.160.57.1), using ESP Tunnel Mode. At each step, describe what is encrypted, what is visible, and what changes.

✔ **Answer:**
1. **Alice's laptop** creates a TCP packet: SRC=192.168.1.100, DST=130.160.57.1, port 443, HTTP payload
2. **SPD lookup:** Traffic to 130.160.57.0/24 via VPN → action: PROTECT with ESP Tunnel Mode using SA #1042
3. **SAD lookup:** SA #1042 → AES-256 encryption key K1, HMAC-SHA256 auth key K2, sequence number=507
4. **ESP Tunnel Mode processing:**
   - Original packet (inner IP header + TCP + payload) → encrypted with AES-256 using K1
   - ESP header added: SPI=1042, Seq=508
   - ESP trailer added: padding + pad length + Next Header=4 (inner IP)
   - HMAC-SHA256 computed over (ESP header + ciphertext + ESP trailer) using K2 → ICV
   - New outer IP header added: SRC=Alice's laptop IP, DST=130.166.128.1 (VPN gateway)
5. **What is visible on the wire:** Outer IP header (192.168.1.100 → 130.166.128.1), ESP header (SPI, SeqNum), encrypted blob, ICV. **Not visible:** actual destination (130.160.57.1), payload content, even original source port.
6. **At VPN gateway (130.166.128.1):** Outer IP header removed. SPI=1042 looked up in SAD. HMAC verified (packet not tampered). AES decrypted. Inner packet recovered: 192.168.1.100 → 130.160.57.1. Gateway forwards inner packet to web server (using NAT or routing).
7. **Web server receives:** Packet from VPN gateway IP (or translated IP), with payload intact.

---

**[Short Answer]** A simplified "IPSec-like" system is proposed with these simplifications: (1) no SPI — the receiver uses destination port to identify the SA; (2) no sequence numbers — anti-replay not implemented; (3) always Transport Mode — tunnel mode removed; (4) no IKE — keys manually configured. Identify four security or operational problems with this design.

✔ **Answer:**
1. **No SPI → SA ambiguity:** Multiple SAs may exist between the same endpoints (e.g., one for TCP:443 and one for UDP:500). Using destination port to identify SAs is ambiguous (port 443 traffic could be from any application). The 32-bit SPI provides a precise, unambiguous SA identifier independent of port numbers. Without SPI, the receiver cannot reliably determine which SA applies.
2. **No sequence numbers → unlimited replay:** An attacker who captures a single legitimate encrypted packet can replay it indefinitely. The receiver has no mechanism to detect duplicates. Every captured ESP-encrypted request (e.g., a bank transfer) can be replayed to trigger the action repeatedly.
3. **Always Transport Mode → no topology hiding and no VPN support:** Transport Mode leaves the original IP header intact and visible. Internal IP addresses (192.168.x.x private addresses) are exposed to external observers. VPN operation (where the gateway is the IPSec endpoint, not the actual source) requires Tunnel Mode to carry the inner IP header encapsulated. Without Tunnel Mode, site-to-site VPNs are impossible.
4. **No IKE → manual keying nightmare:** Every communicating pair requires an administrator to manually configure matching SA parameters and keys on both sides. Key rotation (necessary for security) requires another manual operation. In an enterprise with N hosts, there are O(N²) potential SAs to manage manually. Key distribution itself becomes an unsecured manual process. This is operationally impossible at any meaningful scale and creates persistent stale keys.

---

**[Short Answer]** The course midterm includes a VPN observability question. Given: client C (10.0.0.4), VPN gateway V (130.166.128.1), destination server S (130.160.57.1). Fill in what each observer can see with VPN enabled vs. disabled, for: (a) on-path observer between C and V, (b) on-path observer between V and S, (c) the VPN gateway V itself, (d) the destination server S.

✔ **Answer:**

| Observer | No VPN | VPN Enabled |
|---|---|---|
| **On-path between C and V** | Client IP, Server IP, metadata, payload (if no TLS) | Client IP (10.0.0.4), VPN Gateway IP (130.166.128.1), metadata — NOT server IP, NOT payload |
| **On-path between V and S** | Client IP, Server IP, metadata, payload | Server IP (130.160.57.1), VPN Gateway IP (130.166.128.1), metadata — NOT client IP (gateway did NAT), NOT original payload |
| **VPN Gateway V** | N/A (not on path without VPN) | Client IP + Server IP + VPN Gateway IP + all metadata (decapsulates the tunnel) |
| **Destination Server S** | Client IP, its own IP, metadata | VPN Gateway IP (as source after NAT), its own IP, metadata — NOT original client IP |

Key insight for exam: Even with VPN, the **gateway sees everything** (it is the decapsulation point). The VPN only provides privacy from on-path observers **between** the client and gateway (and between gateway and server, from the perspective of hiding the original client IP).

---

**[Short Answer]** Why does IPSec use symmetric keys for bulk encryption (AES) but often uses asymmetric cryptography (RSA/ECC) during IKE? What would be the disadvantage of using only asymmetric cryptography for all IPSec operations?

✔ **Answer:**
Symmetric cryptography (AES) is orders of magnitude faster than asymmetric (RSA/ECC) for bulk data encryption. A modern CPU can perform AES-256 encryption at multi-gigabit speeds using hardware acceleration (AES-NI). RSA with a 3072-bit key or ECC with a 256-bit key are vastly slower for the same amount of data. IPSec uses asymmetric cryptography (in IKE) only for the key exchange and authentication — a small number of operations per session. Once the symmetric session keys are established, all bulk packet encryption uses the fast symmetric cipher.

Using only asymmetric cryptography for all IPSec operations would:
1. **Performance:** Reduce throughput to a tiny fraction of line speed — gigabit VPNs would become megabit VPNs
2. **CPU load:** Require immense computational resources, especially in VPN gateways handling thousands of tunnels
3. **Battery life:** For mobile clients, continuously running RSA operations would drain batteries rapidly
4. **Key management:** Public key operations require certificate infrastructure (PKI); symmetric keys can be negotiated on the fly via DH

The hybrid model (asymmetric for key exchange, symmetric for bulk data) combines the key distribution advantage of asymmetric cryptography with the performance advantage of symmetric cryptography.

---

*CS 448/548 Network Security · IP Security (IPSec) Protocol · Deep-Dive Annotated Study Guide · Spring 2026 · Dr. Lina Pu*
