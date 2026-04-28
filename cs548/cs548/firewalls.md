# Firewalls — Deep-Dive Annotated Study Guide
**CS 448/548 Network Security · All Firewall Topics · Comprehensive Edition**

---

> **How to use this guide:** Each slide section is followed by a **Discussion** block that explains *why* each design decision was made — not just *what* happens. The guide moves from beginner-friendly analogies to expert-level reasoning. The **Simon Sinek Golden Circle** (🔴 WHY → 🟡 HOW → 🟢 WHAT) organises every major concept. Workflows and comparisons are presented as detailed tables. Practice questions follow each topic group. A Quick Reference Summary and Exam Integrative Questions close the guide.

---

## Reading Legend

| Symbol | Meaning |
|---|---|
| `SRC_IP:PORT` | Source IP address and port number in a packet header |
| `DST_IP:PORT` | Destination IP address and port number in a packet header |
| **ACL** | Access Control List — the rule table a firewall consults |
| **SA** | Security Association (also used in context of firewall state entries) |
| ⚠️ | Security warning or known attack / evasion technique |
| 💡 | Design insight or key exam distinction |
| 🎯 | Analogy to make abstract concepts concrete |

---

# SLIDE 1 — What Is a Firewall and Why Do We Need One?

> *"Firewall: allow or deny network traffic between an enterprise host and an external user"*

**Slide Content:**
- A **firewall** is a network security device (hardware or software) that monitors and controls incoming and outgoing network traffic based on a defined set of security rules
- It establishes a barrier between a trusted internal network and untrusted external networks (e.g., the Internet)
- Acts as the primary perimeter security control for an organisation

---

## 📌 Key Concepts at a Glance

- A firewall is fundamentally a **policy enforcement point** — it implements rules that say what traffic is allowed and what is denied
- Firewalls operate on the concept of **default permit** (allow everything except what is explicitly blocked) or **default deny** (block everything except what is explicitly allowed) — security best practice mandates **default deny**
- A firewall alone is **not sufficient** — it is one layer in a defence-in-depth strategy alongside IDS/IPS, encryption, authentication, and endpoint security
- Firewalls can be implemented as dedicated hardware appliances, software running on general-purpose servers, or as virtual appliances in cloud environments

---

## 📖 Slide 1 Discussion

### 🔴 WHY — The Problem Firewalls Solve

Imagine you run a company with 500 employees. Your internal network contains payroll databases, source code repositories, customer records, and internal email. If you connect this network to the Internet with no controls, every device on your network becomes reachable by every attacker on the planet.

Without a firewall:
- An attacker from anywhere can attempt to connect to your database server directly (TCP port 5432 for PostgreSQL, 3306 for MySQL)
- A malware-infected device inside your network can freely send your data to an attacker's server
- There is no single point where you can inspect, log, or control what crosses the perimeter

A firewall is the **gatekeeper** at the border between your trusted network and the untrusted Internet. Every packet that attempts to cross the border is examined against the security policy, and only authorised traffic is allowed through.

### 🟡 HOW — The Fundamental Operating Model

```
                        FIREWALL
    INTERNET         ┌──────────┐         INTERNAL NETWORK
  (Untrusted)  ──── │  Policy  │ ────    (Trusted)
                    │  Engine  │
  Attack traffic ──X│  (ACL)   │         Protected hosts
                    └──────────┘
                         │
                    Logs & Alerts
```

Every packet arriving at the firewall is compared against an **Access Control List (ACL)** — an ordered list of rules. Each rule specifies:
- **Match criteria:** Which packets does this rule apply to? (IP addresses, ports, protocol, direction)
- **Action:** ALLOW, DENY, DROP, or LOG

The rules are evaluated **in order** — the first matching rule wins. This ordering is critical: rules at the top override rules further down.

### 🟢 WHAT — What Firewalls Protect Against (and What They Don't)

| Firewall Protects Against | Firewall Does NOT Protect Against |
|---|---|
| Unauthorised inbound connections (port scanning, exploitation of open services) | Attacks from inside the network (insider threats, already-compromised hosts) |
| Unauthorised outbound connections (data exfiltration to known bad IPs) | Encrypted malicious traffic inside allowed protocols (e.g., malware over HTTPS on port 443) |
| Known-bad source IP addresses | Zero-day exploits in allowed services |
| Traffic on prohibited ports | Social engineering, phishing |
| Certain DoS amplification attacks | Physical security breaches |

### 🎯 Analogy — The Security Checkpoint

A firewall is like a **security checkpoint at a building entrance**:
- Every person (packet) who wants to enter or leave must pass through the checkpoint
- The guard (firewall) checks credentials (packet headers) against an approved list (ACL)
- Some people are allowed in (ALLOW rule matched)
- Some are turned away (DENY rule matched)
- The checkpoint has logs of everyone who tried to enter
- **Limitation:** Once someone gets past the checkpoint, the guard can't control what they do inside the building — and the checkpoint doesn't help if the attacker is already inside

### 💡 Default Deny vs. Default Permit

| Policy | Meaning | Security Posture |
|---|---|---|
| **Default Permit** | Allow everything; only block what is explicitly listed as bad | Weak — attackers can use any port/protocol not on the block list |
| **Default Deny** | Block everything; only allow what is explicitly listed as good | Strong — attackers can only reach what you have deliberately opened |

Security best practice is always **default deny (allowlisting)**. The principle: if you haven't deliberately decided that traffic type is needed, it should be blocked. This forces administrators to consciously open each port/protocol.

---

## 🧪 Practice Questions — Slide 1

**[Multiple Choice]** Which firewall default policy provides the stronger security posture?
- A) Default Permit — block only known-bad traffic
- B) Default Deny — allow only explicitly approved traffic
- C) Both are equally secure
- D) Default Permit, because it avoids blocking legitimate traffic

✔ **Answer: B) Default Deny.** Blocking all traffic unless explicitly approved (allowlisting) is far more secure than trying to enumerate all bad traffic (blocklisting). Attackers can always use ports/protocols not yet on the block list.

---

**[True/False]** A firewall provides complete protection against all network attacks, including attacks from inside the network.

✔ **Answer: False.** A firewall primarily controls traffic crossing the **perimeter** (the boundary between trusted and untrusted networks). It provides little protection against insider threats, attacks from already-compromised hosts inside the network, or malicious traffic hiding inside allowed protocols (e.g., malware over HTTPS port 443).

---

**[Short Answer]** Explain the role of an Access Control List (ACL) in firewall operation.

✔ **Answer:** An ACL is an **ordered list of rules** that a firewall evaluates against every packet. Each rule specifies match criteria (source IP, destination IP, protocol, port, direction) and an action (ALLOW, DENY, DROP, LOG). Rules are evaluated **in order**; the first matching rule's action is applied. The ordering matters critically — a broad ALLOW rule near the top can inadvertently override a specific DENY rule further down. The last rule in most firewall policies is a **default deny** rule that catches all traffic not matched by any previous rule.

---

**[Fill in the Blank]** A firewall that blocks all traffic by default and only allows explicitly approved traffic is implementing a ________ policy, while one that allows all traffic by default is implementing a ________ policy.

✔ **Answer:** Default deny (allowlist); default permit (blocklist).

---

---

# SLIDE 2 — Firewall Policy Dimensions: User, Service, and Direction Control

> *"Firewall Policy: User control, Service control, Direction control"*

**Slide Content:**
- **User control:**
  - Controls access to data based on the **role of the user** attempting to access it
  - Applied to users **inside** the firewall perimeter
  - Example: HR staff can access the payroll server; developers cannot
- **Service control:**
  - Controls access by the **type of service** offered by the host
  - Applied based on **network address**, **protocol** of connection, and **port numbers**
  - Example: Allow HTTP (port 80) and HTTPS (port 443) to the web server; deny all other ports
- **Direction control:**
  - Determines the **direction** in which requests may be initiated and allowed to flow through the firewall
  - "Inbound" = traffic arriving from outside (untrusted) to inside (trusted)
  - "Outbound" = traffic departing from inside (trusted) to outside (untrusted)
  - Example: Allow internal users to initiate outbound HTTPS; deny inbound HTTPS initiation from the Internet to internal workstations

---

## 📌 Key Concepts at a Glance

- The three dimensions are **orthogonal** — a complete firewall policy addresses all three simultaneously
- **Service control** is the most commonly implemented (packet filters do this natively via port/protocol inspection)
- **User control** is harder at the network layer — it typically requires integration with identity systems (RADIUS, Active Directory) or operating at the application layer
- **Direction control** is why stateful firewalls exist — a stateless filter cannot distinguish "a reply to an outbound connection" from "a new inbound connection"

---

## 📖 Slide 2 Discussion

### 🔴 WHY — Three Dimensions Because Threats Come in Three Dimensions

A network threat is characterised by:
1. **Who** is making the request (user identity)
2. **What service** they are trying to reach (protocol/port)
3. **Which direction** the request is flowing (inside→outside vs. outside→inside)

A firewall that only controls service (port/protocol) but ignores direction would allow an Internet attacker to initiate connections to any internal service on allowed ports — clearly wrong. A firewall that only controls direction but ignores service would block all inbound traffic — breaking all legitimate services. All three dimensions must be addressed for a coherent security policy.

### 🟡 HOW — Mapping Dimensions to Mechanisms

| Policy Dimension | What It Controls | Primary Mechanism | Layer |
|---|---|---|---|
| **User control** | Who can do what — identity-based access | RADIUS/LDAP integration, user authentication, VPN identity, application-layer proxy | Application Layer (L7) |
| **Service control** | Which protocols/ports are allowed | Port/protocol filtering in ACL rules | Transport Layer (L4) and Network Layer (L3) |
| **Direction control** | Inbound vs. outbound initiation | Stateful inspection (connection state tables) | Transport Layer (L4) |

### 🟢 WHAT — A Concrete Policy Example

Consider a corporate network with a web server in the DMZ and workstations on the internal network:

| Rule | User Control | Service Control | Direction Control | Action |
|---|---|---|---|---|
| 1 | Any external user | HTTP/HTTPS (80/443) | Inbound to DMZ web server | ALLOW |
| 2 | Any external user | Any other port | Inbound to DMZ web server | DENY |
| 3 | Any external user | Any port | Inbound to internal workstations | DENY |
| 4 | Internal users | Any outbound HTTP/HTTPS | Outbound from internal | ALLOW |
| 5 | Internal admin users | SSH (22) | Outbound to DMZ servers | ALLOW |
| 6 | Non-admin internal users | SSH (22) | Any | DENY |
| 7 | Any | Any | Any | DENY (default) |

Rules 1-2 = **Service control** on the web server. Rule 3 = **Direction control** (no inbound to workstations). Rules 5-6 = **User control** (admins vs. non-admins). Rule 7 = **Default deny**.

### 🎯 Analogy — A Hotel With Different Rooms

- **User control** = Hotel staff can access any floor; guests can only access their floor (identity-based)
- **Service control** = The restaurant is open to all; the kitchen is staff-only (service type)
- **Direction control** = Guests can go from their room to the pool; pool attendants cannot go from the pool to guest rooms uninvited (directionality)

### 💡 The Direction Control Problem With Stateless Filters

A pure stateless packet filter checking direction has a fundamental problem: **TCP reply packets look like new inbound connections** at the packet level.

When you browse to `google.com`:
1. Your browser sends a TCP SYN to `google.com:443` (outbound) — this is the initiation
2. Google responds with SYN-ACK back to `your_IP:random_port` (inbound) — this is the reply

A stateless filter that blocks all inbound TCP traffic would also block Google's SYN-ACK, breaking your browsing. To solve this without a stateful firewall, you'd have to allow all inbound TCP — which lets attackers in.

The solution is **stateful inspection** — which tracks whether an inbound packet is a reply to an existing outbound connection or a new unsolicited inbound connection. This is covered in detail in the stateful firewall slide.

---

## 🧪 Practice Questions — Slide 2

**[Multiple Choice]** A firewall rule that blocks all incoming connections on port 23 (Telnet) from the Internet, but allows outgoing Telnet from internal hosts, is primarily an example of which policy dimension?
- A) User control
- B) Service control combined with direction control
- C) User control combined with service control
- D) Direction control only

✔ **Answer: B) Service control combined with direction control.** The rule controls **which service** (Telnet, port 23) — service control — and **which direction** (inbound blocked, outbound allowed) — direction control. No user identity is involved, so it is not user control.

---

**[True/False]** Service control (port/protocol filtering) alone is sufficient to implement a complete and effective firewall policy.

✔ **Answer: False.** Service control alone ignores **direction** (whether traffic is initiated from inside or outside) and **user identity** (whether the user is authorised). For example, a rule allowing port 443 without direction control would allow Internet attackers to initiate HTTPS connections to any internal host — not just internal users initiating outbound HTTPS.

---

**[Short Answer]** Why is user control the hardest of the three firewall policy dimensions to implement at the network layer?

✔ **Answer:** At the network layer, packets carry **IP addresses and port numbers** — but not user identities. A packet from IP `192.168.1.50` could be sent by the HR manager, a developer, or malware on that machine — the packet looks identical. User control requires either: (1) mapping IPs to users via network access control (802.1X assigns IPs based on authenticated user) or VPN authentication; (2) operating at the **application layer** (proxy firewall) where user credentials can be checked; or (3) integrating with directory services (RADIUS, Active Directory) to tie IP addresses to authenticated identities. None of these are available to a simple packet filter operating at L3/L4.

---

**[Fill in the Blank]** The three dimensions of firewall policy are ________ control (identity-based), ________ control (protocol/port-based), and ________ control (inbound vs. outbound).

✔ **Answer:** User; service; direction.

---

---

# SLIDE 3 — Classification of Firewalls: Three Types

> *"Three types of firewalls: Packet Filter, Stateful, Application/Proxy"*

**Slide Content:**
- Depending on the mode of operation, there are three types of firewalls:
  1. **Packet Filter Firewall** (stateless)
  2. **Stateful Firewall**
  3. **Application/Proxy Firewall**

---

## 📌 Key Concepts at a Glance

- The three types form a **spectrum of inspection depth**: packet filters inspect headers only; stateful firewalls track connection state; application firewalls inspect full payload content
- **Higher inspection depth = more security but more cost** (CPU, memory, latency, complexity)
- In practice, modern **Next-Generation Firewalls (NGFW)** combine all three levels plus additional capabilities (IPS, DPI, application-layer identification, SSL inspection)
- Each type has distinct strengths and weaknesses — knowing when to use which type is essential for designing network security architectures

---

## 📖 Slide 3 Discussion

### 🔴 WHY — Why Three Types?

The three firewall types evolved in response to successively more sophisticated attacks:

1. **Packet filters** (1980s): sufficient when the Internet was small and threats were basic port-scanning attacks
2. **Stateful firewalls** (early 1990s): evolved to handle TCP state tracking and prevent IP spoofing + unsolicited inbound connections
3. **Application/proxy firewalls** (mid-1990s onwards): evolved to handle application-layer attacks that defeat both packet filters and stateful inspection (e.g., malware in HTTP payloads, SQL injection, malicious DNS responses)

### 🟡 HOW — The Inspection Depth Spectrum

```
LESS INSPECTION ◄─────────────────────────────────► MORE INSPECTION

Packet Filter          Stateful              Application/Proxy
─────────────────      ─────────────────     ─────────────────────
• L3/L4 headers       • L3/L4 headers       • L3–L7 full payload
• Per-packet           • Connection state    • Protocol-aware
• No memory            • State table         • Deep inspection
• Fastest              • Medium speed        • Slowest
• Least overhead       • Medium overhead     • Highest overhead
• Limited security     • Good security       • Best security
```

### 🟢 WHAT — Selection Guide

| Scenario | Recommended Type | Reason |
|---|---|---|
| High-throughput backbone router ACLs | Packet Filter | Speed paramount; application inspection not needed at this layer |
| Enterprise perimeter between corporate LAN and Internet | Stateful | Must handle TCP connection tracking; blocks unsolicited inbound traffic |
| Web Application Firewall (WAF) protecting public web servers | Application/Proxy | Must inspect HTTP payloads for SQL injection, XSS, malformed requests |
| Email gateway | Application/Proxy | Must inspect SMTP content for malware, spam, phishing |
| Internal segmentation between departments | Stateful | Connection tracking between trusted zones; application inspection usually not needed |

---

## 🧪 Practice Questions — Slide 3

**[Multiple Choice]** Which firewall type provides the deepest inspection of network traffic?
- A) Packet filter firewall
- B) Stateful firewall
- C) Application/proxy firewall
- D) All three provide equally deep inspection

✔ **Answer: C) Application/proxy firewall.** Application-layer firewalls inspect traffic all the way up to Layer 7, including the content of application-protocol payloads (HTTP body, SMTP content, DNS answers). Packet filters inspect only L3/L4 headers; stateful firewalls add connection state tracking but do not inspect application payloads.

---

**[True/False]** A stateful firewall provides the same level of application-layer protection as an application/proxy firewall.

✔ **Answer: False.** A stateful firewall tracks TCP/UDP connection state but does **not inspect application-layer payloads**. It cannot detect malware embedded in an HTTP response, SQL injection in an HTTP request, or a malicious DNS answer. An application/proxy firewall inspects protocol-specific payload content up to Layer 7.

---

**[Fill in the Blank]** The three types of firewalls, in order from least to most inspection depth, are ________, ________, and ________.

✔ **Answer:** Packet filter (stateless); stateful; application/proxy.

---

---

# SLIDE 4 — Packet Filter Firewall (Stateless)

> *"Packet Filters — Simplest component; does not maintain states"*

**Slide Content:**
- **Controls traffic based on the information in packet headers**, without looking into the payload
- Does **not** examine if the packet is part of an existing stream or traffic
- Does **not** maintain state about packets — also called **Stateless Firewall**
- Uses **network and transport layer information only:**
  - IP Source Address, Destination Address
  - Protocol/Next Header (TCP, UDP, ICMP, etc.)
  - TCP or UDP source & destination ports
  - TCP Flags (SYN, ACK, FIN, RST, PSH, etc.)
  - ICMP message type
- **Examples:**
  - DNS uses port 53 → No incoming port 53 packets except from known trusted servers
  - Telnet uses port 23 → Block all incoming TCP packets with port 23

---

## 📌 Key Concepts at a Glance

- Packet filters make a **per-packet, independent decision** — each packet is evaluated in isolation with no memory of prior packets
- The **TCP Flags** field is critical — it allows a packet filter to (imperfectly) distinguish connection initiation (SYN) from established-connection traffic (ACK)
- The key vulnerability: a packet filter **cannot distinguish a reply to an outbound connection from a new unsolicited inbound connection** purely from packet headers (without state)
- Common workaround: allow inbound TCP only if the ACK bit is set — this blocks unsolicited TCP SYNs while allowing TCP replies, but can be bypassed by crafting packets with the ACK bit set

---

## 📖 Slide 4 Discussion

### 🔴 WHY — The Simplest, Fastest, Most Limited Approach

Packet filtering is essentially a **header-matching ruleset applied at wire speed**. Because each packet is evaluated independently with no state to maintain, packet filters can operate at very high throughput (millions of packets per second on dedicated hardware). This makes them the right choice for high-speed backbone filtering where deep inspection is impractical.

But their limitation is fundamental: **the Internet is full of stateful protocols** (TCP, especially), and making correct security decisions about a TCP packet often requires knowing what TCP state the connection is in.

### 🟡 HOW — Packet Filter Rule Evaluation

Each rule in the ACL has the form:

```
RULE: [Action] [Protocol] [SRC_IP/mask] [SRC_PORT] [DST_IP/mask] [DST_PORT] [FLAGS]

Examples:
DENY  TCP  any           any   192.168.1.0/24  23              # Block Telnet to internal
ALLOW TCP  192.168.1.0/24 any  any             80,443          # Allow internal → HTTP/HTTPS
DENY  TCP  any           any   any             any  SYN        # Block all inbound TCP SYN
ALLOW TCP  any           any   any             any  ACK        # Allow TCP replies (ACK set)
DENY  UDP  any           any   any             53              # Block inbound DNS
ALLOW UDP  10.0.0.53     53   192.168.1.0/24  any             # Allow DNS from trusted server
DENY  any  any           any   any             any             # Default deny
```

**Rule processing — key points:**
1. Rules are evaluated **top-to-bottom**; the first match wins
2. Rule ordering is security-critical: a permissive rule near the top can mask a restrictive rule below it
3. The **default rule** at the bottom (usually DENY all) determines what happens to packets not matched by any explicit rule

### 🟢 WHAT — The Packet Filter Decision Table

| Header Field | Used For | Example Rule |
|---|---|---|
| **SRC IP** | Block traffic from known-bad IPs; allow traffic only from trusted ranges | DENY any traffic from 185.220.0.0/16 (known Tor exit nodes) |
| **DST IP** | Protect specific servers; restrict access to sensitive hosts | ALLOW traffic only to 10.0.0.80 (web server) on port 80/443 |
| **Protocol** | Block entire protocol families | DENY all ICMP (prevent ping sweeps, though crude) |
| **DST PORT** | Service control — which services are accessible | DENY all traffic to port 23 (Telnet), 21 (FTP), 3389 (RDP) from Internet |
| **SRC PORT** | Rarely used — source ports are typically ephemeral and unpredictable | Allow DNS replies (SRC port 53) from trusted DNS servers |
| **TCP SYN flag** | Distinguish connection initiation from established-connection traffic | DENY inbound TCP with SYN set, no ACK — blocks new inbound TCP connections |

### 🎯 Analogy — The Bouncer Reading IDs

A packet filter is like a **nightclub bouncer who checks your ID but nothing else**:
- They check the card (packet header): your name (IP address), age (port/protocol), membership status (TCP flags)
- They do **not** pat you down or check what you're carrying inside your clothes (payload)
- They have **no memory** of who has already come in — every person at the door is evaluated fresh
- If you show the right ID, you're in — even if the last 10 people with the same ID caused trouble

This means:
- A packet crafted with a legitimate source IP and destination port will get through even if its payload contains malware
- A legitimate user will be blocked if they don't match the header criteria exactly

### ⚠️ Packet Filter Weaknesses

| Weakness | Description | Attack That Exploits It |
|---|---|---|
| **No payload inspection** | Cannot detect malware/exploits inside allowed traffic | Malware embedded in HTTP responses, SQL injection |
| **IP spoofing vulnerability** | Cannot verify that the source IP is genuine | IP spoofing attacks; a spoofed packet from a trusted IP bypasses IP-based rules |
| **TCP ACK bypass** | Filtering on TCP flags only (ACK = established) can be bypassed by crafting packets with ACK bit set without a real connection | TCP session hijacking setup; port scanning with ACK probes to map firewall rules |
| **Fragmentation attacks** | Packet filter may see only the first fragment (containing the TCP header); subsequent fragments are let through without headers | Fragmentation attack for evasion: move the TCP SYN into a later fragment after the decision is made on the first |
| **No application context** | Cannot enforce application-layer policies | DNS cache poisoning, HTTP request smuggling |

### 💡 TCP Flag Filtering in Detail

The most common packet filter trick for handling TCP directionality:

```
Goal: Allow internal users to browse the Internet (outbound TCP)
      but block Internet users from initiating connections to internal hosts (inbound TCP SYN)

Rule: ALLOW TCP from any to internal_net:any  if ACK bit is SET
Rule: DENY  TCP from any to internal_net:any  if SYN bit is SET and ACK bit is NOT SET

Why this works (mostly):
- A TCP SYN (new connection) has SYN=1, ACK=0 → blocked
- A TCP SYN-ACK (server reply to client's SYN) has SYN=1, ACK=1 → allowed
- A TCP ACK (data in established connection) has ACK=1 → allowed
- A TCP FIN (connection teardown) has ACK=1 → allowed

Why this is imperfect:
- An attacker can craft a packet with ACK=1 without a real connection → it bypasses the rule
- ACK-based filtering does not prevent IP spoofing
- Does not handle UDP (which has no SYN/ACK concept)
```

---

## 🧪 Practice Questions — Slide 4

**[Multiple Choice]** A packet filter firewall examines which of the following? (Select all that apply)
- A) IP source and destination addresses
- B) TCP/UDP port numbers
- C) HTTP request body content
- D) TCP flags (SYN, ACK, FIN, RST)
- E) User identity and authentication credentials

✔ **Answer: A, B, D.** Packet filters examine only network-layer (IP headers: source/destination address) and transport-layer (TCP/UDP: port numbers, TCP flags) information. They do NOT inspect application-layer content (HTTP body — option C) or user identity (option E), which require an application/proxy firewall.

---

**[True/False]** A packet filter firewall that blocks all incoming TCP packets with the SYN flag set (but not ACK) completely prevents inbound TCP connection attacks.

✔ **Answer: False.** While blocking SYN-only packets does prevent standard TCP connection initiation, an attacker can **craft packets with the ACK bit set** (a legitimate-looking packet header without a real underlying connection). Such packets bypass the SYN-only block rule. Additionally, fragmentation attacks can split TCP headers across fragments, where only the first fragment triggers the rule check and later fragments are passed without scrutiny.

---

**[Short Answer]** Why is packet filter rule ordering critically important? Give a concrete example where rule order changes the outcome.

✔ **Answer:** Packet filters evaluate rules **top-to-bottom and stop at the first match**. The same set of rules in different orders can produce opposite results.

**Example:**
- *Correct order:* Rule 1: DENY TCP any → 10.0.0.5:23 | Rule 2: ALLOW TCP 192.168.1.0/24 → any:any
  - A Telnet packet from `192.168.1.10` to `10.0.0.5:23` → matches Rule 1 first → **DENIED**
- *Wrong order:* Rule 1: ALLOW TCP 192.168.1.0/24 → any:any | Rule 2: DENY TCP any → 10.0.0.5:23
  - Same Telnet packet → matches Rule 1 first (source IP in 192.168.1.0/24) → **ALLOWED** — the deny rule is never reached

The ALLOW rule in the wrong position "shadows" the DENY rule, making it unreachable for packets from the internal network.

---

**[Fill in the Blank]** A packet filter firewall is also called a ________ firewall because it evaluates each packet ________ with no memory of previous packets.

✔ **Answer:** Stateless; independently (in isolation).

---

---

# SLIDE 5 — Stateful Firewall (Stateful Packet Inspection)

> *"Stateful Firewall: Tracks the state of traffic by monitoring all connection interactions until connection is closed"*

**Slide Content:**
- **Tracks the state of traffic** by monitoring all connection interactions until it is closed
- A **connection state table** is maintained to understand the **context** of packets
- Example: Connections are only allowed through ports that hold open connections
- Traditional packet filters do **not** examine transport layer context (i.e., matching return packets with outgoing flow)
- Stateful packet filters address this need
- They examine each IP packet **in context**:
  - Keep track of client-server sessions
  - Check each packet validly belongs to one
- Hence are **better able to detect bogus packets out of context**

---

## 📌 Key Concepts at a Glance

- The state table is the **core innovation** — it gives the firewall "memory" of ongoing connections
- A stateful firewall implicitly allows **return traffic** for established outbound connections without needing explicit inbound rules
- The state table entries include: source IP/port, destination IP/port, protocol, connection state (SYN_SENT, ESTABLISHED, etc.), and a timeout
- **Stateful inspection is the dominant enterprise firewall paradigm** — virtually all modern firewalls include it
- State tables consume memory and processing — a large number of simultaneous connections (or a SYN flood attack) can exhaust the state table

---

## 📖 Slide 5 Discussion

### 🔴 WHY — The Fundamental Gap Stateful Firewalls Fill

Consider what a packet filter cannot do:

*Scenario:* Alice (192.168.1.10) opens `https://google.com`. Her browser sends a TCP SYN to `142.250.80.46:443`. Google replies with a SYN-ACK from `142.250.80.46:443` to `192.168.1.10:54321`.

From a **packet filter's perspective**, the SYN-ACK arriving from the Internet looks exactly like any other inbound TCP packet from `142.250.80.46:443` destined for `192.168.1.10:54321`. There is no way to determine from the packet header alone whether this is:
- A legitimate reply to Alice's outbound TCP SYN (safe — allow it), OR
- An unsolicited inbound TCP packet from a Google IP to a high port (suspicious — should be investigated)

A packet filter's only option is to either:
1. Allow all inbound TCP ACK packets → security risk (allows unsolicited inbound)
2. Block all inbound TCP packets → breaks all outbound browsing

The stateful firewall's state table solves this: when Alice's SYN went out, the firewall recorded the connection in its state table. When Google's SYN-ACK arrives, the firewall looks it up — matches the state table entry → **this is a legitimate reply → allow it**.

### 🟡 HOW — The State Table in Detail

| Entry Field | Description | Example Value |
|---|---|---|
| **Protocol** | TCP / UDP / ICMP | TCP |
| **SRC IP** | Source IP of the connection originator | 192.168.1.10 |
| **SRC Port** | Ephemeral source port chosen by the client | 54321 |
| **DST IP** | Destination IP | 142.250.80.46 |
| **DST Port** | Service port of the destination | 443 |
| **State** | Current TCP state: SYN_SENT, ESTABLISHED, FIN_WAIT, etc. | ESTABLISHED |
| **Timeout** | Time since last packet; if exceeded, entry is purged | 300 seconds |
| **Direction** | Which side initiated the connection | OUTBOUND (inside→outside) |

**TCP State Progression in the State Table:**

```
Alice sends SYN to Google:443
  → State table entry created: SYN_SENT
  → Outbound SYN packet: ALLOWED

Google sends SYN-ACK to Alice:54321
  → State table lookup: entry found, matches SYN_SENT
  → Entry updated: ESTABLISHED
  → Inbound SYN-ACK: ALLOWED (because it matches existing state)

Alice sends ACK to Google:443
  → State table lookup: entry found, ESTABLISHED
  → Outbound ACK: ALLOWED

[Data exchange — all packets match state table → ALLOWED]

Alice sends FIN to Google:443
  → State table entry: FIN_WAIT_1
  → Outbound FIN: ALLOWED

Google sends ACK + FIN
  → Entry: TIME_WAIT → eventually purged
  → Inbound FIN-ACK: ALLOWED (matches state)
```

**What happens to packets that DON'T match any state table entry:**

- **Inbound TCP SYN** with no matching entry: Is this a new legitimate inbound connection or an attack? Check the explicit rule set — if there's no ALLOW rule for this destination (e.g., no rule permitting inbound port 443 to an internal host), **DENY**.
- **Inbound TCP ACK** with no matching entry: This is definitely suspicious — an ACK with no prior SYN means either a spoofed packet or a firewall reboot wiped the state. **DENY** — this is the "bogus packet out of context" the slide mentions.
- **Inbound TCP RST** with no matching entry: Forged TCP RST attack. **DENY**.

### 🟢 WHAT — What Stateful Inspection Enables vs. Packet Filter

| Capability | Packet Filter | Stateful Firewall |
|---|---|---|
| Block inbound TCP SYN (unsolicited) | ✅ Yes (SYN flag check) | ✅ Yes (no state entry) |
| Allow TCP replies for outbound connections | ⚠️ Imperfect (ACK flag trick) | ✅ Yes (state table match) |
| Detect forged TCP RST | ❌ No | ✅ Yes (no state entry) |
| Block UDP replies with no prior query | ❌ No | ✅ Yes (UDP pseudo-state) |
| Detect out-of-sequence TCP packets | ❌ No | ✅ Some implementations |
| Detect IP fragmentation attacks | ❌ No | ✅ Reassembly before inspection |
| Inspect application payload | ❌ No | ❌ No |

### 🎯 Analogy — The Receptionist with a Visitor Log

A stateful firewall is like a **corporate receptionist who keeps a visitor log**:
- When an internal employee calls to invite a vendor in (outbound connection initiated), the receptionist notes: "Employee A is expecting Vendor B" (state table entry created)
- When Vendor B arrives at the front door (inbound reply packet), the receptionist checks the log: "Yes, Employee A invited them → come in" (state table match → allow)
- If a stranger walks in claiming "I'm here to see Employee A" without any prior call logged (inbound SYN with no state entry), the receptionist challenges them against the explicit visitor policy (check explicit ACL rules)
- If someone walks in and says "I've been here all along" but is not in the log (inbound ACK with no state entry), the receptionist knows something is wrong (bogus packet out of context → deny)

### ⚠️ State Table Exhaustion — The SYN Flood Attack

The state table is a **finite resource**. Each half-open TCP connection (SYN received, SYN-ACK sent, ACK not yet received) occupies a state table entry. An attacker who floods the firewall with TCP SYN packets from spoofed source IPs can:

1. Fill the state table with half-open connection entries
2. The SYN-ACK replies go to the spoofed (non-existent) source IPs — no ACK ever arrives
3. The half-open entries age out slowly (typically 30–75 seconds)
4. New legitimate connections cannot be added — the state table is full

**Countermeasure: SYN Cookies** — the firewall encodes connection state in the SYN-ACK's sequence number instead of allocating a state table entry, only creating an entry when the final ACK arrives (proving the client is real). This is the same mechanism described in the TCP attacks lecture.

---

## 🧪 Practice Questions — Slide 5

**[Multiple Choice]** A user on the internal network connects to an external website. The external server's reply packet arrives at the firewall. How does a stateful firewall decide to allow this reply?
- A) It checks if the source port of the reply is in a known-safe range (1024–65535)
- B) It matches the reply packet against an existing state table entry that was created when the outbound connection was initiated
- C) It checks if the reply packet has the ACK flag set
- D) It forwards all inbound packets from known websites automatically

✔ **Answer: B)** The stateful firewall created a state table entry when the outbound TCP SYN was sent. The reply is matched against this entry — the tuple (SRC IP, SRC Port, DST IP, DST Port, Protocol) is checked against the state table. A match confirms this is a legitimate reply to an existing connection → ALLOW.

---

**[True/False]** A stateful firewall automatically tracks UDP "connections" even though UDP is a connectionless protocol.

✔ **Answer: True (with nuance).** UDP has no connection setup like TCP, but stateful firewalls track UDP flows using a **pseudo-state** model: when an internal host sends a UDP packet to an external destination, the firewall creates a state entry for the (SRC IP, SRC Port, DST IP, DST Port, UDP) tuple with a short timeout (typically 30–120 seconds). UDP replies arriving within this window are matched to the state entry and allowed. This prevents unsolicited UDP inbound packets while allowing DNS replies, VoIP, etc.

---

**[Short Answer]** What is a "bogus packet out of context" in the context of stateful firewall inspection? Give an example.

✔ **Answer:** A "bogus packet out of context" is a packet that arrives at the firewall in a state that is **inconsistent with the established connection state** — i.e., the packet's headers suggest it belongs to a TCP connection that does not exist in the state table. **Example:** An inbound TCP packet with only the ACK flag set (no SYN, no FIN) arriving at the firewall for a destination inside the network, but with no corresponding state table entry. A legitimate TCP ACK in an established connection would have a matching entry. An ACK with no entry is either: (1) a spoofed forged packet (TCP reset injection, session hijacking setup), or (2) the state table entry was purged (connection timed out). The stateful firewall detects this and drops it — a packet filter would pass it through if the port/IP matched an ALLOW rule.

---

**[Fill in the Blank]** A stateful firewall maintains a ________ that records all active connections, allowing it to automatically allow ________ traffic for established outbound connections without explicit inbound rules.

✔ **Answer:** Connection state table (state table); return (reply).

---

---

# SLIDE 6 — Application/Proxy Firewall

> *"Application/Proxy Firewall: Controls input, output, and access from/to an application or service"*

**Slide Content:**
- **Controls input, output, and access** from/to an application or service
- Acts as an **intermediary by impersonating the intended recipient**
- The client's connection **terminates at the proxy** and a **separate connection is initiated from the proxy** to the destination host
- Data on the connection is **analysed up to the application layer** to determine if the packet should be allowed or rejected
- **Has full access to the protocol:**
  - User requests service from proxy
  - Proxy validates request as legal
  - Then proxy actions request and returns result to user
- **Need separate proxies for each service:**
  - WAF (Web Application Firewall)
  - SMTP (E-Mail Firewall)
  - DNS (Domain Name System)
  - Custom services generally not supported

---

## 📌 Key Concepts at a Glance

- The proxy is a **man-in-the-middle by design** — it terminates both connections (client→proxy and proxy→server) and is fully aware of the application-layer content
- This deep visibility is the proxy's power: it can detect malformed protocol messages, policy violations, malware in payloads, and protocol abuse that stateless/stateful firewalls cannot see
- The proxy's overhead is significantly higher — every packet is processed at Layer 7, and the proxy must understand each specific protocol it protects
- **One protocol = one proxy**: a WAF protects HTTP/HTTPS; an SMTP proxy protects email; you cannot use a WAF to protect DNS
- **SSL/TLS inspection** (decryption at the proxy) is often required for application proxies to inspect HTTPS traffic — this raises privacy considerations

---

## 📖 Slide 6 Discussion

### 🔴 WHY — When Packet and Stateful Filtering Are Not Enough

Consider these scenarios that defeat packet filters and stateful firewalls:

1. **SQL injection in an HTTP POST body:** An attacker sends `POST /login HTTP/1.1` with the body `username=admin' OR '1'='1`. The packet filter sees: TCP to port 80/443, from a legitimate IP → ALLOW. The stateful firewall sees: part of an established TCP connection → ALLOW. The payload is never examined. A WAF would inspect the POST body and detect the SQL injection pattern → DENY.

2. **DNS cache poisoning response:** An attacker sends a crafted DNS response. A packet filter allows port 53 UDP from trusted DNS servers. A stateful firewall allows it as a reply to a prior DNS query. Only a DNS application proxy can inspect whether the response is syntactically valid and whether the answer section's domain matches what was queried.

3. **Email with macro malware:** An SMTP proxy can scan email attachments, strip macros from Office documents, and enforce DLP (Data Loss Prevention) policies. No amount of IP/port filtering can do this.

### 🟡 HOW — The Proxy Connection Model

**Standard (non-proxy) connection:**
```
Client ─────────────────────────────────────────► Server
         (Direct TCP connection client to server)
```

**Application proxy connection:**
```
Client ──────► Proxy ──────────────────────────► Server
        Conn 1         Conn 2
   (Client thinks    (Proxy acts as          (Server thinks
    proxy IS server)  a client to server)     proxy IS the client)
```

The proxy has **complete visibility** into both connections. The client's TCP connection terminates at the proxy. The proxy initiates a separate TCP connection to the real server. All data in both directions flows through the proxy, where it is fully analysed at the application layer.

**Step-by-step operation for an HTTP proxy:**

| Step | Action | What the Proxy Does |
|---|---|---|
| 1 | Client connects to proxy on port 8080 (or 443 for HTTPS) | Proxy accepts the TCP connection; client thinks it's talking to the web server |
| 2 | Client sends HTTP request: `GET /page.html HTTP/1.1\nHost: example.com` | Proxy receives and **parses** the full HTTP request at the application layer |
| 3 | Proxy validates the request | Checks for: malformed HTTP, prohibited URLs, request smuggling, oversized headers, XSS in URL |
| 4 | Proxy forwards (or rejects) | If valid: proxy opens its own TCP connection to `example.com:80` and forwards the sanitised request. If invalid: proxy returns an error to the client and logs the event |
| 5 | Server responds | Proxy receives the HTTP response and parses it: checks content type, scans for malware, validates headers |
| 6 | Proxy forwards response to client | If valid: forwards to client. If malicious content found: blocks it |

### 🟢 WHAT — What Application/Proxy Firewalls Can Detect

| Attack / Threat | Packet Filter | Stateful | Application/Proxy |
|---|---|---|---|
| Port scanning | ✅ Partial | ✅ Partial | ✅ Yes |
| IP spoofing | ❌ No | ✅ Partial | ✅ Yes |
| SQL injection in HTTP body | ❌ No | ❌ No | ✅ Yes (WAF) |
| XSS in HTTP request | ❌ No | ❌ No | ✅ Yes (WAF) |
| Malware in email attachment | ❌ No | ❌ No | ✅ Yes (SMTP proxy) |
| DNS cache poisoning response | ❌ No | ❌ No | ✅ Yes (DNS proxy) |
| Oversized HTTP headers | ❌ No | ❌ No | ✅ Yes (WAF) |
| Protocol misuse (e.g., SSH tunnelling over port 443) | ❌ No | ❌ No | ✅ Yes (SSL inspection + DPI) |
| Data exfiltration in allowed protocol | ❌ No | ❌ No | ✅ Partial (DLP features) |

### 🎯 Analogy — The Mail Room Inspector

An application proxy is like a **corporate mail room that opens and inspects every package**:
- Every piece of mail (network packet) addressed to someone inside the company arrives at the mail room (proxy)
- The mail room staff open the package (parse the application payload) and check the contents
- If the contents match a known prohibited item (malware, confidential data, SQL injection pattern): confiscate and alert
- If everything is fine: reseal the package with the company's own label (proxy's IP becomes the source) and forward it to the recipient
- The final recipient only ever sees packages that passed the mail room inspection — they never receive unscreened items

### ⚠️ Application Proxy Limitations

| Limitation | Description |
|---|---|
| **Protocol-specific** | A separate proxy is needed for each protocol (HTTP, SMTP, DNS, FTP, etc.). Protocols not implemented are handled by falling back to stateful or packet-filter rules |
| **Performance overhead** | Layer-7 inspection is CPU-intensive. Requires parsing, reassembling, and inspecting every packet's payload. High-throughput environments may see latency |
| **Encrypted traffic** | HTTPS traffic cannot be inspected without **TLS interception** (proxy decrypts, inspects, re-encrypts). This introduces privacy concerns and certificate management complexity |
| **Custom/proprietary protocols** | Application proxies don't know how to parse custom protocols — they cannot be inspected at L7 |
| **Single point of failure** | All traffic through the proxy; if it fails, the connection fails (unlike transparent packet filters) |

### 💡 Proxy vs. Reverse Proxy

| Type | Who Initiates | Who It Protects | Use Case |
|---|---|---|---|
| **Forward Proxy** | Internal clients → Internet | Internal clients from malicious servers | Egress filtering; corporate web proxy |
| **Reverse Proxy / WAF** | Internet clients → Internal server | Internal servers from Internet clients | Ingress filtering; WAF protecting web servers |

A **WAF (Web Application Firewall)** is a reverse proxy: Internet clients connect to the WAF, which inspects the request and forwards it to the real web server only if it passes inspection. The web server is never directly accessible from the Internet.

---

## 🧪 Practice Questions — Slide 6

**[Multiple Choice]** Which characteristic uniquely distinguishes an application/proxy firewall from both packet filter and stateful firewalls?
- A) It tracks TCP connection state
- B) It filters traffic based on IP addresses and port numbers
- C) It terminates connections at the proxy and initiates new connections to the destination, enabling full application-layer inspection
- D) It operates exclusively at the network layer

✔ **Answer: C)** The proxy's defining characteristic is that it **terminates connections** — the client's connection ends at the proxy, and the proxy initiates a separate connection to the server. This "connection termination" model is what enables full application-layer inspection, because the proxy must fully parse the application protocol to relay it correctly.

---

**[True/False]** A single WAF (Web Application Firewall) can protect HTTP, SMTP email, and DNS traffic without any additional proxy components.

✔ **Answer: False.** Application proxies are **protocol-specific**. A WAF understands HTTP/HTTPS protocol semantics — it cannot parse SMTP or DNS messages. Protecting email requires a dedicated SMTP proxy; protecting DNS requires a DNS proxy. The slide explicitly states: "Need separate proxies for each service."

---

**[Short Answer]** Explain why inspecting HTTPS traffic at an application/proxy firewall requires TLS interception, and why this creates a privacy concern.

✔ **Answer:** HTTPS encrypts HTTP traffic inside TLS. An application proxy that receives HTTPS traffic sees only ciphertext — it cannot inspect the HTTP request or response content. To inspect HTTPS, the proxy must perform **TLS interception (SSL inspection):**
1. The proxy terminates the TLS connection from the client, presenting its own certificate (signed by an internal CA pre-installed in client browsers)
2. The proxy decrypts and inspects the HTTP content
3. The proxy initiates a new TLS connection to the real server

**Privacy concern:** The proxy now has **full plaintext access** to all HTTPS traffic — including passwords, banking information, personal communications, and medical records. Employees using corporate proxies with TLS interception have no end-to-end encryption privacy. This is acceptable in corporate environments with proper disclosure, but controversial in consumer/personal settings. Additionally, the fake certificate chain means the user's browser shows the proxy's certificate rather than the real server's certificate — breaking the security model users rely on.

---

**[Fill in the Blank]** In an application proxy architecture, the client's TCP connection terminates at the ________, which then initiates a separate connection to the ________ server, enabling ________ layer inspection.

✔ **Answer:** Proxy; destination (real/upstream); application (Layer 7).

---

---

# SLIDE 7 — Stateful Filtering Diagram and Connection Context

> *"Stateful Filtering — Keep track of client-server sessions"*

**Slide Content:**
- Stateful packet filters examine each IP packet **in context**
- Keep track of **client-server sessions**
- Check each packet **validly belongs to one** session
- Better able to detect **bogus packets out of context**
- Connection state table maintained to understand context of packets

*(This slide reinforces the state-table mechanism with focus on the session tracking diagram — see the detailed state table workflow in Slide 5)*

---

## 📖 Slide 7 Discussion — State Table Lifecycle and Edge Cases

### 💡 State Table Entry Lifecycle — The Full Picture

Understanding when entries are **created, updated, and removed** is essential for exam questions about stateful firewalls:

| Event | Effect on State Table |
|---|---|
| **Outbound TCP SYN sent** | New entry created: state = SYN_SENT; timeout = 60 seconds (half-open timeout) |
| **Inbound TCP SYN-ACK received** (matching entry) | Entry updated: state = ESTABLISHED; timeout = 3600 seconds (idle timeout) |
| **Inbound TCP SYN-ACK received** (no matching entry) | DROP — unsolicited inbound connection attempt |
| **TCP FIN exchange completes** | Entry marked: state = TIME_WAIT; purged after 60–120 seconds |
| **TCP RST received** (matching entry) | Entry immediately purged |
| **TCP RST received** (no matching entry) | DROP — forged RST (TCP reset attack) |
| **Entry timeout reached** (no traffic) | Entry purged — next packet in this "connection" will have no matching entry |
| **Inbound ACK, no matching entry** | DROP — bogus packet out of context |

### ⚠️ Security Implications of Timeouts

Timeouts are a **security parameter**, not just a performance setting:

- **Too short:** Legitimate long-running connections (SSH sessions, large file transfers) may be dropped mid-session when the state entry times out
- **Too long:** An attacker can keep a malicious "connection" alive by sending occasional packets — the state entry persists, keeping the path open
- **SYN timeout specifically:** Half-open connections (SYN sent, SYN-ACK not yet received) must be timed out quickly to prevent state table exhaustion from SYN flood attacks

---

## 🧪 Practice Questions — Slide 7

**[Short Answer]** An internal host has an established HTTPS connection to an external server. The firewall is rebooted and loses its state table. What happens to the existing HTTPS connection, and why?

✔ **Answer:** After the reboot, the state table is empty. When the next packet arrives from either direction (e.g., the server sends an HTTP response), the firewall has **no state table entry** for this connection. The packet arrives as "context-free" — an ACK or data packet with no known corresponding state. The firewall's behaviour depends on policy:
- If the firewall has a strict "no entry = drop" rule for inbound packets (default deny), it drops the server's response → the connection breaks
- The client may experience a timeout or TCP RST (if the firewall sends a RST)

This is why **firewall failover and high-availability** configurations must handle state table synchronisation between active and standby firewalls — losing the state table means dropping all existing connections.

---

**[True/False]** A stateful firewall creates a state table entry for every packet it processes, including ICMP ping packets.

✔ **Answer: True (partially).** Stateful firewalls track ICMP using a **pseudo-state** model: when an outbound ICMP Echo Request (ping) is sent, the firewall records the source IP, destination IP, ICMP identifier, and sequence number with a short timeout. Inbound ICMP Echo Replies matching this record are allowed; unsolicited ICMP Echos from the Internet are not. However, the "state" for ICMP is simpler than TCP (no connection establishment/teardown) — it is strictly timeout-based.

---

---

# SLIDE 8 — Application-Level Filtering and Web Proxy Details

> *"Application-Level Filtering: Has full access to protocol — validates requests as legal"*

**Slide Content:**
- Has **full access to the protocol**
  - User requests service from proxy
  - Proxy **validates** request as legal
  - Then actions request and returns result to user
- Need separate proxies for each service:
  - **WAF** (Web Application Firewall)
  - **SMTP** (E-Mail Firewall)
  - **DNS** (Domain Name System)
  - Custom services generally not supported
- **Proxy also used to evade egress filtering:**
  - If a firewall conducts packet filtering based on destination address, browsing via a **web proxy** changes the destination address to the proxy server — defeating the packet filtering rules
- **Anonymising Proxy:**
  - One can also use proxies to **hide the origin** of a network request from servers
  - Servers only see traffic after it passes through proxies → source IP will be the proxy's

---

## 📌 Key Concepts at a Glance

- Proxies are a **double-edged sword**: organisations use them to inspect and control outbound traffic, but attackers use them to bypass firewall destination-IP-based filtering
- An **anonymising proxy** completely hides the original client's IP from the destination server — the server only ever sees the proxy's IP
- This same anonymising property is exploited by both privacy-conscious users and attackers trying to evade attribution
- **Chain of proxies** (like Tor's onion routing) makes attribution increasingly difficult

---

## 📖 Slide 8 Discussion

### 🔴 WHY — Proxies as Both Defence and Attack Tools

The same architectural property that makes a proxy powerful for security — it sits in the middle of a connection and can inspect/modify/block traffic — also makes it a powerful tool for evasion.

**Defensive use (corporate forward proxy):**
- An organisation configures all outbound HTTP/HTTPS through a central proxy
- The proxy enforces acceptable use policies (no streaming, no social media on work systems)
- The proxy scans downloads for malware
- The proxy logs all web activity for audit purposes

**Offensive use (proxy evasion):**
- A company's firewall blocks direct access to `streaming-site.com` based on its IP address
- An employee accesses `corporate-proxy.com/sites/streaming-site.com` — the firewall sees a connection to `corporate-proxy.com` (allowed) rather than `streaming-site.com` (blocked)
- The external proxy fetches `streaming-site.com` on the employee's behalf and returns the content

The firewall's destination-IP-based rule is defeated because the packet never shows the blocked destination IP.

### 🟡 HOW — Proxy Evasion of Egress Filtering

| Scenario | Without Proxy | With External Proxy |
|---|---|---|
| **Packet destination as seen by firewall** | `streaming-site.com:443` (blocked) | `proxy-server.com:443` (allowed) |
| **What the firewall allows** | ❌ DENY (blocked domain) | ✅ ALLOW (proxy domain) |
| **What the user accesses** | Blocked | Full access via proxy |
| **Firewall rule bypassed** | N/A | Destination-IP-based DENY rule |

This is precisely why **application/proxy firewalls** that can inspect the HTTP `Host:` header (for HTTP) or SNI (for HTTPS) are needed to enforce domain-based policies — packet filters checking only the destination IP are trivially bypassed by any intermediate proxy.

### 🟢 WHAT — Anonymising Proxies and Privacy

When a client accesses a resource via an anonymising proxy:

```
Client (real IP: 192.168.1.10)
    ↓ sends request to proxy
Proxy (IP: 203.0.113.50)
    ↓ forwards request to server
Server (ip: 198.51.100.20)
    → server logs show: request from 203.0.113.50
    → server NEVER sees 192.168.1.10
```

From the server's perspective, all requests from all clients behind this proxy appear to originate from `203.0.113.50`. The server cannot distinguish individual clients, cannot attribute requests to specific users, and cannot block a specific client without blocking the entire proxy (which would affect all users behind it).

### 💡 The Proxy Paradox in Security Policy

| Proxy Role | Used By | Goal | Security Impact |
|---|---|---|---|
| **Corporate forward proxy** | Security team | Inspect, log, and filter all employee web traffic | Increases security (visibility + control) |
| **External web proxy (evasion)** | Employees bypassing policy | Access blocked sites | Decreases security (evades controls) |
| **Anonymising proxy** | Privacy advocates, journalists | Hide identity from tracking | Neutral (depends on use) |
| **Attacker-controlled proxy** | Attackers covering tracks | Evade attribution, bypass IP blocks | Decreases security |

The firewall's response to proxy evasion must operate at the **application layer** — packet/stateful filtering at L3/L4 cannot solve a problem that exists at L7.

---

## 🧪 Practice Questions — Slide 8

**[Multiple Choice]** A corporate firewall blocks direct access to social media sites by their IP addresses. An employee accesses them through an external web proxy instead. What does the firewall observe, and why does it allow the traffic?
- A) The firewall sees the social media site's IP and blocks it anyway
- B) The firewall sees the external proxy's IP as the destination, which is not on the block list, so it allows the traffic
- C) The firewall recognises the proxy evasion and blocks both the proxy and the social media site
- D) The firewall cannot observe any traffic because the proxy uses TLS

✔ **Answer: B)** The packet from the employee's browser is addressed to the **external proxy server's IP address**, not to the social media site. The firewall's block rule is based on the social media IP — the external proxy's IP is not on the block list, so the rule is never matched, and the traffic is allowed. The proxy then fetches the social media content on the employee's behalf.

---

**[True/False]** An anonymising proxy effectively hides the original client's IP address from the destination server.

✔ **Answer: True.** When traffic flows through an anonymising proxy, the destination server only sees the proxy's IP address as the source of the connection. The original client's IP is hidden. This is the foundational mechanism used in privacy tools, Tor, and also exploited by attackers to evade IP-based detection and attribution.

---

**[Short Answer]** Why is a destination-IP-based egress filtering policy insufficient to prevent employees from accessing blocked websites? What is a more effective control?

✔ **Answer:** Destination-IP-based filtering is easily bypassed by using a web proxy: the employee's traffic is directed to the proxy's IP (not the blocked site's IP), which the firewall allows. The proxy then fetches the blocked content.

More effective controls:
1. **Application-layer proxy (forward proxy):** Route all web traffic through a corporate proxy that inspects HTTP `Host:` headers and HTTPS SNI to apply domain-based policies — the blocked site's domain appears in the header even when accessed via an external proxy
2. **DNS filtering:** Resolve blocked domain names to a block page using a controlled DNS resolver — though this can also be bypassed with custom DNS
3. **URL categorisation (NGFW):** Next-generation firewalls can identify content categories (social media, streaming) by domain name in application-layer inspection, not just by IP address

---

---

# SLIDE 9 — Evading Firewalls: SSH Tunneling and VPN

> *"Evading Firewalls: SSH Tunneling, Dynamic Port Forwarding, VPN"*

**Slide Content:**
- **SSH Tunneling:**
  - SSH creates an encrypted tunnel between a client inside the network and a server outside
  - IP packets can be sent using this tunnel
  - Since the tunnel traffic is encrypted, firewalls are **not able to see what is inside** and cannot conduct filtering
- **Dynamic Port Forwarding:**
  - SSH SOCKS proxy — any TCP traffic can be forwarded through the SSH tunnel
- **Virtual Private Network (VPN):**
  - Using VPN, one can create a tunnel between a computer inside the network and another outside
  - IP packets can be sent using this tunnel
  - Since the tunnel traffic is encrypted, firewalls **cannot see inside** and cannot conduct filtering

---

## 📌 Key Concepts at a Glance

- Encrypted tunnels are **firewall-opaque**: a packet filter or stateful firewall sees only the outer tunnel packets (SSH to port 22, or OpenVPN on UDP 1194) — the tunnelled content is invisible
- This is the fundamental tension in network security: encryption provides confidentiality, but it also **defeats inspection-based security controls**
- **SSH tunneling** is the most common technique for employees to bypass corporate web filtering — it requires only an SSH server on port 22 (or port 443, which is rarely blocked) outside the corporate network
- The defence against tunnel-based evasion requires either: blocking the tunnelling protocol at the perimeter (block port 22 outbound) or using **deep packet inspection (DPI)** to identify SSH traffic masquerading as HTTPS

---

## 📖 Slide 9 Discussion

### 🔴 WHY — Encryption vs. Inspection: The Fundamental Tension

Modern security best practice says: **encrypt everything**. But from a firewall's perspective, encryption means the tunnel's payload is opaque. A stateful firewall that allows outbound SSH connections (for legitimate admin use) has no way to determine whether that SSH connection is:
1. An admin legitimately managing a server
2. An employee tunnelling all their web browsing to bypass the web filter
3. An attacker who compromised an internal host and is using SSH to exfiltrate data

This is not a flaw in SSH — it is the correct design (confidentiality). But it means that **a firewall must decide at the policy level whether to allow or deny the tunnelling protocol itself**, because it cannot inspect inside.

### 🟡 HOW — SSH Tunneling in Detail

**SSH Local Port Forwarding:**
```
Internal Host                    Firewall            External SSH Server
  192.168.1.10                                          203.0.113.50
      │
      │  ssh -L 8080:blocked-site.com:80 user@203.0.113.50
      ↓
  Browser → 127.0.0.1:8080 ──────── SSH tunnel ──────► 203.0.113.50
                                                             │
                                                             ↓
                                                    blocked-site.com:80
```

The firewall sees:
- Outbound SSH connection from 192.168.1.10 → 203.0.113.50:22 ✅ ALLOWED (SSH is permitted)
- Encrypted SSH traffic ← → 203.0.113.50:22

The firewall does NOT see:
- The browser's request to `blocked-site.com` (it is tunnelled inside the SSH connection)
- Any indication of what the SSH session is being used for

**SSH Dynamic Port Forwarding (SOCKS Proxy):**
```
ssh -D 1080 user@external-ssh-server.com
```
This turns the SSH session into a **SOCKS proxy** — the browser (or any application) can be configured to use `localhost:1080` as a SOCKS proxy, and all traffic is forwarded through the SSH tunnel to the external server, which then forwards it to the actual destination.

### 🟢 WHAT — Firewall Defence Against Tunneling

| Defence | Mechanism | Defeats | Limitations |
|---|---|---|---|
| **Block SSH outbound** | Deny TCP/UDP port 22 outbound in firewall ACL | Stops port-22 SSH tunnels | Attacker/employee can run SSH on port 443 or 80 — much harder to block |
| **Deep Packet Inspection (DPI)** | NGFW identifies SSH protocol by traffic pattern (banner, key exchange), not just port number | Identifies SSH even on port 443 | CPU-intensive; must handle TLS-within-SSH edge cases |
| **VPN-only outbound policy** | Only allow outbound VPN traffic via corporate VPN; block all other tunnelling | Forces all traffic through corporate inspection point | Requires strong endpoint management; users may install personal VPN clients |
| **Egress filtering on all ports** | Default deny outbound; only allow specific service ports | Limits which protocols can be tunnelled | Balance between security and operational flexibility |
| **Application-layer proxy** | Force all web traffic through corporate proxy that breaks SSL and inspects | Sees inside HTTPS; identifies proxy evasion | Privacy/legal concerns; certificate management overhead |

### 💡 The Dual Role of VPNs

VPNs are simultaneously:
1. **A legitimate security tool**: corporations use VPNs to provide secure remote access for employees; IPSec VPN tunnels protect branch office connectivity
2. **A firewall evasion tool**: an employee running a personal VPN (e.g., NordVPN, ProtonVPN) on their corporate laptop routes all traffic through the VPN provider's servers — the corporate firewall sees only encrypted traffic to the VPN server and cannot inspect or filter any content

The distinction is **who controls the VPN endpoint**: corporate VPNs route traffic back through corporate inspection infrastructure; personal VPNs route traffic to external infrastructure that the corporation cannot inspect.

---

## 🧪 Practice Questions — Slide 9

**[Multiple Choice]** A corporate firewall blocks access to social media sites. An employee uses SSH dynamic port forwarding (`ssh -D 1080`) to connect to a personal server and configures their browser to use `localhost:1080` as a SOCKS proxy. What does the firewall observe?
- A) An SSH connection to the employee's personal server; cannot see the web traffic inside
- B) A direct connection to social media sites, which is blocked
- C) Malicious activity and automatically blocks the SSH connection
- D) The SOCKS proxy traffic, which it can inspect and block

✔ **Answer: A)** The firewall sees an outbound SSH connection (TCP port 22) to the employee's personal server. If SSH outbound is not blocked, this connection is allowed. The web traffic (to social media sites) is **encapsulated inside the encrypted SSH tunnel** — the firewall cannot see it and cannot apply content-based filtering rules to it.

---

**[True/False]** A stateful firewall can inspect and filter the contents of an SSH tunnel because it tracks the TCP connection state.

✔ **Answer: False.** A stateful firewall tracks **TCP connection state** (SYN, ESTABLISHED, FIN, etc.) but does **not decrypt or inspect the payload**. Inside an SSH connection, all data is encrypted with the SSH session keys. The stateful firewall can see that a TCP connection exists between two endpoints on port 22, but it cannot see anything about the tunnelled content. Only a DPI/NGFW system that identifies and potentially terminates the SSH session can inspect inside.

---

**[Short Answer]** Explain the fundamental tension between encryption and firewall inspection. Why can't a firewall fully solve this tension?

✔ **Answer:** Encryption provides **confidentiality** — data cannot be read by unauthorised parties. But "unauthorised parties" includes the firewall itself, which needs to read traffic to apply security policies. This creates a fundamental contradiction: **the stronger the encryption, the less visibility the firewall has**. A firewall cannot "solve" this tension because doing so would require breaking encryption — which defeats its security purpose. Practical mitigations all involve trade-offs:
- **SSL/TLS inspection** (break and inspect) — requires decrypting all HTTPS traffic at the proxy, introducing latency, privacy concerns, and certificate management complexity
- **Protocol identification by traffic patterns** (DPI) — identifies what protocol is inside the tunnel without decrypting content, but cannot see the actual data
- **Policy-based blocking** (block all encrypted tunnels) — eliminates evasion but also breaks legitimate encrypted communication

There is no solution that simultaneously preserves strong encryption AND allows full inspection.

---

---

# SLIDE 10 — Firewall Policy: Inbound vs. Outbound Rules

> *"Packet Filters: IP Source/Destination Address, Protocol, Ports, TCP Flags"*

**Slide Content (illustrative firewall rules):**
- **DNS uses port 53** → No incoming port 53 packets except from known trusted servers
- **Telnet uses port 23** → Block all incoming TCP packets with port 23
- Direction matters: inbound vs. outbound rules have different default policies

---

## 📌 Key Concepts at a Glance

- **Inbound rules** (Internet → internal): default deny unless explicitly allowed; expose only what must be public
- **Outbound rules** (internal → Internet): default allow with specific blocks; or controlled through forward proxy
- Both **inbound AND outbound** filtering matter: inbound protects against attacks; outbound limits damage from compromised internal hosts (prevents exfiltration, C2 communication, botnet participation)
- DNS port 53 is a critical example: allowing unrestricted inbound UDP port 53 could be exploited for **DNS amplification attacks** or **DNS tunnelling**

---

## 📖 Slide 10 Discussion

### 🔴 WHY — Why Outbound Filtering Matters As Much As Inbound

Most organisations focus heavily on **inbound** filtering (blocking attackers from outside). But **outbound** filtering is equally important:

1. **Malware C2 communication:** Malware on an infected internal host will attempt to contact a command-and-control (C2) server on the Internet. Outbound filtering can block known-bad IPs/domains, or restrict which protocols/ports are allowed outbound.

2. **Data exfiltration:** A compromised host attempting to send company data out. Outbound DLP (Data Loss Prevention) rules can detect and block large outbound data transfers, transfers to unusual destinations, or specific content patterns.

3. **DNS tunnelling:** Malware can encode data in DNS queries to bypass firewalls that allow DNS (port 53 UDP/TCP) outbound. DNS names can carry encoded data; the responses carry the attacker's replies. Only DNS-aware inspection can detect this.

4. **Botnet participation:** A compromised host could participate in DDoS attacks if unrestricted outbound traffic is allowed. Egress filtering that blocks spoofed source addresses (BCP38) prevents your network from amplifying DDoS attacks.

### 🟡 HOW — DNS Port 53 as a Case Study

Why is DNS port 53 specifically called out?

| DNS Rule | Direction | Purpose | Attack Prevented |
|---|---|---|---|
| **Allow outbound UDP/TCP port 53 to specific trusted DNS servers** | Outbound | Internal hosts can query the corporate/ISP DNS resolver | Limits DNS to known-good resolvers; prevents DNS tunnelling to arbitrary external resolvers |
| **Block outbound UDP/TCP port 53 to all other destinations** | Outbound | Forces all DNS through controlled resolvers | DNS tunnelling to attacker-controlled nameservers |
| **Allow inbound UDP/TCP port 53 from specific trusted DNS servers** | Inbound | DNS responses from the resolver reach the internal host | — |
| **Block all other inbound UDP/TCP port 53** | Inbound | Prevent DNS amplification attack reflections; prevent unsolicited DNS queries to internal hosts | DNS amplification, DNS DDoS |

### 🟢 WHAT — A Complete Example Packet Filter Rule Set

```
RULE SET FOR A SIMPLE CORPORATE NETWORK
==========================================
# Inbound rules (Internet → Internal)
1. DENY  TCP  any      any  internal_net  23          # Block inbound Telnet
2. DENY  TCP  any      any  internal_net  3389        # Block inbound RDP
3. ALLOW TCP  any      any  dmz_webserver 80,443      # Allow HTTP/S to DMZ web server
4. DENY  TCP  any      any  dmz_webserver any         # Block other ports to DMZ web server
5. DENY  any  any      any  internal_net  any         # Block ALL direct inbound to internal

# Outbound rules (Internal → Internet)
6. ALLOW TCP  internal  any  any          80,443       # Allow HTTP/HTTPS outbound
7. ALLOW UDP  internal  any  dns_server   53           # Allow DNS to trusted resolver only
8. DENY  UDP  internal  any  any          53           # Block DNS to other resolvers
9. ALLOW TCP  admins    any  any          22           # Allow SSH outbound for admins only
10. DENY TCP  internal  any  any          22           # Block SSH for non-admins
11. DENY any  internal  any  any          any          # Default deny outbound (except above)

# State rule (stateful firewall addition)
12. ALLOW any — inbound packets matching established state table entry
```

---

## 🧪 Practice Questions — Slide 10

**[Multiple Choice]** Why should a corporate firewall restrict outbound DNS queries to only the corporate DNS resolver, blocking port 53 UDP/TCP to all other destinations?
- A) To reduce DNS lookup latency
- B) To prevent DNS tunnelling (encoding data in DNS queries to external nameservers) and force all DNS through a controlled, logged resolver
- C) DNS is not used outbound, only inbound
- D) To prevent the corporate DNS server from being overloaded

✔ **Answer: B)** Restricting outbound DNS to the corporate resolver prevents two threats: (1) **DNS tunnelling** — an attacker or malware can encode arbitrary data in DNS query names and send it to an attacker-controlled authoritative nameserver; if port 53 outbound is unrestricted, this works. (2) **Policy bypass** — users can use alternative DNS resolvers (e.g., 8.8.8.8) to bypass DNS-based content filtering.

---

**[True/False]** Outbound firewall filtering is less important than inbound filtering because threats always come from outside the network.

✔ **Answer: False.** Outbound filtering is equally critical because: (1) internal hosts can be compromised by malware (phishing, drive-by downloads, USB infection) and need to communicate outbound for C2 and data exfiltration; (2) DNS tunnelling, botnet participation, and data exfiltration all require outbound communication; (3) **BCP38 egress filtering** (blocking outbound packets with spoofed source IPs) prevents your network from being used as an amplifier in DDoS attacks.

---

**[Short Answer]** Describe how DNS tunnelling works and how a firewall can be configured to mitigate it.

✔ **Answer:** **DNS tunnelling** encodes arbitrary data in DNS query hostnames. For example, malware sends DNS queries for hostnames like `aGVsbG8gd29ybGQ.attacker-ns.com` where the subdomain `aGVsbG8gd29ybGQ` is base64-encoded data (e.g., `hello world`). The query is forwarded by the corporate DNS resolver to the attacker's authoritative nameserver, which decodes the data and returns a response (also encoding data in the answer). This creates a bidirectional covert channel over DNS.

**Mitigations:**
1. **Restrict outbound DNS to corporate resolver only** — block port 53 UDP/TCP to all IPs except the trusted resolver(s). This prevents direct DNS queries to attacker-controlled nameservers.
2. **DNS inspection at the resolver** — the corporate resolver can detect anomalous query patterns (very long domain names, high query volume to single domain, non-existent domain responses, unusual record types like NULL records)
3. **Application-layer DNS proxy** — a DNS-aware proxy that validates query/response structure can detect and block tunnelled traffic

---

---

# SLIDE 11 — Firewall in the Broader Security Architecture: DMZ and Placement

> *"Firewall placement: DMZ, Perimeter, Internal segmentation"*

**Slide Content (from lecture context on network architecture):**
- Firewalls are placed at **network boundaries** between zones of different trust levels
- The **DMZ (Demilitarized Zone):** a semi-trusted zone between the Internet and the internal network where publicly accessible servers live
- **Two-firewall DMZ architecture:** outer firewall faces the Internet; inner firewall faces the internal network; DMZ sits between them
- **Firewall policies in a DMZ:**
  - Internet → DMZ: allow HTTP/HTTPS to web servers; block everything else
  - DMZ → Internet: allow specific outbound (SMTP for email); block everything else
  - DMZ → Internal: block all (DMZ servers should not initiate connections to internal systems)
  - Internal → DMZ: allow administrative access (SSH) from specific admin hosts only

---

## 📌 Key Concepts at a Glance

- The DMZ is a **buffer zone**: if a DMZ server is compromised, the inner firewall prevents lateral movement to the internal network
- **Defence in depth via firewall placement**: even if the outer firewall is bypassed, the inner firewall provides a second layer of protection
- The **zero trust** architecture extends this concept: even internal hosts are not trusted; every access requires authentication regardless of network location

---

## 📖 Slide 11 Discussion

### 🔴 WHY — Why a DMZ?

A web server must be reachable from the Internet by definition. But it also needs to talk to backend databases and application servers that contain sensitive data. Without a DMZ:

- **Scenario A (no separation):** Web server and database on the same "internal" network. If the web server is compromised, the attacker has direct access to the database. **Catastrophic.**
- **Scenario B (full separation without DMZ):** Web server on the Internet, internal network completely isolated. Web server can't reach the database. **Broken application.**
- **Scenario C (DMZ):** Web server in DMZ; database on internal network. Web server can reach database on specific ports. If web server is compromised, inner firewall blocks lateral movement to the rest of the internal network. **Correct architecture.**

### 🟡 HOW — Two-Firewall DMZ Architecture

```
Internet
   │
[Outer Firewall]  ← Policy: Allow HTTP/443 inbound to DMZ; deny everything else
   │
  DMZ
   │ Web Server (192.168.2.10)
   │ Mail Server (192.168.2.20)
   │ DNS Server (192.168.2.30)
[Inner Firewall]  ← Policy: Block all DMZ→Internal except DB queries from web server on port 5432
   │
Internal Network
   │ Database Server (10.0.0.10)
   │ File Server (10.0.0.20)
   │ Workstations (10.0.0.0/24)
```

**Firewall policies by zone:**

| Traffic Direction | Outer Firewall Policy | Inner Firewall Policy |
|---|---|---|
| Internet → DMZ (web) | ALLOW TCP 80, 443 to web server | DENY (inner FW doesn't see direct Internet traffic) |
| Internet → Internal | DENY all | DENY all |
| DMZ web server → Internal DB | N/A (within DMZ to internal) | ALLOW TCP 5432 from web server only |
| DMZ → Internal (other) | N/A | DENY all |
| Internal → DMZ (admin) | N/A | ALLOW TCP 22 from admin workstations to DMZ servers |
| DMZ → Internet (SMTP email) | ALLOW TCP 25 from mail server | DENY (inner FW doesn't handle this path) |
| Default | DENY | DENY |

### 🎯 Analogy — The Airport Security Zones

- **Internet** = Outside the airport (untrusted, anyone)
- **DMZ** = Airport check-in area (semi-trusted: accessible to the public, but with security checks)
- **Inner firewall** = Security screening checkpoint (only vetted passengers pass)
- **Internal network** = Airside (post-security: restricted to authorised personnel and screened passengers)

You can be in the check-in area (DMZ) without having gone through security (internal network access). Compromising something in the check-in area (DMZ server compromise) does not automatically give you airside access — you still have to pass the screening checkpoint (inner firewall).

---

## 🧪 Practice Questions — Slide 11

**[Multiple Choice]** In a two-firewall DMZ architecture, what is the purpose of the inner firewall?
- A) To protect the DMZ servers from Internet attacks
- B) To prevent compromised DMZ servers from accessing the internal network and to restrict internal→DMZ access to specific administrative connections
- C) To provide a second copy of the outer firewall's rules for redundancy
- D) To encrypt traffic between the DMZ and the internal network

✔ **Answer: B)** The inner firewall's primary job is to prevent a compromised DMZ server from being used as a pivot point to attack the internal network. It enforces: (1) very restricted DMZ→Internal rules (e.g., only database queries from the web server); (2) no general DMZ→Internal connectivity; (3) controlled Internal→DMZ administrative access (SSH from specific admin hosts only).

---

**[Short Answer]** A web server in the DMZ is compromised by an attacker via a SQL injection vulnerability. What does the inner firewall prevent, and what does it NOT prevent?

✔ **Answer:**
**Inner firewall prevents:**
- The attacker from making new TCP connections from the compromised web server to arbitrary internal hosts (the inner firewall blocks all DMZ→Internal connections except specifically allowed ones like DB queries on port 5432)
- The attacker from scanning the internal network directly (ICMP sweeps, port scans to internal IPs are blocked)
- The attacker from stealing files from internal file servers (no DMZ→Internal file-share access)

**Inner firewall does NOT prevent:**
- The attacker from using the web server's **allowed** database connection (port 5432 to the database server) to attack the database — SQL queries from the web server to the DB are allowed by the inner firewall
- The attacker from exfiltrating data via the web server's **outbound Internet access** (if the web server has allowed outbound connections, e.g., for software updates)
- Attacks against the web server itself (the web server is already compromised — the inner firewall can't help with that)

---

---

# Quick Reference Summary

| Concept | What It Is | Key Capability | Key Limitation |
|---|---|---|---|
| **Firewall** | Policy enforcement point at network boundary | Controls what traffic can enter or exit a network | Cannot inspect encrypted tunnels; no protection against insider threats |
| **Default Deny** | Block everything; allow only explicitly permitted traffic | Strongest security posture; minimises attack surface | Requires deliberate configuration of every legitimate traffic type |
| **Default Permit** | Allow everything; block only explicitly prohibited traffic | Easy to configure; unlikely to break legitimate traffic | Weak; attackers exploit any traffic not on the block list |
| **User Control** | Identity-based access control on traffic | Enables role-based network access | Hard to implement at L3/L4; requires identity infrastructure |
| **Service Control** | Port/protocol-based access control | Simple and fast; works at L3/L4 | Cannot distinguish legitimate from malicious traffic on allowed ports |
| **Direction Control** | Inbound vs. outbound initiation control | Prevents unsolicited inbound connections | Stateless filters imperfectly implement this; stateful needed for accuracy |
| **Packet Filter (Stateless)** | Per-packet header inspection only; no state | Fastest; lowest overhead; line-rate capable | No connection context; cannot detect forged TCP ACKs; no payload inspection |
| **Stateful Firewall** | Tracks TCP/UDP connection state | Correctly handles TCP reply traffic; detects bogus out-of-context packets | Cannot inspect application payload; state table vulnerable to exhaustion (SYN flood) |
| **Application/Proxy Firewall** | Terminates connections; L7 payload inspection | Detects SQL injection, XSS, malformed protocols, content policy violations | Protocol-specific (one proxy per protocol); highest overhead; TLS interception needed for HTTPS |
| **Connection State Table** | Firewall memory of all active connections | Enables stateful direction control; detects forged packets | Memory-limited; SYN floods exhaust it; lost on reboot |
| **DMZ** | Semi-trusted network zone between Internet and internal | Limits lateral movement if public-facing server is compromised | Requires two-firewall architecture; inner firewall must be correctly configured |
| **Two-Firewall DMZ** | Outer FW faces Internet; inner FW faces internal | Compromised DMZ server cannot directly attack internal systems | More complex; inner FW rules require careful policy design |
| **SSH Tunneling** | Encrypted tunnel through allowed SSH connections | Legitimate admin use; secure remote access | Firewalls cannot inspect inside; enables firewall evasion by employees/attackers |
| **VPN (Tunnel Mode)** | Encrypted tunnel hiding inner IP header and payload | Legitimate remote access; secure site-to-site links | Firewall-opaque; personal VPNs bypass corporate inspection |
| **Anonymising Proxy** | Proxy that hides client IP from destination | Privacy protection; evading IP-based tracking | Can be used by attackers to evade attribution; bypass IP-based firewall rules |
| **WAF** | Web Application Firewall — reverse proxy for HTTP/HTTPS | Detects SQL injection, XSS, CSRF, malformed HTTP; protects web servers | HTTP/HTTPS only; TLS interception needed for HTTPS; bypassed by obfuscated payloads |
| **Proxy Evasion** | Using external proxy to bypass destination-IP firewall rules | — (attack technique) | Defeated by application-layer proxy that inspects `Host:` header or SNI |
| **DNS Tunneling** | Encoding data in DNS queries to evade content filtering | — (attack technique) | Defeated by restricting DNS outbound to trusted resolver + DNS traffic inspection |
| **ACL** | Ordered list of firewall rules; first match wins | Flexible, expressive policy specification | Rule ordering is security-critical; shadowing errors cause misconfiguration |
| **SYN Flood** | Attack exhausting stateful firewall's state table | — (attack technique) | Mitigated by SYN cookies (encodes state in SYN-ACK sequence number) |

---

# Exam Preparation — Integrative Questions

---

**[Short Answer]** Compare the three types of firewalls (packet filter, stateful, application/proxy) across five dimensions: inspection depth, protocols understood, performance, what it can detect, and what it cannot detect.

✔ **Answer:**

| Dimension | Packet Filter | Stateful | Application/Proxy |
|---|---|---|---|
| **Inspection depth** | L3/L4 headers only | L3/L4 headers + TCP/UDP connection state | L3–L7 including application payload |
| **Protocols understood** | All (IP, TCP, UDP, ICMP) — header level | All + TCP state machine | HTTP, SMTP, DNS, FTP — each requiring a separate proxy |
| **Performance** | Highest (wire-rate capable) | Medium (state table lookup adds overhead) | Lowest (L7 parsing, connection termination, payload inspection) |
| **Can detect** | Port scans, wrong IP/port, TCP SYN initiation | Forged TCP ACKs, unsolicited inbound, TCP RST injection, state table anomalies | SQL injection, XSS, malformed HTTP, malware in email, DNS poisoning response, protocol misuse |
| **Cannot detect** | Forged ACK packets, application attacks, anything in payload | Application-layer attacks (SQL injection, XSS), encrypted tunnel contents | Attacks inside encrypted tunnels (without TLS interception), custom/unknown protocols |

---

**[Short Answer]** An attacker has compromised an internal workstation using a phishing email. Describe what the attacker might try next, and for each step, identify whether and how a firewall would detect or block the activity.

✔ **Answer:**

| Attacker Step | Firewall Response |
|---|---|
| **1. Malware beacons to C2 server on Internet (HTTP to port 80)** | **Stateful/Packet filter:** If C2 IP is unknown, outbound HTTP on port 80 may be ALLOWED (port 80 commonly permitted). Detection requires threat intelligence blocking known C2 IPs. **Application proxy:** Can inspect HTTP headers/content for C2 patterns (anomalous User-Agent, beaconing frequency). |
| **2. C2 via DNS tunnelling** | **Packet filter/Stateful:** Cannot detect — DNS queries look normal. **Application proxy (DNS-aware):** Can detect anomalously long domain names, high query rate, unusual record types → BLOCK. |
| **3. SSH tunnel outbound to attacker's server** | **Packet filter:** If SSH (port 22) outbound is ALLOWED → traffic permitted. If blocked → attacker switches to port 443. **NGFW/DPI:** Can identify SSH protocol even on port 443 by traffic patterns → BLOCK. |
| **4. Lateral movement — scan internal subnets** | **Internal segmentation firewall:** If internal subnets are separated by firewalls (east-west), port scans to other subnets are blocked. Flat internal network = no firewall protection for lateral movement. |
| **5. Exfiltrate data to external server via HTTPS** | **Packet filter/Stateful:** Cannot see inside HTTPS. **Application proxy with TLS inspection:** Decrypts and scans HTTPS content → can detect large data transfers or DLP policy violations → BLOCK. |
| **6. Attempt to connect to internal DB server (10.0.0.10:5432)** | **Inner DMZ firewall:** If workstation is not the authorised web server, the rule `ALLOW TCP 5432 from web_server only` → BLOCK workstation's DB access. |

---

**[Short Answer]** Construct a firewall rule set for a corporate network with the following requirements: (1) Web server in DMZ accessible from Internet on HTTP/HTTPS; (2) Email server in DMZ can send SMTP to Internet; (3) Internal users can browse HTTP/HTTPS; (4) Internal users can send/receive email via SMTP; (5) No direct inbound connections to internal workstations; (6) Admins can SSH to DMZ servers from internal network; (7) Default deny. Write the rules in order and explain the ordering rationale.

✔ **Answer:**

```
OUTER FIREWALL (Internet ↔ DMZ):
Rule 1: ALLOW TCP any → dmz_webserver:80,443         [Internet→DMZ: HTTP/HTTPS to web server]
Rule 2: ALLOW TCP dmz_mailserver:25 → any:25         [DMZ→Internet: Outbound SMTP from mail server]
Rule 3: ALLOW TCP any:25 → dmz_mailserver:25         [Internet→DMZ: Inbound SMTP to mail server]
Rule 4: DENY any → any                               [Default deny: block all other Internet↔DMZ traffic]

INNER FIREWALL (DMZ ↔ Internal):
Rule 5: ALLOW TCP admin_hosts → dmz_servers:22       [Internal admins → DMZ: SSH access]
Rule 6: ALLOW TCP internal → any:80,443              [Internal → Internet via DMZ: HTTP/HTTPS browsing]
Rule 7: ALLOW TCP internal → dmz_mailserver:25,587   [Internal → DMZ mail server: Send email]
Rule 8: ALLOW TCP dmz_mailserver → internal:143,993  [DMZ mail server → Internal: IMAP for user mailboxes]
Rule 9: DENY TCP dmz_net → internal_net              [Block all other DMZ→Internal connections]
Rule 10: DENY any → internal_net                     [Block all other inbound to internal]
Rule 11: DENY any → any                              [Default deny everything else]
```

**Ordering rationale:**
- Specific ALLOW rules appear **before** the catch-all DENY (Rules 1–8 before Rules 9–11)
- The admin SSH rule (Rule 5) is deliberately placed **before** the broader deny rule for DMZ→Internal (Rule 9) because SSH to admin-specific DMZ server IPs is a subset of "DMZ↔Internal" traffic
- Default deny (Rule 11) is always last — it catches all traffic not matched by any prior rule
- Rules protecting the internal network from DMZ (Rules 9–10) appear before the global default (Rule 11)

---

**[Short Answer]** Why is a firewall insufficient as the sole security control, and what other security layers are needed for a comprehensive defence?

✔ **Answer:** A firewall is a perimeter control — it controls traffic at network boundaries, but:

1. **Attacks on allowed services:** A firewall that allows HTTPS (port 443) inbound to a web server cannot stop SQL injection, XSS, or zero-day vulnerabilities in the web application itself. **Solution:** WAF + secure coding + input validation + patching.

2. **Insider threats:** A firewall that blocks external attackers is irrelevant against a malicious or compromised internal employee. **Solution:** IAM (least-privilege access), DLP, UEBA (User/Entity Behaviour Analytics), audit logging.

3. **Encrypted malicious traffic:** Modern malware uses HTTPS for C2; ransomware encrypts exfiltrated data before transmission. A packet/stateful firewall cannot detect this. **Solution:** TLS inspection proxy, endpoint detection (EDR), threat intelligence feeds.

4. **Social engineering / phishing:** A user who clicks a phishing link bypasses all network firewalls. **Solution:** User awareness training, email filtering, multi-factor authentication.

5. **Physical access:** An attacker with physical access to a server bypasses all network controls. **Solution:** Physical security, full-disk encryption, BIOS/firmware security.

6. **Post-breach lateral movement:** Once inside the perimeter (via compromised host), flat internal networks offer no further firewall protection. **Solution:** Network segmentation, east-west firewalls, zero-trust architecture.

A complete security posture uses **defence in depth**: firewall + endpoint security (AV/EDR) + IDS/IPS + strong authentication (MFA) + application security + security monitoring (SIEM) + user training + incident response capability.

---

*CS 448/548 Network Security · Firewalls — Deep-Dive Annotated Study Guide · Spring 2026 · Dr. Lina Pu*
