# SSH Protocol — Deep-Dive Annotated Study Guide
**CS 448/548 Network Security · All 3 Layers · Beginner-to-Expert Edition**

---

> **How to use this guide:** Each protocol layer and key concept is presented as a slide/topic block, followed by a Discussion section that explains *why* each design decision was made — not just *what* happens. The guide uses Simon Sinek's Golden Circle (WHY → HOW → WHAT), workflow tables modelled on the Kerberos study guide, and rich analogies. Practice questions appear after each major topic. A Quick Reference Summary and Exam Integrative Questions close the guide.

---

## Reading Legend

| Symbol / Label | Meaning |
|---|---|
| `Host Key (HK_pub/HK_priv)` | Long-term asymmetric key pair of the server — used for server authentication |
| `Client Key (CK_pub/CK_priv)` | Long-term asymmetric key pair of the client — used for public-key client auth |
| `Session Key (SK)` | Short-term symmetric key — negotiated via Diffie-Hellman; encrypts all session traffic |
| `~/.ssh/authorized_keys` | Server file listing trusted client public keys |
| `~/.ssh/known_hosts` | Client file listing trusted server public keys (fingerprints) |
| `~/.ssh/id_rsa / id_ed25519` | Client's private key file |
| ⚠️ | Security warning or attack surface |
| 💡 | Design insight |
| 🎯 | Analogy |
| 📌 | Key exam fact |

---

# Slide Set 1 — SSH Overview and Position in the Stack

## 📌 Key Concepts at a Glance
- SSH (Secure Shell) is a cryptographic network protocol for **secure remote login**, file transfer, and tunnelling over an **untrusted network**.
- SSH operates at the **Application Layer** of the TCP/IP model but provides security services that span transport and application concerns.
- SSH uses **both asymmetric and symmetric cryptography** — asymmetric for authentication, symmetric for data encryption.
- SSH is a **three-layer protocol stack**: Transport Layer → User Authentication Layer → Connection Layer.
- Contrast with Telnet/rsh: those sent everything in plaintext; SSH encrypts everything including passwords and commands.

## 🌀 Simon Sinek's Golden Circle

| 🔴 WHY — Purpose | 🟡 HOW — Process | 🟢 WHAT — Result |
|---|---|---|
| Before SSH, remote login used Telnet and rsh, which sent **passwords and all data in plaintext** over the network. Any on-path observer could read every keystroke, every command, every file transferred. SSH was created to eliminate this catastrophic exposure. | SSH establishes an encrypted channel first, then authenticates, then multiplexes application channels over that secure pipe. It chains asymmetric cryptography (for identity verification and key exchange) with symmetric cryptography (for bulk data encryption). | All remote login sessions, file transfers (SCP, SFTP), and tunnelled traffic are cryptographically protected — confidential, integrity-checked, and source-authenticated. An on-path attacker sees only random ciphertext. |

## 📖 Beginner-Friendly Deep Dive

### The Problem SSH Solves

Before SSH existed, system administrators used **Telnet** and **rsh (remote shell)** to log into remote servers. These protocols transmitted every character — including your password, your commands, and the server's responses — as **plaintext over the network**. Any device between you and the server could capture your credentials. This was acceptable in the early Internet's "trust everyone" era, but completely unacceptable for modern networked environments.

🎯 **Analogy — The Unencrypted Phone Call:**  
Telnet is like calling your bank from a public payphone, saying your account number and PIN out loud, while a stranger sits next to you taking notes. SSH is like using a phone with end-to-end encryption — the connection still goes through the phone company's infrastructure, but what you say is cryptographically sealed. Even if someone taps the line, they hear noise.

### SSH's Position in the Protocol Stack

SSH sits at the **application layer**, but it is unusual because it provides **transport-level security for other applications**. You can think of SSH as a security wrapper:

```
[ Your Application (shell, SCP, SFTP, port forwarding) ]
            ↓
[ SSH Connection Layer  — multiplexes channels ]
[ SSH User Authentication Layer — verifies who you are ]
[ SSH Transport Layer — encrypts, integrity-checks everything ]
            ↓
[ TCP — reliable stream delivery ]
            ↓
[ IP — routing across the internet ]
```

### Telnet vs SSH — Side-by-Side

| Feature | Telnet | SSH |
|---|---|---|
| Password transmission | **Plaintext** | Encrypted (never visible on wire) |
| Command transmission | **Plaintext** | Encrypted |
| Server authentication | **None** (you trust blind) | Cryptographic (host key verification) |
| Client authentication | Password only | Password, public-key, or more |
| Port | 23 | **22** |
| Status | Obsolete / insecure | Universal standard |

---

# Slide Set 2 — SSH Three-Layer Protocol Architecture

## 📌 Key Concepts at a Glance
- **SSH Transport Layer Protocol:** Server authentication, confidentiality, integrity, optional compression. Runs over TCP port 22.
- **SSH User Authentication Protocol:** Authenticates the *client* to the server. Multiple methods: password, public key, host-based.
- **SSH Connection Protocol:** Multiplexes multiple logical **channels** over one encrypted SSH connection (shell sessions, SCP, port forwarding, X11 forwarding).
- The layers execute **in order** — Transport first, then Authentication, then Connection.

## 🌀 Simon Sinek's Golden Circle

| 🔴 WHY — Purpose | 🟡 HOW — Process | 🟢 WHAT — Result |
|---|---|---|
| A single SSH connection must serve many needs simultaneously — interactive shell, file transfer, port forwarding — without multiplying TCP connections. Separating the protocol into layers allows each concern to be solved cleanly and independently, then composed. | Layer 1 establishes a secure encrypted channel (Transport). Layer 2 verifies the user's identity within that channel (User Auth). Layer 3 opens and manages application channels within the authenticated session (Connection). | A single TCP connection from client to server provides simultaneous shell access, file transfer, and port forwarding — all encrypted and authenticated — through an elegant layered architecture. |

## 📖 Beginner-Friendly Deep Dive

### Layer 1: SSH Transport Layer

This is the **foundation**. Everything built on top of it is protected by what this layer establishes:

**Responsibilities:**
1. **Server authentication** — the client verifies it is talking to the genuine server (not an impostor) using the server's host key.
2. **Key exchange** — client and server use Diffie-Hellman to agree on a shared session key `SK` that was never transmitted over the network.
3. **Confidentiality** — all subsequent data is encrypted using `SK` with a symmetric cipher (AES, ChaCha20, etc.)
4. **Integrity** — a MAC (Message Authentication Code) is appended to every packet so tampering is detected.
5. **Optional compression** — data can be compressed before encryption to save bandwidth.

💡 **Key insight:** The Transport Layer is analogous to TLS — it creates the encrypted tunnel. But unlike TLS, SSH's Transport Layer performs **server-only** authentication. The **client** is not authenticated at this stage.

---

### Layer 2: SSH User Authentication Layer

Once the encrypted tunnel from Layer 1 exists, the client must prove **who they are** to the server. This layer supports multiple methods:

| Method | How it works | Security properties |
|---|---|---|
| **password** | Client sends password inside the encrypted tunnel | Simple; password never exposed on wire because tunnel is already encrypted |
| **publickey** | Client signs a challenge with its private key; server verifies with the corresponding public key from `~/.ssh/authorized_keys` | Strongest; no password ever involved; resistant to password-guessing attacks |
| **hostbased** | Trust based on the client machine's identity (not common) | Less common; less secure than publickey |
| **keyboard-interactive** | Server prompts user for factors (e.g., OTP, challenge questions) | Enables multi-factor authentication |

📌 **Exam note:** SSH User Authentication runs **inside** the already-encrypted Transport Layer channel. This means even password authentication in SSH is secure — the password cannot be intercepted because it travels inside the encrypted tunnel.

---

### Layer 3: SSH Connection Protocol

Once authenticated, the Connection Protocol provides **channel multiplexing**: multiple independent logical data streams over the single underlying SSH session.

**Channel types:**
- **session** — an interactive shell, a single command, SCP/SFTP subsystem
- **direct-tcpip** — local port forwarding (tunnel a local port to a remote host)
- **forwarded-tcpip** — remote port forwarding (expose a remote service locally)
- **x11** — X Window System display forwarding

🎯 **Analogy — The Highway:**  
The TCP connection is a single-lane road between your machine and the server. The SSH Transport Layer paves it with encryption. The Connection Protocol is like adding multiple lanes — each channel is a lane carrying different traffic (shell commands in one lane, file transfer in another, forwarded database port in a third) all over the same underlying road.

---

# Slide Set 3 — SSH Transport Layer: Server Authentication and Key Exchange

## 📌 Key Concepts at a Glance
- Server authentication in SSH uses **asymmetric cryptography** (RSA, ECDSA, Ed25519) via **host keys**.
- Every SSH server has a **long-term host key pair**: `HK_priv` (kept secret on server) and `HK_pub` (shared with connecting clients).
- Client verifies server identity by checking `HK_pub` against its **`~/.ssh/known_hosts`** file — a local trust database.
- **First connection problem (TOFU):** On first connection to a new server, the client has no prior knowledge of `HK_pub` and must decide whether to trust it — this is "Trust On First Use" (TOFU).
- Session key negotiation uses **Diffie-Hellman** — neither side transmits the session key; both independently compute it.
- ⚠️ If the `known_hosts` fingerprint changes unexpectedly → **possible Man-in-the-Middle attack**.

## 🌀 Simon Sinek's Golden Circle

| 🔴 WHY — Purpose | 🟡 HOW — Process | 🟢 WHAT — Result |
|---|---|---|
| Without server authentication, an attacker could intercept the connection and impersonate the server — a classic Man-in-the-Middle (MITM) attack. You would be "securely" communicating with the attacker, thinking you are communicating with your real server. | The server holds a long-term asymmetric key pair. During the handshake, the server proves it knows the private key by signing the key exchange data. The client verifies this signature against its stored copy of the server's public key. | The client is cryptographically certain it is talking to the legitimate server — not an impostor — before any credentials are sent. MITM attacks at the network level are defeated. |

## 📖 Workflow Table: SSH Transport Layer Handshake

| # | Action | Actor → Recipient | Object / Key | What Happens | Why This Design |
|---|---|---|---|---|---|
| T.1 | TCP connection established | Client → Server | TCP SYN/SYN-ACK/ACK | Standard 3-way TCP handshake on port 22. | SSH runs over TCP for reliable, ordered delivery. |
| T.2 | Version exchange | Client ↔ Server | Protocol version strings | Both sides send `SSH-2.0-<implementation>`. If versions incompatible, connection closes. | Ensures both sides agree on the SSH protocol version before doing any cryptographic work. |
| T.3 | Algorithm negotiation | Client ↔ Server | `SSH_MSG_KEXINIT` packets | Each side sends lists of supported algorithms: key exchange, host key type, symmetric cipher, MAC, compression. Intersection (server preferred) is selected. | Cryptographic agility — the protocol is not tied to specific algorithms. Allows upgrading to better algorithms as cryptography advances without changing the protocol. |
| T.4 | Diffie-Hellman key exchange | Client ↔ Server | `g`, `p` (public DH params); `e` = g^x mod p; `f` = g^y mod p | Client picks secret `x`, sends `e = g^x mod p`. Server picks secret `y`, sends `f = g^y mod p`. Both compute `K = g^(xy) mod p`. Neither side ever transmits `x`, `y`, or `K`. | The session key `K` is never transmitted — it is independently computed on both sides. An eavesdropper who captures `e` and `f` cannot compute `K` without solving the Discrete Logarithm Problem. **Forward secrecy:** if long-term host key is later stolen, past sessions remain protected. |
| T.5 | Server signs exchange hash | Server → Client | Signed with `HK_priv`; hash `H` = hash(client_version ‖ server_version ‖ client_kexinit ‖ server_kexinit ‖ server_host_key ‖ e ‖ f ‖ K) | Server computes `H` over all key exchange data and signs it: `sig = Sign(HK_priv, H)`. Sends: server's `HK_pub` + `sig`. | The signature binds the server's identity (`HK_priv` ownership) to the exact key exchange material. An MITM who relays `e` and `f` cannot forge `sig` without knowing `HK_priv`. |
| T.6 | Client verifies server identity | Client → internal | Key: `HK_pub`; checks `sig` against `known_hosts` | Client looks up server's hostname/IP in `~/.ssh/known_hosts`. If found: verifies `sig` using stored `HK_pub`. If not found: TOFU prompt. If fingerprint mismatch: **STARK WARNING** (possible MITM). | `known_hosts` is the client's personal trust database — its equivalent of a CA certificate store. Unlike TLS which uses a hierarchical CA, SSH uses a flat per-user trust database built incrementally. |
| T.7 | Session keys derived | Client ↔ Server (internal) | `SK_enc`, `SK_MAC`, `SK_IV` derived from `K` and `H` | Both sides use `K` and `H` to independently derive matching sets of symmetric keys via a KDF. Each direction gets its own encryption key, MAC key, and IV. | Separate keys per direction prevent certain cross-direction attacks. Deriving from both `K` and `H` ensures the keys are tied to this specific session. |
| T.8 | Encrypted channel activated | Client ↔ Server | All subsequent packets encrypted + MAC'd | Both sides send `SSH_MSG_NEWKEYS`. From this point forward every packet is: `encrypt(SK_enc, data)` + `HMAC(SK_MAC, packet)`. | The Transport Layer has completed its job. The tunnel is live. User Authentication Layer now begins operating inside this encrypted channel. |

## 📖 Deep Dive: Server Authentication and TOFU

### The `known_hosts` File: SSH's Trust Database

When you connect to a server for the **first time**, SSH does something unusual — it asks you:

```
The authenticity of host 'example.com (192.0.2.1)' can't be established.
ED25519 key fingerprint is SHA256:abc123...xyz.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

This is **TOFU — Trust On First Use**. You are being asked to make a one-time trust decision: "Do you believe this fingerprint represents the real server?" If you type `yes`, SSH adds the server's public key to `~/.ssh/known_hosts`:

```
example.com,192.0.2.1 ssh-ed25519 AAAA...base64...
```

On **all subsequent connections**, SSH silently verifies the server's signature against this stored key. If the server's key changes, you see:

```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
```

⚠️ **This warning means:**
1. The server genuinely rotated its host key (legitimate, but unusual), OR
2. You are under a **Man-in-the-Middle attack** — someone is intercepting your connection and presenting their own public key.

🎯 **Analogy — The Office Key Card:**  
Your first day at a new office, you scan your access card and the system doesn't recognize you yet — security manually verifies your identity and registers your card. Every subsequent visit, the card reader verifies your card automatically and instantly. If someone different's card sends "open sesame" on what should be your card reader, the alarm goes off.

### Why SSH Uses TOFU Instead of a CA (like TLS)?

TLS (HTTPS) solves the "how do I trust this server's key?" problem using a **Certificate Authority (CA)** hierarchy: a pre-trusted root CA vouches for intermediate CAs, which vouch for specific websites' certificates. Your browser comes pre-loaded with ~150 root CA certificates.

SSH takes a different approach: **TOFU + manual trust management**. Why?

| | TLS / CA Model | SSH / TOFU Model |
|---|---|---|
| First-contact trust | Automatic (pre-loaded CA) | Manual (user reviews fingerprint) |
| Trust infrastructure | Centralized CAs (potential attack target) | Distributed (each user's `known_hosts`) |
| Revocation | CRL / OCSP | No standard revocation (manual key rotation) |
| Best for | Large-scale public web (millions of anonymous users) | Controlled environments (sysadmins know their servers) |

💡 SSH's TOFU model works because its users are typically **system administrators** who know which servers they are connecting to and can verify fingerprints through an out-of-band channel (phone, IT documentation). For the public web with anonymous users, CA-based TLS is more practical.

---

# Slide Set 4 — SSH User Authentication: Password vs. Public Key

## 📌 Key Concepts at a Glance
- SSH user authentication runs **inside the encrypted Transport Layer tunnel** — credentials are never exposed on the wire.
- **Password authentication:** Client sends the password inside the tunnel. Simple but vulnerable to password guessing, phishing, and brute force. Often disabled on hardened servers.
- **Public-key authentication:** Client proves possession of the private key corresponding to a public key registered in `~/.ssh/authorized_keys` on the server. **No password ever transmitted.** Strongest common method.
- Key files: private key stored locally (`~/.ssh/id_rsa`, `~/.ssh/id_ed25519`); public key on server (`~/.ssh/authorized_keys`).
- The client **signs** a session-specific challenge with its private key; server verifies with the stored public key.

## 🌀 Simon Sinek's Golden Circle

| 🔴 WHY — Purpose | 🟡 HOW — Process | 🟢 WHAT — Result |
|---|---|---|
| Password authentication, while encrypted on the wire, is still vulnerable to password guessing, re-use from other breached sites, and social engineering. Public-key authentication eliminates all password-based attacks: there is no password to guess, steal, or phish — only a private key that never leaves the user's machine. | The user generates an asymmetric key pair locally. The public key is registered on any server they need to access. On login, the server issues a challenge; the client signs it with the private key; the server verifies the signature. | Authentication is provably secure: an attacker on the network sees only the challenge-response exchange, from which the private key cannot be extracted. No dictionary attack, no brute force, no phishing. |

## 📖 Workflow Table: Public-Key Authentication

| # | Action | Actor → Recipient | Object / Key | What Happens | Why This Design |
|---|---|---|---|---|---|
| PK.1 | Client announces intent | Client → Server | `SSH_MSG_USERAUTH_REQUEST` with method="publickey", algorithm, `CK_pub` | Client tells server: "I want to authenticate as username `alice` using public-key method with this public key." Marks as a "probe" (no signature yet). | Lets the server check `authorized_keys` first before the client expends cryptographic work. Server responds with "yes this key is acceptable" or "no." |
| PK.2 | Server checks authorized_keys | Server → internal | `~/.ssh/authorized_keys` lookup by `CK_pub` | Server looks for `CK_pub` in `~/.ssh/authorized_keys`. If found: responds `SSH_MSG_USERAUTH_PK_OK`. If not found: rejects. | Server does not store private keys — only public keys. The `authorized_keys` file is the access control list: "I trust whoever can prove they hold the private key matching one of these public keys." |
| PK.3 | Client signs the challenge | Client → internal | Key: `CK_priv`; signs `session_id ‖ "publickey" ‖ username ‖ algorithm ‖ CK_pub` | Client constructs the data-to-be-signed (includes the `session_id` from the Transport Layer handshake). Signs with `CK_priv`. The signature binds this authentication to this specific SSH session. | Including `session_id` in the signed data means the signature cannot be replayed in a different SSH session — it is session-specific. |
| PK.4 | Client sends full auth request | Client → Server | `SSH_MSG_USERAUTH_REQUEST` with `CK_pub` + `sig` | Client sends the complete authentication request including the signature from PK.3. | The signature is the cryptographic proof of private-key possession. |
| PK.5 | Server verifies signature | Server → internal | Key: `CK_pub` from `authorized_keys` | Server verifies: `Verify(CK_pub, signed_data, sig)`. If valid: authentication succeeds. If invalid: reject (wrong key, corrupted data, or impostor). | Verification is a pure public-key operation. The private key `CK_priv` never left the client's machine — the server never needs to know it. |
| PK.6 | Authentication success | Server → Client | `SSH_MSG_USERAUTH_SUCCESS` | Server sends success. SSH Connection Protocol layer activates. Shell/SFTP/other services now available. | Authentication is complete. The client is now positively identified as `alice` on this server. |

## 📖 Deep Dive: Generating and Deploying SSH Keys

### Generating a Key Pair

```bash
# Generate an Ed25519 key pair (modern, recommended)
ssh-keygen -t ed25519 -C "alice@workstation"

# Generates:
# ~/.ssh/id_ed25519      (PRIVATE KEY — never share this)
# ~/.ssh/id_ed25519.pub  (PUBLIC KEY — safe to distribute)
```

The private key file can optionally be **passphrase-protected**. This adds a second layer of protection: even if an attacker steals the key file, they cannot use it without the passphrase. The passphrase encrypts the private key file locally — it is never sent to the server.

### Deploying the Public Key

```bash
# Copy public key to server (easiest method)
ssh-copy-id alice@server.example.com

# This appends ~/.ssh/id_ed25519.pub to server's ~/.ssh/authorized_keys
```

The `authorized_keys` file on the server contains one public key per line:
```
ssh-ed25519 AAAA...base64... alice@workstation
ssh-rsa AAAA...base64... alice@laptop
```

A single server can trust multiple client public keys. A single client can have multiple key pairs for different servers.

### Password Auth vs Public-Key Auth: Security Comparison

| Attack Vector | Password Auth | Public-Key Auth |
|---|---|---|
| Network sniffing | ✅ Protected (inside encrypted tunnel) | ✅ Protected |
| Password guessing / brute force | ⚠️ Vulnerable (given time) | ✅ Immune (no password to guess) |
| Phishing (user tricked into entering password on fake site) | ⚠️ Vulnerable | ✅ Immune (no password used) |
| Password reuse from other breaches | ⚠️ Vulnerable | ✅ Immune |
| Private key theft from disk | N/A | ⚠️ Vulnerable (mitigated by passphrase) |
| Key revocation | Change password | Remove from `authorized_keys` |

💡 **Best practice on hardened servers:** Disable password authentication entirely in `/etc/ssh/sshd_config`:
```
PasswordAuthentication no
PubkeyAuthentication yes
```

---

## 🧪 Practice Questions — Layers 1–3 and Authentication

**[Multiple Choice]** Which SSH layer is responsible for establishing the encrypted channel?

A) SSH Connection Protocol  
B) SSH User Authentication Protocol  
C) SSH Transport Layer Protocol  
D) TCP Transport Layer  

✔ **Answer: C** — The SSH Transport Layer Protocol is responsible for server authentication, key exchange (Diffie-Hellman), and establishing the symmetric encryption + MAC channel. It runs first, before any user authentication occurs.

---

**[Multiple Choice]** What does a client use to verify a server's identity during the SSH handshake?

A) The server's X.509 certificate signed by a CA  
B) The server's public host key stored in `~/.ssh/known_hosts`  
C) The server's username and password  
D) The session key derived from Diffie-Hellman  

✔ **Answer: B** — SSH uses a TOFU-based trust model. The server's public host key is stored in the client's `~/.ssh/known_hosts` after the first verified connection. On subsequent connections, the server's signature is verified against this stored key.

---

**[True/False]** In SSH public-key authentication, the client's private key is transmitted to the server so the server can verify the client's identity.

✔ **Answer: False.** The private key **never leaves the client's machine**. The client signs a session-specific challenge with its private key and sends only the **signature**. The server verifies the signature using the client's **public key** stored in `~/.ssh/authorized_keys`.

---

**[True/False]** SSH User Authentication is performed before the SSH Transport Layer establishes an encrypted channel.

✔ **Answer: False.** The SSH Transport Layer (encrypted channel) is established **first**. User Authentication runs **inside** the already-encrypted tunnel. This is why even password authentication in SSH is secure — the password is never transmitted in plaintext.

---

**[Short Answer]** What is TOFU in the context of SSH, and what is its security implication?

✔ **Answer:** TOFU = Trust On First Use. On the first connection to a new SSH server, the client has no prior knowledge of the server's host key. The client displays the server's public key fingerprint and asks the user to verify it. If the user accepts, the key is stored in `~/.ssh/known_hosts`. On all subsequent connections, the key is verified automatically. Security implication: If the first connection is made over an untrusted network under an MITM attack, the attacker's key can be trusted instead of the server's. Mitigations include verifying fingerprints out-of-band (IT documentation, phone) before accepting.

---

**[Fill in the Blank]** In SSH, the file `~/.ssh/authorized_keys` on the **server** stores client ________ keys, while the file `~/.ssh/known_hosts` on the **client** stores server ________ keys.

✔ **Answer:** `authorized_keys` stores client **public** keys; `known_hosts` stores server **public** keys (or their fingerprints).

---

**[Short Answer]** Why is Diffie-Hellman used for session key exchange in SSH rather than simply encrypting a session key with the server's host key?

✔ **Answer:** Diffie-Hellman provides **forward secrecy**. If the server's long-term host key (`HK_priv`) is stolen in the future, an attacker who recorded past encrypted sessions cannot decrypt them — because the session key was never transmitted (not even in encrypted form). With DH, the session key `K = g^(xy) mod p` is computed independently on both sides using ephemeral secrets `x` and `y` that are discarded after the handshake. If instead the client had encrypted the session key with `HK_pub`, a future theft of `HK_priv` would allow decrypting all recorded past sessions.

---

# Slide Set 5 — Complete SSH End-to-End Workflow

## 📌 Key Concepts at a Glance
- A complete SSH session comprises three sequential phases: **Transport Handshake → User Authentication → Connection/Session**.
- Each phase occurs strictly after the previous one completes.
- The TCP connection carries everything; SSH adds its own layered framing on top.
- The session key is **never transmitted** — it is derived independently on both sides via Diffie-Hellman.
- Both parties derive **multiple keys** from the DH output: separate encryption keys, MAC keys, and IVs for each direction.

## 📖 Complete SSH Session Workflow Table

| # | Action | Actor → Recipient | Object / Key | What Happens | Why This Design |
|---|---|---|---|---|---|
| **Phase 1: Transport Layer** | | | | | |
| 1 | TCP 3-way handshake | Client → Server | TCP SYN, SYN-ACK, ACK on port 22 | Reliable TCP connection established. | SSH requires reliable ordered delivery — TCP provides this before SSH adds security. |
| 2 | SSH version exchange | Client ↔ Server | `SSH-2.0-OpenSSH_9.x` strings | Both sides announce SSH version. Incompatible versions → connection closed. | Early compatibility check before cryptographic investment. |
| 3 | Algorithm negotiation (`KEXINIT`) | Client ↔ Server | Lists of supported: KEX, host-key type, cipher, MAC, compression | Each side sends its supported algorithm lists. Negotiated set = server's most preferred algorithm from client's list. | Cryptographic agility: supports many algorithms so the protocol doesn't need to change when algorithms age. |
| 4 | Diffie-Hellman key exchange | Client ↔ Server | Client sends `e = g^x mod p`; Server sends `f = g^y mod p`, host key `HK_pub`, and signature `sig` | Client picks random `x`, computes `e`. Server picks random `y`, computes `f`. Both compute shared secret `K = g^(xy) mod p`. Neither `x`, `y`, nor `K` is ever transmitted. | Core of forward secrecy. Session key is derived from information that was never on the wire, so recording the session and later stealing `HK_priv` doesn't help the attacker. |
| 5 | Server signs exchange hash | Server → Client | `HK_priv` signs `H = hash(all_kex_data ‖ K)` | Server computes hash `H` of all key exchange material (both versions, both KEXINIT payloads, `HK_pub`, `e`, `f`, `K`) and signs it with `HK_priv`. | The signature cryptographically binds the server's identity to this specific key exchange. An MITM cannot forge this signature without knowing `HK_priv`. |
| 6 | Client verifies server identity | Client → internal | `HK_pub` from `known_hosts` vs received `HK_pub` | Client verifies: (a) received `HK_pub` matches `known_hosts` entry; (b) `sig` is valid under `HK_pub` over `H`. TOFU prompt if first connection. Fatal error if fingerprint mismatch. | This is the anti-MITM check. A network attacker who intercepts the connection cannot present a valid signature because they don't know `HK_priv`. |
| 7 | Session keys derived | Client ↔ Server (internal) | KDF(K, H, session_id) → `SK_enc_C→S`, `SK_enc_S→C`, `SK_MAC_C→S`, `SK_MAC_S→C`, `IV_C→S`, `IV_S→C` | Both sides use the same inputs (K, H, session_id) and the same KDF to independently derive identical sets of keys. Each direction gets its own encryption key, MAC key, and IV. | Per-direction keys prevent certain reflection attacks. Deriving multiple keys from one KDF ensures all keys are cryptographically independent. |
| 8 | `SSH_MSG_NEWKEYS` exchanged | Client ↔ Server | Unencrypted final exchange | Both sides signal readiness to switch to encrypted mode. | From this point forward, all packets are encrypted + MAC'd. Transport Layer complete. |
| **Phase 2: User Authentication** | | | | | |
| 9 | Client requests auth service | Client → Server | `SSH_MSG_SERVICE_REQUEST` for `ssh-userauth` | Client asks for the user authentication service. Server confirms with `SSH_MSG_SERVICE_ACCEPT`. | Formally activates the authentication layer within the established encrypted tunnel. |
| 10 | Client attempts authentication | Client → Server | `SSH_MSG_USERAUTH_REQUEST` | Client specifies: username, service (`ssh-connection`), and authentication method (password / publickey / etc.) plus credentials. | The credential (password or signature) is sent inside the encrypted tunnel — it cannot be intercepted. |
| 11 | Server evaluates credentials | Server → internal | `~/.ssh/authorized_keys` (for publickey) or PAM/shadow (for password) | For **publickey**: verify sig = Sign(CK_priv, session_id ‖ auth_data) using CK_pub from authorized_keys. For **password**: compare against hashed password in system files. | The two-layer design means the network never sees the raw credential. The server evaluates the credential using its own local security policy. |
| 12 | Auth success or failure | Server → Client | `SSH_MSG_USERAUTH_SUCCESS` or `SSH_MSG_USERAUTH_FAILURE` | On success: Connection layer activates. On failure: client may retry (up to server-configured limit) with different method. | Multiple methods allow fallback (e.g., try publickey first, fall back to password). Rate-limiting retries mitigates brute force. |
| **Phase 3: Connection / Application** | | | | | |
| 13 | Client opens a channel | Client → Server | `SSH_MSG_CHANNEL_OPEN` with type ("session", "direct-tcpip", etc.) | Client requests a logical channel. Server confirms with channel number and window size. | Channel multiplexing: one TCP connection can carry multiple independent data streams simultaneously. |
| 14 | Shell session / command execution | Client ↔ Server | `SSH_MSG_CHANNEL_REQUEST` for "shell" or "exec" | Client requests an interactive shell or command execution on the server. | The most common use case: remote terminal access. |
| 15 | Bidirectional data flow | Client ↔ Server | Application data in `SSH_MSG_CHANNEL_DATA` packets | All shell input (keystrokes) and output (terminal display) flows as channel data — encrypted + MAC'd by the Transport Layer. | End-to-end encryption of all application data: the on-path observer sees only random ciphertext. |
| 16 | Session termination | Client or Server → other | `SSH_MSG_CHANNEL_CLOSE` then `SSH_MSG_DISCONNECT` | One side closes the channel, then the SSH connection. TCP connection closes. Session keys are discarded. | Clean teardown ensures no state lingers. Discarding session keys limits the window during which a memory dump could expose keys. |

---

# Slide Set 6 — SSH vs TLS vs Kerberos: Comparative Analysis

## 📌 Key Concepts at a Glance
- SSH, TLS, and Kerberos all provide authentication and confidentiality but at **different layers and for different purposes**.
- TLS uses **Certificate Authorities** for server authentication; SSH uses **TOFU + known_hosts**; Kerberos uses a **trusted KDC**.
- All three use **symmetric session keys** for bulk data encryption after an asymmetric or shared-secret handshake.
- Kerberos uses **only symmetric cryptography**; SSH and TLS use both asymmetric and symmetric.

## 📖 Comparison Table

| Dimension | SSH | TLS (HTTPS) | Kerberos |
|---|---|---|---|
| **Purpose** | Secure remote shell + file transfer + tunnelling | Secure web (and other) application communication | Enterprise single sign-on: authenticate once, access many services |
| **Protocol Layer** | Application (with transport-level security) | Transport | Application |
| **Server Auth Method** | Host key + TOFU / `known_hosts` | X.509 certificate + CA hierarchy | Symmetric (KDC as trusted third party) |
| **Client Auth Method** | Public key (`authorized_keys`) or password | Optional client certificate or form login | Password-derived symmetric key → TGT → ticket |
| **Session Key Exchange** | Diffie-Hellman (ephemeral) | DH or RSA (DH preferred for forward secrecy) | KDC-generated random key, distributed in encrypted tickets |
| **Forward Secrecy** | Yes (ephemeral DH) | Yes (when ECDHE/DHE cipher suites used) | No (session key distributed by KDC using long-term keys) |
| **Symmetric Crypto Only?** | No | No | **Yes** |
| **Trust Model** | Per-user flat trust database | Hierarchical CA / PKI | Centralized KDC (single point of failure) |
| **Ticket / Token** | None (stateless per session) | None (stateless per session) | TGT + service tickets (stateful, time-limited) |
| **Primary Attack Surface** | MITM on first connection (TOFU), stolen private keys | Compromised CA, weak certificates | KDC compromise, Pass-the-Ticket |
| **Typical Use** | Sysadmin remote access, CI/CD pipelines, DevOps | All HTTPS web traffic | Enterprise Active Directory, Windows domain auth |

---

# Slide Set 7 — SSH Security Vulnerabilities and Defenses

## 📌 Key Concepts at a Glance
- ⚠️ **MITM on first connection:** If TOFU is accepted blindly over an untrusted network, an attacker's key can be trusted.
- ⚠️ **Stolen private key:** If `~/.ssh/id_rsa` is stolen and has no passphrase, the attacker can authenticate anywhere that key is registered.
- ⚠️ **Brute-force against password auth:** If password auth is enabled and the server is exposed to the internet, automated bots will constantly try passwords.
- ⚠️ **SSH agent hijacking:** The ssh-agent stores decrypted private keys in memory; a privileged local attacker can hijack the agent socket.
- 💡 **Defenses:** Disable password auth, use passphrase-protected keys, use `known_hosts` CA signing in enterprise environments, restrict `sshd_config`.

## 📖 Attack Surface and Defense Table

| Attack | How It Works | Why It's Dangerous | Defense |
|---|---|---|---|
| MITM on first connection (TOFU abuse) | Attacker intercepts first SSH connection, presents their own `HK_pub`. User accepts without verifying fingerprint. | Attacker now has a stored "trusted" key. Can MITM all future connections until the user clears `known_hosts`. | Verify fingerprint out-of-band before accepting. Use SSH CA (enterprise) to pre-sign server host keys. |
| Host key compromise | Attacker steals the server's `HK_priv` (e.g., via server compromise). | Can impersonate the server to any client that trusts the old `HK_pub`. | Rotate host keys immediately; use modern algorithms (Ed25519); protect key file permissions (chmod 600). |
| Private key theft (no passphrase) | Attacker copies `~/.ssh/id_rsa`. No passphrase = immediate access. | Can authenticate to any server that has the corresponding public key in `authorized_keys`. | Always use passphrases on private keys. Use hardware security keys (FIDO2/U2F) for high-value keys. |
| Password brute force | Automated bots try millions of username/password combinations against port 22. | Default exposure on the internet; many users have weak passwords. | Disable password auth (`PasswordAuthentication no`). Change port (security-through-obscurity, minor). Use fail2ban. |
| SSH agent hijacking | The ssh-agent process stores decrypted private keys in memory with a socket. A root attacker on the same machine can use the socket. | Can impersonate the legitimate user to any server they're connected to, even without knowing the key or passphrase. | Don't use `ForwardAgent` (`-A`) to untrusted servers. Use `ssh-agent` with key lifetimes (`-t`). |
| Downgrade attack | Attacker tries to force negotiation to weak algorithms during KEXINIT. | Old weak ciphers (RC4, DES, MD5 MAC) have known attacks. | Configure `sshd_config` and `ssh_config` to explicitly list only strong algorithms. Reject weak cipher suites. |

---

## 🧪 Practice Questions — Complete SSH, Comparison, and Security

**[Multiple Choice]** In a complete SSH session, in what order do the three layers execute?

A) User Authentication → Transport → Connection  
B) Connection → Transport → User Authentication  
C) Transport → User Authentication → Connection  
D) Transport → Connection → User Authentication  

✔ **Answer: C** — The SSH Transport Layer establishes the encrypted channel first. User Authentication runs inside that channel second. The Connection Protocol (channels, shell, etc.) activates after successful authentication. This order is mandatory — you cannot authenticate before the channel is encrypted.

---

**[Multiple Choice]** The warning "REMOTE HOST IDENTIFICATION HAS CHANGED" in SSH means:

A) The server has upgraded its SSH software version  
B) The server's public host key no longer matches the `known_hosts` entry — possible MITM attack  
C) The session key negotiation algorithm has changed  
D) The server requires a different authentication method  

✔ **Answer: B** — This warning means the server is presenting a different public key than what was previously stored in `~/.ssh/known_hosts`. This could indicate a server re-key (legitimate) or an MITM attack (dangerous). The user must verify the new fingerprint out-of-band before proceeding.

---

**[True/False]** SSH uses only symmetric cryptography, similar to Kerberos.

✔ **Answer: False.** SSH uses **both** asymmetric and symmetric cryptography. Asymmetric cryptography is used for server authentication (host key signatures) and optionally for client authentication (public-key auth). Symmetric cryptography is used for bulk data encryption after the session key is derived via Diffie-Hellman. Kerberos, by contrast, uses **only** symmetric cryptography.

---

**[True/False]** If an SSH server is configured with `PasswordAuthentication no`, users who have not set up public keys will be locked out.

✔ **Answer: True.** With `PasswordAuthentication no`, the only way to authenticate is via public-key (or other configured methods like `keyboard-interactive` for MFA). A user who has not added their public key to `~/.ssh/authorized_keys` on the server will be unable to log in. This is intentional on hardened servers — it forces the stronger authentication method.

---

**[Short Answer]** Explain what forward secrecy means in the context of SSH, and how Diffie-Hellman key exchange achieves it.

✔ **Answer:** Forward secrecy means that the compromise of a long-term secret (the server's host private key `HK_priv`) does not allow decryption of past recorded sessions. In SSH, Diffie-Hellman achieves this as follows: the session key `K = g^(xy) mod p` is derived from ephemeral secrets `x` (client) and `y` (server) that exist only in RAM during the handshake and are discarded immediately after. Neither `x`, `y`, nor `K` is ever transmitted over the network. Even if an attacker recorded an entire encrypted SSH session AND later stole `HK_priv`, they cannot compute `K` because they never captured `x` or `y`. Without `K`, they cannot decrypt the recorded session.

---

**[Fill in the Blank]** In SSH public-key authentication, the client's ________ key is stored on the server in `authorized_keys`, while the client's ________ key is used to sign the authentication challenge and never leaves the client's machine.

✔ **Answer:** **public** key is stored on the server; **private** key is used to sign and never leaves the client.

---

**[Short Answer]** Compare how SSH and TLS differ in their approach to server authentication.

✔ **Answer:** 
- **TLS** uses a **hierarchical Certificate Authority (CA) model**. The server presents an X.509 certificate signed by a CA. The client trusts the CA (pre-loaded root certificates), and via the CA's signature, transitively trusts the server's certificate. This allows automatic trust without prior contact with the server.
- **SSH** uses a **TOFU (Trust On First Use) + `known_hosts` model**. There is no pre-trusted CA hierarchy. On first connection, the client is shown the server's raw public key fingerprint and must manually accept it. On subsequent connections, the client verifies the fingerprint against its locally stored record. Trust is built individually, per user.
- **Key difference:** TLS suits anonymous users connecting to public services (they trust the CA's judgment). SSH suits sysadmins who know their specific servers and can verify fingerprints out-of-band.

---

**[Multiple Choice]** An attacker captures all traffic from an SSH session today. Two years later, they steal the server's private host key. Can they decrypt the captured session traffic?

A) Yes, because the host key was used to encrypt the session key  
B) Yes, because all SSH traffic is encrypted with the host key  
C) No, because SSH uses ephemeral Diffie-Hellman to derive session keys that were never transmitted  
D) No, because SSH uses asymmetric encryption for all data  

✔ **Answer: C** — SSH uses **ephemeral** Diffie-Hellman. The session key is derived from ephemeral secrets that existed only in RAM during the handshake and were never transmitted. Stealing the host key later cannot decrypt past sessions — this is forward secrecy.

---

# Quick Reference Summary

| Concept | What It Is | Security Property | Lifetime |
|---|---|---|---|
| **Host Key (`HK_pub/HK_priv`)** | Server's long-term asymmetric identity key | Proves server identity; enables session key authentication. Compromise → MITM possible | Long-term (admin-managed, rare rotation) |
| **Client Key (`CK_pub/CK_priv`)** | User's asymmetric key pair for public-key auth | Eliminates password; no credential on wire; compromise mitigated by passphrase | Long-term (user-managed) |
| **Session Key (`SK`)** | Symmetric key derived per session via DH | Never transmitted; forward secrecy; encrypts all session data | Per-session (discarded at session end) |
| **`~/.ssh/known_hosts`** | Client's trust database of server public keys | TOFU-based; prevents MITM after first use | Persistent (user updates manually) |
| **`~/.ssh/authorized_keys`** | Server's trust database of client public keys | Access control list; defines who can log in | Persistent (admin/user manages) |
| **TOFU** | Trust On First Use — accept key on first connect | Weak on first contact; strong afterward. Verify fingerprints OOB | First-connection vulnerability window |
| **Diffie-Hellman** | Key exchange algorithm; both sides compute `K` independently | Session key never transmitted; forward secrecy against future key compromise | Per-handshake (ephemeral) |
| **SSH Transport Layer** | Layer 1: Encrypted channel + server auth | Confidentiality, integrity, server authentication; all data encrypted + MAC'd | Per-session |
| **SSH User Authentication** | Layer 2: Client identity verification | Runs inside encrypted tunnel; supports password, publickey, MFA | Per-session |
| **SSH Connection Protocol** | Layer 3: Channel multiplexing | Multiple independent data streams over one TCP connection | Per-session |
| **`PasswordAuthentication no`** | `sshd_config` option disabling password auth | Eliminates brute-force, password-guessing, and phishing attacks | Permanent config |
| **SSH Agent** | Holds decrypted private keys in memory | Convenience; agent socket can be hijacked by privileged local attacker | Until killed or key removed |
| **Port Forwarding** | Tunnels other protocol traffic through SSH | Bypasses firewalls; encrypted; can be misused to exfiltrate data | Per-channel |
| **`sshd_config`** | Server configuration file | Controls ciphers, auth methods, access controls | Admin-managed |

---

# Exam Preparation — Integrative Questions

**[Short Answer]** Trace a complete SSH public-key authentication session from TCP connection to shell prompt. For each step, identify which SSH layer is active and what cryptographic operation is performed.

✔ **Answer:**
1. **TCP handshake** (TCP layer) — 3-way handshake on port 22. No SSH crypto yet.
2. **Version exchange** (SSH Transport) — Plaintext version strings compared.
3. **KEXINIT** (SSH Transport) — Algorithm lists exchanged and negotiated. No crypto yet.
4. **Diffie-Hellman** (SSH Transport) — Client sends `e = g^x mod p`. Server sends `f = g^y mod p`, `HK_pub`, and `sig = Sign(HK_priv, H)`. Both compute `K = g^(xy) mod p`. **Asymmetric crypto: server signs with `HK_priv`.**
5. **Server verification** (SSH Transport, client-side) — Client verifies `sig` against `HK_pub` from `known_hosts`. **Asymmetric crypto: verification with `HK_pub`.**
6. **Key derivation** (SSH Transport, both sides) — Both independently derive `SK_enc`, `SK_MAC`, etc. from `K`, `H`. No network traffic. **Symmetric key derivation.**
7. **`SSH_MSG_NEWKEYS`** (SSH Transport) — Encrypted channel active.
8. **Service request** (SSH User Auth) — Client requests `ssh-userauth` service inside encrypted tunnel.
9. **Publickey probe** (SSH User Auth) — Client announces intent to use publickey with `CK_pub`.
10. **Server checks `authorized_keys`** — Verifies `CK_pub` is listed.
11. **Client signs challenge** (SSH User Auth) — `sig2 = Sign(CK_priv, session_id ‖ auth_data)`. **Asymmetric crypto: client signs with `CK_priv`.**
12. **Server verifies signature** (SSH User Auth) — `Verify(CK_pub, signed_data, sig2)`. **Asymmetric crypto: verification.**
13. **`SSH_MSG_USERAUTH_SUCCESS`** — Authentication complete. Connection layer activates.
14. **Channel open + shell request** (SSH Connection) — Shell started. All terminal I/O encrypted with `SK_enc`, integrity-checked with `SK_MAC`.

---

**[Short Answer]** Identify three distinct ways SSH is more secure than Telnet, with specific reference to the protocol mechanisms that provide each security property.

✔ **Answer:**
1. **Confidentiality of all data (including passwords):** Telnet sends every character as plaintext. SSH Transport Layer encrypts all data with a symmetric session key derived via Diffie-Hellman. No credential or command is ever visible to a network observer.
2. **Server authentication:** Telnet has no mechanism to verify the server's identity — you simply trust you connected to the right IP. SSH authenticates the server using its host key: the server signs the DH exchange hash with `HK_priv`; the client verifies against `known_hosts`. MITM attacks that intercept and impersonate the server are cryptographically defeated (the attacker cannot forge the signature without `HK_priv`).
3. **Strong client authentication (public-key):** Telnet uses only plaintext passwords. SSH supports public-key authentication where the client proves private-key possession by signing a session-specific challenge. No password is involved; dictionary attacks and brute force are completely ineffective.

---

**[Short Answer]** An organization wants to deploy SSH across 500 servers without relying on manual `known_hosts` management. Describe how an SSH Certificate Authority (SSH CA) can solve this, and contrast it with the default TOFU model.

✔ **Answer:** In the **TOFU model**, every user must manually verify each server's fingerprint and build their `known_hosts` database over time. Across 500 servers, this is error-prone and doesn't scale.

With an **SSH CA:** (1) The organization generates a CA key pair. (2) Each server's host key is signed by the CA: `cert = Sign(CA_priv, HK_pub ‖ server_metadata)`. (3) The signed host certificate is deployed on the server. (4) Each client's SSH config is updated with `@cert-authority *.company.com CA_pub` in `~/.ssh/known_hosts` or the system `known_hosts`. (5) When a client connects to any server, SSH verifies the server's host certificate against the CA public key — automatic, no per-server `known_hosts` entries needed.

This mirrors the TLS/CA model: a single trusted root (the SSH CA) vouches for all servers. If a server is compromised, only its certificate needs to be revoked (via `RevokedKeys` in `sshd_config`). New servers can be added to the fleet without updating every client's `known_hosts`.

**Contrast:** TOFU — distributed, per-user trust, no central management, scales poorly. SSH CA — centralized, automated trust, scales to thousands of servers and users.

---

**[Short Answer]** A security audit finds that a company's SSH server allows password authentication from the public internet. What two attacks does this enable and what configuration change mitigates both?

✔ **Answer:**
1. **Brute-force / dictionary attacks:** Automated bots (botnets) continuously attempt logins with common username/password combinations. Given enough time and if rate-limiting is absent, accounts with weak passwords will be compromised.
2. **Credential stuffing:** Passwords stolen from breaches of other services are tried against SSH. Many users reuse passwords, so a leaked password from site A may work on the company's SSH server.

**Mitigation:** Set `PasswordAuthentication no` in `/etc/ssh/sshd_config` and restart sshd. This forces public-key authentication for all users. Both attacks rely on the existence of a password to guess — with no password accepted by the server, both attacks are completely neutralized.

---

*CS 448/548 Network Security · SSH Protocol · Deep-Dive Annotated Study Guide · Spring 2026 · Dr. Lina Pu*
