# Kerberos Authentication Protocol — Annotated Study Guide
**CS 448/548 Network Security · All 5 Phases · Deep-Dive Edition**

---

> **How to use this guide:** Each phase header is followed by a table of every atomic action. Below each table section, a **Discussion** block explains *why* each design decision was made — not just *what* happens. The guide progresses from beginner-friendly analogies to expert-level reasoning. Practice questions appear after each phase group. A Quick Reference Summary and Exam Integrative Questions close the guide.

---

## Reading Legend

| Symbol / Color label | Meaning |
|---|---|
| `Kc` | Long-term client key — derived from password; used minimally |
| `K_TGS` | Long-term TGS key — seals TGTs |
| `Kv` | Long-term server key — seals service tickets |
| `Kc,TGS` | Short-term session key between Client ↔ TGS |
| `Kc,v` | Short-term session key between Client ↔ Server V |
| **field** | Protocol field name (ID_client, TS, AD_client, etc.) |
| ⚠️ | Security warning or attack surface |
| 💡 | Design insight |
| 🎯 | Analogy |

---

# Phase 0 — Pre-Setup
> *Before any login · One-time admin configuration*

| # | Action | Actor → Recipient | Object / Key | What Happens | Why This Design |
|---|---|---|---|---|---|
| 0.1 | KDC registers client | KDC Admin → KDC DB | `Kc` = hash(password) | Admin creates Alice's account. KDC computes `Kc` = hash(Alice's password) and stores it. The raw password is **never stored**. The same hash will run on Alice's machine at login time to reproduce `Kc` locally. | Storing a derived key instead of the raw password limits damage from DB theft. The derivation is deterministic — Alice can always re-derive `Kc` locally without the KDC sending it. |
| 0.2 | KDC registers each service | KDC Admin → KDC DB + Server V | `Kv` (random, one per service) | Admin generates a random `Kv` for service V (file server, mail server, etc.). Stored in: (1) KDC database, (2) installed on Server V out-of-band by sysadmin. Each service gets its **own independent** `Kv`. | Per-service random key means compromise of one service's `Kv` leaves all others unaffected. Out-of-band installation avoids transmitting `Kv` over the network at all. |
| 0.3 | TGS key established | KDC Admin → AS + TGS | `K_TGS` (random) | Admin generates `K_TGS`, shared between AS and TGS. Allows AS to seal TGTs that **only TGS** can open. In practice AS and TGS often run on the same KDC machine. | `K_TGS` is what makes the TGT mechanism possible. The client carries the TGT but cannot read it — only TGS can, by decrypting with `K_TGS`. |

---

## 📖 Phase 0 Discussion

### 🔴 WHY — The Core Problem Kerberos Solves
Every time a user wants to access a network service, something must answer the question: *"Is this really Alice?"* The naive answer — "just send the password every time" — is catastrophically insecure. Passwords on the wire get stolen. Kerberos's answer is: **the password never travels on the wire, ever.** Phase 0 sets up the cryptographic infrastructure that makes this possible.

### 🟡 HOW — The Pre-Shared Key Model
Kerberos is built entirely on **symmetric cryptography**. Before any login can happen, every principal (client, TGS, each service) must share a long-term secret with the KDC. These secrets are established once, out-of-band, by an administrator:

- `Kc` is derived from the user's password using a one-way hash. The same hash function runs on both sides (KDC database at account creation time; Alice's machine at login time), so both arrive at the same key without ever transmitting it.
- `Kv` for each service is a randomly generated key that lives in the KDC database and is physically installed on the server. No network transmission involved.
- `K_TGS` lets the AS seal TGTs that only the TGS can open.

### 🟢 WHAT — The Result
When Alice logs in later, the KDC already has her `Kc` in the database. It can immediately prepare a response that only Alice can decrypt, because only Alice (via her password) and the KDC know `Kc`. No challenge-response over the wire, no password transmission — just math.

### 🎯 Analogy — The Safety Deposit Box
Think of the KDC database as a bank's master key registry. When you open a safe deposit box account (create a Kerberos account), the bank records a copy of your box key (Kc). Later, when you want to open your box, the bank doesn't ask you to show your key directly — instead they prepare something that only your key can unlock. The key itself never goes over the counter.

### 💡 Why Per-Service Keys?
Each service has a completely independent long-term key. This is the **principle of key isolation**: if the file server's `Kv` is stolen (e.g., the file server is compromised), the attacker gains access only to the file server. The mail server's key, the print server's key, every other service's key — all unaffected. This limits the blast radius of any individual compromise to exactly one service.

---

# Phase 1 — Initial Authentication (AS Exchange)
> *Client ↔ Authentication Server · Password verification · TGT issuance*

| # | Action | Actor → Recipient | Object / Key | What Happens | Why This Design |
|---|---|---|---|---|---|
| 1.1 | Client sends login request | Alice → AS | **ID_client**, **ID_TGS**, **TS1** — all plaintext | Alice sends her username, the TGS identifier, and her current timestamp. **No password, no key, no credential of any kind is sent.** | Sending only the username is the *foundational security decision* of Kerberos. The AS will verify identity implicitly by encrypting its response with `Kc` — if Alice can decrypt it, she proved she knows the password. |
| 1.2 | AS looks up client record | AS → KDC Database | `Kc` retrieved via **ID_client** | AS queries DB using Alice's username as key. Retrieves `Kc` — the stored hash of Alice's password. | KDC is the single authoritative store of all long-term keys. Centralization is the design trade-off: strong guarantees in exchange for a single point of failure. |
| 1.3 | AS generates fresh session key | AS → internal | `Kc,TGS` = new random key | AS calls a CSPRNG to generate a brand-new `Kc,TGS`. This key has never existed before and will never be reused. | Freshly generated per-session key means compromise of this session's key reveals nothing about `Kc` (Alice's password-derived key) or any other session's key. |
| 1.4 | AS constructs the TGT | AS → internal | Encrypted with `K_TGS`; contains `Kc,TGS`, **ID_client**, **AD_client**, **ID_TGS**, **TS1**, **Lifetime** | `TGT = E(K_TGS, [Kc,TGS ‖ ID_client ‖ AD_client ‖ ID_TGS ‖ TS1 ‖ Lifetime])` | Encrypting with `K_TGS` means: (1) client **cannot read** the TGT contents (especially `Kc,TGS` inside); (2) client **cannot modify** it. The Lifetime field inside the encrypted content means Alice cannot extend it. |
| 1.5 | AS encrypts session key for client | AS → internal | Encrypted with `Kc`; contains `Kc,TGS`, **ID_TGS**, **TS1** | `Part A = E(Kc, [Kc,TGS ‖ ID_TGS ‖ TS1])` | This is the **secure key delivery mechanism** AND the **implicit password verification step**. If Alice's password is wrong → wrong `Kc` → garbled decryption → authentication fails without the AS ever saying "wrong password." |
| 1.6 | AS sends complete response | AS → Alice | Part A + Part B (TGT) | Two-part message: Part A for Alice (sealed with `Kc`); Part B for TGS (sealed with `K_TGS`). Alice gets both but can only open Part A. | Bundling both in one message reduces round trips. Alice needs both pieces immediately: `Kc,TGS` from Part A to authenticate to TGS, TGT from Part B to present as KDC endorsement. |
| 1.7 | Client derives Kc locally | Alice → internal (no network) | `Kc` = hash(typed password) | Alice types her password. Software computes `Kc` = hash(password) — same algorithm used at account creation. **Entirely on Alice's machine. No network packet sent.** | The password is the one thing that never leaves Alice's machine. Using a hash separates the human-memorable password from the cryptographic key. |
| 1.8 | Client decrypts Part A | Alice → internal | Key: `Kc`; extracts `Kc,TGS`, **ID_TGS**, **TS1** | Alice decrypts Part A with locally-derived `Kc`. If password correct → decryption succeeds → extracts `Kc,TGS`. Also verifies **ID_TGS** (is this for the right TGS?) and **TS1** (is this a reply to my specific request?). | This step simultaneously: (a) delivers `Kc,TGS`; (b) verifies the password; (c) authenticates the AS — only the real AS holding `Kc` from the KDC database could produce a message that decrypts correctly. **TS1 echo-check prevents replay of old AS responses.** |
| 1.9 | Client stores credentials; discards Kc | Alice → credentials cache | Stores: `Kc,TGS` + TGT. **Discards: `Kc`** | Credentials cache stores the TGT (opaque blob) and `Kc,TGS`. `Kc` is immediately erased from memory — it served its one purpose (decrypting Part A). | `Kc` is the highest-value key — it represents Alice's permanent identity. Minimizing its in-memory lifetime closes the window for memory-dump attacks (e.g., Mimikatz). |

---

## 📖 Phase 1 Discussion

### 🔴 WHY — Why Not Just Send the Password?
Simple question, profound answer. If Alice sent her password to the AS, it would be exposed on the network — sniffable by anyone. Even if encrypted, an attacker could capture the exchange and mount an offline dictionary attack against it. Kerberos's genius is that **the password is used only locally** to derive `Kc`, which is then used only to decrypt a response. The password never touches the network.

### 🟡 HOW — The Implicit Verification Trick (Step 1.5 & 1.8)
Here is the most elegant design decision in Kerberos:

The AS never explicitly says "correct password" or "wrong password." Instead, it encrypts Part A with `Kc`. If Alice types the correct password → she derives the correct `Kc` → decryption produces valid data (a recognizable session key and matching timestamps). If she types the wrong password → wrong `Kc` → decryption produces garbage → her Kerberos client reports authentication failure.

This approach has a subtle but important security benefit: an attacker cannot tell from AS's response whether they guessed the right password, because the response is identical regardless — it's just ciphertext. (In practice, an attacker trying dictionary attacks offline against a captured response *can* tell when decryption succeeds, but this requires capturing the response first.)

### 🟢 WHY Timestamps? (TS1 in Steps 1.1 and 1.5)

**TS1 in Step 1.1 (sent by Alice):** Alice includes her current timestamp in the request. This serves two purposes:
1. It becomes part of the TGT's validity window reference (`TS1` + `Lifetime` = expiry time)
2. It allows the AS to reject obviously stale requests (if TS1 is too far in the past, it might be a replayed old request)

**TS1 echoed back in Part A (Step 1.5):** The AS includes TS1 in the encrypted Part A that Alice decrypts. When Alice decrypts and sees TS1 matching what she sent, she is assured of two things:
- This response is fresh and specifically addressed to her request (not a replayed old AS response from a previous session)
- The AS processed her specific request (an attacker replaying an old response would have a different TS1)

💡 **The Timestamp Philosophy:** In Kerberos, timestamps are the universal mechanism for establishing freshness. Every proof-of-possession uses timestamps. The underlying assumption is that clocks are synchronized (within ~5 minutes via NTP). If clocks drift, Kerberos breaks — this is both a limitation and a security feature (it makes replay attacks time-bounded).

### 💡 Why Does the TGT Contain Kc,TGS? (Step 1.4)
The TGT is a sealed container that the client carries to the TGS. The TGS needs `Kc,TGS` in order to:
1. Decrypt Alice's Authenticator (which is encrypted with `Kc,TGS`)
2. Encrypt the session key `Kc,v` for delivery back to Alice

But how does TGS learn `Kc,TGS`? It can't contact AS for every ticket request — that would bottleneck everything at the AS. The solution: AS embeds `Kc,TGS` **inside the TGT itself**, encrypted with `K_TGS`. The TGT is self-contained proof. TGS decrypts the TGT → learns `Kc,TGS` → uses it to verify Alice's identity. No AS contact needed at all.

### 💡 Why Does Alice Carry the TGT if She Can't Read It?
The TGT is a sealed "passport" issued by the AS. Alice is essentially a courier — she carries it to the TGS exactly as issued, and the TGS is the intended recipient who can open it. This is a deliberate design choice:
- The KDC doesn't maintain state per-session. It issues the TGT and is done.
- The TGS doesn't need to call back to AS; it just opens the TGT.
- Alice cannot forge or modify the TGT because she doesn't know `K_TGS`.

This is the **stateless ticket model** — the ticket IS the state, carried by the client.

### ⚠️ What if Someone Captures the AS Exchange?
An eavesdropper captures Part A (encrypted with `Kc`) and the TGT (encrypted with `K_TGS`). They can:
- Try offline dictionary attacks against Part A to recover `Kc` (and thus Alice's password) — this is the **AS-REP Roasting** attack in Active Directory environments
- **Cannot** open the TGT — they don't know `K_TGS`

Defense: strong, non-guessable passwords. Pre-authentication (RFC 4120) forces Alice to prove she knows `Kc` before AS even sends Part A, preventing the offline attack.

---

# Phase 2 — Service Ticket Request (TGS Exchange)
> *Client ↔ TGS · TGT presented · Service ticket (Ticket_v) issued*

| # | Action | Actor → Recipient | Object / Key | What Happens | Why This Design |
|---|---|---|---|---|---|
| 2.1 | Client constructs Authenticator1 for TGS | Alice → internal | `Authenticator1 = E(Kc,TGS, [ID_client ‖ AD_client ‖ TS2])` | Alice creates a fresh authenticator encrypted with `Kc,TGS`. Fields: her identity, her IP, and **TS2** (current timestamp at exact moment of this TGS request). | Authenticator is proof of live presence. TGT proves KDC endorsed Alice *at some point*; Authenticator proves Alice is present *right now* and knows `Kc,TGS`. A new Authenticator is created for every TGS request — never reused. |
| 2.2 | Client sends TGS request | Alice → TGS | **ID_v** (desired service) + TGT (opaque, forwarded untouched) + Authenticator1 | Three-part message: what Alice wants (**ID_v**), KDC's endorsement (TGT), and proof Alice is present now (Authenticator1). | Each piece serves a distinct role. Removing any one breaks the security model. Alice forwards TGT without reading it — she cannot, since it's sealed with `K_TGS` which she doesn't know. |
| 2.3 | TGS decrypts TGT | TGS → internal | Key: `K_TGS`; extracts `Kc,TGS`, **ID_client**, **AD_client**, **ID_TGS**, **TS1**, **Lifetime** | TGS uses its own `K_TGS` to open the TGT. Successful decryption is itself proof the TGT was issued by the legitimate AS — only AS knows `K_TGS`. | TGS verifies the KDC's endorsement of Alice without any live call to the AS. The TGT is **self-contained proof**. Protocol scales to unlimited TGS requests without bottlenecking at AS. |
| 2.4 | TGS checks TGT validity | TGS → internal | **TS1** + **Lifetime** from TGT vs. current clock | Checks: `TS1 ≤ now ≤ TS1 + Lifetime`. If expired → reject. Also optionally checks **AD_client** vs. actual source IP. | Lifetime is inside the encrypted TGT content — Alice cannot extend it (she can't modify content she can't even read). |
| 2.5 | TGS decrypts Authenticator1 | TGS → internal | Key: `Kc,TGS` (extracted from TGT in 2.3); extracts **ID_client**, **AD_client**, **TS2** | TGS uses `Kc,TGS` from the TGT to decrypt Authenticator1. Successful decryption proves the sender knows `Kc,TGS`. | **Two-layer verification:** Layer 1 (TGT): "KDC says session belongs to alice, session key is `Kc,TGS`." Layer 2 (Authenticator): "Sender knows `Kc,TGS` right now." Together they prove KDC endorsed Alice AND the requester is Alice — not someone who merely stole her TGT. |
| 2.6 | TGS cross-validates identities | TGS → internal | **ID_client** from TGT (trusted) vs. **ID_client** from Authenticator1 (claimed) | `ID_client(TGT) == ID_client(Authenticator1)` must match exactly. | Prevents combination attacks: attacker cannot splice Alice's TGT (for KDC endorsement) with their own Authenticator (for key possession). Both pieces must name the same identity. |
| 2.7 | TGS checks timestamp and replay cache | TGS → internal | **TS2** from Authenticator1, TGS replay cache | Freshness check: `|now − TS2| ≤ 5 minutes`. Replay check: (**ID_client**, **TS2**) pair must not exist in replay cache. If new → add to cache → accept. | Replay prevention: captured Authenticator1 from the network cannot be reused. Two checks needed: freshness alone doesn't prevent replay *within* the window. |
| 2.8 | TGS generates service session key | TGS → internal | `Kc,v` = new random key | TGS generates a fresh random `Kc,v` — the key Alice and Server V will use. Independent of `Kc,TGS` and all other session keys. | Per-service, per-session key isolation. Alice's file-server session and mail-server session each have completely separate keys. |
| 2.9 | TGS constructs Service Ticket (Ticket_v) | TGS → internal | `Ticket_v = E(Kv, [Kc,v ‖ ID_client ‖ AD_client ‖ ID_v ‖ TS2 ‖ Lifetime_v])` | TGS assembles Ticket_v sealed with `Kv`. **ID_v** inside the encrypted content binds the ticket to a specific service. | Encrypting with `Kv` means: (1) Alice carries it but cannot read `Kc,v` inside; (2) Alice cannot modify it; (3) Server V trusts contents because only TGS could produce valid `Kv`-encryption. **ID_v** inside prevents misdirecting ticket to a different service. |
| 2.10 | TGS encrypts Kc,v for client | TGS → internal | `Part A = E(Kc,TGS, [Kc,v ‖ ID_v ‖ TS2])` | TGS creates Part A: `Kc,v` wrapped in `Kc,TGS` encryption. Also includes **ID_v** (binds `Kc,v` to specific service) and **TS2** (Alice can verify response freshness). | `Kc,TGS` is the established secure channel between Alice and TGS — created specifically to protect this key delivery. **ID_v** prevents Alice from accidentally or maliciously using `Kc,v` for a different service. **TS2** prevents replay of old TGS responses. |
| 2.11 | TGS sends response | TGS → Alice | Part A + Part B (Ticket_v) | Two-part response: Part A for Alice (sealed with `Kc,TGS`); Part B for Server V (sealed with `Kv`). | Same structural pattern as Phase 1 response. Alice gets both but only opens Part A. |
| 2.12 | Client decrypts Part A from TGS | Alice → internal | Key: `Kc,TGS`; extracts `Kc,v`, **ID_v**, **TS2** | Alice decrypts Part A. Extracts `Kc,v` (stored in credentials cache alongside Ticket_v). Verifies **ID_v** and **TS2**. | Alice and Server V now both have `Kc,v` — Alice from this decryption, Server V from opening Ticket_v in Phase 3. A shared secret established between two parties who have never directly communicated. |

---

## 📖 Phase 2 Discussion

### 🔴 WHY — The Need for a Two-Step Ticket System
Why not just have the AS issue service tickets directly? Why the intermediate TGS step?

The answer is **Single Sign-On (SSO) with minimized password exposure**. If every service access required going back to the AS, the AS would need Alice's `Kc` frequently, and Alice would need to re-derive it (i.e., re-enter her password) frequently. The TGT mechanism solves this: Alice authenticates with her password **once** to get a TGT, then uses the TGT (without touching her password) to get service tickets for any number of services throughout her work session.

### 🟡 HOW — The Authenticator: Proof of Live Presence

The Authenticator is one of Kerberos's most important innovations. Here's the problem it solves:

Imagine Alice's TGT is stolen from her machine. The thief now has the TGT and, from memory, `Kc,TGS`. They can present this TGT to the TGS and request service tickets impersonating Alice. How do we prevent this?

You can't fully prevent it from the protocol side if the session key itself is stolen (that's the Pass-the-Ticket attack, discussed in Phase 4). But the Authenticator provides a time-bounded defense:

- The Authenticator contains **TS2** — the exact current timestamp when Alice created it
- TGS checks `|now − TS2| ≤ 5 minutes`
- TGS maintains a **replay cache** of all (ID_client, TS2) pairs seen in the last 5 minutes

So a captured Authenticator is usable only within a 5-minute window, and even within that window, only once. After 5 minutes, it's completely useless.

### 🟢 WHY Use `Kc,TGS` for the Authenticator, Not `Kc`?

This is a critical design question. `Kc` is Alice's long-term key. `Kc,TGS` is a short-term session key. Why use `Kc,TGS` for the Authenticator?

**Key isolation and limited exposure:** `Kc` should be used as infrequently as possible — it represents Alice's permanent identity. If it were used for Authenticators, every service request would potentially expose it to analysis. Using the short-term `Kc,TGS` means:
- Compromise of `Kc,TGS` is time-bounded (expires with TGT)
- `Kc` remains unexposed for the session duration
- Different phases use different keys: Phase 1 uses `Kc`, Phase 2 uses `Kc,TGS`, Phase 3 uses `Kc,v`

### 💡 The Replay Cache — Why Two Checks?

Why both a freshness check (5-minute window) AND a replay cache?

- **Freshness check alone:** Prevents replays older than 5 minutes, but within the 5-minute window, the same Authenticator could be submitted multiple times simultaneously by multiple attackers
- **Replay cache alone:** Would grow indefinitely if not bounded; also hard to know when to expire entries
- **Both together:** The freshness check bounds the cache size (only entries from the last 5 minutes needed); the cache ensures uniqueness within that window

### 💡 Why Does Ticket_v Contain ID_v Inside the Encrypted Content?

The ticket is sealed with `Kv` — only Server V can open it. But **which** Server V? If `ID_v` were outside the encryption, an attacker could take a Ticket_v issued for the file server, change the `ID_v` label to point to the mail server, and present it there.

With `ID_v` inside the encryption, Server V decrypts the ticket and verifies that `ID_v` matches its own identity. If it doesn't match, the ticket is rejected. A ticket issued for the file server **cannot** be used at the mail server, even if both use the same `Kv` (which they don't — each has its own `Kv`).

### ⚠️ Kerberoasting Attack (Phase 2 Vulnerability)
Because Ticket_v is encrypted with `Kv` (derived from the service account's password in many implementations), an attacker who gets a Ticket_v can attempt offline brute-force against weak service account passwords. This is the Kerberoasting attack, common in Active Directory environments. Defense: use strong, randomly-generated service account passwords or managed service accounts.

---

# Phase 3 — Service Access
> *Client ↔ Server V · Ticket presented · Mutual authentication · Secure session*

| # | Action | Actor → Recipient | Object / Key | What Happens | Why This Design |
|---|---|---|---|---|---|
| 3.1 | Client constructs Authenticator2 for Server V | Alice → internal | `Authenticator2 = E(Kc,v, [ID_client ‖ AD_client ‖ TS3])` | Alice creates a new Authenticator encrypted with `Kc,v`. **TS3** is a third fresh timestamp reading, distinct from TS1 and TS2. Uses `Kc,v`, not `Kc,TGS`. | Each phase uses its own session key, so Authenticators are cryptographically incompatible across phases. Phase 2's Authenticator1 (encrypted with `Kc,TGS`) cannot be replayed against Server V — wrong key. |
| 3.2 | Client sends service access request | Alice → Server V | Ticket_v (opaque, forwarded) + Authenticator2 | Two-part message: TGS-endorsed proof of Alice's identity (Ticket_v) + proof Alice is present now (Authenticator2). | Server V needs both: the TGS endorsement and the live-presence proof. Removing either breaks the model. |
| 3.3 | Server V decrypts Ticket_v | Server V → internal | Key: `Kv`; extracts `Kc,v`, **ID_client**, **AD_client**, **ID_v**, **TS2**, **Lifetime_v** | Server V uses its own `Kv` to open Ticket_v. Extracts `Kc,v` — Server V learns this key for the first time. Checks **ID_v** matches its own name. | **Offline verification**: Server V verifies TGS's endorsement without any network call to KDC or TGS. The protocol scales to thousands of service accesses per second with zero KDC bottleneck. |
| 3.4 | Server V checks Ticket_v validity | Server V → internal | **TS2** + **Lifetime_v** vs. current clock; **AD_client** vs. source IP | Expiry check: `TS2 ≤ now ≤ TS2 + Lifetime_v`. Optional address check: **AD_client** from ticket vs. actual source IP. | Ticket lifetime for services is typically shorter than TGT (e.g., 1–2 hours vs. 8–10 hours). A stolen service ticket has a bounded, short window of usefulness. |
| 3.5 | Server V decrypts Authenticator2 | Server V → internal | Key: `Kc,v` (from Ticket_v in 3.3); extracts **ID_client**, **AD_client**, **TS3** | Server V uses `Kc,v` to decrypt Authenticator2. Successful decryption proves the sender knows `Kc,v`. | Same two-layer verification as Phase 2 step 2.5, now applied by Server V. Layer 1 (Ticket_v): TGS endorsement. Layer 2 (Authenticator2): live key possession. |
| 3.6 | Server V cross-validates and checks timestamp | Server V → internal | **ID_client** from Ticket_v vs. Authenticator2; **TS3** freshness; Server V's replay cache | Three checks: (1) `ID_client(Ticket_v) == ID_client(Authenticator2)`; (2) `|now − TS3| ≤ 5 minutes`; (3) (alice, TS3) not in Server V's own replay cache. All three must pass. | Server V runs all checks **independently** — no central coordinator. Each service maintains its own replay cache. Server V's cache covers Authenticator2 (which was never shown to TGS). |
| 3.7 | Server V grants access (authorization) | Server V → Alice's session | ACL checked against **ID_client** = "alice@REALM.COM" | Server V performs authorization: looks up Alice's permissions. Authentication ≠ authorization. If authorized → access granted. If not → authorization error (distinct from authentication errors). | Kerberos handles authentication only. Each service implements its own authorization policy. Authenticating as Alice doesn't automatically grant access — permissions are checked separately. |
| 3.8 | Server V sends mutual auth response | Server V → Alice | `E(Kc,v, [TS3 + 1])` | Server V takes **TS3** from Authenticator2, increments by exactly 1, encrypts with `Kc,v`, sends to Alice. To produce this: V had to decrypt Ticket_v with `Kv`, extract `Kc,v`, decrypt Authenticator2, extract TS3. **Only the real Server V can execute all these steps.** | An impostor server cannot produce this response — it doesn't know `Kv`, cannot open Ticket_v, cannot extract `Kc,v`, cannot produce `E(Kc,v, [TS3+1])`. This is Alice's proof that Server V is genuine. |
| 3.9 | Client verifies mutual authentication | Alice → internal | Key: `Kc,v`; verifies decrypted value == **TS3 + 1** | Alice decrypts Server V's response. Verifies: (1) decryption succeeds (V knows `Kc,v`); (2) value == TS3+1 (V processed Alice's specific Authenticator); (3) TS3+1 is appropriately recent (not a replayed old mutual-auth message). | **Full mutual authentication achieved**: Server V authenticated Alice (3.3–3.6); Alice authenticated Server V (3.8–3.9). |
| 3.10 | Secure session established | Alice ↔ Server V | `Kc,v` (shared, never transmitted in plaintext) | All application messages encrypted/integrity-protected with `Kc,v`. Neither side transmitted `Kc,v` in plaintext: Alice learned it via `Kc,TGS` encryption; Server V learned it via `Kv` encryption. KDC is completely out of the picture from here. | `Kc,v` expires with Ticket_v. When expired, Alice gets new Ticket_v from TGS (no password re-entry). When TGT expires, Alice re-enters password. Two-tier expiry: service key (security) vs. TGT (usability). |

---

## 📖 Phase 3 Discussion

### 🔴 WHY — The Final Mile Problem
After all the AS and TGS exchanges, Alice finally needs to prove her identity to the actual service she wants to use. But here's the subtlety: Server V has **never directly communicated with Alice before**. It received Ticket_v from Alice — but Ticket_v could have been stolen. The Authenticator bridges this gap.

### 🟡 HOW — The Key Derivation Chain

Notice the clean separation of keys across the three phases:

```
Phase 1 (Alice ↔ AS):     uses Kc       — Alice's long-term key
Phase 2 (Alice ↔ TGS):    uses Kc,TGS  — Phase 1's session key
Phase 3 (Alice ↔ Server V): uses Kc,v  — Phase 2's session key
```

Each phase uses the session key established by the previous phase. This creates a **key hierarchy** where:
- Long-term keys (`Kc`, `K_TGS`, `Kv`) are used minimally
- Short-term keys do all the actual work
- Compromise of a short-term key doesn't expose long-term keys or other short-term keys

### 🟢 WHY Use `Kc,v` for Authenticator2 Instead of `Kc,TGS`?

`Kc,TGS` is the session key for Alice's relationship with the TGS, not with Server V. Using it for communication with Server V would be a security violation because:

1. **Wrong party:** `Kc,TGS` is a secret shared between Alice and TGS. If Alice used it to communicate with Server V, Server V would learn `Kc,TGS` — a key it should never know
2. **No binding:** Using `Kc,TGS` for the service would mean the same key protects all Alice's service communications, violating key isolation
3. **Replay risk:** An Authenticator encrypted with `Kc,TGS` and intended for TGS could theoretically be replayed against Server V if V could decrypt it

`Kc,v` is specific to the Alice ↔ Server V relationship. It's generated fresh for this service, for this session. When it expires, a new one is generated — Server V never accumulates any knowledge about Alice's other session keys.

### 💡 Why Is the Mutual Authentication Response `TS3 + 1`, Not Something Else?

This is a subtle but important design decision. Why not just encrypt `TS3`? Why not some random nonce?

**The `+1` convention proves freshness:** If Server V simply encrypted `TS3` and sent it back, an attacker who intercepted that encrypted value could replay it later. But `TS3 + 1` proves that Server V specifically received **Alice's** Authenticator and computed a response. An attacker cannot generate `TS3 + 1` without:
1. Knowing `Kc,v` (to decrypt Authenticator2 and learn TS3)
2. Knowing `Kv` (to open Ticket_v and learn `Kc,v`)

**Why not `TS3 + 2` or any other increment?** The convention `+1` is specified in the Kerberos RFC. The specific value doesn't matter — what matters is that both sides agree on a convention that proves the server read Alice's specific Authenticator. Alice checks: did I get back TS3+1? If yes, Server V is genuine.

**Why not a random nonce challenge?** Kerberos is designed around timestamps rather than challenge-response to avoid an extra round trip. A challenge-response would require: Alice sends challenge → Server responds → Alice verifies. Timestamps collapse this into a single round trip because both sides know the current time (within the 5-minute tolerance).

### 💡 Why Offline Verification at Server V?

In steps 3.3–3.6, Server V verifies everything locally without calling back to KDC or TGS. This is crucial for:

1. **Scalability:** If Server V had to call the KDC for every service request, the KDC would become a bottleneck for the entire organization's file access, email, printing, etc.
2. **Availability:** If the KDC is temporarily unavailable, existing Kerberos sessions continue working until their tickets expire
3. **Performance:** Local cryptographic operations (decryption + timestamp check) take microseconds; a network call to KDC adds latency

The trade-off is that ticket revocation is not instant. If Alice's account is disabled, any existing service tickets remain valid until they expire naturally.

### ⚠️ Authentication vs. Authorization — Step 3.7
Kerberos proves **who Alice is**. It says nothing about **what Alice is allowed to do**. This is a deliberate separation:
- Step 3.7 (authorization) is entirely Server V's responsibility
- Alice's Kerberos credentials are identity claims, not permission grants
- A compromised Kerberos account gives an attacker Alice's *identity*, not necessarily Alice's *permissions* on every server

---

# Phase 4 — Expiry & Attack Surface
> *Ticket lifecycle · Real-world threats*

| # | Action | Actor → Recipient | Object / Key | What Happens | Why This Design |
|---|---|---|---|---|---|
| 4.1 | Ticket_v expires | Server V (rejects) → Alice | **Lifetime_v** field in Ticket_v vs. current clock | `TS2 + Lifetime_v < now` → Server V rejects with `KRB_AP_ERR_TKT_EXPIRED`. Alice's client automatically goes back to Phase 2 (TGS exchange) to get a fresh Ticket_v. No password re-entry needed as long as TGT is valid. Transparent to Alice. | Short service ticket lifetime minimizes damage from a stolen Ticket_v. Automatic renewal is transparent to users. Two-tier expiry design: service key refreshes silently; full re-auth once per workday. |
| 4.2 | TGT expires | TGS (rejects) → Alice (must re-login) | **Lifetime** field in TGT vs. current clock | `TS1 + Lifetime < now` → TGS rejects. Alice must return to Phase 1 — re-enter password to get new TGT. Old TGT, all cached Ticket_v's, and all session keys are discarded. Typical TGT lifetime = 8–10 hours (one workday). | TGT expiry forces periodic re-authentication. If Alice left her desk, an attacker cannot continue her session beyond TGT lifetime. Automatic expiry — no manual revocation needed. |
| 4.3 | Pass-the-Ticket attack | Attacker → Server V (impersonating Alice) | Stolen from LSASS memory: `TGT` + `Kc,TGS` **or** `Ticket_v` + `Kc,v` | Attacker dumps Alice's machine memory (e.g., Mimikatz), extracts TGT + `Kc,TGS`. Uses these to request service tickets from any machine until TGT expires. Alice's password is never recovered — only temporary tickets. | Kerberos protocol is sound — attacker exploited OS-level credential storage, not the cryptographic protocol. Defenses: Credential Guard (hardware-isolated credential storage), Protected Users group, smart card/PKINIT, short TGT lifetimes. |

---

## 📖 Phase 4 Discussion

### 🔴 WHY — The Importance of Ticket Expiry
Kerberos has no built-in revocation mechanism equivalent to TLS certificate revocation (CRL/OCSP). If Alice's account is disabled in the directory, any currently-issued TGTs and service tickets remain valid until they expire naturally. This is why short ticket lifetimes are critical:

- **Ticket_v lifetime** (typically 1–2 hours): Limits the damage window from a stolen service ticket to at most 1–2 hours of unauthorized access to one specific service
- **TGT lifetime** (typically 8–10 hours): Forces daily re-authentication, limiting the window for a stolen TGT to one workday

### 🟡 HOW — The Two-Tier Renewal Model

When Ticket_v expires:
1. Alice's client automatically contacts TGS with the still-valid TGT
2. Gets a fresh Ticket_v for the service
3. Alice never notices — the application just works

When TGT expires:
1. Next service access fails
2. Alice is prompted to re-enter her password
3. Phase 1 repeats; new TGT and session keys are generated

This two-tier design provides the right balance of security and usability: service tickets expire frequently (security), TGT expires once per workday (usability).

### 🟢 Pass-the-Ticket: The Real-World Attack

Pass-the-Ticket is the most common Kerberos-related attack in enterprise environments. Key points for exam preparation:

**What the attacker gets:** The TGT blob + `Kc,TGS` (or Ticket_v + `Kc,v`). These together are equivalent to a temporary password.

**What they can do:** Present the TGT to any TGS and request service tickets — impersonate Alice for all services she has access to, from any machine, until the TGT expires.

**What they DON'T get:** Alice's actual password. The attack is session-limited, not permanent.

**Why Kerberos isn't "broken":** The Kerberos cryptographic protocol itself remains sound. The attack exploits the OS storing credentials in accessible memory (LSASS on Windows). If the OS protected credential storage, the attack would fail.

**Defenses ranked by effectiveness:**
1. **Credential Guard** — hardware virtualization-based isolation of LSASS; Mimikatz cannot reach credential material
2. **Protected Users security group** — TGTs not cached for high-privilege accounts
3. **Smart card / PKINIT** — TGT cannot be used without physical card present
4. **Short TGT lifetimes** — reduces the window of opportunity
5. **Privileged Access Workstations** — reduce attack surface of admin machines

---

# Practice Questions

## Phase 0–1 Questions

**[Multiple Choice]** What does the KDC store for each client in the Kerberos database?

A) The client's plaintext password  
B) A hash of the client's password (`Kc`)  
C) The client's TGT  
D) The client's public key certificate  

✔ **Answer: B** — `Kc` = hash(password). The raw password is never stored, only its derived key, limiting damage from database theft.

---

**[True/False]** In Phase 1, Alice sends her password encrypted with `K_TGS` to the AS so the AS can verify her identity.

✔ **Answer: False** — Alice sends only her username (**ID_client**), **ID_TGS**, and **TS1** in plaintext. No password or key is sent. The AS verifies Alice implicitly: it encrypts Part A with `Kc`, and only the real Alice (who can derive `Kc` from her password) can decrypt it.

---

**[Short Answer]** Explain the "implicit password verification" mechanism in Kerberos Phase 1. Why does the AS never explicitly say "wrong password"?

✔ **Answer:** The AS encrypts Part A with `Kc` (the key derived from Alice's password). If Alice entered the correct password → derives correct `Kc` → decryption succeeds → valid data extracted. If wrong password → wrong `Kc` → decryption produces garbage → client reports failure. The AS's response is identical in both cases (just ciphertext), so an eavesdropper cannot tell from the response whether the password was correct. Additionally, the attacker would need Alice's response to mount an offline attack.

---

**[Fill in the Blank]** After successfully decrypting Part A in Phase 1, Alice immediately ________ `Kc` from memory because it is no longer needed and represents a high-value target.

✔ **Answer: discards / erases** — `Kc` is the long-term key representing Alice's permanent identity. Minimizing its in-memory lifetime closes the window for memory-dump attacks.

---

**[Multiple Choice]** Why is **TS1** included in both Alice's initial request (Step 1.1) AND in Part A that the AS sends back (Step 1.5)?

A) TS1 in the request tells the AS when to expire the session; TS1 in Part A is just echoed for logging purposes  
B) TS1 in the request helps establish the TGT validity window; TS1 echoed in Part A lets Alice verify the response is fresh and specific to her request  
C) Both occurrences of TS1 are for the AS to detect replay attacks on itself  
D) TS1 is not security-relevant; it is included only for clock synchronization  

✔ **Answer: B** — TS1 serves dual purposes: it anchors the TGT's lifetime (`TS1 + Lifetime = expiry`), and when echoed in Part A, allows Alice to verify she's reading a response to her specific current request and not a replayed old AS response.

---

## Phase 2 Questions

**[Multiple Choice]** When TGS decrypts Alice's TGT (Step 2.3), how does TGS learn `Kc,TGS`?

A) TGS calls the AS via a secure back-channel  
B) `Kc,TGS` is embedded inside the TGT, encrypted with `K_TGS`  
C) Alice sends `Kc,TGS` in plaintext alongside the TGT  
D) TGS derives `Kc,TGS` from Alice's username  

✔ **Answer: B** — The TGT is self-contained proof. AS embedded `Kc,TGS` inside the TGT encrypted with `K_TGS`. TGS opens the TGT with `K_TGS` and extracts `Kc,TGS`. No AS contact needed — this is the key scalability property of Kerberos.

---

**[True/False]** The cross-identity check in Step 2.6 (`ID_client(TGT) == ID_client(Authenticator1)`) is unnecessary because only Alice knows `Kc,TGS` and therefore only Alice could have created the Authenticator.

✔ **Answer: False** — Without this check, an attacker could combine Alice's stolen TGT (providing KDC endorsement for "alice") with an Authenticator the attacker creates using their own `Kc,TGS` claiming to be "alice." The cross-check requires both the TGT identity and the Authenticator identity to match exactly, preventing this combination attack.

---

**[Short Answer]** Why does Ticket_v contain `Kc,v` encrypted inside it (under `Kv`) rather than transmitting `Kc,v` separately to Server V?

✔ **Answer:** The TGS cannot transmit `Kc,v` to Server V directly at ticket-request time — Server V might not even be contacted until hours later, and this would require a live TGS↔Server V communication channel for every ticket. Instead, the TGS embeds `Kc,v` inside Ticket_v sealed with `Kv`. Alice carries Ticket_v to Server V when she actually needs the service. Server V decrypts it with `Kv` and learns `Kc,v` — a shared secret established with Alice without the two ever communicating directly. This is the **self-contained ticket model**.

---

**[Fill in the Blank]** The TGS maintains a ________ cache to prevent an attacker from submitting the same captured Authenticator multiple times within the 5-minute freshness window.

✔ **Answer: replay** — The replay cache records all (ID_client, TS2) pairs seen in the last 5 minutes. If a pair already exists in the cache, the request is rejected with `KRB_AP_ERR_REPEAT`.

---

**[Multiple Choice]** Why does `Kc,v` use a freshly generated random key for each service session, rather than deriving it from `Kc,TGS`?

A) Derivation from `Kc,TGS` would be computationally expensive  
B) Fresh random keys ensure that compromise of one session's key reveals nothing about `Kc,TGS` or any other session's key  
C) The Kerberos RFC mandates random keys for compliance reasons only  
D) `Kc,TGS` is not accessible to TGS when it generates Ticket_v  

✔ **Answer: B** — Key isolation. If `Kc,v` were derived from `Kc,TGS`, compromise of any service session key could potentially expose `Kc,TGS` and cascade. Fresh random keys ensure each session is cryptographically independent.

---

## Phase 3 Questions

**[Multiple Choice]** Why is the mutual authentication response `E(Kc,v, [TS3 + 1])` and not simply `E(Kc,v, [TS3])`?

A) `TS3 + 1` is more computationally difficult to forge  
B) Sending `TS3` back unchanged could allow replay of a captured mutual-auth message from a previous session; `TS3 + 1` proves the server specifically processed Alice's current Authenticator  
C) `TS3` is reserved for use in the replay cache; `TS3 + 1` avoids cache conflicts  
D) The increment ensures the response is larger than 64 bits  

✔ **Answer: B** — If Server V simply returned `TS3`, a captured response from a previous session (where `TS3` happened to have the same value) could be replayed. `TS3 + 1` is an agreed-upon transformation proving Server V received and processed Alice's specific Authenticator. Alice verifies she receives exactly `TS3 + 1`.

---

**[True/False]** In Phase 3 (Step 3.6), Server V contacts the KDC to verify Alice's identity before granting access.

✔ **Answer: False** — Server V performs entirely offline verification. It decrypts Ticket_v with its own `Kv`, extracts `Kc,v`, decrypts Authenticator2, checks timestamps, and cross-validates identities — all locally. This is a core scalability design of Kerberos: the KDC is not in the critical path for service access.

---

**[Short Answer]** Explain why Authenticator2 is encrypted with `Kc,v` instead of `Kc,TGS`. What would break if `Kc,TGS` were used?

✔ **Answer:** 
1. **Wrong secret:** `Kc,TGS` is shared between Alice and TGS — Server V should never learn it. If Authenticator2 used `Kc,TGS`, Server V would need `Kc,TGS` to verify it, which is a key exposure violation.
2. **No service binding:** Using `Kc,TGS` for all service communications would collapse Alice's separate service relationships into one key, eliminating key isolation.
3. **Cross-phase replay:** A Authenticator1 encrypted with `Kc,TGS` (intended for TGS in Phase 2) could potentially be replayed against Server V if Server V could decrypt it.

`Kc,v` is specific to the Alice ↔ Server V relationship and is known only to Alice (from TGS's Part A) and Server V (from Ticket_v).

---

**[Fill in the Blank]** Kerberos achieves mutual authentication: Server V authenticates Alice by verifying the ________ and ________; Alice authenticates Server V by verifying that the server returns ________ encrypted with `Kc,v`.

✔ **Answer:** Ticket_v (plus cross-identity check and timestamp); Authenticator2 (replay cache check); TS3 + 1

---

## Phase 4 / Integrated Questions

**[Multiple Choice]** In a Pass-the-Ticket attack, what does the attacker extract from Alice's machine?

A) Alice's plaintext password and `Kc`  
B) The TGT blob and `Kc,TGS` (or Ticket_v and `Kc,v`)  
C) Server V's long-term key `Kv`  
D) The KDC's `K_TGS`  

✔ **Answer: B** — The attacker extracts the credential cache contents: TGT + `Kc,TGS`. These together enable the attacker to impersonate Alice for all services until the TGT expires. Alice's password is never recovered.

---

**[True/False]** If Alice's account is disabled in the directory while she has an active TGT, all her service tickets immediately become invalid.

✔ **Answer: False** — Kerberos has no real-time revocation mechanism. Existing TGTs and service tickets remain valid until their natural expiry (`Lifetime` and `Lifetime_v` respectively). This is why short ticket lifetimes are a critical security control. Disabling an account stops new TGT issuance but does not revoke outstanding tickets.

---

**[Short Answer]** A security auditor argues that Kerberos is "broken" because Pass-the-Ticket attacks are possible. How would you respond?

✔ **Answer:** The Kerberos cryptographic protocol itself is sound — Pass-the-Ticket exploits OS-level credential storage (LSASS), not any flaw in Kerberos's cryptographic design. The protocol correctly assumes that if an attacker has full access to Alice's machine memory, they can impersonate Alice (this is a reasonable assumption — a fully compromised machine is entirely trusted to the attacker). Kerberos's design correctly limits the damage: the attack is time-bounded by ticket lifetimes (typically ≤8 hours), affects only Alice's identity (not the entire Kerberos realm), and leaves the long-term keys (`Kc`, `Kv`, `K_TGS`) unexposed. The appropriate defense is OS-level hardening (Credential Guard, Privileged Access Workstations), not a change to the Kerberos protocol.

---

# Quick Reference Summary

| Concept | Role in Kerberos | Security Property | Lifetime |
|---|---|---|---|
| `Kc` | Alice's long-term key = hash(password) | Never transmitted on wire; used once per session to decrypt Part A | Permanent (until password change) |
| `K_TGS` | Seals TGTs; shared AS ↔ TGS | Client cannot read or forge TGTs | Permanent (admin-managed) |
| `Kv` | Seals service tickets; unique per service | Compromise of one `Kv` doesn't affect other services | Permanent (admin-managed) |
| `Kc,TGS` | Session key: Alice ↔ TGS | Workhorse of Phase 2; separates session from long-term key | Until TGT expires (~8–10 hrs) |
| `Kc,v` | Session key: Alice ↔ Server V | Unique per Alice-service pair; mutual auth key | Until Ticket_v expires (~1–2 hrs) |
| TGT | KDC-endorsed "passport" carried by client to TGS | Opaque to client; sealed with `K_TGS`; tamper-proof | ~8–10 hours |
| Ticket_v | TGS-endorsed service ticket carried to Server V | Opaque to client; sealed with `Kv`; contains `Kc,v` for V | ~1–2 hours |
| Authenticator | Freshly created proof-of-live-presence | Encrypted with session key; contains timestamp; replay cache enforced | Single use (5-minute window) |
| Timestamp (TS) | Freshness anchor for all exchanges | Prevents replay; requires NTP sync (≤5 min tolerance) | One per exchange |
| Replay Cache | Database of seen Authenticators | Each Authenticator accepted at most once | Rolling 5-minute window |
| KDC | Trusted third party (AS + TGS) | All authentication flows through KDC; single point of failure | Always-on service |
| Mutual Auth | Server proves identity to client via `E(Kc,v, [TS3+1])` | Prevents impersonation by rogue servers | Per-connection |
| Pass-the-Ticket | Attack: steal TGT+`Kc,TGS` from memory | Protocol sound; OS-level defense (Credential Guard) needed | Bounded by TGT lifetime |

---

# Exam Preparation — Integrative Questions

**[Short Answer]** Trace a complete Kerberos authentication from Alice typing her password to Alice reading a file on Server V. List each key used at each step and why that particular key is used.

✔ **Answer:**
1. Alice types password → derives `Kc` = hash(password) locally. **Why `Kc`:** It's the long-term identity key, identical to what KDC has in its database.
2. Alice sends **ID_client, ID_TGS, TS1** to AS (plaintext). **Why no key here:** No credential is sent — verification is implicit.
3. AS sends `E(Kc, [Kc,TGS...])` + TGT = `E(K_TGS, [Kc,TGS...])`. **Why `Kc`:** Only Alice can open it. **Why `K_TGS`:** Only TGS can open it.
4. Alice decrypts Part A with `Kc`, extracts `Kc,TGS`. Discards `Kc`.
5. Alice sends **ID_v** + TGT + `E(Kc,TGS, [ID_client, AD_client, TS2])` to TGS. **Why `Kc,TGS`:** Proves Alice knows the session key; TGS extracts this from TGT.
6. TGS issues Ticket_v = `E(Kv, [Kc,v...])` + Part A = `E(Kc,TGS, [Kc,v...])`. **Why `Kv`:** Only Server V can open it. **Why `Kc,TGS`:** Delivers `Kc,v` securely to Alice.
7. Alice sends Ticket_v + `E(Kc,v, [ID_client, AD_client, TS3])` to Server V. **Why `Kc,v`:** Service-specific, session-specific key.
8. Server V opens Ticket_v with `Kv`, extracts `Kc,v`, decrypts Authenticator. Returns `E(Kc,v, [TS3+1])`. All file access encrypted with `Kc,v`.

---

**[Short Answer]** Compare the three types of Kerberos keys (`Kc`, `Kc,TGS`, `Kc,v`) on four dimensions: how derived, who knows it, how long it lives, what it protects.

✔ **Answer:**

| | `Kc` | `Kc,TGS` | `Kc,v` |
|---|---|---|---|
| **How derived** | hash(Alice's password) — deterministic | Random CSPRNG — generated by AS | Random CSPRNG — generated by TGS |
| **Who knows it** | Alice (re-derives) + KDC database | Alice (from Part A) + TGS (from TGT) | Alice (from TGS Part A) + Server V (from Ticket_v) |
| **Lifetime** | Permanent (until password change) | TGT lifetime (~8–10 hours) | Service ticket lifetime (~1–2 hours) |
| **Protects** | Wraps `Kc,TGS` delivery in Phase 1 | Authenticator1 in Phase 2; wraps `Kc,v` delivery | Authenticator2 in Phase 3; all application data |

---

**[Short Answer]** Identify four distinct security flaws in a simplified "Kerberos-like" scheme where: (1) Alice sends her password `Pc` to AS in plaintext, (2) there is no TGS — each service ticket is obtained directly from AS, (3) tickets contain no timestamp or lifetime, (4) no session key is distributed for client-server communication, (5) no Authenticator is required when presenting a ticket.

✔ **Answer (four flaws, select any four):**
1. **Password sent in plaintext (flaw 1):** `Pc` on the wire can be intercepted by any network observer. Fix: Kerberos never sends the password — only the implicit verification via `Kc` encryption.
2. **No TGS / no SSO (flaw 2):** Alice must send credentials for each service — increased exposure frequency. Fix: TGT issued once; Kc used only in Phase 1.
3. **No timestamp/lifetime in ticket (flaw 3):** A captured ticket can be replayed indefinitely. Fix: Tickets carry `TS` + `Lifetime`; Authenticators carry fresh timestamps checked against a replay cache.
4. **No session key for C↔S communication (flaw 4):** After authentication, all application traffic is unprotected — confidentiality and integrity are not guaranteed. Fix: `Kc,v` distributed via Ticket_v; all traffic encrypted.
5. **No Authenticator required (flaw 5):** Ticket theft (without session key knowledge) is sufficient to access the service — no proof of live presence required. Fix: Authenticator = `E(Kc,v, [ID, TS])` proves key possession and freshness.
6. **No mutual authentication (flaw 6):** Client cannot verify the server's identity — vulnerable to rogue servers. Fix: Server responds with `E(Kc,v, [TS3+1])`.

---

**[Short Answer]** Why does Kerberos require global clock synchronization (NTP within 5 minutes)? What happens if clocks drift beyond the tolerance?

✔ **Answer:** Timestamps are Kerberos's primary freshness mechanism. All replay prevention (Authenticators, replay cache) is based on timestamps. If Alice's clock and the TGS clock are more than 5 minutes apart:
- Authenticator1's **TS2** falls outside TGS's freshness window → TGS rejects with `KRB_AP_ERR_SKEW`
- All Kerberos authentication fails — no new tickets can be issued
- This is both a limitation and a security feature: it forces environments to maintain synchronized clocks, which is a good practice generally

If NTP is compromised and clocks are artificially advanced/reversed, the 5-minute replay window can be manipulated — an attacker who can control NTP can extend the window in which captured Authenticators are accepted.

---

*CS 448/548 Network Security · Kerberos Authentication Protocol · Annotated Study Guide · Spring 2026 · Dr. Lina Pu*
