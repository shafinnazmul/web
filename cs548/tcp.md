# TCP Protocol & Attacks — Deep-Dive Annotated Study Guide
**CS 448/548 Network Security · All 5 Sections · Beginner-to-Expert Edition**

---

> **How to use this guide:** Each section header is followed by a workflow table of every atomic action or concept. Below each table, a **Discussion** block explains *why* each design decision was made — not just *what* happens. The guide follows **Simon Sinek's Golden Circle** (🔴 WHY → 🟡 HOW → 🟢 WHAT), progressing from beginner-friendly analogies to expert-level reasoning. Practice questions appear after each major topic. A Quick Reference Summary and Exam Integrative Questions close the guide.

---

## Reading Legend

| Symbol / Label | Meaning |
|---|---|
| `SYN` | Synchronize flag — initiates a TCP connection |
| `SYN-ACK` | Synchronize-Acknowledge — server's reply to SYN |
| `ACK` | Acknowledge flag — confirms receipt of data |
| `FIN` | Finish flag — gracefully closes a connection |
| `RST` | Reset flag — abruptly terminates a connection |
| `SEQ` | Sequence number — tracks byte position in the stream |
| `ACK#` | Acknowledgement number — next expected byte from sender |
| `TCB` | Transmission Control Block — kernel data structure tracking a connection |
| **field** | Protocol field name highlighted for emphasis |
| ⚠️ | Security warning or attack surface |
| 💡 | Design insight |
| 🎯 | Analogy |
| 🔴 | WHY — the motivation |
| 🟡 | HOW — the mechanism |
| 🟢 | WHAT — the observable result |

---

# Section 1 — TCP Protocol Fundamentals
> *What TCP is · Why it exists · How it sits in the network stack*

## Slide 1: TCP Protocol Overview

| Aspect | Detail |
|---|---|
| **Full name** | Transmission Control Protocol |
| **Layer** | Transport Layer (Layer 4 of TCP/IP model) |
| **Sits on top of** | IP (Internet Protocol) at the Network Layer |
| **Primary service** | Reliable, ordered, bidirectional byte-stream between two applications |
| **Counterpart** | UDP — lightweight, unreliable, connectionless (lower overhead) |
| **Use cases** | HTTP/HTTPS, SSH, FTP, SMTP — anything requiring reliability |
| **Non-use cases** | Video streaming, gaming, DNS — where speed > reliability → UDP |

---

## 📖 Section 1 Discussion

### 🔴 WHY — The Core Problem TCP Solves

IP (the layer beneath TCP) is fundamentally unreliable. It delivers packets on a *best-effort* basis — packets can be lost, duplicated, reordered, or corrupted in transit. For many applications (web browsing, file transfer, remote login), this is unacceptable. You cannot browse a website where random HTML fragments go missing.

TCP's entire existence is an answer to one question: **"How do two applications communicate reliably over an unreliable network?"**

### 🟡 HOW — TCP's Design Philosophy

TCP achieves reliability through three foundational mechanisms:

1. **Sequence numbers:** Every byte of data is numbered. The receiver knows exactly which bytes it has received and which are missing.
2. **Acknowledgements:** The receiver explicitly tells the sender which bytes it has received. The sender retransmits anything not acknowledged.
3. **Connection state:** Before any data flows, both sides agree to communicate and synchronize their sequence numbers (the 3-way handshake). This *connection* is a shared state maintained by both endpoints.

### 🟢 WHAT — The Result

TCP provides a **reliable, ordered, bidirectional byte stream** between two sockets. From the application's perspective, data goes in one end and comes out the other end correctly — no missing bytes, no duplicates, in order. The application doesn't need to know about packet loss, reordering, or retransmission. TCP handles it invisibly.

### 🎯 Analogy — Registered Mail vs. Regular Mail

Imagine sending a book by mail, one page at a time:
- **UDP** is like regular mail — cheap, fast, but pages might not arrive, might arrive twice, might arrive out of order.
- **TCP** is like registered mail with delivery confirmation — each page has a number, the recipient signs for each one, you resend any that don't get confirmed. Slower and more expensive, but reliable.

### 💡 TCP vs. UDP — When Does Reliability Matter?

| Application | Protocol | Why |
|---|---|---|
| Web browsing (HTTP/HTTPS) | TCP | A missing HTML chunk breaks the page |
| SSH remote login | TCP | Missing command characters = corrupted shell session |
| Video streaming (YouTube) | UDP | A missing video frame is less bad than buffering to retransmit it |
| Online gaming | UDP | Low latency more important than perfect delivery |
| DNS queries | UDP | Small single-packet queries; retry is cheap |
| File transfer (FTP) | TCP | File corruption is unacceptable |

### 💡 The Security Implication of "Connection State"

TCP maintaining state is what makes it powerful — and vulnerable. Because TCP remembers the state of every connection (sequence numbers, buffer sizes, flags), an attacker who can **predict or observe that state** can:
- Forge packets that appear to belong to a legitimate connection (session hijacking)
- Inject packets that forcibly terminate a connection (reset attacks)
- Exhaust the state storage of a server (SYN flooding)

**All three major TCP attacks in this course exploit the stateful nature of TCP.**

---

## Slide 2: Data Transmission and Buffers

| Concept | Description |
|---|---|
| **Send buffer** | Kernel buffer at sender side — application writes data here; TCP reads and sends |
| **Receive buffer** | Kernel buffer at receiver side — TCP writes incoming data here; application reads |
| **Segment** | Unit of data at the transport layer (TCP header + payload) |
| **Sequence number (SEQ)** | Byte offset of the first data byte in this segment |
| **Acknowledgement number (ACK#)** | Next byte the receiver expects — implicitly acknowledges all prior bytes |
| **Window size** | How many bytes the receiver can accept before requiring an ACK |
| **Full-duplex** | Both sides can send and receive simultaneously — two independent byte streams |

---

## 📖 Section 2 Discussion — Buffers and Sequence Numbers

### 🔴 WHY — Buffers Decouple Application Speed from Network Speed

Applications produce and consume data at their own speed. The network delivers data at its own (variable) speed. Buffers are the bridge: the application writes to the send buffer whenever it wants; TCP drains the send buffer and sends segments according to network conditions. Similarly, TCP fills the receive buffer as segments arrive; the application reads from it when ready.

### 🟡 HOW — Sequence Numbers Track Every Byte

When a TCP connection is established, each side chooses a random **Initial Sequence Number (ISN)**. Every byte of data sent after that is assigned the next sequence number. If the ISN is 1000 and Alice sends 500 bytes:
- First segment: SEQ=1000, data bytes 1000–1499
- Second segment: SEQ=1500, data bytes 1500–…

The receiver's ACK# is always "the next byte I expect." After receiving SEQ=1000 with 500 bytes: ACK#=1500 ("I got bytes up to 1499, send me 1500 next").

### 🎯 Analogy — Numbered Pages in a Book

Imagine sending a book one page at a time with confirmed delivery:
- Each page has a number (sequence number).
- The recipient confirms: "I got pages up to 47, please send 48 next" (acknowledgement number = 48).
- If page 23 is lost, the recipient says "I still need 23" and the sender retransmits only page 23.

### ⚠️ Security Implication — Sequence Number Prediction

The security of TCP connections depends on the sequence numbers being **unpredictable**. If an attacker can predict what sequence numbers will be used in a connection between Alice and Bob, the attacker can inject forged packets that Bob will accept as legitimate from Alice — **without ever being on the network path between them**.

This is why TCP implementations use **random initial sequence numbers**. It's one of the primary defenses against TCP session hijacking.

---

# Section 2 — The TCP 3-Way Handshake
> *Connection establishment · Sequence number synchronization · State machine*

## Slide 3: TCP 3-Way Handshake — Step by Step

| Step | Actor → Actor | Flag | SEQ / ACK# | What Happens | Purpose |
|---|---|---|---|---|---|
| **1. SYN** | Client → Server | `SYN` | SEQ=**x** (random ISN chosen by client) | Client sends a SYN packet with a randomly chosen sequence number x. No application data yet — just the handshake signal. | Tells the server: "I want to connect. My starting sequence number is x." The random ISN prevents predictability attacks. |
| **2. SYN-ACK** | Server → Client | `SYN` + `ACK` | SEQ=**y** (server's random ISN); ACK#=**x+1** | Server allocates a **TCB** (Transmission Control Block) to track this *half-open* connection. Replies with its own random ISN y and acknowledges the client's ISN by setting ACK#=x+1 ("I got your SYN, expecting byte x+1 from you next"). | Server proves receipt of client's SYN. Synchronizes the server's own sequence number. Creates a half-open connection state. |
| **3. ACK** | Client → Server | `ACK` | SEQ=**x+1**; ACK#=**y+1** | Client sends final ACK, acknowledging the server's SYN-ACK. Server receives this, moves TCB from the half-open queue to the established connections table. | Completes the three-way exchange. Both sides have now synchronized sequence numbers. Connection is fully established. Data can flow. |

### Half-Open Connection State

| State | Trigger | TCB Location | Vulnerability |
|---|---|---|---|
| **LISTEN** | Server calls `listen()` | No TCB yet | — |
| **SYN-RECEIVED** | Server gets SYN, sends SYN-ACK | **Half-open queue** (limited capacity!) | ⚠️ SYN Flood target |
| **ESTABLISHED** | Server gets final ACK | Established connections table | Normal operation |
| **TIME-WAIT** | After FIN exchange | Kept briefly to catch delayed packets | — |

---

## 📖 Section 2 Discussion — The 3-Way Handshake

### 🔴 WHY — Why Three Messages? Why Not Two?

A two-way handshake (SYN → SYN-ACK, then data) would be insufficient because it only proves the **server received the client's SYN**. It doesn't prove the **client received the server's SYN-ACK**. The third message (ACK) closes the loop:

- After step 1: Server knows client wants to connect.
- After step 2: Client knows server is ready and has its ISN.
- After step 3: Server knows client has its ISN and is ready.

Both sides must confirm each other's initial sequence numbers before data can safely flow. That's inherently a 3-message exchange.

### 🟡 HOW — Random ISN Selection

The ISN is not zero or sequential. It's chosen from a large random space (32-bit number = ~4 billion possibilities). This matters because:

- An attacker trying to inject a forged TCP segment must get the sequence number right (within the receiver's window).
- If ISNs were predictable (e.g., based on time or incrementing counters), an attacker could guess the ISN of a connection they haven't observed and inject forged packets.
- **Randomized ISNs make off-path injection attacks statistically impractical.**

### 🟢 WHAT — What the TCB Contains

When the server receives a SYN, it allocates a **Transmission Control Block (TCB)** — a kernel data structure that stores everything about this connection:

```
TCB = {
  source IP, source port,
  destination IP, destination port,
  client_ISN (x), server_ISN (y),
  current state (SYN-RECEIVED),
  timer (for retransmitting SYN-ACK if ACK never arrives),
  send/receive buffers
}
```

The half-open queue has a **finite capacity**. This is the attack surface for SYN flooding.

### 🎯 Analogy — The Telephone Protocol

Think of the 3-way handshake as establishing a phone call:

1. **SYN:** Alice calls Bob. Bob's phone rings. (Alice initiates, Bob doesn't know if Alice can hear yet.)
2. **SYN-ACK:** Bob picks up and says "Hello?" (Bob confirms he answered, but Alice needs to confirm she can hear him.)
3. **ACK:** Alice says "Hello, I can hear you!" (Both sides confirmed the line is open. Conversation can begin.)

If Alice hangs up silently after Bob says "Hello?", Bob is left waiting — this is the SYN flood analogy.

### 💡 Connection Teardown — The 4-Way FIN Exchange

Closing a connection is *not* a 3-way process — it's 4-way because each side must independently close its half of the full-duplex connection:

```
Alice → Bob:   FIN   (Alice done sending)
Bob → Alice:   ACK   (Bob acknowledges Alice's FIN)
Bob → Alice:   FIN   (Bob done sending)
Alice → Bob:   ACK   (Alice acknowledges Bob's FIN)
```

Alternatively, either side can send a **RST (Reset)** flag to abruptly terminate — no graceful exchange. RST is used in normal operations too (e.g., connecting to a closed port), but it's also the basis of TCP Reset Attacks.

---

## ✅ Practice Questions — Section 1 & 2

**[Multiple Choice]** During the TCP 3-way handshake, when the server sends SYN-ACK, what does it set the ACK# field to?

- A) 0
- B) x (the client's ISN)
- C) **x + 1** ✔
- D) y (the server's ISN)

> **Explanation:** The ACK# field always means "the next byte I expect from you." The client's ISN was x (the SYN packet counted as 1 byte in sequence space), so the server expects byte x+1 next.

---

**[True/False]** A TCP connection is fully established after the server sends the SYN-ACK.

**False ✔** — The connection is only **half-open** at this point. The third message (ACK from client) must arrive before the connection moves to ESTABLISHED state.

---

**[Multiple Choice]** Why do TCP implementations use random Initial Sequence Numbers (ISNs)?

- A) To make the headers larger for better error detection
- B) To reduce memory usage in the kernel
- C) **To make it difficult for off-path attackers to inject forged TCP segments** ✔
- D) To comply with the IPv4 addressing standard

---

**[Fill in the Blank]** The kernel data structure that stores all information about a half-open TCP connection is called a __________.

**Answer: TCB (Transmission Control Block)**

---

**[Short Answer]** Explain the difference between TCP and UDP. Give one application that benefits from TCP's reliability and one that benefits from UDP's low overhead.

**Answer:** TCP provides reliable, ordered, bidirectional byte-stream delivery with acknowledgements and retransmission. UDP is connectionless, unreliable, and has no ordering guarantees — but it has much lower overhead. **TCP benefit example:** SSH (missing characters corrupt the session). **UDP benefit example:** Online gaming or video streaming (a dropped frame is less harmful than buffering to retransmit it).

---

# Section 3 — SYN Flooding Attack
> *Exhausting the half-open connection queue · Denial-of-Service*

## Slide 4: SYN Flooding Attack — Mechanics

| Step | Actor | Action | Effect on Server |
|---|---|---|---|
| 1 | Attacker | Sends SYN with **spoofed source IP** (non-existent or victim's IP) | Server allocates a TCB in the half-open queue, starts timer |
| 2 | Server | Sends SYN-ACK to the spoofed IP | SYN-ACK goes to a non-existent host or an innocent victim; **no ACK will ever arrive** |
| 3 | Server | Waits for ACK (timer running) | TCB stays in the half-open queue occupying memory |
| 4 | Attacker | Repeats step 1 thousands of times per second | Half-open queue **fills to capacity** |
| 5 | Legitimate client | Tries to connect with a real SYN | Server has no room to store new TCBs → **connection refused / dropped → Denial of Service** |

### Why IP Spoofing is Central to the Attack

| Variant | Spoofed IP? | What Happens | Effectiveness |
|---|---|---|---|
| **With spoofed IP** | Yes (random/victim) | SYN-ACK goes nowhere; TCB never cleared; queue fills | ✅ Effective DoS |
| **Without spoofed IP** | No (real attacker IP) | Server's SYN-ACK reaches attacker; attacker ignores it; TCB stays half-open | ⚠️ Still works but attacker's IP is exposed and can be blocked |
| **Amplified (with botnet)** | Yes, distributed | Millions of spoofed SYNs from many IPs; rate massively amplified | ✅✅ DDoS — very hard to defend |

---

## 📖 Section 3 Discussion — SYN Flooding Attack

### 🔴 WHY — What Resource Is Being Exhausted?

The SYN flood attack targets a specific, limited resource: the **half-open connection queue** on the server. Every operating system allocates a fixed-size queue for connections in the SYN-RECEIVED state. On older systems this was very small (8 entries); modern systems have larger queues, but they are still finite.

The attacker's goal is not to crash the server outright — it's to consume this queue so that **legitimate connection attempts find no space and are silently dropped**. The server is still running, but it cannot accept new TCP connections. This is a **Denial of Service (DoS)** attack.

### 🟡 HOW — Why IP Spoofing Makes It Lethal

Without IP spoofing:
- The attacker sends SYN from their real IP.
- Server sends SYN-ACK back to the real attacker.
- The attacker's kernel (which didn't originate this connection) sends an RST.
- The TCB is removed from the half-open queue.
- The queue never fills.

With IP spoofing:
- The attacker sends SYN from a fake IP (or a victim's IP, turning them into an amplifier).
- Server sends SYN-ACK to the fake IP — which either doesn't exist or belongs to an innocent host that sends RST back (harmless to attacker).
- **The SYN-ACK never reaches the attacker.** No RST is generated by the attacker.
- **The TCB stays in the half-open queue until its timer expires** (typically 75 seconds on older systems).
- The attacker floods faster than the timers expire → queue stays full → DoS.

### 🟢 WHAT — The Result

Legitimate users trying to connect to a SYN-flooded server experience connection timeouts. The server's web/SSH/mail service appears "down" even though the server process is running and healthy.

### 🎯 Analogy — The Fake Reservation Attack

Imagine a restaurant with 20 tables. An attacker calls and makes 20 reservations using fake names and phone numbers. When real customers arrive, they're told "fully booked." The restaurant isn't closed — it just has no capacity for legitimate customers because fake reservations are holding all tables.

The timers are like no-show policies: after 75 minutes (or seconds), the restaurant cancels the no-show reservation. But if the attacker keeps calling faster than reservations expire, the restaurant is permanently full.

---

## Slide 5: SYN Cookies — The Defense

| Step | Actor | Action | How It Defeats the Attack |
|---|---|---|---|
| 1 | Server | Receives SYN | Instead of allocating a TCB immediately, computes a **SYN cookie** |
| 2 | Server | Computes: `H = HMAC(secret, [src_IP ‖ src_port ‖ dst_IP ‖ dst_port ‖ timestamp])` | Cookie encodes all connection info using a secret key; **no TCB allocated** |
| 3 | Server | Sends SYN-ACK with SEQ = H (the SYN cookie as the server's ISN) | SYN-ACK goes out, but server stores nothing — zero memory used |
| 4a | **Attacker** | No ACK arrives (spoofed IP) | Server wasted nothing — no TCB, no queue entry. Attack is neutralized. |
| 4b | **Legitimate client** | Sends ACK with ACK# = H + 1 | Server receives ACK, recomputes the cookie, verifies H+1 matches → allocates TCB now → connection established |

### SYN Cookies — Trade-offs

| Property | Without SYN Cookies | With SYN Cookies |
|---|---|---|
| **Memory per half-open connection** | Full TCB (hundreds of bytes) | **Zero** |
| **Vulnerability to SYN flood** | Yes — queue can be exhausted | **Resistant** — no queue to exhaust |
| **TCP options negotiation** | Full (window scaling, SACK, etc.) | ⚠️ **Limited** — options can't be stored in the cookie |
| **Computational cost** | Low | Slightly higher (HMAC per SYN) |
| **Used in practice** | As fallback | Linux/Windows enable automatically under flood conditions |

---

## 📖 Section 3 Discussion — SYN Cookies

### 🔴 WHY — The Core Insight

The vulnerability exists because the server allocates state (TCB) before the three-way handshake is complete — before the client has proven it's reachable. SYN cookies flip this: **don't allocate state until the client proves it received the SYN-ACK** (by sending a valid ACK with ACK# = cookie+1).

### 🟡 HOW — The Cookie Is Self-Describing

The SYN cookie encodes:
- Connection 4-tuple (src IP, src port, dst IP, dst port)
- Timestamp (to expire old cookies)
- HMAC (keyed hash using a server secret — prevents forgery)

When the ACK arrives, the server *recomputes* the cookie from the ACK's source/destination information and verifies the ACK# matches. If it does, the server trusts the handshake and allocates the TCB *now*.

### 🟢 WHAT — Why It Works Against SYN Floods

A spoofed SYN never gets an ACK back (the SYN-ACK went to a fake IP). Without a valid ACK, the server **never allocates a TCB**. The attacker floods SYNs and gets nothing — no queue entries, no memory consumed. The attack is computationally almost free to defend against.

### ⚠️ Limitation — TCP Options Are Lost

The cookie must fit in 32 bits (the ISN field). This is tight. Advanced TCP options (window scaling, selective acknowledgements/SACK, timestamps) negotiated during the handshake cannot be stored in the cookie. If SYN cookies are in use, these options may be lost, slightly degrading performance. This is why SYN cookies are typically enabled only as a **fallback** when the server detects flood conditions, not always.

---

## ✅ Practice Questions — Section 3

**[Multiple Choice]** What resource does a SYN flooding attack primarily exhaust?

- A) CPU processing cycles
- B) Disk I/O bandwidth
- C) **The half-open connection queue (TCB memory)** ✔
- D) The server's routing table

---

**[True/False]** A SYN flood attack requires the attacker to complete the three-way handshake.

**False ✔** — The entire point of a SYN flood is to send SYN packets and *never* send the third ACK, keeping TCBs in the half-open queue. Completing the handshake would free the queue entry.

---

**[Multiple Choice]** How do SYN cookies prevent SYN flooding?

- A) They block all SYN packets from unknown IP addresses
- B) By increasing the size of the half-open connection queue
- C) **By deferring TCB allocation until a valid ACK is received** ✔
- D) By encrypting the SYN-ACK response

---

**[Fill in the Blank]** In a SYN flood attack, the attacker typically uses __________ source IP addresses so the server's SYN-ACK replies never return to the attacker.

**Answer: spoofed (forged / fake)**

---

**[Short Answer]** Explain why IP spoofing is critical to the success of a SYN flood attack. What happens if the attacker uses their real IP address?

**Answer:** With a real IP address, the server's SYN-ACK reaches the attacker. The attacker's kernel — which has no record of initiating this connection — sends an RST packet back to the server. This RST causes the server to remove the TCB from the half-open queue, freeing the space. The queue never fills, and the DoS fails. With spoofed IPs, SYN-ACKs go to non-existent hosts (or innocent victims that send RST back to the server — but this is less useful to the attacker). The key result is that the attacker's kernel never sends an RST, so TCBs accumulate until their timer expires.

---

# Section 4 — TCP Reset Attack
> *Abruptly terminating existing connections · Forging RST packets*

## Slide 6: TCP Reset Attack — Mechanics

| Step | Actor | Action | Detail |
|---|---|---|---|
| 1 | Attacker | **Observes** traffic between Alice (A) and Bob (B) | Uses a packet sniffer (e.g., Wireshark/tcpdump) to capture packets on the same LAN or network path |
| 2 | Attacker | **Records** connection fields from observed packet | Extracts: src IP (A), src port, dst IP (B), dst port, **current sequence number** |
| 3 | Attacker | **Crafts** a forged RST packet with spoofed source IP = A | Sets RST flag; fills in all 4-tuple fields; crucially, sets SEQ# to a value within Bob's receive window |
| 4 | Attacker | **Injects** the forged RST packet to Bob | Bob receives what appears to be a legitimate RST from Alice |
| 5 | Bob | **Terminates** the connection | Bob closes the connection; sends error to its application ("Connection reset by peer") |
| 6 | Alice | Continues sending data | Alice's data arrives at Bob who has already closed the connection → further packets are rejected |

### Fields Required for a Valid Forged RST

| Field | Must Match | Why |
|---|---|---|
| Source IP address | Alice's IP | Bob uses this to look up the connection in his TCP table |
| Source port | Alice's port | Part of the 4-tuple identifying the connection |
| Destination IP | Bob's IP | Routing |
| Destination port | Bob's port | Part of the 4-tuple |
| **Sequence number** | **Within Bob's receive window** | ⚠️ **Critical** — Bob discards RSTs outside the window; attacker must get this right |
| RST flag | Set | Identifies this as a reset request |

---

## 📖 Section 4 Discussion — TCP Reset Attack

### 🔴 WHY — What Motivates a Reset Attack?

An attacker may want to:
- **Disrupt a specific connection** (e.g., terminate an SSH session, kill a VPN tunnel, disconnect a user from a game server)
- **Censorship** — the "Great Firewall of China" uses injected TCP RSTs to terminate connections to blocked domains
- **Deny service selectively** — rather than flooding to deny all connections, precisely kill one connection
- **Precondition for another attack** — force a reconnection that can be intercepted or manipulated

### 🟡 HOW — Why the Sequence Number Is the Challenge

A TCP receiver only accepts a RST (or any packet) if its sequence number falls within the **receive window** — the range of sequence numbers the receiver is currently expecting. This is a standard TCP validity check to discard old/duplicate packets.

For an attacker who can observe the connection (on the same LAN, via ARP spoofing, or via a mirror port), this is trivial — the current SEQ# is visible in every packet. For an **off-path attacker** who cannot observe the traffic, guessing the sequence number is hard (it's a 32-bit value, so ~4 billion possibilities), which is why randomized ISNs are important for defending off-path attacks.

### 🟢 WHAT — The Result

Bob's application receives: `Connection reset by peer` (errno ECONNRESET). The connection is gone. Bob and Alice must re-establish from scratch. If the attacker monitors the reconnection and resets it immediately, the service is effectively denied for that connection pair without flooding anything.

### 🎯 Analogy — Fake Hang-Up on a Phone Call

Alice and Bob are on a phone call. An attacker (who can hear the call) picks up another handset and presses the "End Call" button on what looks like Alice's phone. From Bob's perspective, Alice hung up. Alice is still talking but Bob has already disconnected.

The attacker needs to know the right moment (sequence number) to "press the button" convincingly. If they press at a wrong moment (wrong SEQ), the phone system ignores it.

### 💡 Real-World Use — The Great Firewall of China

China's censorship system injects TCP RST packets into connections when the payload contains blacklisted keywords (detected by deep packet inspection). The firewall observes the connection, sees the keyword, and immediately injects RST packets in both directions (to the client and to the server), terminating the connection. From both sides, it appears the other party hung up. This is an application of TCP reset attacks at national scale.

### ⚠️ Defense — Why Randomized Sequence Numbers Help (Partially)

Randomized ISNs force an off-path attacker to guess which of ~4 billion sequence numbers is in the current window. The probability of guessing correctly on a single attempt is low. However:
- **On-path attackers** (same LAN, or after ARP poisoning) can observe sequence numbers directly — randomization provides no protection.
- **Local on-path attackers** can trivially observe the traffic and craft valid RSTs.
- This is why the lecture notes that "randomizing initial sequence numbers is **not** effective against local on-path TCP RST attackers" — the quiz content reflects this distinction.

---

## ✅ Practice Questions — Section 4

**[Multiple Choice]** In a TCP Reset Attack, which field in the forged RST packet is the most critical to get right for the attack to succeed?

- A) The IP TTL field
- B) The destination port number
- C) **The sequence number (must fall within the receiver's window)** ✔
- D) The IP checksum

---

**[True/False]** Randomizing initial sequence numbers is effective against local on-path TCP RST attackers.

**False ✔** — A local on-path attacker can observe the traffic directly (via sniffing on the same LAN or after ARP poisoning), so they can read the current sequence numbers from passing packets. Randomization only helps against *off-path* attackers who cannot observe the connection.

---

**[Multiple Choice]** Which of the following correctly describes why a TCP RST packet terminates a connection?

- A) The RST packet contains an encrypted shutdown command
- B) **When a receiver gets a valid RST, it immediately closes the connection and notifies the application** ✔
- C) The RST packet floods the receiver with duplicate packets
- D) RST instructs the kernel to deallocate all network interfaces

---

**[Short Answer]** A student claims: "If we use HTTPS (TLS over TCP), TCP Reset Attacks are defeated because the traffic is encrypted." Evaluate this claim.

**Answer:** The claim is **false**. TLS encrypts the *payload* (application data), but **TCP headers including the RST flag and sequence numbers are not encrypted** — they are in the clear IP/TCP headers. A TCP Reset Attack operates at the TCP layer by injecting RST packets that manipulate connection state. TLS cannot prevent the TCP connection from being reset because the RST flag is processed by the kernel's TCP stack *before* the data ever reaches the TLS layer. TLS provides confidentiality and integrity for the *data*, not for the TCP connection lifecycle.

---

# Section 5 — TCP Session Hijacking Attack
> *Injecting data into an existing connection · Taking over an established session*

## Slide 7: TCP Session Hijacking — Mechanics

| Step | Actor | Action | Detail |
|---|---|---|---|
| 1 | Attacker | **Observes** an established TCP session between Alice and Server | Uses sniffing on the same network segment (LAN, Wi-Fi) to monitor packets |
| 2 | Attacker | **Records** all 4-tuple fields and current sequence numbers | Tracks Alice's current SEQ# and the server's current SEQ# from observed packets |
| 3 | Attacker | **Crafts** a forged data packet with: spoofed src IP = Alice; correct SEQ# | Packet appears to come from Alice but contains attacker's payload |
| 4 | Attacker | **Injects** forged packet before Alice's next legitimate packet arrives | Server accepts the forged packet as Alice's legitimate data |
| 5 | Server | **Processes** attacker's injected data | Server executes or responds to attacker's command as if Alice sent it |
| 6 | Alice | Sends her own legitimate packet with the same SEQ# | Server already advanced its expected SEQ# — Alice's packet is now **out of order** |
| 7 | Connection | Enters **desynchronized state** | Alice and Server are out of sync on sequence numbers; the legitimate connection is effectively dead |

### Sequence Number Requirements for Injection

| Scenario | SEQ# value | Server's Response |
|---|---|---|
| SEQ# = exactly expected next byte | Perfect injection | Server accepts immediately, processes payload |
| SEQ# = expected + δ (small positive δ) | Out of order | Server buffers the data in a gap, waits for the gap to be filled |
| SEQ# = expected − δ (already received) | Duplicate | Server discards |
| SEQ# far outside window | Invalid | Server discards |

**Key insight:** The attacker must inject a packet with **SEQ# = the server's next expected byte from Alice** (i.e., matching the last ACK# the server sent to Alice).

---

## 📖 Section 5 Discussion — TCP Session Hijacking

### 🔴 WHY — What Makes This Attack Valuable?

TCP Reset Attack kills a connection. Session Hijacking does something more dangerous: **it keeps the connection alive while inserting the attacker's commands into it**. If Alice has an established, authenticated shell session (SSH-like telnet in the 1990s, or an unencrypted TCP-based protocol), the attacker can:
- Execute commands as Alice on the server
- Read responses (if monitoring traffic)
- Maintain control of Alice's session indefinitely

This is particularly devastating for legacy unencrypted protocols like Telnet, FTP without TLS, or HTTP.

### 🟡 HOW — The Sequence Number Arithmetic

Say Alice has sent 5000 bytes total, and the server's last ACK to Alice was ACK#=5001 (expecting byte 5001 from Alice). The attacker injects a packet with:
- Source IP = Alice's IP
- SEQ = 5001 (the expected next byte)
- Payload = `"rm -rf /important-dir\n"` (or any malicious command)

The server:
1. Receives the forged packet.
2. Checks SEQ=5001 — matches expected. ✅
3. Accepts the payload, advances its expected SEQ to 5001 + len(payload).
4. Executes the command.

When Alice's *legitimate* next packet arrives with SEQ=5001 (her intended next command), the server has already advanced to expecting 5001 + payload_length. Alice's packet is now stale/duplicate — discarded. The connection is desynchronized.

### 🟢 WHAT — The Desynchronization Problem

After injection, Alice and the server are desynchronized: they disagree on sequence numbers. Every subsequent legitimate packet from Alice is rejected. The session appears to hang from Alice's perspective. She may try to restart — giving the attacker another opportunity. The server may believe Alice is behaving erratically.

### 🎯 Analogy — Intercepting a Letter Sequence

Alice is sending a series of numbered letters to a librarian: "Letter #47: Please find book X." Before Letter #47 arrives, the attacker intercepts and substitutes their own: "Letter #47: Delete all records." The librarian processes letter #47 as authentic (right number). When Alice's real letter #47 arrives, the librarian says "I already got #47" and discards it. Alice's library access is now broken.

### ⚠️ Why Encrypting the Payload (TLS) Defeats This

Unlike the TCP Reset Attack (which operates on headers only), session hijacking also requires the *content* of injected packets to be meaningful to the server. If the connection uses TLS:
- All data is encrypted with session keys only Alice and the server know.
- The attacker's injected plaintext payload would arrive encrypted incorrectly (the attacker doesn't have the TLS session key).
- The server's TLS layer would reject the malformed ciphertext — the TCP layer accepts the segment (sequence number matches), but TLS decryption fails.
- **Result: The injected payload is useless.** The attacker can still desynchronize (inject garbage), which amounts to a reset, but cannot inject meaningful commands.

This is the core reason why **encrypting payloads (TLS) defends against session hijacking** — even though it doesn't prevent TCP-level disruption.

---

## Slide 8: Defenses Against TCP Attacks — Summary

| Defense | Protects Against | Mechanism | Limitation |
|---|---|---|---|
| **Randomized ISNs** | Off-path RST / hijacking | Makes SEQ# unpredictable (~2³² guesses needed) | Does NOT help against on-path (local LAN) attackers |
| **Randomized source port** | Some injection attacks | Adds another dimension attackers must guess | Ports are observable if attacker is on-path |
| **SYN Cookies** | SYN flooding | No TCB until valid ACK received | Loses some TCP options |
| **Payload encryption (TLS/IPsec)** | Session hijacking (content injection) | Injected ciphertext fails decryption → payload useless | TCP connection can still be reset (RST not encrypted) |
| **IPsec** | Multiple TCP attacks | Authenticates IP packets → spoofed packets rejected | Requires IPsec deployment on both endpoints |
| **Ingress/Egress filtering** | IP spoofing (SYN flood source) | ISPs drop packets with impossible source IPs | Requires ISP cooperation; not universally deployed |

---

## 📖 Section 5 Discussion — Defense Summary

### 🔴 WHY — No Single Defense Is Complete

Each defense targets a specific aspect of TCP's design:
- **SYN cookies** protect the state allocation vulnerability.
- **Randomized ISNs/ports** protect against SEQ# prediction (off-path only).
- **TLS** protects the *content* of the session from injection.
- **IPsec** protects the IP-level authentication.

None of these alone is comprehensive. A defense-in-depth approach combines multiple layers.

### 🟡 HOW — Encryption Is the Most Powerful Defense for Hijacking

TLS deserves special emphasis: it doesn't just protect confidentiality, it also provides **connection integrity**. Even if an attacker injects a TCP segment with the correct sequence number, the TLS record layer will reject it because:
1. The injected ciphertext doesn't decrypt correctly (wrong key).
2. TLS uses authenticated encryption (AEAD — like AES-GCM) which detects tampering.
3. The TLS connection will be terminated with a fatal alert, rather than silently accepting corrupted data.

For modern systems running HTTPS (TLS 1.3), TCP session hijacking is effectively mitigated at the application layer — though the TCP connection itself can still be reset by forged RST packets.

### 🟢 WHAT — The Practical State of the Art

Modern servers:
- Use TLS for all sensitive connections (HTTPS everywhere).
- OS kernels use randomized ISNs (RFC 6528).
- SYN cookies are automatically enabled under flood conditions.
- IPsec is deployed in enterprise VPN environments for added authentication.

The remaining vulnerability is against **local on-path attackers** (same LAN), which is where WiFi security (WPA2-Enterprise), physical network security, and network segmentation (VLANs) provide the outer layer of defense.

---

## ✅ Practice Questions — Section 5

**[Multiple Choice]** What is the primary goal of TCP session hijacking (as distinct from a TCP Reset Attack)?

- A) To fill the server's half-open connection queue
- B) To terminate the TCP connection between two parties
- C) **To inject malicious data into an existing TCP session while keeping it alive** ✔
- D) To decrypt TLS-encrypted traffic

---

**[True/False]** Encrypting payloads with TLS can help defend against TCP session hijacking attacks.

**True ✔** — Even if an attacker injects a TCP segment with the correct sequence number, TLS authenticated encryption (e.g., AES-GCM) will detect the tampered ciphertext and reject it, making the injected content useless.

---

**[Multiple Choice]** Which of the following is NOT an effective defense against off-path TCP RST attacks?

- A) Randomizing initial sequence numbers
- B) Randomizing source port numbers
- C) **Deploying SYN cookies** ✔
- D) Using IPsec to authenticate IP packets

> **Explanation:** SYN cookies specifically defend against SYN flooding (exhausting the half-open queue). They do not help against RST attacks or session hijacking, which exploit the sequence number space of *established* connections.

---

**[Short Answer]** Explain why a TCP session hijacking attack fails when TLS is used, even if the attacker correctly guesses the sequence number.

**Answer:** TLS uses authenticated encryption (AEAD, e.g., AES-GCM). Every TLS record contains a Message Authentication Code (MAC/authentication tag) computed using the TLS session key, which the attacker does not possess. Even if the attacker injects a TCP segment with the correct sequence number (so the TCP layer accepts it), the TLS layer will attempt to decrypt the data and verify the authentication tag. Since the attacker cannot produce a valid tag without the session key, verification fails. TLS terminates the connection with a fatal alert rather than passing corrupted data to the application. The injected content is rendered meaningless.

---

**[Fill in the Blank]** After a successful TCP session hijacking injection, the legitimate connection between Alice and the server enters a __________ state because their sequence numbers no longer agree.

**Answer: desynchronized**

---

# Section 6 — Integrative Attack Comparison
> *Side-by-side comparison of all three TCP attacks*

## Slide 9: Attack Comparison Table

| Dimension | SYN Flooding | TCP Reset Attack | TCP Session Hijacking |
|---|---|---|---|
| **Goal** | Deny service (prevent new connections) | Terminate an existing connection | Inject commands into an existing session |
| **Target** | Half-open connection queue (server resource) | An established TCP connection | An established TCP session's data stream |
| **What attacker needs** | Ability to send IP packets (spoofed SYNs) | Observed SEQ# of an existing connection | Observed SEQ# + ability to inject before legitimate packet |
| **Requires on-path position?** | No (spoofed SYN goes to server directly) | No (if off-path, must guess SEQ#; yes if on-path for easy SEQ# reading) | Typically yes (needs to observe current SEQ#) |
| **Affected parties** | All new clients trying to connect | The two parties of the targeted connection | The legitimate session owner (Alice) |
| **TCP flags used** | `SYN` (sent by attacker) | `RST` (forged by attacker) | No special flag — normal `ACK` + data |
| **IP spoofing involved?** | Yes (typically) | Yes (impersonates one party) | Yes (impersonates Alice to the server) |
| **Defense: Randomized ISN** | Not applicable | ✅ Partially (off-path only) | ✅ Partially (off-path only) |
| **Defense: SYN Cookies** | ✅ Effective | ❌ Not applicable | ❌ Not applicable |
| **Defense: TLS** | ❌ Not applicable (TCP-level) | ❌ RST is in TCP header, unencrypted | ✅ **Effective** — injected ciphertext rejected |
| **Defense: IPsec** | ✅ Partially | ✅ Effective | ✅ Effective |
| **Equivalent attack analog** | Fake restaurant reservations (fill all tables) | Someone hanging up your phone call | Someone intercepting your letter and substituting their own |

---

## 📖 Section 6 Discussion — Why Understanding All Three Matters

### 🔴 WHY — The Common Root Cause

All three attacks share the same root vulnerability: **TCP was designed for a cooperative, trusted network environment.** In the original ARPANET design, all participants were trusted research institutions. TCP's designers did not anticipate:
- Malicious participants who would send spoofed packets
- Network positions that would allow passive observation of traffic
- Attackers who would exploit finite server resources

### 🟡 HOW — The Three Threat Models

| Attack | Threat Model | Attacker Capability |
|---|---|---|
| SYN Flood | **Volumetric resource exhaustion** | Can send many packets at high rate; IP spoofing possible |
| RST Attack | **Protocol abuse** | Can observe traffic (on-path) OR guess SEQ# (off-path, harder) |
| Hijacking | **Active man-in-the-middle** | Must be able to observe and inject (typically same LAN) |

### 🟢 WHAT — The Defense Hierarchy

```
Layer 1 (Network):  IPsec / Ingress filtering → stop spoofed packets at the IP layer
Layer 2 (TCP):      SYN cookies → protect state allocation
                    Randomized ISNs → protect off-path SEQ# guessing  
Layer 3 (App/TLS):  TLS authenticated encryption → protect session content
Layer 4 (Physical): Network segmentation, VLANs → limit on-path attacker access
```

No single layer is sufficient. Defense in depth is the answer.

---

## ✅ Practice Questions — Section 6

**[Multiple Choice]** Which TCP attack can be prevented by SYN cookies but NOT by TLS?

- A) TCP Session Hijacking
- B) TCP Reset Attack
- C) **SYN Flooding** ✔
- D) IP Spoofing

---

**[Multiple Choice]** An attacker on the same LAN as Alice wants to inject malicious commands into Alice's Telnet (unencrypted TCP) session with a server. Which attack is most appropriate?

- A) SYN Flooding
- B) TCP Reset Attack
- C) **TCP Session Hijacking** ✔
- D) ARP Spoofing (this would be a prerequisite, not the TCP attack itself)

---

**[True/False]** SYN cookies protect against TCP Session Hijacking.

**False ✔** — SYN cookies specifically address the half-open queue exhaustion of SYN flooding. Session hijacking targets *established* connections, which are past the point where SYN cookies operate.

---

**[Short Answer]** Compare TCP Reset Attack and TCP Session Hijacking on: (a) what the attacker wants to achieve; (b) what happens to the existing connection; (c) whether TLS defeats the attack.

**Answer:**
- **(a) Goal:** Reset Attack wants to *terminate* the connection. Hijacking wants to *take over* the connection to inject attacker-controlled data.
- **(b) Effect on connection:** Reset Attack kills it immediately (RST causes both sides to close). Hijacking keeps the connection alive (from the server's perspective) but desynchronizes the legitimate client — the legitimate user loses access while the attacker effectively has a session.
- **(c) TLS:** TLS does NOT prevent RST attacks — RST is a TCP header flag, which is never encrypted. TLS *does* defeat session hijacking content injection — the attacker's injected data cannot be authenticated by TLS and is rejected.

---

# Quick Reference Summary

| Attack / Concept | Core Mechanism | Key Resource Targeted | Primary Defense | TLS Helps? |
|---|---|---|---|---|
| **SYN Flooding** | Spoofed SYNs never followed by ACK | Server's half-open queue (TCB storage) | SYN cookies | ❌ (TCP-level, below TLS) |
| **SYN Cookie** | HMAC-based stateless cookie as server ISN | Eliminates half-open state | n/a (IS the defense) | n/a |
| **TCP Reset Attack** | Forged RST with valid SEQ# | Established connection integrity | Randomized ISN (off-path); IPsec | ❌ (RST header unencrypted) |
| **Session Hijacking** | Forged data packet with valid SEQ# | Session data stream | TLS encryption; Randomized ISN | ✅ (Injected ciphertext rejected) |
| **3-Way Handshake** | SYN → SYN-ACK → ACK to sync ISNs | — | — | n/a |
| **Randomized ISN** | 32-bit random starting SEQ# | SEQ# prediction space | n/a (IS the defense) | — |
| **TCB** | Kernel structure tracking half-open connections | Server memory | SYN cookies | — |
| **Desynchronization** | After hijacking injection, legit client's SEQ# out of sync | Session continuity for legitimate user | TLS; IPsec | ✅ |
| **Payload encryption** | TLS AEAD (e.g., AES-GCM) authenticates all data | Content integrity of session | n/a (IS the defense) | — |
| **IPsec** | Authenticates IP packets at Layer 3 | Spoofed packet acceptance | n/a (IS the defense) | — |
| **Ingress/Egress filtering** | ISPs drop packets with impossible source IPs | Spoofed IP feasibility | n/a (IS the defense) | — |

---

# Exam Preparation — Integrative Questions

---

**[Short Answer]** Walk through a complete SYN flood attack: what does the attacker send, what does the server do with each packet, what resource is exhausted, and how does SYN cookie prevent the exhaustion?

✔ **Answer:**
1. Attacker sends thousands of SYN packets per second, each with a different spoofed source IP address.
2. Server receives each SYN → allocates a TCB → sends SYN-ACK to the (fake) source IP → waits for ACK → none arrives → TCB stays in half-open queue for ~75 seconds.
3. Exhausted resource: The **half-open connection queue** fills completely.
4. Legitimate SYN packets from real users arrive but find no space in the half-open queue → dropped → DoS.
5. **SYN cookies:** Server computes `H = HMAC(secret, [4-tuple ‖ timestamp])` and sets the SYN-ACK's ISN = H. **No TCB is allocated.** Spoofed SYN-ACKs go nowhere; no ACK arrives; no memory used. Legitimate client sends ACK with ACK#=H+1; server recomputes H, verifies, then allocates TCB → connection established.

---

**[Short Answer]** Explain the full sequence of a TCP Session Hijacking attack, including what information the attacker must obtain, how they inject, and why the legitimate user's connection breaks.

✔ **Answer:**
1. **Observe:** Attacker sniffs traffic on the LAN between Alice (A) and Server (S). Records: src IP=A, src port, dst IP=S, dst port, Alice's current SEQ# (e.g., 5001) — extracted from a captured packet.
2. **Craft:** Attacker creates a forged TCP segment: src IP=Alice, src port=Alice's, dst IP=Server, SEQ#=5001, payload = malicious command, ACK flag set.
3. **Race:** Attacker injects the forged segment, hoping it arrives at S before Alice's next real packet.
4. **Server accepts:** Server sees SEQ#=5001, correct 4-tuple, accepts the packet. Processes attacker's command. Server's expected next SEQ# from Alice advances to 5001 + len(payload).
5. **Alice's real packet:** Alice sends her intended data with SEQ#=5001. Server now expects a higher number → Alice's packet is duplicate/stale → discarded.
6. **Desynchronization:** Alice and Server now disagree on sequence numbers. Alice's subsequent packets are all rejected. The session is effectively stolen.

---

**[Short Answer]** A network administrator says: "We've deployed TLS everywhere, so we don't need to worry about TCP attacks." Provide a nuanced evaluation of this claim for each of the three attacks covered in this lecture.

✔ **Answer:**
- **SYN Flooding:** TLS provides **no protection**. The SYN flood exhausts the TCP half-open queue before any TLS handshake begins. The server cannot even establish a TCP connection to start TLS. Correct defense: SYN cookies.
- **TCP Reset Attack:** TLS provides **no protection**. RST packets are TCP header flags, which are never encrypted by TLS. An attacker can still inject a forged RST with a valid sequence number to terminate the TCP connection, which will also kill the TLS session on top of it. Correct defense: IPsec (which authenticates IP packets), or network-level access controls.
- **TCP Session Hijacking:** TLS provides **strong protection** against *content injection*. Even if the attacker injects a TCP segment with the correct sequence number, TLS's authenticated encryption (AEAD) rejects the ciphertext as invalid. The application never processes the attacker's data. However, TLS cannot prevent the TCP connection from being desynchronized or reset — the attacker can still disrupt the connection, just not inject meaningful data.

**Conclusion:** TLS is the right defense for session hijacking content injection, but insufficient for SYN flooding (need SYN cookies) and TCP reset attacks (need IPsec or physical network controls). "TLS everywhere" is necessary but not sufficient.

---

**[Short Answer]** Compare the information an attacker needs for each of the three TCP attacks. Which attack requires the most attacker capability, and why?

✔ **Answer:**

| Attack | Minimum Attacker Capability | Required Information |
|---|---|---|
| **SYN Flooding** | Ability to send IP packets (possibly spoofed) | Just the server's IP and port — no connection state needed |
| **TCP Reset Attack** (off-path) | Can send spoofed packets; must guess SEQ# | Server IP, port, approximate SEQ# (32-bit guess) |
| **TCP Reset Attack** (on-path) | Network position to observe traffic | Observed SEQ# from captured packet — trivial |
| **Session Hijacking** | On-path position (typically) + ability to inject before legitimate packet | Current SEQ#, full 4-tuple, timing precision |

**Most capable requirement:** TCP Session Hijacking. The attacker must: (1) be on-path or have a way to observe traffic; (2) read the current sequence number from a captured packet; (3) inject their packet before Alice's legitimate next packet arrives (a timing race condition); (4) craft a packet with a meaningful payload. SYN flooding is the most accessible — no prior connection information needed, just send SYNs at the server.

---

**[True/False Rapid Fire — Exam Style]**

1. TCP Reset Attacks can be defeated by using HTTPS instead of HTTP. **False** — RST is a TCP header flag, not affected by TLS.
2. SYN cookies eliminate the need for a half-open connection queue by computing a stateless cookie. **True**
3. Randomizing ISNs makes session hijacking impossible for a local on-path attacker. **False** — A local on-path attacker can read the current SEQ# from observed packets regardless of how the ISN was chosen.
4. After a successful session hijacking injection, the server's connection with Alice enters a desynchronized state. **True**
5. A SYN flood attack requires the attacker to be on the same LAN as the victim server. **False** — SYN packets can be sent from anywhere on the Internet, and IP spoofing does not require local network access.
6. Encrypting payloads with IPsec at Layer 3 can help defend against TCP session hijacking. **True** — IPsec provides packet-level authentication; spoofed/injected packets without valid IPsec authentication are rejected.
7. In a TCP 3-way handshake, the server allocates a TCB when it receives the client's final ACK (Step 3). **False** — The TCB is allocated when the server receives the initial SYN (Step 1). It moves from the half-open queue to the established table upon receiving the final ACK.

---

*CS 448/548 Network Security · TCP Protocol & Attacks · Deep-Dive Annotated Study Guide · Spring 2026 · Dr. Lina Pu*