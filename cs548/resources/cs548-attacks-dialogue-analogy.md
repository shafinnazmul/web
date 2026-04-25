## IP Spoofing — The Forged Return Address (Annotated)

```
Attacker    : [writes a letter to Server]
              [REAL: crafts an IP packet using Scapy or libnet]
               "From: President's Office (1.1.1.1)
                To: Server (2.2.2.2)
               [REAL: sets Source IP = 1.1.1.1 (victim's IP)
                      sets Destination IP = 2.2.2.2 (server's IP)
                      in the IP header — a field the SENDER fills in,
                      with zero verification by the network]
                Please send me all your confidential files!"
               [REAL: payload could be an HTTP request, 
                      a database query, or any application request
                      that the server trusts based on source IP]

               [Note: Attacker's real address is 9.9.9.9
                but he wrote 1.1.1.1 on the envelope]
               [REAL: Attacker's true IP is 9.9.9.9
                      but the IP header's Source Address field
                      is manually overwritten to 1.1.1.1.
                      IP protocol has NO mechanism to verify
                      that the source address is genuine —
                      it is filled in entirely by the sender]

Courier     : [carries the letter through the postal network]
              [REAL: routers along the path forward the packet
                     based ONLY on Destination IP = 2.2.2.2.
                     No router checks "did 1.1.1.1 really send this?"
                     Routers only care WHERE to send it, not WHO sent it]

Server      : [receives letter, checks return address]
              [REAL: server receives IP packet,
                     reads Source IP field = 1.1.1.1,
                     checks its trust/access control list —
                     "1.1.1.1 is the President's Office, 
                      they are authorized!"]
               Oh! This is from the President's Office!
               I'd better comply immediately!
               [sends confidential files to 1.1.1.1]
              [REAL: server sends response packets with
                     Destination IP = 1.1.1.1 (the spoofed address).
                     This response goes to the REAL President's machine,
                     NOT to the attacker at 9.9.9.9!
                     This is called a "blind" spoofing attack —
                     attacker cannot see the response directly]

President   : [confused, receiving unexpected files]
               Why is the server sending me files I never asked for?!
              [REAL: the real machine at 1.1.1.1 receives 
                     a flood of unexpected response packets.
                     It will likely send TCP RST packets back
                     to the server, since it never opened 
                     this connection in the first place.
                     This is a side effect that can reveal
                     that spoofing is occurring]

Attacker    : [to himself] The postal system never checks
               if the return address is real.
              [REAL: IP protocol was designed in 1981 (RFC 791)
                     in an era of trusted academic networks.
                     Authentication of source address was
                     deliberately left out for simplicity.
                     This fundamental design decision
                     has never been fixed at the IP layer itself]
               Anyone can write anything on that envelope.
              [REAL: using tools like Scapy in Python:
                     send(IP(src="1.1.1.1", dst="2.2.2.2")/payload)
                     One line of code. That's all it takes.]
               No stamps. No ID. No verification. Ever.
              [REAL: no cryptographic signature on IP headers,
                     no PKI, no certificate — 
                     nothing prevents source IP forgery
                     at the IP layer itself]

Server      : [blissfully unaware]
               I just follow the return address.
               Why would anyone lie about who they are?
              [REAL: any server using IP-address-based 
                     authentication (like old r-utilities:
                     rlogin, rsh, rhosts) is fundamentally
                     vulnerable to this attack.
                     This is why IP-based trust relationships
                     are considered dangerous today]
```

---

## Annotations Mapped to Real Technical Fields

```
LETTER ANALOGY          REAL IP PACKET FIELD
─────────────────────────────────────────────────────
Envelope "From"     →   IP Header: Source Address (32 bits)
Envelope "To"       →   IP Header: Destination Address (32 bits)
Letter contents     →   IP Payload (TCP/UDP segment + data)
Postal courier      →   Internet routers (forward by Dst IP only)
Return address lie  →   Source IP spoofing (no verification exists)
Writing the letter  →   Scapy: IP(src="1.1.1.1", dst="2.2.2.2")
─────────────────────────────────────────────────────

WHAT THE IP HEADER ACTUALLY LOOKS LIKE:

Normal packet:
┌─────────────────────────────────────┐
│ Source IP:      9.9.9.9  (Attacker) │
│ Destination IP: 2.2.2.2  (Server)   │
│ Payload:        "send me files"      │
└─────────────────────────────────────┘

Spoofed packet:
┌─────────────────────────────────────┐
│ Source IP:      1.1.1.1  (FORGED)   │ ← anyone can write anything here
│ Destination IP: 2.2.2.2  (Server)   │
│ Payload:        "send me files"      │
└─────────────────────────────────────┘
                  ↑
                  Server reads this and trusts it completely
```

---

## Why Attacker Cannot See the Response — The Blind Spot

```
Attacker    : [realizes a problem]
               Wait. I told the server I'm at 1.1.1.1.
               So the server sends its response TO 1.1.1.1.
               But I'm sitting at 9.9.9.9!
               I will NEVER see that response!
              [REAL: this is called a "blind" or "one-way" 
                     spoofing attack — attacker cannot see replies.
                     This limits what the attacker can do directly]

Attacker    : [thinking of what he CAN still do]
               But I don't need to see the response to:
               1. Cause a DDoS — server floods 1.1.1.1 with replies
              [REAL: Smurf attack, amplification attacks]
               2. Exhaust server resources — SYN flood
              [REAL: send thousands of SYNs, server stores 
                     half-open connections, resources exhausted]
               3. Abuse IP-based trust — if server executes 
                  commands from "trusted" IP 1.1.1.1
              [REAL: old rsh/rlogin services did exactly this]

Attacker    : [for two-way communication, needs extra step]
               If I want to actually READ the responses,
               I need to get on the network path first —
               via ARP poisoning or compromising a router.
              [REAL: true bidirectional session hijacking 
                     requires the attacker to be on-path,
                     not just spoofing blindly]
```

---

## Defenses — The Post Office Reforms

```
Defense 1 — Ingress Filtering (BCP38):
Post Office : [new rule at every local post office]
              "We will NOT forward any letter whose return 
               address is from OUTSIDE our neighborhood.
               If you're mailing from Maple Street,
               your return address must be a Maple Street address."
             [REAL: ISP routers drop packets whose source IP
                    does not belong to that ISP's address range.
                    Prevents spoofed packets from leaving 
                    the attacker's own network]

Defense 2 — IPSec:
Server      : [new policy]
              "I now require every letter to have a 
               cryptographic wax seal that only the real
               sender could have produced."
             [REAL: IPSec AH/ESP adds cryptographic 
                    authentication to IP packets —
                    a spoofed source IP cannot produce
                    a valid cryptographic signature]

Defense 3 — Don't Trust IP Addresses:
Server      : [new policy]  
              "I no longer give special access based on
               which house the letter claims to come from.
               Everyone must show proper ID — 
               username, password, certificate."
             [REAL: eliminate IP-address-based authentication.
                    Use TLS certificates, passwords, or 
                    Kerberos tickets instead —
                    things that cannot be spoofed by 
                    simply writing a fake return address]
```