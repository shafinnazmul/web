# 📘 CS 448/548 — Network Security: Final Exam Study Appendix & Page Map

**Course:** CS 448/548 Network Security (Spring 2026, Dr. Lina Pu)
**Exam:** Final — April 27, 2026 · 8:00-10:00 AM · Closed-book · 120 minutes
**Master Reference:** `00_Lectures_all_merged_compressed.pdf` (601 slides)
[00_Lectures_all_merged_compressed.pdf](./00_Lectures_all_merged_compressed.pdf)


00_Lectures_all_merged_compressed.pdf

> ### How to read this appendix
>
> - **Page numbers** refer to slide positions (1-601) inside `00_Lectures_all_merged_compressed.pdf`. Each slide block in that file = one "page".
> - **Signal badges** reflect what the instructor said in the lecture scripts:
>   - 🔴 **EXPLICIT** - instructor directly said it will be on the exam
>   - 🟠 **STRONG** - emphasized repeatedly, significant class time, or appears in multiple review scripts
>   - 🟡 **MODERATE** - mentioned once or implied via worked examples
> - ⭐ marks topics that appear in *both* lecture slides *and* quiz/past exams.
> - Topic priorities are set primarily by `scriptFinalExamReview-cs548.txt` (highest-priority source), cross-referenced with `scriptMidtermReview-cs548.txt` and `scriptMidTermSolution-cs548.txt`.

-

## 📑 Table of Contents

1. [Exam Strategy Summary](#1-exam-strategy-summary)
2. [Master Lecture-to-Page Map](#2-master-lecture-to-page-map)
3. [Topic Index (Exam Priority Order)](#3-topic-index--exam-priority-order)
4. [Detailed Topic Maps](#4-detailed-topic-maps)
   - [Topic 1: Wireless / Link-Layer Security (WPA2, 802.1X, EAP)](#topic-1--wireless--link-layer-security-wpa2-8021x-eap)
   - [Topic 2: Common Network Attacks](#topic-2--common-network-attacks-tcp--ip--arp--dns)
     - 2a: TCP Attacks
     - 2b: IP / Network-Layer Attacks
     - 2c: ARP (Link-Layer) Attacks
     - 2d: DNS Attacks
   - [Topic 3: Cryptography Foundations](#topic-3--cryptography-foundations-symmetric--asymmetric--hash)
   - [Topic 4: TLS / HTTPS / SSH](#topic-4--tls--https--ssh)
   - [Topic 5: User Authentication (Kerberos, OpenID/OAuth)](#topic-5--user-authentication-kerberos-openidoauth-passwords)
   - [Topic 6: IPsec and VPN](#topic-6--ipsec-and-vpn)
   - [Topic 7: Firewalls](#topic-7--firewalls)
5. [Cross-Topic Themes & Integration Points](#5-cross-topic-themes--integration-points)
6. [Supplementary Resource Map](#6-supplementary-resource-map)

-

## 1. Exam Strategy Summary

The instructor stated verbatim in the final-exam review script:

> *"Our final will be comprehensive... the midterm only covers partial of the chapters... today's lecture, I will mainly cover the materials not tested in the midterm exam."*

### What this means for study prioritization

| Bucket | Content | Source |
|-|-|-|
| **A — NEW material (highest yield)** | Link-layer/wireless security + Common network attacks (TCP, IP, ARP, DNS) | Final Exam Review script; never tested before |
| **B — Midterm material (re-tested)** | Crypto, TLS, User Auth, IPsec, VPN, Firewalls | Midterm Review script + all midterm past exams |
| **C — Integration / "challenge" questions** | Combining across topics (e.g., wireless security built on TLS + crypto certs) | Final Review script explicitly calls these out |

### Question format distribution (per instructor)

Final exam will have ~2× the questions of the midterm: True/False, Single-answer MCQ, Multiple-answer MCQ, Short Answer, and **Challenge questions** (multi-topic). The instructor recommended **bullet-style answers** on short-answer questions for clarity/partial credit.

-

## 2. Master Lecture-to-Page Map

Physical mapping of the 601-slide PDF to the 22 lectures delivered in the semester. Use this for coarse-grained navigation before drilling into a topic.

| PDF Pages | Lecture # | Lecture Title | Covered in |
|-|-|-|-|
| 1 - 27 | L1 | Syllabus & Introduction | - |
| 28 - 53 | L2 | Introduction to Internet & Network Security | Midterm |
| 54 - 82 | L3 | Cryptography Primitives (Symmetric) | Midterm ⭐ |
| 83 - 115 | L4 (pt. 1) | Asymmetric Cryptography | Midterm ⭐ |
| 116 - 134 | L4 (pt. 2) | Asymmetric Cryptography (continued) | Midterm ⭐ |
| 135 - 162 | L5 | Asymmetric Cryptography & Secure Hash | Midterm ⭐ |
| 163 - 181 | L6 | Message Authentication (MAC, HMAC, AES-GCM) | Midterm ⭐ |
| 182 - 206 | L7 | Review of Part I (crypto review) | Midterm |
| 207 - 233 | L8 | Web Browsing Security (TLS) | Midterm ⭐ |
| 234 - 245 | L9 | HTTPS | Midterm |
| 246 - 258 | L10 | SSH | Midterm ⭐ |
| 259 - 291 | L11 | User Authentication (Part 1) | Midterm ⭐ |
| 292 - 342 | L12 | User Authentication Pt. 2 - **Kerberos** | Midterm ⭐⭐ |
| 343 - 354 | L13 | User Authentication (Part 3) | Midterm |
| 355 - 368 | L14 | IP Security (Part 1) | Midterm ⭐ |
| 369 - 396 | L16 (pt. 1) | IP Security (Part 2) | Midterm ⭐ |
| 397 - 434 | L16 (pt. 2) | **Firewalls** | Midterm ⭐ |
| 435 - 464 | L17 | Wireless Security (intro) | **FINAL** 🔴 |
| 465 - 502 | L19 (pt. 1) | IoT Wireless Technologies | Midterm (light) |
| 503 - 540 | L19 (pt. 2) | **IP Attacks & ARP Attacks** | **FINAL** 🔴 |
| 541 - 557 | L20 (pt. 1) | **TCP Attacks** | **FINAL** 🔴 |
| 558 - 578 | L20 (pt. 2) | **Wireless Security (WPA/802.1X/EAP) + Cellular** | **FINAL** 🔴 |
| 579 - 601 | L22 | **DNS Attacks** | **FINAL** 🔴 |

> ⚠️ **Note on lecture numbering:** The course slide deck has some non-contiguous lecture numbers (no L15, no L18, no L21). This appears intentional - some slots were used for quizzes/labs. All 601 slides in the master PDF map cleanly to the above table.

-

## 3. Topic Index - Exam Priority Order

Ranked from highest to lowest expected exam weight based on signal analysis.

| # | Topic | Signal | Why high priority | 📄 Key Pages |
|-|-|-|-|-|
| 1 | **Wireless / Link-Layer Security** (WPA2, 802.1X, EAP, WPA enterprise vs personal) | 🔴 EXPLICIT | Entire new chapter; instructor dedicated most of Final Review script to it | pp. 435-464, 558-578 |
| 2 | **TCP Attacks** (SYN flood, Reset, Session Hijack) | 🔴 EXPLICIT | Called out by name in Final Review script; countermeasures (SYN cookies) emphasized | pp. 541-557 |
| 3 | **DNS Attacks** (DNS spoofing, Kaminsky, DNSSEC) | 🔴 EXPLICIT | Entire dedicated lecture; instructor walked through detailed attack flow | pp. 579-601 |
| 4 | **IP / Network-Layer Attacks** (IP spoofing, DDoS, ICMP attacks) | 🔴 EXPLICIT | Called out with defenses (ingress/egress filtering) | pp. 503-540 |
| 5 | **ARP Spoofing & MITM** | 🔴 EXPLICIT | Part of "common attacks" enumeration; link-layer focus | pp. 531-538 |
| 6 | **Kerberos** (AS/TGS, tickets, authenticator, key types) | 🟠 STRONG | Heavily emphasized in both midterm reviews; likely re-tested | pp. 294-342 |
| 7 | **TLS Handshake & Record Layer** | 🟠 STRONG | Midterm staple; instructor emphasized handshake steps | pp. 207-233 |
| 8 | **Cryptography Foundations** (symmetric, asymmetric, hash, AES-GCM) | 🟠 STRONG | Fundamental building block for everything else | pp. 54-181 |
| 9 | **IPsec / VPN** (AH vs ESP, transport vs tunnel mode) | 🟠 STRONG | Named as re-tested in Final Review script | pp. 355-396 |
| 10 | **Firewalls** (stateless, stateful, application/proxy) | 🟠 STRONG | Named as re-tested; iptables in lab | pp. 397-434 |
| 11 | **SSH & HTTPS** | 🟡 MODERATE | Map to TLS principles | pp. 234-258 |
| 12 | **OpenID Connect & OAuth** | 🟡 MODERATE | "Know services each protocol provides" | pp. 271-291 |

-

## 4. Detailed Topic Maps

Each topic block below is formatted for direct use when building the Section-1-through-5 study-guide blocks per the master prompt.

-

### Topic 1 — Wireless / Link-Layer Security (WPA2, 802.1X, EAP)

[Wireless / Link-Layer Security (WPA2, 802.1X, EAP)](./study_guide_topic1_wireless_security.html)

> **Signal: 🔴 EXPLICIT.** From `scriptFinalExamReview-cs548.txt`:
> *"What will be tested, additionally include the link layer security, which is about the network access control... we introduced the encryption solutions... the security suite... the key management... the encryption, and also the access control, so and also the EAP framework..."*

```
╔════════════════════════════════════════════════════════════════════════════╗
║ TOPIC PAGE INDEX — 00_Lectures_all_merged_compressed.pdf                  ║
╠════════════════════════════════════════════════════════════════════════════╣
║ Sub-topic / Concept                                      │  Page(s)       ║
║ ──────────────────────────────────────────────────────── │ ────────────── ║
║ Why wireless is insecure (broadcast, mobility, etc.)     │  p. 559        ║
║ Wireless security services overview                      │  pp. 441, 560  ║
║ WEP / WPA / WPA2 / WPA3 history & comparison             │  pp. 442-448, 561 ║
║ WEP vulnerabilities                                      │  pp. 441-446   ║
║ WPA2 personal (Pre-Shared Key / PSK)                     │  pp. 448-449, 561, 570 ║
║ WPA2 enterprise (802.1X / EAP)                           │  pp. 448, 451-456, 561-567 ║
║ CCMP / AES-CCMP                                          │  p. 446        ║
║ TKIP                                                     │  pp. 448, 561  ║
║ AES-GCM for link-layer encryption                        │  p. 446        ║
║ Encryption vs Message Authentication on link layer       │  pp. 446-448   ║
║ 802.1X Network Access Control framework                  │  pp. 451-456, 561-567 ║
║ Controlled vs Uncontrolled port concept                  │  pp. 455, 566  ║
║ Access Point (AP) role                                   │  pp. 439-442, 455-456 ║
║ Authentication Server (AS / RADIUS)                      │  pp. 455-456, 566-567 ║
║ SSID broadcasting / hiding                               │  p. 439        ║
║ Probe request / Probe response                           │  pp. 513, 515  ║
║ Association request / response                           │  pp. 439-440, 450 ║
║ Full 802.11 message flow (probe → auth → association)    │  pp. 439-442, 450 ║
║ EAP (Extensible Authentication Protocol) framework       │  pp. 451-452, 458-461, 561-572 ║
║ EAP method: EAP-TLS (mutual cert auth)                   │  pp. 459, 570, 578 ║
║ EAP method: EAP-TTLS / PEAP (server cert + user/pass)    │  pp. 459, 570, 578 ║
║ EDU-ROAM example (AS chaining across institutions)       │  pp. 571-572   ║
║ VLAN / Network Segmentation (defense context)            │  pp. 362, 393, 452, 563 ║
║ DHCP as network-access control                           │  pp. 361, 452, 563, 587 ║
║ Cellular (4G/5G) architecture [LIGHT, may skip]          │  pp. 575-578   ║
╚════════════════════════════════════════════════════════════════════════════╝
```

**Key challenge-question hook** (per script): *"When you read this diagram, you need to think about the TLS... and also think about the TLS part when we introduced the server certificate. This is a good example of what the challenge question in wireless security can be tested — it requires you to link different components."* → **Wireless + TLS + certificates** is a likely combined question.

**Pages for follow-up depth:** entire Lecture 17 (pp. 435-464) and Lecture 20 Part 2 (pp. 558-578).

-

### Topic 2 — Common Network Attacks (TCP / IP / ARP / DNS)

> **Signal: 🔴 EXPLICIT.** From `scriptFinalExamReview-cs548.txt`:
> *"Additional material chapter is the common network attacks. We introduced from top to bottom: TCP attacks, network layer attacks, link layer attacks, and DNS attacks... typically those can be tested in terms of true and false, or multiple choice, or multiple answer questions. But when you review those topics, you also need to think about how they are related to network security / defense / protection mechanisms."*

This is a 4-sub-topic cluster. The instructor emphasized that for every attack you must know: **(1)** the attack mechanism, **(2)** the conditions required for it to succeed (local vs remote attacker), **(3)** the defense / countermeasure.

#### 2a — TCP Attacks

```
╔════════════════════════════════════════════════════════════════════════════╗
║ TOPIC PAGE INDEX — TCP Attacks                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║ Sub-topic / Concept                                      │  Page(s)       ║
║ ──────────────────────────────────────────────────────── │ ────────────── ║
║ TCP 3-way handshake (background)                         │  pp. 547-548   ║
║ SYN flooding attack                                      │  pp. 542, 549, 557 ║
║ SYN cookies (defense)                                    │  pp. 550-551   ║
║ TCP Reset attack                                         │  pp. 542, 552-554, 557 ║
║ Preconditions: source/dest IP+port, valid seq number     │  pp. 552-554   ║
║ Local vs remote attacker difficulty                      │  pp. 552-554   ║
║ TCP Session Hijacking                                    │  pp. 542, 555-556, 557 ║
║ Defense: randomize ISN, randomize source port            │  pp. 551, 554  ║
║ Defense: IPsec encryption to neutralize transport attacks│  pp. 370-371   ║
║ Summary slide                                            │  p. 557        ║
╚════════════════════════════════════════════════════════════════════════════╝
```

#### 2b — IP / Network-Layer Attacks

```
╔════════════════════════════════════════════════════════════════════════════╗
║ TOPIC PAGE INDEX — IP Attacks                                             ║
╠════════════════════════════════════════════════════════════════════════════╣
║ Sub-topic / Concept                                      │  Page(s)       ║
║ ──────────────────────────────────────────────────────── │ ────────────── ║
║ IP address spoofing (mechanism)                          │  pp. 505-512   ║
║ IP spoofing as vehicle for DDoS                          │  pp. 511-512, 521 ║
║ DDoS / DoS attacks (overview)                            │  pp. 511, 521-527 ║
║ Defense: ingress / egress packet filtering               │  pp. 403, 425, 512 ║
║ Defense: randomize TCP sequence number                   │  p. 512        ║
║ ICMP Echo scan / ping scan                               │  pp. 505-506   ║
║ ICMP Destination Unreachable attack                      │  pp. 505-506, 519-523, 528 ║
║ Network segmentation as ICMP-scan defense                │  pp. 362, 393  ║
║ Reconnaissance / port scanning (context)                 │  p. 520        ║
╚════════════════════════════════════════════════════════════════════════════╝
```

#### 2c — ARP (Link-Layer) Attacks

```
╔════════════════════════════════════════════════════════════════════════════╗
║ TOPIC PAGE INDEX — ARP Attacks                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║ Sub-topic / Concept                                      │  Page(s)       ║
║ ──────────────────────────────────────────────────────── │ ────────────── ║
║ ARP purpose: IP ↔ MAC address translation                │  pp. 531-535   ║
║ ARP cache / ARP table                                    │  pp. 531-535   ║
║ ARP spoofing mechanism                                   │  pp. 505, 507, 531-538 ║
║ ARP → Man-in-the-middle attack                           │  pp. 537-538   ║
║ Why ARP attacks persist (cache caching effect)           │  pp. 531-535   ║
╚════════════════════════════════════════════════════════════════════════════╝
```

#### 2d — DNS Attacks

```
╔════════════════════════════════════════════════════════════════════════════╗
║ TOPIC PAGE INDEX — DNS Attacks (Lecture 22, pp. 579-601)                 ║
╠════════════════════════════════════════════════════════════════════════════╣
║ Sub-topic / Concept                                      │  Page(s)       ║
║ ──────────────────────────────────────────────────────── │ ────────────── ║
║ DNS overview                                             │  pp. 580-581   ║
║ DNS domain hierarchy (root, TLD, authoritative)          │  pp. 582, 584, 597 ║
║ DNS query process (recursive vs iterative)               │  pp. 583-586   ║
║ Local DNS files / hosts file                             │  p. 587        ║
║ DNS attacks overview                                     │  p. 588        ║
║ DNS spoofing — LAN (local attacker)                      │  p. 589        ║
║ Remote DNS Cache Poisoning                               │  pp. 590-591   ║
║ DNS Packet structure (transaction ID, port)              │  pp. 590-591   ║
║ Kaminsky attack (mechanism + sample)                     │  pp. 592-593   ║
║ Defense — Protect DNS Cache Poisoning (overview)         │  p. 594        ║
║ DNSSEC (digital-signature-based protection)              │  pp. 595, 597  ║
║ DNS over TLS/SSL                                         │  p. 596        ║
║ DNSSEC vs TLS/SSL (chain-of-trust comparison)            │  p. 597        ║
║ DoS on DNS servers                                       │  pp. 598-601   ║
║ DoS on root servers                                      │  p. 599        ║
║ DoS on TLD servers                                       │  p. 600        ║
║ DoS on authoritative / nameservers of a zone             │  p. 601        ║
╚════════════════════════════════════════════════════════════════════════════╝
```

-

### Topic 3 — Cryptography Foundations (Symmetric, Asymmetric, Hash)

> **Signal: 🟠 STRONG (re-tested material).** From `scriptMidtermReview-cs548.txt`:
> *"Topics... crypto, the first part, basically the symmetric, asymmetric, secure hash... AES in block mode, stream mode, message integrity, message authentication, AES GCM mode."*

```
╔════════════════════════════════════════════════════════════════════════════╗
║ TOPIC PAGE INDEX — Cryptography                                           ║
╠════════════════════════════════════════════════════════════════════════════╣
║ Sub-topic / Concept                                      │  Page(s)       ║
║ ──────────────────────────────────────────────────────── │ ────────────── ║
║ Security objectives (C-I-A & related)                    │  pp. 30-31, 40 ║
║ Symmetric vs Asymmetric cipher overview                  │  pp. 41, 136   ║
║ Cryptography taxonomy summary                            │  pp. 115, 134  ║
║ DES / 3DES                                               │  pp. 41, 53, 55 ║
║ AES (overview, key sizes)                                │  pp. 63-68, 77, 81-82 ║
║ Block cipher concept                                     │  pp. 41, 49-52, 70-76 ║
║ Stream cipher concept                                    │  pp. 41, 49, 77-82 ║
║ Block mode: ECB                                          │  pp. 70-72, 75 ║
║ Block mode: CBC                                          │  pp. 70, 73-76 ║
║ Counter (CTR) mode / Stream server mode                  │  pp. 70, 77, 82, 170, 181 ║
║ Initialization Vector (IV)                               │  pp. 76, 158, 165, 231, 232 ║
║ Asymmetric: RSA                                          │  pp. 83-95, 98-101 ║
║ Asymmetric: Diffie-Hellman (DH / DHE / ECDHE)            │  pp. 84, 94-98, 101-103, 113-115, 122-123 ║
║ Elliptic Curve Cryptography (ECC)                        │  pp. 94, 101, 115, 134, 137, 144, 152 ║
║ Ephemeral keys                                           │  pp. 101, 122-123, 192, 231, 449 ║
║ Public-key certificate                                   │  pp. 104, 128, 145, 193, 262-263, 327 ║
║ X.509 certificate                                        │  pp. 128, 145, 344, 396 ║
║ Certificate Authority (CA) & chain of trust              │  pp. 106, 110, 130-131, 151, 230, 240-244 ║
║ Secure hash (SHA family)                                 │  pp. 135-137, 152-157, 160 ║
║ Hash properties                                          │  pp. 152-157  ║
║ Digital signature                                        │  pp. 94, 102-104, 110, 114, 120, 126-128 ║
║ Message Authentication Code (MAC / HMAC)                 │  pp. 172, 174, 177-180, 201 ║
║ AES-GCM mode (encryption + MAC together) ⭐              │  pp. 181, 189, 202, 392 ║
║ Review summary (Part I)                                  │  pp. 182-206   ║
╚════════════════════════════════════════════════════════════════════════════╝
```

**Exam-intelligence note:** AES-GCM is the **integrated primitive** that shows up repeatedly across TLS (p. 181), IPsec (p. 392), wireless (p. 446) — a classic challenge-question integration point.

-

### Topic 4 — TLS / HTTPS / SSH

> **Signal: 🟠 STRONG (re-tested).** From `scriptMidtermReview-cs548.txt`:
> *"TLS... you need to know how TLS is implemented, what security services are provided, the handshakes, different steps, purpose of each step, HTTPS is HTTP over TLS, SSH security services implementation..."*

```
╔════════════════════════════════════════════════════════════════════════════╗
║ TOPIC PAGE INDEX — TLS / HTTPS / SSH                                      ║
╠════════════════════════════════════════════════════════════════════════════╣
║ Sub-topic / Concept                                      │  Page(s)       ║
║ ──────────────────────────────────────────────────────── │ ────────────── ║
║ TLS protocol stack (handshake + record layer)            │  pp. 215, 227-228, 238 ║
║ TLS security services                                    │  pp. 215, 238  ║
║ TLS Handshake Protocol (overview)                        │  pp. 215, 226-229, 233 ║
║ ClientHello                                              │  pp. 230, 232, 237, 240 ║
║ ServerHello                                              │  pp. 221-223, 230, 232, 237, 240 ║
║ Server Certificate (step 5)                              │  pp. 230, 240  ║
║ Key exchange in TLS (ECDHE)                              │  pp. 230, 240-241 ║
║ Cipher suite negotiation                                 │  pp. 230, 240  ║
║ Handshake Finished (MAC over handshake)                  │  pp. 227-228   ║
║ TLS Record Layer (encryption + MAC)                      │  pp. 215, 227-228, 238, 241 ║
║ What TLS encrypts vs leaves in plaintext (IP/TCP)        │  pp. 227-228, 238 ║
║ HTTPS = HTTP over TLS (port 443)                         │  pp. 224-226, 233 ║
║ SSH overview                                             │  pp. 246-258   ║
║ SSH handshake (TLS-similar)                              │  pp. 248-253, 256-257 ║
║ SSH known-hosts (public key saved locally)               │  pp. 248-253   ║
║ SSH as example challenge question (protocol mapping)     │  pp. 248-253   ║
╚════════════════════════════════════════════════════════════════════════════╝
```

-

### Topic 5 — User Authentication (Kerberos, OpenID/OAuth, Passwords)

> **Signal: 🟠 STRONG (Kerberos especially).** From `scriptMidtermReview-cs548.txt`:
> *"For Kerberos, you will need to understand why we have AS, TGS, service-server separate... what are long-term keys, what are short-term keys... ticket, authenticator, purpose of the authenticator, mutual authentication..."*

```
╔════════════════════════════════════════════════════════════════════════════╗
║ TOPIC PAGE INDEX — User Authentication                                    ║
╠════════════════════════════════════════════════════════════════════════════╣
║ Sub-topic / Concept                                      │  Page(s)       ║
║ ──────────────────────────────────────────────────────── │ ────────────── ║
║ Authentication vs Authorization                          │  pp. 262-265, 271 ║
║ Password-based authentication                            │  pp. 269, 279, 286 ║
║ Two-factor authentication                                │  pp. 267, 271, 294, 297, 344 ║
║ Public-key authentication (via certificate vs known host)│  pp. 265-271   ║
║ OpenID Connect (ID token / SSO)                          │  pp. 271-291   ║
║ OAuth 2.0 (access token)                                 │  pp. 271-291   ║
║ OpenID vs OAuth difference                               │  pp. 271-291   ║
║ Single Sign-On (SSO)                                     │  pp. 272-285   ║
║ Kerberos overview (symmetric-only)                       │  pp. 294, 298-299 ║
║ Kerberos AS (Authentication Server)                      │  pp. 303-310, 325 ║
║ Kerberos TGS (Ticket Granting Server)                    │  pp. 302-308, 316-326 ║
║ Kerberos V (Service Server)                              │  pp. 303-310   ║
║ Why AS / TGS / V are separated                           │  pp. 302-310   ║
║ Long-term keys (K_C, K_TGS, K_V)                         │  pp. 306-310   ║
║ Short-term / session keys (K_C,TGS; K_C,V)               │  pp. 306-310   ║
║ Ticket (what's inside, encrypted by which key)           │  pp. 310, 319-322 ║
║ Authenticator (purpose, mutual auth)                     │  pp. 310, 319-322, 348 ║
║ Implicit vs Explicit authentication                      │  pp. 319-322   ║
║ Kerberos realm                                           │  pp. 312, 325, 350 ║
║ KDC                                                      │  pp. 302-310, 345 ║
║ Simplified Kerberos-based auth (with security flaws)     │  pp. 313-342   ║
║ Summary table of Kerberos messages                       │  pp. 310, 318, 348 ║
╚════════════════════════════════════════════════════════════════════════════╝
```

> ⚠️ Instructor's hint: *"Given a key, you will need to know: is this a long-term key or a session key? For each piece of key, who knows this key, who doesn't know this key?"* — expect key-identification questions.

-

### Topic 6 — IPsec and VPN

> **Signal: 🟠 STRONG.** From `scriptMidtermReview-cs548.txt`:
> *"You need to understand what security services provided by IPsec... the two different modes: transport mode and tunnel mode... what's the difference? Transport mode: IP addresses are NOT encrypted. Tunnel mode: inner IP is encrypted."*

```
╔════════════════════════════════════════════════════════════════════════════╗
║ TOPIC PAGE INDEX — IPsec & VPN                                            ║
╠════════════════════════════════════════════════════════════════════════════╣
║ Sub-topic / Concept                                      │  Page(s)       ║
║ ──────────────────────────────────────────────────────── │ ────────────── ║
║ IPsec overview & security services                       │  pp. 370-372, 386-389 ║
║ IPsec benefits vs TLS (Layer 3, transparent to apps)     │  pp. 370-373   ║
║ IPsec applications (VPN, branch office, remote access)   │  pp. 371, 389-391 ║
║ IPsec AH (Authentication Header) — auth only             │  pp. 375, 378-389 ║
║ IPsec ESP (Encapsulating Security Payload) — enc + MAC   │  pp. 375-389   ║
║ Security Association (SA)                                │  pp. 375-381, 387-389 ║
║ Security Association Database / SPI                      │  pp. 375-381, 395 ║
║ Security Policy Database                                 │  pp. 375-381   ║
║ Transport mode (IP header visible)                       │  pp. 384, 386-388 ║
║ Tunnel mode (inner IP encrypted → traffic-flow conf.)    │  pp. 371, 387-388 ║
║ Anti-replay (sequence number)                            │  pp. 378-381, 395 ║
║ Data origin authentication                               │  pp. 175, 370, 379-381, 451 ║
║ Limited traffic flow confidentiality                     │  pp. 370-371, 387-388 ║
║ Key exchange in IPsec (IKE / DHE)                        │  pp. 386-389   ║
║ AES-GCM in IPsec                                         │  p. 392        ║
║ VPN overview                                             │  pp. 356-357, 368-374, 389-391 ║
║ VPN implementations (TLS-based, IPsec-based)             │  pp. 389-391, 427 ║
╚════════════════════════════════════════════════════════════════════════════╝
```

-

### Topic 7 — Firewalls

> **Signal: 🟠 STRONG.** From `scriptMidtermReview-cs548.txt`:
> *"Three types of firewall — stateless, stateful, and application / proxy-based firewall. You need to know the features of each firewall, and how it is implemented."*

```
╔════════════════════════════════════════════════════════════════════════════╗
║ TOPIC PAGE INDEX — Firewalls                                              ║
╠════════════════════════════════════════════════════════════════════════════╣
║ Sub-topic / Concept                                      │  Page(s)       ║
║ ──────────────────────────────────────────────────────── │ ────────────── ║
║ What is a firewall                                       │  pp. 397-402   ║
║ Firewall outline                                         │  p. 398        ║
║ Stateless (packet-filter) firewall                       │  pp. 405, 531  ║
║ Stateful firewall                                        │  pp. 404, 406, 414, 419-421, 434 ║
║ Application / Proxy firewall                             │  pp. 404, 407, 422-425, 432, 434 ║
║ Building a simple firewall with Netfilter                │  pp. 409-411   ║
║ iptables in Linux                                        │  pp. 398, 409, 411, 413-414, 434 ║
║ Ingress / Egress filtering                               │  pp. 403, 425, 512 ║
║ Evading firewalls                                        │  pp. 398, 429-434 ║
╚════════════════════════════════════════════════════════════════════════════╝
```

-

## 5. Cross-Topic Themes & Integration Points

These are the most likely **challenge-question** / multi-topic integration hooks. The instructor explicitly said challenge questions "test multiple combined related techniques."

| # | Integration Theme | Topics Combined | 📄 Anchor Pages |
|-|-|-|-|
| 1 | **Wireless-EAP-TLS challenge** — map 802.1X/EAP-TLS onto TLS handshake & public-key certificates | Wireless + TLS + Crypto-certs | pp. 451-460, 227-230, 128-145 |
| 2 | **"Defense stack" question** — given an attack, name the counter-measure at each layer (link / network / transport) | All attacks + TLS + IPsec + WPA2 | pp. 505-540, 370-395, 558-578 |
| 3 | **Kerberos key-identification** — given a key, identify long-term vs session, and which entities know it | Crypto (symmetric) + Kerberos | pp. 306-322 |
| 4 | **TLS vs IPsec vs DNSSEC** — chain-of-trust comparison (CA hierarchy vs DNS zone hierarchy) | TLS + IPsec + DNS Attacks | pp. 240-244, 595-597 |
| 5 | **AES-GCM everywhere** — identify the same primitive across TLS record layer, IPsec ESP, WPA2 CCMP/GCM | Crypto + TLS + IPsec + Wireless | pp. 181, 392, 446 |
| 6 | **Local vs Remote attacker difficulty** — why spoofing/hijacking is harder remotely (random ISN, random port, random DNS transaction ID) | TCP + IP + DNS attacks | pp. 552-554, 512, 590-592 |

-

## 6. Supplementary Resource Map

These files were not used for primary page-referencing (the master PDF is authoritative) but provide cross-verification and practice questions.

| File | Role |
|-|-|
| `MergeResult_L02_05.docx` | Text narrative for crypto lectures (Topic 3). Use if a slide's text is too brief. |
| `MergeResult_L06_10.docx` | Text narrative for MAC, TLS, HTTPS, SSH (Topic 4, part of Topic 3). |
| `MergeResult_L11-15.docx` | Text narrative for user authentication & IPsec (Topics 5, 6). |
| `cs548p2.html` | HTML narrative for Lectures 16-24 — covers firewalls, wireless, IoT, attacks, DNS (Topics 1, 2, 7). **Highest supplementary value for the final.** |
| `kerberos_workflow.html` | Kerberos message-exchange walkthrough (Topic 5). |
| `scriptFinalExamReview-cs548.txt` | 🔴 **Primary exam-signal source** (final). |
| `scriptMidtermReview-cs548.txt` | 🟠 Exam-signal source (midterm re-tested). |
| `scriptMidTermSolution-cs548.txt` | 🟡 Reveals what students struggled with. |
| `00_26_exam_Quiz1_5_merged.pdf` | Past quiz questions - question-format practice. |
| `33_exam_exam_solution_01_miderm_2026.pdf` | Midterm 2026 solution (most recent instructor-written answers). |
| `midterm_exam_spring2025.pdf` | Prior-year midterm (question-style reference). |
| `exam_solutions_2022.pdf` | Older prior exam (lower priority). |
| `31_exam_exam_review_01_midterm_2026.pdf` | Midterm review slides (2026 version). |
| `32_exam_exam_review_02_final2026.pdf` | **Final review slides (2026)** - image-PDF; visual structure matches `scriptFinalExamReview-cs548.txt`. |
| `32_exam_exam_review_02_final2025.pdf` | Prior-year final review (cross-reference only). |

-

*End of appendix. Next step in the master-prompt pipeline: use this map to generate the full Section 1-5 study-guide blocks for each of Topics 1-7, starting with the 🔴 EXPLICIT topics.*
