# Diffie-Hellman Key Exchange — Deep-Dive Annotated Study Guide

> **CS 448 / 548 • Network Security**
> Spring 2026 • Dr. Lina Pu
> Based on Stallings [C]/[N], Lecture slides, and Exam Review materials

---

> 📘 **How to Use This Guide**
> Each slide section follows a consistent structure to build deep, lasting understanding:
> - 📌 **Key Concepts at a Glance** — Quick memory anchors
> - 🌀 **Simon Sinek's Golden Circle** — WHY (purpose) → HOW (mechanism) → WHAT (result)
> - 📖 **Beginner-Friendly Deep Dive** — Plain-English narrative with analogies
> - 📊 **Workflow Tables** — Step-by-step protocol breakdowns (like the Kerberos guide)
> - 🧪 **Practice Questions** — Multiple Choice, True/False, Short Answer, Fill in the Blank

---

## TABLE OF CONTENTS

1. [Slide 1 — The Key Exchange Problem](#slide-1--the-key-exchange-problem)
2. [Slide 2 — Mathematical Foundations: Modular Arithmetic](#slide-2--mathematical-foundations-modular-arithmetic)
3. [Slide 3 — The Discrete Logarithm Problem (DLP)](#slide-3--the-discrete-logarithm-problem-dlp)
4. [Slide 4 — The Diffie-Hellman Protocol — Overview](#slide-4--the-diffie-hellman-protocol--overview)
5. [Slide 5 — DH Step-by-Step: Full Protocol Walkthrough](#slide-5--dh-step-by-step-full-protocol-walkthrough)
6. [Slide 6 — Why the Shared Secret Works (The Math)](#slide-6--why-the-shared-secret-works-the-math)
7. [Slide 7 — Worked Numerical Example](#slide-7--worked-numerical-example)
8. [Slide 8 — Security of Diffie-Hellman](#slide-8--security-of-diffie-hellman)
9. [Slide 9 — The Man-in-the-Middle (MITM) Attack on DH](#slide-9--the-man-in-the-middle-mitm-attack-on-dh)
10. [Slide 10 — Authenticated DH: Defeating MITM](#slide-10--authenticated-dh-defeating-mitm)
11. [Slide 11 — DH vs RSA for Key Exchange](#slide-11--dh-vs-rsa-for-key-exchange)
12. [Slide 12 — Elliptic Curve Diffie-Hellman (ECDH)](#slide-12--elliptic-curve-diffie-hellman-ecdh)
13. [Slide 13 — Forward Secrecy and Ephemeral DH (DHE / ECDHE)](#slide-13--forward-secrecy-and-ephemeral-dh-dhe--ecdhe)
14. [Slide 14 — DH in Practice: TLS and Real-World Protocols](#slide-14--dh-in-practice-tls-and-real-world-protocols)
15. [Quick Reference Summary](#quick-reference-summary)
16. [Exam Preparation — Integrative Questions](#exam-preparation--integrative-questions)

---

## SLIDE 1 — THE KEY EXCHANGE PROBLEM

### 📌 Key Concepts at a Glance

- Symmetric encryption (AES) is fast and secure — but **both parties must share a secret key first**.
- Over an insecure network, how do two strangers securely agree on a shared secret **without ever meeting**?
- This is the **Key Exchange Problem** — one of the most important unsolved problems in cryptography until 1976.
- Diffie-Hellman (DH) solved this problem for the first time, enabling modern secure communication.
- DH is **NOT** an encryption algorithm — it is a **key agreement protocol**.

---

### 🌀 Understanding via Simon Sinek's Golden Circle

| 🔴 **WHY — Purpose** | 🟡 **HOW — Process** | 🟢 **WHAT — Result** |
|---|---|---|
| Before any two parties can communicate privately using symmetric encryption (like AES), they must share a secret key. But how do you safely hand someone a key over a public network that everyone can see? This is the fundamental bootstrapping problem of all cryptography. | Diffie-Hellman uses a mathematical one-way function based on **modular exponentiation** and the **discrete logarithm problem** to allow two parties to each contribute a piece of a puzzle. Each piece is public, but the combination — the shared secret — can only be computed by the two parties who know their own private inputs. | Two parties who have never met and share no prior secrets can compute **the same shared secret** by exchanging only public values over an insecure channel — and an eavesdropper who sees all the public exchanges cannot compute the secret. |

---

### 📖 Beginner-Friendly Deep Dive

#### 🎨 The Paint Mixing Analogy (The Classic Explanation)

This is the most famous analogy for Diffie-Hellman, and it is genuinely perfect:

Imagine Alice and Bob want to agree on a **secret paint color**, but Eve is watching everything they do in public.

1. **Public agreement**: Alice and Bob publicly agree on a common starting paint color — say, **yellow**. Eve knows this.
2. **Private secrets**: Alice secretly picks **red** and mixes it into her yellow → gets **orange** (her public color). Bob secretly picks **blue** and mixes it into his yellow → gets **teal** (his public color).
3. **Public exchange**: Alice sends her orange to Bob. Bob sends his teal to Alice. Eve sees orange and teal — but she doesn't know what private colors were mixed in.
4. **Final mixing**: Alice takes Bob's teal and mixes in her secret red → gets the **final color**. Bob takes Alice's orange and mixes in his secret blue → gets the **same final color**!

**Eve's problem**: Eve saw yellow (public), orange (Alice's public), and teal (Bob's public). To get the final color, she needs to "unmix" the paint — separate a color mixture back into its components. **Paint mixing is one-way** — this is computationally infeasible. In mathematics, this corresponds to solving the **discrete logarithm problem**.

#### Why This Matters So Much

Before 1976, the ONLY way to establish a shared secret key was:
- **Physical courier**: Literally carrying a key in a briefcase (used by governments and militaries).
- **Key distribution centers**: A trusted third party that everyone shared a key with in advance.

Both approaches are **completely impractical at Internet scale**. When you visit a new website for the first time, there is no pre-shared key. There is no courier. Diffie-Hellman (and its descendants like ECDHE) are what make your HTTPS connection possible, right now, with a server you have never contacted before.

---

### 🧪 Practice Questions — Topic 1

**[Multiple Choice]** What problem does Diffie-Hellman primarily solve?
- A) Encrypting large amounts of data efficiently
- B) Securely agreeing on a shared secret key over an insecure channel
- C) Digitally signing messages to prove authenticity
- D) Storing passwords securely in databases

> ✔ **Answer: B**. DH is a *key agreement* protocol. It does not encrypt data itself — it establishes the shared key that AES (or another symmetric cipher) then uses to encrypt data.

---

**[True/False]** Diffie-Hellman is an encryption algorithm like AES.

> ✔ **Answer: False.** DH is a *key exchange/agreement* protocol. It establishes a shared secret, but the actual encryption of data is done by a separate symmetric cipher (like AES) using that shared secret as the key.

---

**[Fill in the Blank]** The key exchange problem is: how do two parties establish a shared ________ over an ________ channel without meeting in advance?

> ✔ **Answer:** shared **secret key** over an **insecure** (public) channel.

---

## SLIDE 2 — MATHEMATICAL FOUNDATIONS: MODULAR ARITHMETIC

### 📌 Key Concepts at a Glance

- **Modular arithmetic** is arithmetic with a "wraparound" — like a clock.
- `a mod n` = the remainder when `a` is divided by `n`.
- Example: `17 mod 5 = 2` (17 = 3×5 + 2)
- **Modular exponentiation**: Computing `g^x mod p` — easy to calculate forward, hard to reverse.
- `Z_p*` = the set {1, 2, 3, ..., p−1} — the multiplicative group modulo a prime `p`.
- A **generator** `g` of `Z_p*` means that `g^1, g^2, g^3, ...` produces every element of `Z_p*` before cycling.
- DH uses **prime** `p` because primes create the richest, most unpredictable cycle structure.

---

### 🌀 Understanding via Simon Sinek's Golden Circle

| 🔴 **WHY — Purpose** | 🟡 **HOW — Process** | 🟢 **WHAT — Result** |
|---|---|---|
| DH needs a mathematical operation that is **easy in one direction and infeasible in reverse**. Modular exponentiation provides exactly this property at scale — with large primes, forward computation takes milliseconds while reverse computation would take longer than the age of the universe. | Given a prime `p` and a generator `g`, computing `g^x mod p` for known `g`, `x`, `p` is straightforward. But given only `g`, `p`, and the result `y = g^x mod p`, recovering `x` (the discrete logarithm) is computationally infeasible for large `p`. | The asymmetry between forward (easy) and reverse (hard) computation forms the **mathematical trapdoor** that makes DH secure. Public values can be shared freely; private exponents cannot be recovered from them. |

---

### 📖 Beginner-Friendly Deep Dive

#### The Clock Analogy for Modular Arithmetic

A clock has 12 positions. If it is 10 o'clock and you add 5 hours, you get 3 o'clock — not 15. This is `(10 + 5) mod 12 = 3`.

Modular arithmetic works identically. `17 mod 5 = 2` because `17 = 3×5 + 2` — the remainder is 2.

#### Why Modular Exponentiation Is "One-Way"

Consider this problem:

- **Forward (easy)**: "What is `3^13 mod 17`?" — Just compute: `3^13 = 1,594,323`, then divide by 17 and take the remainder. Answer: `12`. Your calculator does this in an instant. For huge numbers, we use the **Square-and-Multiply** algorithm — still fast.
- **Reverse (hard — the Discrete Log Problem)**: "I know `g=3`, `p=17`, and the result is `12`. What is `x`?" — For small numbers, you could try x=1,2,3,... until you find it. But for a prime `p` with **2048 bits** (a number with 617 decimal digits), there is no known efficient algorithm. The best known methods would take more computing power than the entire world possesses.

#### Generators and Z_p*

For prime `p`, the group `Z_p* = {1, 2, 3, ..., p-1}`. A generator `g` is a number such that:
```
g^1 mod p, g^2 mod p, g^3 mod p, ..., g^(p-1) mod p
```
...produces **every** number in `{1, 2, ..., p-1}` exactly once before cycling.

**Example with p=7, g=3:**
```
3^1 mod 7 = 3
3^2 mod 7 = 2
3^3 mod 7 = 6
3^4 mod 7 = 4
3^5 mod 7 = 5
3^6 mod 7 = 1  ← back to start
```
All 6 elements of `{1,2,3,4,5,6}` appear — `g=3` is a generator of `Z_7*`. Not every number is a generator; DH specifically requires choosing a true generator.

---

### 🧪 Practice Questions — Topic 2

**[Multiple Choice]** What is `7^3 mod 11`?
- A) 343
- B) 2
- C) 7
- D) 5

> ✔ **Answer: B**. `7^3 = 343`. `343 ÷ 11 = 31` remainder `2`. So `343 mod 11 = 2`.

---

**[True/False]** For DH to be secure, computing `g^x mod p` from known `g` and `x` must be computationally infeasible.

> ✔ **Answer: False.** The *forward* direction (computing `g^x mod p`) must be *easy*. The *reverse* direction (recovering `x` from `g^x mod p`) must be infeasible. This asymmetry is the security foundation.

---

**[Short Answer]** What is a "generator" `g` in the context of `Z_p*`?

> ✔ **Answer:** A generator `g` is a number such that the sequence `g^1 mod p, g^2 mod p, ..., g^(p-1) mod p` produces every integer in `{1, 2, ..., p-1}` exactly once. It "generates" the entire multiplicative group. DH requires `g` to be a generator so that private exponents `x` map uniformly across all possible values — preventing statistical attacks.

---

**[Fill in the Blank]** The security of DH relies on the computational difficulty of solving the ________ problem: given `g`, `p`, and `g^x mod p`, find `x`.

> ✔ **Answer:** **Discrete Logarithm** problem (DLP).

---

## SLIDE 3 — THE DISCRETE LOGARITHM PROBLEM (DLP)

### 📌 Key Concepts at a Glance

- **Discrete Logarithm Problem (DLP)**: Given `y = g^x mod p`, find `x`. This is believed to be computationally infeasible for large `p`.
- The DLP is the **mathematical hardness assumption** upon which DH security rests.
- **No efficient algorithm** exists for solving the DLP in general — the best known (General Number Field Sieve) runs in sub-exponential but super-polynomial time.
- DH security requires: `p` is a **large prime** (≥ 2048 bits recommended today), `g` is a valid generator, private exponents `x` are chosen randomly.
- The DLP is related to but **distinct from** the integer factorization problem (RSA's basis).

---

### 🌀 Understanding via Simon Sinek's Golden Circle

| 🔴 **WHY — Purpose** | 🟡 **HOW — Process** | 🟢 **WHAT — Result** |
|---|---|---|
| Every public-key cryptosystem needs a mathematical problem that is easy to compute in one direction but practically impossible to reverse. DH chose the DLP because modular exponentiation is fast (polynomial time) while the inverse (discrete log) has no known polynomial-time solution. | Alice picks a random secret `x`, computes `g^x mod p` in milliseconds using Square-and-Multiply, and publishes this public value. Eve, who wants to find `x`, faces the DLP — she must search exponential space without any shortcut. | As long as `p` is large enough and the DLP remains hard (no polynomial algorithm discovered), the DH public values can be published openly with no loss of security — a remarkable property. |

---

### 📖 Beginner-Friendly Deep Dive

#### The Asymmetry in Numbers

Let us make the asymmetry viscerally concrete with current computing power estimates:

| Operation | Key Size | Time Required |
|---|---|---|
| Compute `g^x mod p` (forward) | Any | **Milliseconds** (Square-and-Multiply) |
| Solve DLP for `p` = 512 bits | 512-bit | Hours to days (broken!) |
| Solve DLP for `p` = 1024 bits | 1024-bit | Computationally expensive (not recommended) |
| Solve DLP for `p` = 2048 bits | 2048-bit | **Infeasible** with current technology |
| Solve DLP for `p` = 3072 bits | 3072-bit | **Infeasible** for the foreseeable future |

#### Why the DLP Is Hard

The intuition: modular arithmetic "scrambles" the output. When you compute `g^x mod p`, the result bounces around `{1, ..., p-1}` in a pattern that looks completely random unless you know `x`. Given just the output value, there is no mathematical "shortcut" to unwinding the exponent — you are left with essentially trying all possibilities.

The best known classical algorithm — the **Index Calculus / General Number Field Sieve** — runs in time roughly proportional to `exp((log p)^(1/3))`. For `p` = 2048 bits, this is still **astronomically large**.

#### DLP vs. Integer Factorization

| Property | DLP (DH) | Integer Factorization (RSA) |
|---|---|---|
| **Easy direction** | `g^x mod p` — compute given `g`, `x`, `p` | `n = p × q` — multiply two primes |
| **Hard direction** | Find `x` given `g^x mod p`, `g`, `p` | Find `p`, `q` given only `n` |
| **Best classical attack** | GNFS / Index Calculus | GNFS |
| **Quantum threat** | **Broken** by Shor's algorithm | **Broken** by Shor's algorithm |
| **Key sizes for 128-bit security** | 3072-bit `p` | 3072-bit `n` |

> ⚠️ **Quantum Warning**: Shor's algorithm (quantum computing) can efficiently solve both the DLP and integer factorization. This is why **post-quantum cryptography** (lattice-based, hash-based schemes) is being standardized by NIST to replace DH and RSA.

---

### 🧪 Practice Questions — Topic 3

**[Multiple Choice]** What is the discrete logarithm problem?
- A) Given `x` and `p`, find `g^x mod p`
- B) Given `g`, `p`, and `y = g^x mod p`, find `x`
- C) Given `p` and `q`, find their product `n`
- D) Given `n`, factor it into primes `p` and `q`

> ✔ **Answer: B.** The DLP asks: given the public values `g`, `p`, and the result `y`, recover the private exponent `x`. This is computationally infeasible for large `p`.

---

**[True/False]** The Discrete Logarithm Problem and the Integer Factorization Problem (used by RSA) are the same mathematical problem.

> ✔ **Answer: False.** They are related in difficulty but mathematically distinct. DLP: find `x` given `g^x mod p`. Integer Factorization: find prime factors of a composite number `n`. Both are believed hard classically; both are broken by Shor's quantum algorithm.

---

**[Short Answer]** Why does increasing the prime `p` from 1024 bits to 2048 bits dramatically improve DH security?

> ✔ **Answer:** The best known DLP algorithms (Index Calculus, GNFS) have sub-exponential but super-polynomial time complexity roughly proportional to `exp((log p)^(1/3) × (log log p)^(2/3))`. When `p` doubles in bit-length, the search space grows exponentially faster than the doubling suggests. Going from 1024 to 2048 bits increases attacker effort by many orders of magnitude, moving from "computationally expensive but feasible for nation-states" to "infeasible with current and near-future computing resources."

---

## SLIDE 4 — THE DIFFIE-HELLMAN PROTOCOL — OVERVIEW

### 📌 Key Concepts at a Glance

- DH involves two parties: conventionally **Alice** and **Bob**.
- **Public parameters** (known to everyone, including Eve): prime `p` and generator `g`.
- **Alice's private key**: randomly chosen `X_A ∈ {2, ..., p-2}`.
- **Bob's private key**: randomly chosen `X_B ∈ {2, ..., p-2}`.
- **Alice's public value**: `Y_A = g^(X_A) mod p` — sent publicly to Bob.
- **Bob's public value**: `Y_B = g^(X_B) mod p` — sent publicly to Alice.
- **Shared secret**: Both parties compute `K = g^(X_A × X_B) mod p` — Alice computes `Y_B^(X_A) mod p`, Bob computes `Y_A^(X_B) mod p`. They arrive at the **same value** K.

---

### 🌀 Understanding via Simon Sinek's Golden Circle

| 🔴 **WHY — Purpose** | 🟡 **HOW — Process** | 🟢 **WHAT — Result** |
|---|---|---|
| Two parties need a shared secret they can use as a symmetric encryption key. They cannot meet in advance. They communicate over a channel that Eve monitors completely. The goal is to make Eve's position mathematically hopeless despite seeing everything Alice and Bob exchange. | Alice and Bob each pick a random private number, compute a public "commitment" using modular exponentiation, exchange these public commitments, and then each applies their own private number to the other's commitment. The mathematics of modular exponentiation guarantees they arrive at the same shared value. | Alice and Bob share a secret `K` that Eve cannot compute — even though Eve saw `g`, `p`, `Y_A`, and `Y_B`. Eve faces the DLP to recover either private exponent, which is computationally infeasible. |

---

### 📖 Beginner-Friendly Deep Dive

#### The Protocol at a High Level — One Sentence Each

| Party | What They Do |
|---|---|
| **Alice & Bob** | Publicly agree on `p` (large prime) and `g` (generator) |
| **Alice** | Secretly picks `X_A`, computes `Y_A = g^(X_A) mod p`, sends `Y_A` to Bob |
| **Bob** | Secretly picks `X_B`, computes `Y_B = g^(X_B) mod p`, sends `Y_B` to Alice |
| **Alice** | Computes shared key `K = Y_B^(X_A) mod p` |
| **Bob** | Computes shared key `K = Y_A^(X_B) mod p` |
| **Eve** | Sees `p`, `g`, `Y_A`, `Y_B` — but cannot compute `K` without solving the DLP |

#### The Magic: Why They Compute the Same K

This is the mathematical heart of the protocol:

```
Alice computes:  K = Y_B^(X_A) mod p
               = (g^X_B)^X_A mod p
               = g^(X_B × X_A) mod p

Bob computes:    K = Y_A^(X_B) mod p
               = (g^X_A)^X_B mod p
               = g^(X_A × X_B) mod p

Since X_A × X_B = X_B × X_A:  BOTH = g^(X_A × X_B) mod p ✓
```

Multiplication is commutative, and modular exponentiation obeys the rule `(g^a)^b = g^(ab)`. These two facts together guarantee that Alice and Bob compute identical values despite computing in different orders.

---

## SLIDE 5 — DH STEP-BY-STEP: FULL PROTOCOL WALKTHROUGH

### 📌 Key Concepts at a Glance

Below is the complete Diffie-Hellman protocol broken into atomic steps, mirroring the Kerberos workflow table format.

---

### 📊 Diffie-Hellman Protocol — End-to-End Workflow

#### Pre-Protocol: Public Parameter Setup

| Step | Actor | Action | Object/Value | What Happens | Why This Design | Security Guarantee |
|---|---|---|---|---|---|---|
| **0.1** | Standards body or Alice | Agree on prime `p` | `p` — large prime (≥ 2048 bits) | Alice (or a standards body) selects or reuses a published safe prime `p`. A **safe prime** is one where `p = 2q + 1` with `q` also prime — this eliminates certain subgroup attacks. `p` is published openly. | Using a large prime maximizes the difficulty of the DLP. Safe primes provide the strongest security structure. Reusing standardized primes (RFC 3526 groups) avoids weak parameter selection errors. | A 2048-bit prime means the DLP search space is 2^2048 — computationally infeasible. |
| **0.2** | Standards body or Alice | Choose generator `g` | `g` — primitive root of `Z_p*` | Select `g` such that `g^1, g^2, ..., g^(p-1)` generates all elements of `{1, ..., p-1}`. Typical small values like `g=2` or `g=5` are often valid generators for standardized primes. `g` is published openly alongside `p`. | A generator ensures Alice's and Bob's private exponents map uniformly to all possible public values — if `g` were not a generator, only a fraction of `{1,...,p-1}` would be reachable, drastically reducing security. | Private exponents are uniformly distributed. Eve cannot exploit a weak cycle structure if `g` is a proper generator. |

---

#### Phase 1: Alice's Side

| Step | Actor | Action | Object/Value | What Happens | Why This Design | Security Guarantee |
|---|---|---|---|---|---|---|
| **1.1** | Alice | Generate private key | `X_A` — random integer, `2 ≤ X_A ≤ p-2` | Alice calls a **cryptographically secure random number generator (CSPRNG)** to produce `X_A`. This number is never revealed to anyone — it is Alice's permanent secret for this session. It has a lifetime matching the session; for ephemeral DH, it is discarded after one use. | `X_A` must be uniformly random from the full range `{2,...,p-2}`. A weak RNG is catastrophic — if `X_A` is predictable, Eve can compute it directly and break the entire protocol. The session-scoped lifetime limits exposure. | `X_A` is a 2048-bit random number. An attacker guessing it at random has probability 1/2^2048 per guess — computationally hopeless. |
| **1.2** | Alice | Compute public value | `Y_A = g^(X_A) mod p` | Alice applies **modular exponentiation** using the Square-and-Multiply algorithm: represent `X_A` in binary, then iteratively square and conditionally multiply. For a 2048-bit `p`, this takes ~3,000 modular multiplications — completing in under a millisecond on modern hardware. | The forward computation is fast (polynomial via Square-and-Multiply) while the reverse (recovering `X_A` from `Y_A`) is infeasible (DLP). This one-way function property is the entire basis of DH. | `Y_A` can be published openly. It reveals nothing computationally useful about `X_A`. |
| **1.3** | Alice | Send public value | `Y_A` transmitted over insecure channel | Alice sends `Y_A` to Bob over the network. Eve can — and does — intercept and record `Y_A`. This is intentional and acceptable. | Publishing `Y_A` is the entire point of asymmetric cryptography: one half of the protocol is designed to be openly visible. The security guarantee comes from the DLP, not from hiding `Y_A`. | Eve learns `Y_A` completely. This gives her zero advantage in recovering `X_A` or the final shared key. |

---

#### Phase 2: Bob's Side (Symmetric to Alice)

| Step | Actor | Action | Object/Value | What Happens | Why This Design | Security Guarantee |
|---|---|---|---|---|---|---|
| **2.1** | Bob | Generate private key | `X_B` — random integer, `2 ≤ X_B ≤ p-2` | Bob independently calls his CSPRNG to generate `X_B`. **Critically**, `X_B` is chosen completely independently of `X_A` — there is no coordination. Bob keeps `X_B` secret permanently (or for the session lifetime in ephemeral DH). | Independent randomness is essential. If `X_A` and `X_B` were correlated or if one party could influence the other's choice, the protocol could be weakened. Each party's private key is truly independent. | The independence of `X_A` and `X_B` means breaking one reveals nothing about the other. |
| **2.2** | Bob | Compute public value | `Y_B = g^(X_B) mod p` | Bob computes his public value using the same Square-and-Multiply algorithm. Same public parameters `g` and `p` are used. | Same reasoning as Step 1.2 — fast forward, infeasible reverse. | `Y_B` reveals nothing about `X_B`. |
| **2.3** | Bob | Send public value | `Y_B` transmitted over insecure channel | Bob transmits `Y_B` to Alice. Eve intercepts and records it. Eve now has: `g`, `p`, `Y_A`, `Y_B` — all four public values. She is missing `X_A` and `X_B`. | Eve's position after this step: she must solve the **Computational Diffie-Hellman problem (CDH)** — compute `g^(X_A × X_B) mod p` given only `g^X_A mod p` and `g^X_B mod p`. This is believed to be as hard as the DLP. | Eve's complete information is insufficient to compute the shared secret. |

---

#### Phase 3: Shared Secret Computation

| Step | Actor | Action | Object/Value | What Happens | Why This Design | Security Guarantee |
|---|---|---|---|---|---|---|
| **3.1** | Alice | Compute shared secret | `K = Y_B^(X_A) mod p` = `(g^X_B)^X_A mod p` = `g^(X_A × X_B) mod p` | Alice receives Bob's `Y_B` and applies her own private exponent `X_A` using modular exponentiation. The result is the shared secret `K`. This computation takes the same millisecond-scale time as computing public values. | Alice cannot directly communicate "my secret is `X_A`" to Bob — but she doesn't need to. The mathematics guarantees that applying `X_A` to Bob's `Y_B` yields the same result as Bob applying `X_B` to Alice's `Y_A`. | Alice has `K = g^(X_A × X_B) mod p`. She did not transmit `X_A` at any point. |
| **3.2** | Bob | Compute shared secret | `K = Y_A^(X_B) mod p` = `(g^X_A)^X_B mod p` = `g^(X_B × X_A) mod p` | Bob receives Alice's `Y_A` and applies his own private exponent `X_B`. | Since `X_A × X_B = X_B × X_A` (commutativity), Bob's computation yields the same value K as Alice's. They independently arrive at the same shared secret through completely different computation paths. | Bob has `K = g^(X_A × X_B) mod p`. This equals Alice's K exactly. |
| **3.3** | Alice & Bob | Derive session key | `SessionKey = KDF(K)` | In practice, `K` is not used directly as an encryption key. Instead, it is passed through a **Key Derivation Function (KDF)** — such as HKDF (RFC 5869) — which stretches `K` into the exact key size needed (e.g., 128 or 256 bits for AES) and adds domain separation. | Raw DH output `K` may have bias in low-order bits or otherwise not be uniformly random in the exact format needed. A KDF extracts maximum entropy and produces a uniformly distributed key. | The derived session key is cryptographically indistinguishable from random, suitable for use with AES-GCM or other symmetric ciphers. |

---

#### Eve's View: What She Knows vs. What She Needs

| Information | Eve Has It? | Notes |
|---|---|---|
| Prime `p` | ✅ Yes | Public parameter |
| Generator `g` | ✅ Yes | Public parameter |
| Alice's public value `Y_A = g^(X_A) mod p` | ✅ Yes | Transmitted openly |
| Bob's public value `Y_B = g^(X_B) mod p` | ✅ Yes | Transmitted openly |
| Alice's private key `X_A` | ❌ No | Never transmitted — requires solving DLP |
| Bob's private key `X_B` | ❌ No | Never transmitted — requires solving DLP |
| Shared secret `K = g^(X_A × X_B) mod p` | ❌ No | Requires CDH problem — believed as hard as DLP |

---

### 🧪 Practice Questions — Topics 4 & 5

**[Multiple Choice]** In Diffie-Hellman, which values are kept secret and never transmitted?
- A) `p` and `g` (the public parameters)
- B) `Y_A` and `Y_B` (the public values)
- C) `X_A` and `X_B` (the private exponents)
- D) The prime factors of `p`

> ✔ **Answer: C.** `X_A` (Alice's private key) and `X_B` (Bob's private key) are the only secret values. They are chosen randomly and never transmitted. Everything else — `p`, `g`, `Y_A`, `Y_B` — is transmitted in plaintext.

---

**[True/False]** After the DH exchange, Alice and Bob use the raw computed value `g^(X_A × X_B) mod p` directly as their AES encryption key.

> ✔ **Answer: False (in practice).** The raw DH output is passed through a Key Derivation Function (KDF) first. This ensures the derived key is uniformly random and the correct size for the target cipher. Using raw DH output directly can introduce subtle biases and security weaknesses.

---

**[Short Answer]** Alice computes `Y_B^(X_A) mod p`. Bob computes `Y_A^(X_B) mod p`. Prove algebraically that these two expressions are equal.

> ✔ **Answer:**
> ```
> Alice: Y_B^(X_A) mod p = (g^X_B)^X_A mod p = g^(X_B × X_A) mod p
> Bob:   Y_A^(X_B) mod p = (g^X_A)^X_B mod p = g^(X_A × X_B) mod p
> Since X_B × X_A = X_A × X_B (integer multiplication is commutative):
> Both expressions equal g^(X_A × X_B) mod p ✓
> ```

---

## SLIDE 6 — WHY THE SHARED SECRET WORKS (THE MATH)

### 📌 Key Concepts at a Glance

- The core identity: `(g^a)^b mod p = (g^b)^a mod p = g^(ab) mod p`
- This follows from the **laws of exponents** combined with the properties of **modular arithmetic**.
- Specifically: modular exponentiation satisfies `(x^a)^b ≡ x^(ab) (mod p)` — the exponents multiply.
- This is **not** obvious! Regular exponentiation has this property, but modular exponentiation preserves it — this is the key mathematical fact.
- The **Computational Diffie-Hellman (CDH) assumption**: computing `g^(ab) mod p` from `g^a mod p` and `g^b mod p` (without knowing `a` or `b`) is computationally infeasible.

---

### 📖 Beginner-Friendly Deep Dive

#### The Exponent Rule Under Modular Arithmetic

The standard rule of exponents says: `(x^a)^b = x^(ab)`. This means the order of exponentiation doesn't matter.

**Does this still hold under modular arithmetic?** Yes! This is a theorem from group theory:

> For any prime `p`, any `g` in `Z_p*`, and any integers `a`, `b`:
> `(g^a mod p)^b mod p ≡ g^(ab) mod p`

This is what makes DH work. Alice applies `X_A` to Bob's `g^(X_B)`:
```
(g^X_B)^X_A mod p = g^(X_B × X_A) mod p
```
Bob applies `X_B` to Alice's `g^(X_A)`:
```
(g^X_A)^X_B mod p = g^(X_A × X_B) mod p
```
Since `X_B × X_A = X_A × X_B`, both equal `g^(X_A × X_B) mod p`. ✓

#### The Three Problems: DLP, CDH, DDH

Security analyses of DH protocols refer to three related but distinct problems:

| Problem | Statement | Relationship |
|---|---|---|
| **DLP** (Discrete Log) | Given `g`, `p`, `g^a mod p` — find `a` | Hardest to break; if DLP is easy, CDH and DDH are easy |
| **CDH** (Computational DH) | Given `g^a mod p` and `g^b mod p` — compute `g^(ab) mod p` | No harder than DLP; may be easier |
| **DDH** (Decisional DH) | Given `g^a`, `g^b`, `g^c` — decide if `c = ab mod (p-1)` | Generally believed easier than CDH |

> DH key exchange security relies on CDH being hard. Most analyses assume CDH ≤ DLP in difficulty.

---

## SLIDE 7 — WORKED NUMERICAL EXAMPLE

### 📌 Key Concepts at a Glance

- Toy example with small numbers illustrates the protocol concretely.
- From lecture slides: `p = 23`, `g = 5` (a generator of `Z_23*`).
- Alice chooses `X_A = 6`; Bob chooses `X_B = 15`.
- **Real implementations use `p` ≥ 2048 bits** — these small numbers are for illustration ONLY.
- Working through a small example manually is a common exam question.

---

### 📖 Complete Worked Example

**Given public parameters:** `p = 23`, `g = 5`

#### Step 1: Alice's Computation
```
X_A = 6  (Alice's private key — secret)
Y_A = g^(X_A) mod p
    = 5^6 mod 23
    = 15625 mod 23

Computing 15625 mod 23:
  15625 ÷ 23 = 679 remainder 8
  
Y_A = 8  ← Alice sends this to Bob publicly
```

#### Step 2: Bob's Computation
```
X_B = 15  (Bob's private key — secret)
Y_B = g^(X_B) mod p
    = 5^15 mod 23
    = 30517578125 mod 23

Using modular exponentiation (Square-and-Multiply):
  5^1  mod 23 = 5
  5^2  mod 23 = 2
  5^4  mod 23 = 4
  5^8  mod 23 = 16
  5^15 = 5^8 × 5^4 × 5^2 × 5^1
       = 16 × 4 × 2 × 5 mod 23
       = 640 mod 23
       = 640 - 27×23 = 640 - 621 = 19

Y_B = 19  ← Bob sends this to Alice publicly
```

#### Step 3: Alice Computes Shared Key
```
K = Y_B^(X_A) mod p
  = 19^6 mod 23

Using Square-and-Multiply:
  19^1 mod 23 = 19
  19^2 mod 23 = 361 mod 23 = 361 - 15×23 = 361 - 345 = 16
  19^4 mod 23 = 16^2 mod 23 = 256 mod 23 = 256 - 11×23 = 256 - 253 = 3
  19^6 = 19^4 × 19^2 = 3 × 16 mod 23 = 48 mod 23 = 48 - 2×23 = 2

Alice's K = 2
```

#### Step 4: Bob Computes Shared Key
```
K = Y_A^(X_B) mod p
  = 8^15 mod 23

Using Square-and-Multiply:
  8^1  mod 23 = 8
  8^2  mod 23 = 64 mod 23 = 18
  8^4  mod 23 = 18^2 mod 23 = 324 mod 23 = 324 - 14×23 = 324 - 322 = 2
  8^8  mod 23 = 2^2 mod 23 = 4
  8^15 = 8^8 × 8^4 × 8^2 × 8^1
       = 4 × 2 × 18 × 8 mod 23
       = 1152 mod 23
       = 1152 - 50×23 = 1152 - 1150 = 2

Bob's K = 2  ✓ Matches Alice!
```

#### Verification Using Direct Formula
```
K = g^(X_A × X_B) mod p
  = 5^(6 × 15) mod 23
  = 5^90 mod 23

5^22 mod 23 = 1  (Fermat's Little Theorem: g^(p-1) ≡ 1 mod p)
90 mod 22 = 90 - 4×22 = 90 - 88 = 2
5^90 mod 23 = 5^2 mod 23 = 25 mod 23 = 2 ✓
```

#### What Eve Sees and Cannot Compute
```
Public:  p=23, g=5, Y_A=8, Y_B=19
Eve must solve: "Find x such that 5^x mod 23 = 8"
Trying: 5^1=5, 5^2=2, 5^3=10, 5^4=4, 5^5=20, 5^6=8 ← found x=6
```
> ⚠️ For `p=23`, Eve trivially brute-forces this! With `p` = 2048 bits, trying all values is impossible — `2^2048` attempts would take longer than the universe's age.

---

### 🧪 Practice Questions — Topics 6 & 7

**[Multiple Choice]** In the worked example with `p=23`, `g=5`, `X_A=6`, `X_B=15`, what is the shared secret K?
- A) 8
- B) 19
- C) 2
- D) 5

> ✔ **Answer: C.** K = 2. Alice computes `19^6 mod 23 = 2`. Bob computes `8^15 mod 23 = 2`. They match.

---

**[Short Answer]** Given `p=11`, `g=2`, `X_A=3`, `X_B=5`, compute Y_A, Y_B, and the shared secret K.

> ✔ **Answer:**
> - `Y_A = 2^3 mod 11 = 8 mod 11 = 8`
> - `Y_B = 2^5 mod 11 = 32 mod 11 = 10`
> - Alice's K: `Y_B^(X_A) mod 11 = 10^3 mod 11 = 1000 mod 11 = 10` (since 1000 = 90×11 + 10)
> - Bob's K: `Y_A^(X_B) mod 11 = 8^5 mod 11 = 32768 mod 11 = 10` (since 32768 = 2978×11 + 10)
> - **K = 10** ✓

---

**[Fill in the Blank]** In DH, computing `Y_A = g^(X_A) mod p` is ________ (easy/hard), while recovering `X_A` from `Y_A` is ________ (easy/hard) for large `p`.

> ✔ **Answer:** **easy** (polynomial time via Square-and-Multiply); **computationally infeasible/hard** (discrete logarithm problem).

---

## SLIDE 8 — SECURITY OF DIFFIE-HELLMAN

### 📌 Key Concepts at a Glance

- DH security rests on the **CDH/DLP hardness assumptions** — believed true but not proven.
- **Parameter requirements**: `p` ≥ 2048 bits (NIST SP 800-57), `g` must be a proper generator.
- **Private key requirements**: `X_A`, `X_B` must be truly random, chosen from the full range.
- **Passive attacks (eavesdropping)**: Eve sees `Y_A`, `Y_B` but cannot compute K → DLP.
- **Active attacks (MITM)**: Eve intercepts and impersonates both sides → DH alone cannot prevent this!
- **Perfect Forward Secrecy (PFS)**: Using fresh `X_A`, `X_B` per session means compromising future/past keys doesn't expose session keys.

---

### 🌀 Understanding via Simon Sinek's Golden Circle

| 🔴 **WHY — Purpose** | 🟡 **HOW — Process** | 🟢 **WHAT — Result** |
|---|---|---|
| Understanding DH security requires knowing both what it protects against (passive eavesdropping) and what it cannot protect against alone (active man-in-the-middle). Knowing the boundaries prevents misapplying the protocol. | DH's passive security comes from the DLP. Its weakness against active attacks comes from its lack of authentication — neither Alice nor Bob verifies *who* they are exchanging keys with. | DH provides unconditional security against passive eavesdroppers. Against active attackers, DH must be combined with authentication (certificates, pre-shared keys, or signatures) to be truly secure. |

---

### 📖 Beginner-Friendly Deep Dive

#### What DH Protects (Passive Security)

Against a **passive eavesdropper** (Eve recording all traffic but not modifying it):

Eve has: `p`, `g`, `Y_A = g^(X_A) mod p`, `Y_B = g^(X_B) mod p`

To compute K, Eve needs either:
1. `X_A` (Alice's private key) — requires solving `DLP: Y_A = g^x mod p` for `x`
2. `X_B` (Bob's private key) — requires solving `DLP: Y_B = g^x mod p` for `x`
3. Directly compute `g^(X_A×X_B) mod p` from `Y_A` and `Y_B` — this is the **CDH problem**

All three are computationally infeasible for 2048-bit `p`. **DH is excellent against passive eavesdroppers.**

#### What DH Does NOT Protect (Active MITM)

Against an **active man-in-the-middle** (Mallory intercepting and modifying traffic):

DH is vulnerable because **neither Alice nor Bob knows WHO they are exchanging keys with**. Mallory can impersonate both parties simultaneously — see Slide 9 for the full attack.

#### Security Parameters (Current Best Practices)

| Parameter | Minimum (2024) | Recommended | Notes |
|---|---|---|---|
| Prime size `p` | 2048 bits | 3072 bits | NIST SP 800-57 |
| Generator `g` | Proper generator | `g=2` for RFC 3526 groups | Must generate full group |
| Private key size | 224 bits | 256+ bits | Should be roughly `√p` in size |
| Group | `Z_p*` | **Elliptic curve** preferred | ECC gives same security with smaller keys |

#### Small Subgroup Attack

If `g` is not a full generator of `Z_p*`, an attacker can force the shared secret into a small subgroup — dramatically reducing the keyspace. This is why:
- **Safe primes** `p = 2q + 1` are preferred (only subgroups of order 2, q, or 2q exist).
- Parameter validation at protocol implementation time is critical.

---

### 🧪 Practice Questions — Topic 8

**[Multiple Choice]** What kind of attack is Diffie-Hellman inherently vulnerable to without additional authentication?
- A) Brute-force key guessing
- B) Replay attacks
- C) Man-in-the-middle attacks
- D) Birthday attacks on the prime `p`

> ✔ **Answer: C.** DH provides no authentication — neither party knows who they are exchanging keys with. A Man-in-the-Middle attacker can impersonate both sides, establishing separate shared keys with each party and relaying (possibly modified) traffic between them.

---

**[True/False]** A 512-bit DH prime `p` is considered secure for use in production systems today.

> ✔ **Answer: False.** 512-bit DH was broken by the Logjam attack in 2015, which precomputed the discrete log tables for commonly used 512-bit primes. NIST recommends a minimum of 2048 bits, with 3072 bits preferred.

---

**[Short Answer]** What is a "safe prime" and why is it preferred for Diffie-Hellman?

> ✔ **Answer:** A safe prime is a prime `p` of the form `p = 2q + 1` where `q` is also prime. It is preferred for DH because the multiplicative group `Z_p*` for a safe prime has very limited subgroup structure — subgroups of order 1, 2, q, or 2q only. This prevents **small subgroup attacks**, where an attacker forces the DH computation into a small subgroup, dramatically reducing the effective keyspace. With a safe prime, the only "large" subgroup has order `q` (roughly half the bits of `p`), which remains computationally secure.

---

## SLIDE 9 — THE MAN-IN-THE-MIDDLE (MITM) ATTACK ON DH

### 📌 Key Concepts at a Glance

- DH's critical weakness: **no authentication** — Alice cannot verify she is talking to Bob, and vice versa.
- Mallory positions herself between Alice and Bob, intercepting all traffic.
- Mallory establishes **two separate DH sessions**: one with Alice (pretending to be Bob) and one with Bob (pretending to be Alice).
- Alice and Bob each believe they established a secure channel with each other — but both channels go through Mallory.
- Mallory can **read and modify** all traffic between them.
- **This attack is fully feasible in practice.** It is not theoretical.

---

### 🌀 Understanding via Simon Sinek's Golden Circle

| 🔴 **WHY — Purpose** | 🟡 **HOW — Process** | 🟢 **WHAT — Result** |
|---|---|---|
| DH allows two parties to agree on a shared secret — but it cannot verify the *identity* of those parties. If an attacker can intercept messages, she can impersonate each party to the other, undermining the entire security promise. | Mallory intercepts Alice's `Y_A` before it reaches Bob, substitutes her own `Y_M1`. She intercepts Bob's `Y_B` before it reaches Alice, substitutes `Y_M2`. She maintains two shared secrets — one with Alice, one with Bob — and silently relays traffic. | Alice and Bob think they have a private channel but every message passes through Mallory unencrypted (from Mallory's perspective). Mallory can read, modify, inject, or drop any message. The DH shared secrets are each secure — but they are shared with the wrong party. |

---

### 📊 MITM Attack on DH — Step-by-Step

| Step | Real Actor | Apparent Actor | Action | What Mallory Does | Alice's View | Bob's View |
|---|---|---|---|---|---|---|
| **0** | — | — | `p`, `g` agreed publicly | Mallory records `p`, `g` | Knows `p`, `g` | Knows `p`, `g` |
| **1** | Alice | Alice | Alice sends `Y_A = g^(X_A) mod p` to "Bob" | **Intercepts** `Y_A`. **Does not forward to Bob.** Generates her own `X_M1`, computes `Y_M1 = g^(X_M1) mod p`, sends `Y_M1` to Bob as if from Alice | Sends `Y_A`; unaware of interception | Receives `Y_M1`, thinks it's from Alice |
| **2** | Bob | Bob | Bob sends `Y_B = g^(X_B) mod p` to "Alice" | **Intercepts** `Y_B`. **Does not forward to Alice.** Generates her own `X_M2`, computes `Y_M2 = g^(X_M2) mod p`, sends `Y_M2` to Alice as if from Bob | Receives `Y_M2`, thinks it's from Bob | Sends `Y_B`; unaware of interception |
| **3** | Alice | Alice | Computes `K_Alice = Y_M2^(X_A) mod p` | Computes `K_Alice = Y_A^(X_M2) mod p` — **same value** as Alice computes! | `K_Alice` established with "Bob" (actually Mallory) | — |
| **4** | Bob | Bob | Computes `K_Bob = Y_M1^(X_B) mod p` | Computes `K_Bob = Y_B^(X_M1) mod p` — **same value** as Bob computes! | — | `K_Bob` established with "Alice" (actually Mallory) |
| **5** | Alice | Alice | Encrypts message M with `K_Alice`, sends to "Bob" | **Decrypts with `K_Alice`**, reads M in plaintext, optionally modifies it, **re-encrypts with `K_Bob`**, forwards to Bob | Believes M was securely sent to Bob | Receives M, believes it came securely from Alice |
| **6** | — | — | — | Mallory has **full visibility** of all traffic and can modify messages at will | Believes secure E2E channel | Believes secure E2E channel |

#### Result

- Alice has a genuine shared secret with Mallory — not Bob.
- Bob has a genuine shared secret with Mallory — not Alice.
- All DH mathematics are correct. No math was broken.
- The attack exploits the **absence of identity binding** — DH does not prove WHO you are exchanging keys with.

---

### 📖 Beginner-Friendly Deep Dive

#### The Telephone Operator Analogy

Think of Mallory as a telephone operator who can intercept calls before they connect:

1. Alice calls "Bob" → Operator (Mallory) answers, pretending to be Bob
2. Bob is called by "Alice" → Operator (Mallory) calls Bob, pretending to be Alice
3. Alice talks to "Bob" (really Mallory), Bob talks to "Alice" (really Mallory)
4. Mallory relays messages between them (possibly modified)
5. Both Alice and Bob feel they are in a private call — they have no way to know

The solution: **caller ID** — some mechanism for Alice to verify she is really talking to Bob. In cryptography, this is provided by **digital certificates** (as in TLS/HTTPS) or **pre-shared authentication keys**.

#### Real-World Exploitability

The MITM attack on unauthenticated DH is not just theoretical:
- **SSL Strip** and similar attacks exploit DH without proper certificate validation.
- **Rogue WiFi access points** perform MITM attacks on unauthenticated DH sessions.
- **Logjam attack (2015)** combined MITM with downgrade to force weak DH parameters.

---

### 🧪 Practice Questions — Topic 9

**[Multiple Choice]** After a successful MITM attack on DH, what does Mallory know?
- A) Alice's private key `X_A` and Bob's private key `X_B`
- B) Two separate shared keys — one with Alice, one with Bob
- C) The shared key `K` that Alice and Bob think they share
- D) Both B and C

> ✔ **Answer: D.** Mallory has established `K_Alice` (shared with Alice, who thinks she's talking to Bob) and `K_Bob` (shared with Bob, who thinks he's talking to Alice). These are the keys Alice and Bob each believe is their shared DH session key — so Mallory effectively knows "the key Alice and Bob think they share" because she can decrypt messages from each.

---

**[True/False]** A Man-in-the-Middle attack on DH requires breaking the Discrete Logarithm Problem.

> ✔ **Answer: False.** The MITM attack does not break any mathematics. It exploits DH's lack of authentication — Mallory runs two parallel, completely legitimate DH exchanges simultaneously, one with each party. No DLP solving is required at all.

---

**[Short Answer]** Why does encrypting messages with the DH-derived shared key NOT prevent the MITM attack?

> ✔ **Answer:** Because in a successful MITM attack, Alice and Bob are each encrypting with a key shared with *Mallory*, not with each other. When Alice encrypts with `K_Alice`, Mallory (who established `K_Alice` with Alice) can trivially decrypt it. Encryption guarantees confidentiality only against those who don't know the key — in a MITM attack, Mallory *is* the key holder for both channels. The vulnerability is not about encryption strength; it is about not knowing *whose* key you are using.

---

## SLIDE 10 — AUTHENTICATED DH: DEFEATING MITM

### 📌 Key Concepts at a Glance

- **Root cause of MITM**: DH has no authentication — Alice cannot verify Bob's identity.
- **Solution**: Combine DH with an authentication mechanism:
  1. **Certificates + Digital Signatures (TLS)**: Bob signs his `Y_B` with his private key; Alice verifies against Bob's certificate from a CA.
  2. **Pre-Shared Keys (PSK)**: Both parties already share a secret; use it to authenticate DH values (e.g., WPA-Enterprise via 802.1X/EAP).
  3. **Station-to-Station (STS) Protocol**: Interactive authentication built directly into DH.
- In TLS 1.3, DH is always authenticated via **digital signatures** on handshake messages.

---

### 📖 Beginner-Friendly Deep Dive

#### Approach 1: Sign the DH Public Value (Used in TLS)

The simplest and most common fix:

1. Bob has a long-term RSA or ECDSA key pair (private key `b`, public key `B`).
2. Bob's identity is certified by a Certificate Authority (CA): `Cert_Bob = CA_sign(B, "Bob")`.
3. During DH: Bob computes `Y_B = g^(X_B) mod p`, then **signs it**: `Sig_Bob = Sign(b, Y_B)`.
4. Bob sends `Y_B || Sig_Bob || Cert_Bob` to Alice.
5. Alice verifies: `Verify(B, Sig_Bob, Y_B)` using Bob's public key `B` (from the certificate).
6. If the signature is valid, Alice knows `Y_B` came from the real Bob — MITM is defeated.

**Why Mallory cannot forge this**: Mallory does not have Bob's private key `b`. She cannot produce a valid `Sig_Bob` over her own `Y_M`. The CA-issued certificate binds `B` to Bob's identity — the entire PKI trust chain prevents impersonation.

#### Approach 2: Station-to-Station (STS) Protocol

A more elegant approach where authentication is embedded in the DH exchange itself:

| Step | Alice | Bob |
|---|---|---|
| 1 | Send `Y_A = g^(X_A) mod p` | — |
| 2 | — | Send `Y_B = g^(X_B) mod p`, `Sign(b, Y_A || Y_B)`, `Cert_Bob` |
| 3 | Verify Bob's signature; send `Sign(a, Y_A || Y_B)`, `Cert_Alice` | — |
| 4 | — | Verify Alice's signature |
| 5 | Compute `K = Y_B^(X_A) mod p` | Compute `K = Y_A^(X_B) mod p` |

Both parties authenticate by signing both DH values — any MITM would be detected because Mallory cannot sign with Alice's private key `a` or Bob's private key `b`.

---

### 🧪 Practice Questions — Topic 10

**[Multiple Choice]** In TLS, how is the Man-in-the-Middle attack on DH prevented?
- A) By using a larger prime `p`
- B) By the server digitally signing its DH public value with its certificate's private key
- C) By encrypting the DH public values with AES before transmission
- D) By using a pre-shared symmetric key to encrypt the DH exchange

> ✔ **Answer: B.** In TLS, the server signs its DH parameters (including `Y_B`) with its long-term private key (from its X.509 certificate). The client verifies this signature using the server's public key (certified by a trusted CA). Since a MITM doesn't have the server's private key, they cannot forge a valid signature and the attack is detected.

---

**[True/False]** Diffie-Hellman combined with digital signatures can defeat the Man-in-the-Middle attack.

> ✔ **Answer: True.** Digital signatures bind the DH public values to authenticated identities. Since only the legitimate owner can produce a valid signature (without the private key), a MITM cannot substitute their own DH values without detection.

---

## SLIDE 11 — DH VS RSA FOR KEY EXCHANGE

### 📌 Key Concepts at a Glance

- Both DH and RSA can be used for key exchange — but they work very differently.
- **RSA key exchange**: Alice encrypts a random session key with Bob's RSA public key; only Bob can decrypt.
- **DH key exchange**: Neither party sends the session key at all — both compute it independently.
- **Critical difference**: RSA key exchange does NOT provide **forward secrecy**; DH (ephemeral) does.
- TLS 1.3 **eliminated** RSA key exchange entirely — only (EC)DHE is permitted.
- From the course reference table: RSA supports Encryption/Decryption ✓, Digital Signature ✓, Key Exchange ✓. DH supports Key Exchange only ✓.

---

### 🌀 Understanding via Simon Sinek's Golden Circle

| 🔴 **WHY — Purpose** | 🟡 **HOW — Process** | 🟢 **WHAT — Result** |
|---|---|---|
| TLS evolved away from RSA key exchange specifically because of the forward secrecy gap. Understanding why requires seeing exactly what each approach exposes if a private key is later compromised. | RSA key exchange transmits the session key (encrypted). If the RSA private key is later stolen, the session key can be retroactively decrypted. DH key exchange never transmits the session key — it is derived independently. Even with private keys, past sessions cannot be decrypted. | Modern TLS 1.3 mandates (EC)DHE for all key exchanges, providing forward secrecy as a baseline guarantee. RSA is still used for authentication (signatures) but no longer for key transport. |

---

### 📊 DH vs RSA Key Exchange — Comparison Table

| Property | RSA Key Exchange | DH Key Exchange |
|---|---|---|
| **Method** | Alice generates random key K, encrypts with Bob's RSA public key, sends `RSA_enc(PK_Bob, K)` | Both compute K independently: `K = g^(X_A × X_B) mod p` |
| **Is K ever transmitted?** | ✅ Yes — K is transmitted (encrypted) | ❌ No — K is computed, never sent |
| **Who computes K?** | Alice alone (Bob decrypts to get K) | Both parties independently |
| **Private key needed to recover K?** | Bob's RSA private key | Alice's `X_A` OR Bob's `X_B` |
| **Forward Secrecy** | ❌ None — compromise of RSA private key exposes ALL past sessions | ✅ Yes (if ephemeral) — each session uses fresh `X_A`, `X_B` |
| **Key exchange complexity** | One RSA encryption/decryption | Two modular exponentiations per party |
| **Typical key size for 128-bit security** | 3072-bit RSA | 3072-bit DH or 256-bit ECC |
| **Status in TLS 1.3** | ❌ **Removed** | ✅ Only key exchange method (as DHE or ECDHE) |
| **Authentication** | Implicit (encrypting to Bob's key authenticates Bob) | Requires explicit authentication (signatures) |

---

### 🧪 Practice Questions — Topic 11

**[Multiple Choice]** Which of the following is widely used today for Diffie-Hellman key exchange in TLS?
- A) AES
- B) RSA
- C) **ECC (Elliptic Curve Cryptography)**
- D) SHA-512

> ✔ **Answer: C.** (This directly matches the course midterm answer.) ECDH (Elliptic Curve Diffie-Hellman) is the dominant form of DH in modern TLS 1.3 because it provides equivalent security to classical DH with much smaller key sizes (256 bits vs. 3072 bits).

---

**[True/False]** TLS 1.3 still supports RSA key exchange for backward compatibility with older servers.

> ✔ **Answer: False.** TLS 1.3 explicitly removed RSA key exchange (and all static key exchange methods) from the specification. Only forward-secret key exchange mechanisms — specifically (EC)DHE — are permitted. RSA is still used in TLS 1.3 for authentication (signing the handshake) but not for key transport.

---

**[Short Answer]** Explain why RSA key exchange does not provide forward secrecy, while DHE does.

> ✔ **Answer:** In RSA key exchange, Alice generates the session key K, encrypts it with Bob's RSA public key, and sends it. The encrypted K traverses the network. If an attacker records all traffic today and later obtains Bob's RSA private key (through theft, legal compulsion, or cryptanalysis), they can retroactively decrypt the recorded ciphertext containing K, exposing all past sessions. In DHE (ephemeral DH), the session key K is **never transmitted** — it is computed independently by both parties using fresh, randomly chosen private exponents (`X_A`, `X_B`) that are discarded after the session. Even if long-term keys are later compromised, there is no recorded ciphertext to decrypt that would reveal K — it existed only in memory and was discarded. This property — past sessions remain secure even if long-term keys are compromised — is **forward secrecy**.

---

## SLIDE 12 — ELLIPTIC CURVE DIFFIE-HELLMAN (ECDH)

### 📌 Key Concepts at a Glance

- **Elliptic Curve Cryptography (ECC)** provides the same security as classical DH but with dramatically smaller key sizes.
- ECDH replaces modular exponentiation with **point multiplication** on an elliptic curve.
- Security basis: **Elliptic Curve Discrete Logarithm Problem (ECDLP)** — believed harder than classical DLP.
- **Key size comparison**: 256-bit ECC ≈ 3072-bit classical DH ≈ 128-bit security level.
- Standard curves: **P-256** (NIST), **X25519** (Bernstein), **P-384**, **P-521**.
- ECDH is the **dominant** form of DH in modern TLS, SSH, and Signal Protocol.

---

### 🌀 Understanding via Simon Sinek's Golden Circle

| 🔴 **WHY — Purpose** | 🟡 **HOW — Process** | 🟢 **WHAT — Result** |
|---|---|---|
| Classical DH requires enormous key sizes (3072+ bits) to be secure today, creating performance overhead. IoT devices, mobile phones, and embedded systems need strong security with minimal computational cost. ECC provides the same security with keys 10× smaller. | ECDH replaces `Z_p*` (integers mod prime) with a mathematical group of points on an elliptic curve. Point addition replaces multiplication; scalar multiplication (`k × P`) replaces modular exponentiation. The analog of the DLP — the ECDLP — is believed harder, enabling smaller keys. | 256-bit ECDH keys provide equivalent security to 3072-bit classical DH. ECDH operations are faster, use less memory, and consume less battery — making strong cryptography practical on constrained devices. |

---

### 📖 Beginner-Friendly Deep Dive

#### What Is an Elliptic Curve?

An elliptic curve over a finite field is defined by an equation: **`y² = x³ + ax + b (mod p)`**

The "points" on this curve (plus a special "point at infinity") form a mathematical group under a custom addition operation. The curve looks like a smooth cubic curve, but the points are only at coordinates that satisfy the equation modulo `p`.

#### Point Multiplication (The DLP Analog)

Given a base point `G` on the curve:
- **Easy**: Compute `Q = k × G` (add G to itself k times) — efficient algorithms exist.
- **Hard (ECDLP)**: Given `G` and `Q`, find `k` — believed infeasible for curves over 256-bit fields.

#### ECDH Protocol

| Classical DH | ECDH Equivalent |
|---|---|
| Public prime `p`, generator `g` | Public curve parameters, base point `G` |
| Alice's private key `X_A` (integer) | Alice's private key `d_A` (integer) |
| Alice's public key `Y_A = g^(X_A) mod p` | Alice's public key `Q_A = d_A × G` (point) |
| Bob's private key `X_B` | Bob's private key `d_B` |
| Bob's public key `Y_B = g^(X_B) mod p` | Bob's public key `Q_B = d_B × G` (point) |
| Shared secret `K = Y_B^(X_A) mod p` | Shared secret `K = d_A × Q_B = d_A × d_B × G` |
| Verification: `Y_A^(X_B) mod p = K` | Verification: `d_B × Q_A = d_B × d_A × G = K` ✓ |

The mathematics work identically — just in a different group. The security comes from a harder problem, enabling smaller keys.

#### X25519 — The Modern Standard

`X25519` (Curve25519 in DH mode) by Daniel Bernstein is the most widely deployed ECDH algorithm today:
- Curve: `y² = x³ + 486662x² + x (mod 2^255 - 19)`
- Security level: ~128 bits
- Designed to be fast, constant-time (immune to timing attacks), and simple to implement correctly
- Used in: TLS 1.3, Signal Protocol, WireGuard VPN, SSH OpenSSH

---

### 🧪 Practice Questions — Topic 12

**[Multiple Choice]** What key size in ECC provides approximately the same security as 3072-bit classical DH?
- A) 512 bits
- B) 256 bits
- C) 1024 bits
- D) 128 bits

> ✔ **Answer: B.** 256-bit ECC provides approximately 128-bit security, equivalent to 3072-bit classical DH. This is the efficiency advantage of ECC — roughly 10× smaller keys for equivalent security.

---

**[True/False]** ECDH uses modular exponentiation as its core mathematical operation.

> ✔ **Answer: False.** ECDH uses **point multiplication** (scalar multiplication of a point on an elliptic curve) — adding a base point to itself `k` times. Modular exponentiation is the core operation of classical DH. Both serve as one-way functions, but they operate in different mathematical groups.

---

**[Short Answer]** What is the Elliptic Curve Discrete Logarithm Problem (ECDLP)?

> ✔ **Answer:** Given a base point `G` on an elliptic curve and a public point `Q = k × G`, find the scalar `k`. This is analogous to the classical DLP but in the group of elliptic curve points. The ECDLP is believed to be harder than the classical DLP — no sub-exponential algorithm is known for the ECDLP (unlike classical DLP which has index calculus). This hardness allows equivalent security with much smaller key sizes.

---

## SLIDE 13 — FORWARD SECRECY AND EPHEMERAL DH (DHE / ECDHE)

### 📌 Key Concepts at a Glance

- **Forward Secrecy (FS)** / **Perfect Forward Secrecy (PFS)**: Compromise of long-term keys does NOT expose past session keys.
- **Ephemeral DH (DHE)**: New `X_A`, `X_B` generated fresh for **every session** and discarded immediately after.
- **Ephemeral ECDH (ECDHE)**: Same concept with elliptic curves — the dominant mode in TLS 1.3.
- **Static DH**: Same private keys reused across sessions — no forward secrecy.
- WPA3 uses **SAE (Simultaneous Authentication of Equals)** — a DH-like protocol providing forward secrecy over WiFi.
- **"E" matters**: DHE = forward secrecy; DH = no forward secrecy. Always prefer the "E" variant.

---

### 🌀 Understanding via Simon Sinek's Golden Circle

| 🔴 **WHY — Purpose** | 🟡 **HOW — Process** | 🟢 **WHAT — Result** |
|---|---|---|
| An attacker may record encrypted traffic today, hoping to decrypt it in the future when keys are stolen or computing improves. Forward secrecy eliminates this threat: even a future key compromise cannot expose past sessions. | In DHE, fresh private exponents (`X_A`, `X_B`) are generated per session and permanently deleted after the session key is derived. The session key exists only in RAM during the session — it is never written to disk and cannot be reconstructed later. | Each session has a completely independent, ephemeral key. Compromise of the server's long-term certificate key (or any other key) cannot decrypt past sessions. "Harvest now, decrypt later" attacks become permanently futile. |

---

### 📖 Beginner-Friendly Deep Dive

#### Static DH vs. DHE — The Key Difference

| | **Static DH** | **DHE (Ephemeral DH)** |
|---|---|---|
| Private keys `X_A`, `X_B` | Reused across all sessions | Fresh random values per session |
| Session key K if `X_A` stolen | All past sessions exposed | Only current session exposed |
| Session key K if `X_B` stolen | All past sessions exposed | Only current session exposed |
| Forward Secrecy | ❌ No | ✅ Yes |
| Performance overhead | Lower (keys precomputed) | Slightly higher (new keys each session) |
| TLS 1.3 status | ❌ Removed | ✅ Required |

#### The "Harvest Now, Decrypt Later" Threat

Intelligence agencies and sophisticated attackers routinely record encrypted traffic, even when they cannot currently decrypt it. Their strategy:
1. **Now**: Record all encrypted HTTPS, VPN, etc. traffic.
2. **Later**: When keys are stolen, computing improves, or quantum computers arrive — decrypt everything retroactively.

**DHE defeats this**: The ephemeral keys `X_A`, `X_B` exist only in RAM for milliseconds. They are deleted after the session key is derived. When the server's certificate key is later stolen, there is literally nothing to retroactively decrypt — the session keys were never stored.

#### WPA3 and SAE (from course slides)

Course material notes: *"WPA3-PSK uses DH-like key exchange (ephemeral) — Simultaneous Authentication of Equals (SAE). Forward secrecy!"*

SAE replaces WPA2-PSK's vulnerable pre-shared key handshake with a DH-like zero-knowledge proof exchange. Even if an attacker knows the WiFi password, they cannot decrypt past sessions — each session's key was derived from an ephemeral DH-like exchange.

---

### 🧪 Practice Questions — Topic 13

**[Multiple Choice]** Which property does DHE (ephemeral Diffie-Hellman) provide that static DH does not?
- A) Stronger encryption of the session key
- B) Perfect Forward Secrecy — past sessions remain secure if long-term keys are compromised
- C) Protection against Man-in-the-Middle attacks
- D) Larger prime `p` for better security

> ✔ **Answer: B.** DHE generates fresh private exponents per session and immediately discards them. This ensures that even if long-term server keys are later compromised, past session keys cannot be recovered — providing perfect forward secrecy.

---

**[True/False]** TLS 1.3 allows both static RSA key exchange and ECDHE key exchange, depending on server configuration.

> ✔ **Answer: False.** TLS 1.3 *removed* static key exchange methods entirely. Only forward-secret key exchange — specifically (EC)DHE — is permitted. This was a deliberate security improvement to guarantee forward secrecy for all TLS 1.3 connections.

---

**[Fill in the Blank]** In DHE, the private exponents `X_A` and `X_B` are discarded ________ the session key is derived, ensuring that future compromise of long-term keys cannot expose ________ sessions.

> ✔ **Answer:** discarded **immediately after** the session key is derived; cannot expose **past** sessions.

---

## SLIDE 14 — DH IN PRACTICE: TLS AND REAL-WORLD PROTOCOLS

### 📌 Key Concepts at a Glance

- DH (as ECDHE) is the **primary key exchange mechanism** in TLS 1.3.
- **TLS 1.3 Handshake**: Client sends supported key shares (ECDHE public keys) in `ClientHello`; server selects one and responds with its own public key share.
- **SSH**: Uses DH or ECDH for key exchange in the SSH Transport Layer Protocol.
- **Signal Protocol**: Uses **Double Ratchet Algorithm** — multiple DH exchanges per message for extreme forward secrecy.
- **WPA3 (SAE)**: DH-like key exchange replaces PSK handshake, providing forward secrecy on WiFi.
- **IPsec IKEv2**: Uses DH for establishing Security Associations (SAs).

---

### 📖 DH in TLS 1.3 — Simplified Flow

```
Client                                              Server
  |                                                    |
  |--- ClientHello -----------------------------------→|
  |    (supported ciphers, ECDHE key shares g^X_A)     |
  |                                                    |
  |←-- ServerHello + Certificate + CertVerify --------|
  |    (selected cipher, server's ECDHE share g^X_B,   |
  |     server's signature on handshake transcript)    |
  |                                                    |
Both compute:  K = HKDF(g^(X_A × X_B) mod p)          |
  |                                                    |
  |--- Finished (MAC over handshake) ----------------→|
  |←-- Finished (MAC over handshake) -----------------|
  |                                                    |
  ←====== Encrypted Application Data (AES-GCM) ======→
```

Key observations:
- The server's `CertVerify` message contains a **digital signature** over the entire handshake transcript, defeating MITM.
- The `Finished` messages use a MAC to verify both parties derived the same keys.
- Total forward DH exponents: 1 per party per TLS connection — then discarded.

---

### 📖 The Applications Table from Course Slides

| Algorithm | Encryption/Decryption | Digital Signature | Key Exchange |
|---|---|---|---|
| **RSA** | ✅ Yes | ✅ Yes | ✅ Yes (deprecated in TLS 1.3) |
| **Diffie-Hellman** | ❌ No | ❌ No | ✅ Yes (primary purpose) |
| **DSS (ECDSA)** | ❌ No | ✅ Yes | ❌ No |
| **Elliptic Curve (ECDH/ECDSA)** | ✅ Yes | ✅ Yes | ✅ Yes |

> **Exam note** (direct from course midterm): "Which is widely used today for Diffie-Hellman key exchange? → **ECC**"

---

### 🧪 Practice Questions — Topic 14

**[Multiple Choice]** In TLS 1.3, how does the client know it is talking to the real server (not a MITM) during the ECDHE key exchange?
- A) By verifying the server's IP address in the certificate
- B) By verifying the server's digital signature on the handshake transcript using the server's certificate
- C) By using a pre-shared key installed during manufacturing
- D) By checking that the ECDHE public key matches a hardcoded value

> ✔ **Answer: B.** The server sends a `CertificateVerify` message containing a digital signature over the entire handshake transcript (including the server's ECDHE public key share). The client verifies this signature using the server's public key from the CA-issued certificate. A MITM cannot forge this signature without the server's private key.

---

**[Short Answer]** Why does IPsec use IKE (Internet Key Exchange) rather than having administrators manually configure DH parameters?

> ✔ **Answer:** IKE automates the DH key exchange and negotiation process for IPsec Security Associations (SAs). Manual configuration would require: (1) generating matching DH parameters on both endpoints, (2) manually exchanging public values securely, (3) deriving and installing keys — for potentially thousands of tunnels. IKE handles DH parameter negotiation, authentication, and key derivation automatically, making large-scale IPsec deployments (VPNs, branch offices, etc.) practical. Without IKE, IPsec key management would be impractical at any significant scale.

---

## QUICK REFERENCE SUMMARY

| Concept | Definition | Security Role | Exam Focus |
|---|---|---|---|
| **Diffie-Hellman (DH)** | Key agreement protocol; two parties compute a shared secret over a public channel | Solves the key exchange problem; neither party transmits the secret | Core protocol — know all steps |
| **Public parameters** | Large prime `p` and generator `g` — shared openly with everyone including Eve | Define the mathematical group; security relies on DLP in this group | `p` ≥ 2048 bits required |
| **Private key** `X_A` / `X_B` | Random secret integer chosen by each party; **never transmitted** | The only secret values; security depends on these never being revealed | Must be cryptographically random |
| **Public value** `Y_A` / `Y_B` | `g^X mod p` — computed from private key; transmitted openly | Safe to share publicly; Eve cannot recover `X` from `Y` (DLP) | Know the formula |
| **Shared secret K** | `g^(X_A × X_B) mod p` — computed independently by both parties | Used as (or derived into) the symmetric session key | Know why both compute the same K |
| **Discrete Logarithm Problem (DLP)** | Given `g^x mod p`, find `x` — computationally infeasible for large `p` | Mathematical foundation of DH security | Key hardness assumption |
| **MITM Attack on DH** | Mallory intercepts and replaces both public values; establishes keys with each party | DH alone cannot prevent this — requires authentication to fix | Classic attack — know full flow |
| **Authenticated DH** | DH + digital signatures (certificates) — server signs its DH public value | Defeats MITM by binding public values to verified identities | Used in TLS |
| **Forward Secrecy** | Past session keys remain secure even if long-term keys are later compromised | Critical property for protecting against "harvest now, decrypt later" | TLS 1.3 requires it |
| **Ephemeral DH (DHE)** | Fresh `X_A`, `X_B` per session, discarded after key derivation | Provides forward secrecy; no historical session can be retroactively decrypted | "E" = ephemeral = forward secrecy |
| **ECDH(E)** | DH using elliptic curve groups instead of `Z_p*` | Equivalent security with 10× smaller keys; dominant in modern protocols | 256-bit ≈ 3072-bit classical DH |
| **ECDLP** | Given base point `G` and `Q = kG`, find `k` — harder than classical DLP | Enables smaller, faster keys | Basis of ECDH security |
| **Key Derivation Function (KDF)** | Derives uniform, correctly-sized key from raw DH output | Eliminates bias in raw DH output; provides domain separation | Raw DH output is NOT directly used |
| **Generator `g`** | Element that produces all of `Z_p*` when repeatedly exponentiated | Ensures private exponents map uniformly; prevents small subgroup attacks | Must be a proper generator |
| **Safe prime** | `p = 2q + 1` where both `p` and `q` are prime | Eliminates small subgroup attacks; strongest DH group structure | Preferred over arbitrary primes |
| **TLS 1.3 + DH** | TLS 1.3 mandates (EC)DHE-only key exchange | All TLS 1.3 sessions have forward secrecy | Know that RSA key exchange was removed |
| **DH vs RSA key exchange** | DH: both compute K; RSA: one generates K and encrypts it | DH provides forward secrecy; RSA key exchange does not | Fundamental distinction |

---

## EXAM PREPARATION — INTEGRATIVE QUESTIONS

---

**[Integrative Short Answer]** Alice and Bob execute Diffie-Hellman with `p=17`, `g=3`. Alice chooses `X_A=4`, Bob chooses `X_B=7`. (a) What are `Y_A` and `Y_B`? (b) What is the shared secret K? (c) What does Eve see, and why can't she compute K?

> ✔ **Answer:**
> (a) `Y_A = 3^4 mod 17 = 81 mod 17 = 13`. `Y_B = 3^7 mod 17 = 2187 mod 17 = 11` (2187 = 128×17 + 11).
> (b) Alice: `K = 11^4 mod 17 = 14641 mod 17 = 4` (14641 = 861×17 + 4). Bob: `K = 13^7 mod 17 = 4`. **K = 4**.
> (c) Eve sees `p=17, g=3, Y_A=13, Y_B=11`. To find K, she must either: (1) find `X_A` such that `3^x ≡ 13 mod 17` — the DLP — or (2) directly compute `g^(X_A × X_B)` from only `Y_A` and `Y_B` — the CDH problem. For real-world 2048-bit parameters, both are computationally infeasible (though for p=17, she can trivially check x=1,2,...).

---

**[Integrative Short Answer]** Compare DH and RSA for key exchange: explain the mechanism of each and why TLS 1.3 removed RSA key exchange but retained RSA signatures.

> ✔ **Answer:**
> **RSA key exchange (removed from TLS 1.3):** Alice generates a random session key K, encrypts it with the server's RSA public key, and sends `RSA_enc(PK_Server, K)`. Only the server can decrypt to recover K using its private key. **Problem:** K is transmitted (encrypted). If the server's RSA private key is ever compromised (now or in the future), all historically recorded sessions can be retroactively decrypted — no forward secrecy.
>
> **DH key exchange (retained in TLS 1.3 as ECDHE):** Neither party transmits the session key. Both independently compute the same K = `g^(X_A × X_B) mod p` using fresh, ephemeral private exponents discarded after the session. Even if long-term keys are later compromised, K cannot be recovered — it was never stored or transmitted.
>
> **RSA signatures (retained in TLS 1.3):** RSA is still used to *sign* the TLS handshake transcript, authenticating the server's identity and defeating MITM. This is authentication, not key transport — the session key is not involved. A signature neither transmits nor derives K; it merely proves the server's identity. Forward secrecy of the key exchange is orthogonal to the authentication mechanism.

---

**[Integrative Multiple Choice]** Which of the following describes a COMPLETE defense against BOTH passive eavesdropping and active Man-in-the-Middle attacks on a key exchange?

- A) Classical DH with a 3072-bit prime
- B) DHE with fresh ephemeral keys
- C) ECDHE combined with server certificate verification
- D) RSA key exchange with a large key size

> ✔ **Answer: C.** Classical DH (A) and DHE (B) defeat passive eavesdropping but not MITM. RSA key exchange (D) defeats MITM (via certificate) but lacks forward secrecy. ECDHE + certificate verification (C) defeats both: ECDHE defeats passive eavesdropping via DLP/ECDLP hardness; certificate verification defeats MITM by binding the ECDHE public value to an authenticated identity; ephemeral keys provide forward secrecy.

---

**[Integrative True/False]** If an attacker records a TLS 1.3 session today and later steals the server's certificate private key, they can decrypt the recorded session data.

> ✔ **Answer: False.** TLS 1.3 mandates ECDHE key exchange, which provides forward secrecy. The session key was derived from ephemeral ECDHE private exponents that were discarded immediately after the handshake. The server's certificate private key was used only for signing the handshake transcript — it was not used in deriving or encrypting the session key. Stealing the certificate key allows future MITM attacks but cannot retroactively decrypt past sessions.

---

**[Integrative Short Answer]** Explain the "harvest now, decrypt later" threat and describe precisely why ephemeral DH (DHE) defeats it while static DH does not.

> ✔ **Answer:**
> **Harvest now, decrypt later**: A sophisticated attacker (e.g., a state-level adversary) records all encrypted traffic passing through their infrastructure today, storing it for future analysis. Their bet: eventually, through key theft, legal compulsion, improved algorithms, or quantum computing, they will obtain the decryption keys and retroactively expose the recorded traffic. This strategy is realistic — hard drives are cheap, and the "decrypt later" timeline can be years or decades.
>
> **Why static DH fails against this**: In static DH, Alice and Bob reuse their private exponents `X_A`, `X_B` across all sessions. The session key K = `g^(X_A × X_B) mod p` is the same (or computable from the same keys) for all sessions. If either `X_A` or `X_B` is ever compromised, all past recorded sessions can be decrypted retroactively.
>
> **Why DHE defeats this**: In DHE, fresh, randomly chosen `X_A` and `X_B` are generated for each session and permanently deleted from memory immediately after K is derived. The session key K was never written to disk, never transmitted, and the values needed to recompute it (`X_A`, `X_B`) no longer exist anywhere. Even if every long-term key (certificate, server key) is later stolen, there is no mathematical path from the stolen keys to a past session's K — the ephemeral exponents are gone permanently. Harvest now, decrypt later is defeated: there is nothing to decrypt with, even later.

---

**[Integrative Short Answer]** Describe the full Diffie-Hellman MITM attack in the context of an HTTPS connection, and explain the specific mechanism by which the server's X.509 certificate defeats this attack.

> ✔ **Answer:**
> **The attack**: Mallory positions herself between a user's browser and a bank's web server. She intercepts the browser's ECDHE public key share `Y_A`, substitutes her own `Y_M1`. She intercepts the server's ECDHE public key share `Y_B`, substitutes her own `Y_M2`. She establishes two separate ECDHE sessions: one with the browser (acting as the bank), one with the bank (acting as the browser). All traffic passes through her — she can read account numbers, credentials, and transaction data in plaintext, then re-encrypt and forward it. The browser's "HTTPS" padlock appears green because an ECDHE session WAS established — just with Mallory.
>
> **How certificates defeat this**: The bank's server has an X.509 certificate issued by a trusted Certificate Authority (CA) that binds the bank's domain name (`bank.com`) to its long-term public key (`PK_Bank`). During the TLS handshake, the server sends a `CertificateVerify` message containing a digital signature over the entire handshake transcript — including the server's ECDHE public key share `Y_B` — using the bank's certificate private key. The browser verifies: (1) the certificate chain back to a trusted CA root, (2) the signature on the transcript. For the attack to succeed, Mallory must replace `Y_B` with `Y_M2`. But she cannot produce a valid signature over `Y_M2` using `PK_Bank` — she doesn't have the bank's certificate private key. The signature verification fails. The browser displays a certificate error, alerting the user.

---

*CS 448/548 Network Security  •  Diffie-Hellman Key Exchange Deep-Dive Study Guide  •  Spring 2026  •  Dr. Lina Pu*

*Reference: Stallings [C] Cryptography and Network Security, Chapters 10–11; [N] Network Security Essentials, Chapter 3. Supplement: RFC 2631, RFC 7748, NIST SP 800-57.*
