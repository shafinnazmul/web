This is a complete HTML document that visualizes the Kerberos authentication protocol as a "Royal Pass System" story. You can switch between light and dark themes using the toggle button in the top-right corner.
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes">
  <title>Kerberos · The Royal Pass System (Annotated Deep Dive)</title>
  <!-- Fonts: elegant display, readable serif, crisp mono -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Cinzel:wght@400;600;700;900&family=Crimson+Pro:ital,wght@0,300;0,400;0,600;1,300;1,400&family=JetBrains+Mono:wght@400;600;700&display=swap" rel="stylesheet">
  <style>
    /* ===== LIGHT & DARK VARIABLES ===== */
    :root {
      /* Light theme (default) */
      --bg: #faf9f5;
      --bg2: #f3efe7;
      --bg3: #e8e2d6;
      --gold: #b0823c;
      --gold-lt: #c59a4b;
      --gold-dk: #7a5c2e;
      --ivory: #2e2b24;
      --ivory2: #4a453c;
      --ivory3: #6b6458;
      --red: #b34a4a;
      --green: #2f6b48;
      --blue: #2d5075;
      --purple: #6a4a78;
      --border: #d9cfbb;
      --border2: #c4b99e;
      --mono: 'JetBrains Mono', monospace;
      --serif: 'Crimson Pro', Georgia, serif;
      --display: 'Cinzel', serif;
      --shadow-soft: 0 6px 18px rgba(0,0,0,0.06);
      --card-bg: #fcfaf5;
      --code-bg: #f0ede5;
      --code-border: #d6cebc;
      --table-stripe: #f6f3ec;
      --hover-row: #f0ebe0;
      --tag-bg-light: #f5f0e6;
      --why-bg: #f0f5ec;
      --why-border: #9bbf8b;
      --sec-bg: #edf3f8;
      --sec-border: #6f9bc0;
      --warn-bg: #fef0f0;
      --warn-border: #d98b8b;
      --phase-badge-bg: #f4ede0;
    }

    body.dark {
      --bg: #0c0a08;
      --bg2: #12100d;
      --bg3: #1a1712;
      --gold: #c9963c;
      --gold-lt: #e8b84b;
      --gold-dk: #8a6522;
      --ivory: #f0e8d4;
      --ivory2: #c8bfa8;
      --ivory3: #7a7060;
      --red: #b04040;
      --green: #3d7a58;
      --blue: #3a6090;
      --purple: #7a558a;
      --border: #2a2418;
      --border2: #3a3020;
      --shadow-soft: 0 6px 18px rgba(0,0,0,0.5);
      --card-bg: #141210;
      --code-bg: #0e0d0a;
      --code-border: #2f2a1e;
      --table-stripe: #100e0b;
      --hover-row: #1a1712;
      --tag-bg-light: #1e1810;
      --why-bg: #0c1008;
      --why-border: #3d7a58;
      --sec-bg: #0a0c14;
      --sec-border: #3a6090;
      --warn-bg: #140808;
      --warn-border: #b04040;
      --phase-badge-bg: #14100a;
    }

    * { box-sizing: border-box; margin: 0; padding: 0; }
    html { scroll-behavior: smooth; }

    body {
      background: var(--bg);
      color: var(--ivory);
      font-family: var(--serif);
      font-size: 16px;
      line-height: 1.75;
      min-height: 100vh;
      transition: background 0.3s ease, color 0.2s ease;
    }

    /* Theme toggle button */
    .theme-toggle {
      position: fixed;
      top: 20px;
      right: 24px;
      z-index: 1000;
      background: var(--bg2);
      border: 1px solid var(--border2);
      border-radius: 30px;
      padding: 8px 18px;
      font-family: var(--mono);
      font-size: 0.8rem;
      font-weight: 600;
      letter-spacing: 0.5px;
      color: var(--ivory);
      cursor: pointer;
      backdrop-filter: blur(6px);
      box-shadow: var(--shadow-soft);
      display: flex;
      align-items: center;
      gap: 6px;
      transition: all 0.2s;
    }
    .theme-toggle:hover {
      background: var(--bg3);
      border-color: var(--gold);
      color: var(--gold-lt);
    }
    .toggle-icon {
      font-size: 1.1rem;
    }

    /* ── HEADER ── */
    .masthead {
      background: linear-gradient(160deg, var(--bg2) 0%, var(--bg) 60%);
      border-bottom: 2px solid var(--gold-dk);
      padding: 60px 64px 48px;
      position: relative;
      overflow: hidden;
    }
    .masthead::before {
      content: '';
      position: absolute;
      inset: 0;
      background: repeating-linear-gradient(45deg, transparent, transparent 40px, rgba(201,150,60,0.08) 40px, rgba(201,150,60,0.08) 41px);
    }
    .masthead-inner { position: relative; max-width: 1200px; margin: 0 auto; }
    .masthead-eyebrow {
      font-family: var(--mono);
      font-size: .72em;
      letter-spacing: .2em;
      text-transform: uppercase;
      color: var(--gold-dk);
      margin-bottom: 16px;
    }
    .masthead h1 {
      font-family: var(--display);
      font-size: clamp(2em, 4vw, 3.4em);
      font-weight: 900;
      color: var(--gold-lt);
      letter-spacing: .04em;
      line-height: 1.15;
      margin-bottom: 18px;
    }
    .masthead-sub {
      font-size: 1.1em;
      color: var(--ivory2);
      max-width: 720px;
      font-style: italic;
    }

    .page {
      max-width: 1200px;
      margin: 0 auto;
      padding: 56px 64px 100px;
    }

    /* Entity map, tables, cards... (same as before, adapted variables) */
    .entity-map {
      background: var(--bg2);
      border: 1px solid var(--border2);
      border-top: 3px solid var(--gold);
      border-radius: 0 0 12px 12px;
      margin-bottom: 60px;
      overflow-x: auto;
    }
    .entity-map-header {
      background: linear-gradient(90deg, var(--bg3), var(--bg2));
      padding: 20px 28px;
      border-bottom: 1px solid var(--border2);
    }
    .entity-map-header h2 {
      font-family: var(--display);
      font-size: 1em;
      font-weight: 700;
      color: var(--gold);
      letter-spacing: .1em;
      text-transform: uppercase;
    }
    .entity-map-header p {
      font-size: .88em;
      color: var(--ivory3);
      margin-top: 6px;
      font-style: italic;
    }
    .em-table { width: 100%; border-collapse: collapse; }
    .em-table th {
      background: var(--bg3);
      padding: 11px 16px;
      text-align: left;
      font-family: var(--mono);
      font-size: .68em;
      letter-spacing: .12em;
      text-transform: uppercase;
      color: var(--gold-dk);
      border-bottom: 1px solid var(--border2);
      white-space: nowrap;
    }
    .em-table td {
      padding: 13px 16px;
      vertical-align: top;
      border-bottom: 1px solid var(--border);
      font-size: .92em;
      line-height: 1.6;
    }
    .em-table tr:last-child td { border-bottom: none; }
    .em-table tr:hover td { background: var(--hover-row); }
    .em-table tr:nth-child(even) td { background: var(--table-stripe); }
    .em-table tr:nth-child(even):hover td { background: var(--hover-row); }
    .sym {
      font-family: var(--mono);
      font-size: .85em;
      font-weight: 700;
      white-space: nowrap;
      padding: 2px 6px;
      border-radius: 4px;
    }
    .sym-entity  { background: #e9dbb8; color: #5c3e1a; } body.dark .sym-entity { background: #1e1810; color: #e8b84b; }
    .sym-key     { background: #d9e6f2; color: #1b3b5c; } body.dark .sym-key { background: #0e1820; color: #6aaddd; }
    .sym-ticket  { background: #e0d6f0; color: #3e2a6e; } body.dark .sym-ticket { background: #120e1e; color: #a88be8; }
    .sym-ts      { background: #d4edda; color: #1e4a2c; } body.dark .sym-ts { background: #0e1a10; color: #5ec47a; }
    .sym-danger  { background: #f5dcdc; color: #7a2e2e; } body.dark .sym-danger { background: #1a0e0e; color: #dd6a6a; }
    .role-tag {
      display: inline-block;
      font-family: var(--mono);
      font-size: .65em;
      letter-spacing: .08em;
      text-transform: uppercase;
      padding: 2px 8px;
      border-radius: 10px;
      font-weight: 700;
      margin-right: 6px;
    }
    .rt-client   { background: #f5e5c0; color: #7a5518; } body.dark .rt-client { background: #2a1e08; color: #e8b84b; }
    .rt-kdc      { background: #cfe1f2; color: #143654; } body.dark .rt-kdc { background: #081828; color: #6aaddd; }
    .rt-service  { background: #c8e6d0; color: #1e4628; } body.dark .rt-service { background: #0e1a10; color: #5ec47a; }
    .rt-attacker { background: #f2cfcf; color: #811d1d; } body.dark .rt-attacker { background: #1a0808; color: #dd6a6a; }
    .rt-key      { background: #e2d4f0; color: #44265e; } body.dark .rt-key { background: #18081e; color: #a88be8; }

    .phase-divider {
      display: flex;
      align-items: center;
      gap: 18px;
      margin: 56px 0 32px;
    }
    .phase-divider::before, .phase-divider::after {
      content: '';
      flex: 1;
      height: 1px;
      background: linear-gradient(90deg, transparent, var(--gold-dk));
    }
    .phase-divider::after {
      background: linear-gradient(90deg, var(--gold-dk), transparent);
    }
    .phase-badge {
      font-family: var(--display);
      font-size: .75em;
      font-weight: 700;
      letter-spacing: .14em;
      text-transform: uppercase;
      color: var(--gold);
      white-space: nowrap;
      padding: 6px 20px;
      border: 1px solid var(--gold-dk);
      border-radius: 20px;
      background: var(--phase-badge-bg);
    }

    .step-card {
      background: var(--card-bg);
      border: 1px solid var(--border2);
      border-radius: 12px;
      margin-bottom: 32px;
      overflow: hidden;
      box-shadow: var(--shadow-soft);
    }
    .step-header {
      display: grid;
      grid-template-columns: 64px 1fr auto;
      align-items: center;
      border-bottom: 1px solid var(--border2);
      background: linear-gradient(90deg, var(--bg3), var(--bg2));
    }
    .step-num {
      font-family: var(--display);
      font-size: 1.4em;
      font-weight: 900;
      color: var(--gold-dk);
      text-align: center;
      padding: 18px 12px;
      border-right: 1px solid var(--border2);
    }
    .step-title-area { padding: 14px 20px; }
    .step-title {
      font-family: var(--display);
      font-size: .92em;
      font-weight: 700;
      color: var(--gold-lt);
      letter-spacing: .06em;
      text-transform: uppercase;
    }
    .step-actors {
      font-family: var(--mono);
      font-size: .7em;
      color: var(--ivory3);
      margin-top: 4px;
    }
    .step-phase-tag {
      font-family: var(--mono);
      font-size: .62em;
      letter-spacing: .1em;
      text-transform: uppercase;
      padding: 4px 14px;
      margin-right: 18px;
      border-radius: 12px;
      font-weight: 700;
      align-self: center;
    }
    .tag-as     { background: #f1e5c7; color: #7a5d1e; border:1px solid #c6a44b; } body.dark .tag-as { background:#1e1808; color:#e8b84b; border-color:#3a2e10; }
    .tag-tgs    { background: #d2e5f7; color: #1c4468; } body.dark .tag-tgs { background:#081828; color:#6aaddd; border-color:#10284a; }
    .tag-svc    { background: #cde6d4; color: #1e4a2c; } body.dark .tag-svc { background:#0e1a10; color:#5ec47a; border-color:#1a3420; }
    .tag-setup  { background: #ecddf5; color: #4c2e5e; } body.dark .tag-setup { background:#1e0e1e; color:#c488e8; border-color:#3a1e4a; }
    .tag-threat { background: #f5d2d2; color: #891f1f; } body.dark .tag-threat { background:#1a0808; color:#dd6a6a; border-color:#4a1010; }

    .step-body {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 0;
    }
    .story-side {
      padding: 24px 26px;
      border-right: 1px solid var(--border2);
      background: var(--bg2);
    }
    .story-label {
      font-family: var(--mono);
      font-size: .62em;
      letter-spacing: .18em;
      text-transform: uppercase;
      color: var(--gold-dk);
      margin-bottom: 12px;
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .story-label::after { content: ''; flex: 1; height: 1px; background: var(--border2); }
    .story-dialogue {
      font-style: italic;
      color: var(--ivory2);
      font-size: .95em;
      line-height: 1.8;
      margin-bottom: 14px;
      border-left: 3px solid var(--gold-dk);
      padding-left: 16px;
    }
    .story-speaker {
      font-family: var(--display);
      font-size: .72em;
      font-weight: 700;
      color: var(--gold);
      letter-spacing: .08em;
      text-transform: uppercase;
      margin-bottom: 6px;
      margin-top: 14px;
    }
    .story-action { color: var(--ivory3); font-size: .9em; line-height: 1.7; margin-top: 10px; }

    .real-side {
      padding: 24px 26px;
      background: var(--card-bg);
    }
    .real-label {
      font-family: var(--mono);
      font-size: .62em;
      letter-spacing: .18em;
      text-transform: uppercase;
      color: var(--blue);
      margin-bottom: 12px;
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .real-label::after { content: ''; flex: 1; height: 1px; background: var(--border2); }

    .proto-block {
      background: var(--code-bg);
      border: 1px solid var(--code-border);
      border-radius: 8px;
      padding: 16px 18px;
      font-family: var(--mono);
      font-size: .82em;
      line-height: 2;
      margin-bottom: 14px;
      white-space: pre-wrap;
      color: var(--ivory2);
    }
    .annot-table { width: 100%; border-collapse: collapse; margin-top: 14px; }
    .annot-table td {
      padding: 8px 10px;
      border-bottom: 1px solid var(--border);
      font-size: .82em;
      vertical-align: top;
      line-height: 1.6;
    }
    .annot-table tr:last-child td { border-bottom: none; }
    .annot-sym { font-family: var(--mono); font-weight: 700; }
    .annot-real { color: var(--ivory2); }
    .annot-story { color: var(--ivory3); font-style: italic; }

    .why-box {
      background: var(--why-bg);
      border: 1px solid var(--why-border);
      border-left: 3px solid var(--green);
      border-radius: 0 8px 8px 0;
      padding: 14px 16px;
      font-size: .87em;
      color: var(--ivory2);
      line-height: 1.75;
      margin-top: 14px;
    }
    .sec-box {
      background: var(--sec-bg);
      border: 1px solid var(--sec-border);
      border-left: 3px solid var(--blue);
      border-radius: 0 8px 8px 0;
      padding: 14px 16px;
      font-size: .87em;
      color: var(--ivory2);
      margin-top: 10px;
    }
    .warn-box {
      background: var(--warn-bg);
      border: 1px solid var(--warn-border);
      border-left: 3px solid var(--red);
      border-radius: 0 8px 8px 0;
      padding: 14px 16px;
      font-size: .87em;
      color: var(--ivory2);
      margin-top: 10px;
    }
    .map-strip {
      background: var(--bg3);
      border-top: 1px solid var(--border2);
      padding: 12px 26px;
      font-size: .8em;
      display: flex;
      flex-wrap: wrap;
      gap: 16px;
      align-items: center;
    }
    .map-strip-label {
      font-family: var(--mono);
      font-size: .65em;
      letter-spacing: .12em;
      text-transform: uppercase;
      color: var(--ivory3);
    }
    .map-item { display: flex; align-items: center; gap: 6px; font-size: .85em; color: var(--ivory2); }
    .map-arrow { color: var(--gold-dk); font-family: var(--mono); }

    .symbol-master { background: var(--bg2); border:1px solid var(--border2); border-top:3px solid var(--gold-dk); border-radius:0 0 12px 12px; margin-top:60px; overflow:hidden; }
    .sm-section-header { background:var(--bg3); padding:12px 24px; font-family:var(--display); font-size:.8em; letter-spacing:.12em; text-transform:uppercase; color:var(--gold); border-bottom:1px solid var(--border2); }
    .sm-table { width:100%; border-collapse:collapse; }
    .sm-table th { background:var(--bg3); padding:10px 16px; font-family:var(--mono); font-size:.65em; letter-spacing:.14em; text-transform:uppercase; color:var(--ivory3); border-bottom:1px solid var(--border2); text-align:left; }
    .sm-table td { padding:11px 16px; border-bottom:1px solid var(--border); font-size:.88em; vertical-align:top; }
    .sm-table tr:last-child td { border-bottom:none; }
    .sm-table tr:hover td { background:var(--hover-row); }
    .sm-cat-row td { background:var(--bg3) !important; font-family:var(--display); font-size:.72em; letter-spacing:.1em; text-transform:uppercase; color:var(--gold-dk); padding:8px 16px; border-bottom:1px solid var(--border2); }

    .flow-box { background:var(--bg2); border:1px solid var(--border2); border-radius:12px; padding:32px 36px; margin-top:48px; }
    .flow-box h3 { font-family:var(--display); font-size:.95em; font-weight:700; letter-spacing:.1em; text-transform:uppercase; color:var(--gold); margin-bottom:24px; }
    .flow-step { display:flex; gap:16px; align-items:flex-start; margin-bottom:20px; }
    .flow-n { width:28px; height:28px; border-radius:50%; background:var(--gold-dk); color:var(--bg); font-family:var(--display); font-size:.75em; font-weight:700; display:flex; align-items:center; justify-content:center; flex-shrink:0; }
    .flow-text { font-size:.93em; color:var(--ivory2); line-height:1.7; }
    .flow-arrow { margin-left:44px; margin-bottom:20px; color:var(--gold-dk); font-size:1.4em; }

    .guarantee-grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(260px,1fr)); gap:18px; margin-top:48px; }
    .guarantee-card { background:var(--bg2); border:1px solid var(--border2); border-radius:10px; padding:22px 24px; }
    .gc-icon { font-size:1.6em; margin-bottom:10px; }
    .gc-title { font-family:var(--display); font-size:.8em; font-weight:700; letter-spacing:.1em; text-transform:uppercase; color:var(--gold); margin-bottom:10px; }
    .gc-body { font-size:.88em; color:var(--ivory2); line-height:1.7; }

    @media (max-width:900px) {
      .masthead { padding:40px 28px 32px; }
      .page { padding:36px 24px 60px; }
      .step-body { grid-template-columns:1fr; }
      .story-side { border-right:none; border-bottom:1px solid var(--border2); }
      .step-header { grid-template-columns:48px 1fr; }
      .step-phase-tag { display:none; }
    }
  </style>
</head>
<body class="light">
  <!-- Theme toggle button -->
  <button class="theme-toggle" id="themeToggle" aria-label="Switch dark/light mode">
    <span class="toggle-icon">☀️</span> <span>Light</span>
  </button>

  <div class="masthead">
    <div class="masthead-inner">
      <div class="masthead-eyebrow">CS 448/548 Network Security · Annotated Analogy</div>
      <h1>Kerberos — The Royal Pass System</h1>
      <p class="masthead-sub">Every analogy element precisely mapped to its real Kerberos counterpart. Each step shows the palace story, the formal protocol notation, and a full annotation table — side by side.</p>
    </div>
  </div>

  <div class="page">
    <!-- Entity map, steps... (content unchanged, only structure preserved) -->
    <div class="entity-map">
      <div class="entity-map-header"><h2>Master Entity Correspondence Table</h2><p>Read this first. Every symbol and every palace character — who they are, what they do, and why they exist.</p></div>
      <table class="em-table"><thead><tr><th>Symbol</th><th>Role</th><th>Real Kerberos Entity</th><th>Palace Story</th><th>Responsibility</th><th>Knows/Holds</th><th>Never Knows</th></tr></thead><tbody>
        <tr><td><span class="sym sym-entity">C</span></td><td><span class="role-tag rt-client">Client</span></td><td>Client machine (Alice)</td><td>Alice, petitioner</td><td>Initiates auth, carries tickets</td><td>Kc (briefly), Kc,tgs, Kc,v</td><td>Ticket contents, Ktgs, Kv</td></tr>
        <tr><td><span class="sym sym-entity">AS</span></td><td><span class="role-tag rt-kdc">KDC/AS</span></td><td>Authentication Server</td><td>Palace Front Desk</td><td>Issues TGT, holds Kc</td><td>Kc, Ktgs, Kv</td><td>Alice's plaintext password</td></tr>
        <tr><td><span class="sym sym-entity">TGS</span></td><td><span class="role-tag rt-kdc">KDC/TGS</span></td><td>Ticket Granting Server</td><td>Permit Office</td><td>Issues service tickets</td><td>Ktgs, Kv, Kc,tgs</td><td>Kc, Alice's password</td></tr>
        <tr><td><span class="sym sym-entity">V</span></td><td><span class="role-tag rt-service">Service</span></td><td>Service Server (Verifier)</td><td>Treasury Room</td><td>Verifies ticket, serves resource</td><td>Kv, Kc,v</td><td>Kc, Kc,tgs</td></tr>
        <tr><td><span class="sym sym-key">Kc</span></td><td><span class="role-tag rt-key">Long-term</span></td><td>hash(password)</td><td>Alice's seal impression</td><td>Used once for AS reply</td><td>Client + AS</td><td>TGS, V</td></tr>
        <tr><td><span class="sym sym-key">Ktgs</span></td><td><span class="role-tag rt-key">Long-term</span></td><td>TGS secret key</td><td>Permit Office master seal</td><td>Seals TGT</td><td>KDC, TGS</td><td>Client, V</td></tr>
        <tr><td><span class="sym sym-key">Kv</span></td><td><span class="role-tag rt-key">Long-term</span></td><td>Service secret key</td><td>Treasury master key</td><td>Seals Ticket_v</td><td>KDC, Server V</td><td>Client</td></tr>
        <tr><td><span class="sym sym-key">Kc,tgs</span></td><td><span class="role-tag rt-key">Session</span></td><td>Client↔TGS session key</td><td>"BlueTiger"</td><td>Proves presence to TGS</td><td>Client, TGS</td><td>V</td></tr>
        <tr><td><span class="sym sym-key">Kc,v</span></td><td><span class="role-tag rt-key">Session</span></td><td>Client↔V session key</td><td>"GoldenKey"</td><td>Proves presence to V</td><td>Client, V</td><td>TGS</td></tr>
        <tr><td><span class="sym sym-ticket">Ticket_tgs</span></td><td>Ticket</td><td>TGT (sealed with Ktgs)</td><td>Sealed permit-pass</td><td>Alice carries opaque</td><td>Alice (carrier), TGS (reader)</td><td>Alice cannot open</td></tr>
        <tr><td><span class="sym sym-ticket">Ticket_v</span></td><td>Ticket</td><td>Service ticket (sealed with Kv)</td><td>Treasury access pass</td><td>Alice carries opaque</td><td>Alice, Server V</td><td>Alice cannot open</td></tr>
        <tr><td><span class="sym sym-ts">Auth_c</span></td><td>Authenticator</td><td>E(Kc,tgs, IDc‖TS)</td><td>Alice's live declaration</td><td>Anti-replay</td><td>Client creates, TGS verifies</td><td>—</td></tr>
        <tr><td><span class="sym sym-ts">Auth_v</span></td><td>Authenticator</td><td>E(Kc,v, TS+1)</td><td>Guard's echo</td><td>Mutual auth</td><td>Server creates, Client verifies</td><td>—</td></tr>
      </tbody></table>
    </div>

    <!-- Phase 0, 1, 2, 3, 4 content same as original, using variables -->
    <div class="phase-divider"><div class="phase-badge">Phase 0 — Pre-Setup</div></div>
    <div class="step-card"><div class="step-header"><div class="step-num">0.1</div><div class="step-title-area"><div class="step-title">KDC Registers Alice's Account</div><div class="step-actors">KDC Admin → Database</div></div><div class="step-phase-tag tag-setup">Setup</div></div><div class="step-body"><div class="story-side"><div class="story-label">Palace Story</div><div class="story-speaker">Archivist:</div><div class="story-dialogue">"I record Alice's seal impression in the Grand Ledger."</div></div><div class="real-side"><div class="real-label">Real Protocol</div><div class="proto-block">Kc = hash(password); store Kc under IDc</div><div class="why-box"><strong>Why hash?</strong> Database theft yields only hash, not plaintext password.</div></div></div></div>
    <div class="step-card"><div class="step-header"><div class="step-num">0.2</div><div class="step-title-area"><div class="step-title">Register Service V (Treasury)</div></div><div class="step-phase-tag tag-setup">Setup</div></div><div class="step-body"><div class="story-side"><div class="story-dialogue">"Treasury master key given to Guard in person."</div></div><div class="real-side"><div class="proto-block">Kv = random(); install on Server V out-of-band.</div></div></div></div>

    <div class="phase-divider"><div class="phase-badge">Phase 1 — AS Exchange</div></div>
    <div class="step-card"><div class="step-header"><div class="step-num">1.1</div><div class="step-title-area"><div class="step-title">Client Login Request</div></div><div class="step-phase-tag tag-as">AS</div></div><div class="step-body"><div class="story-side"><div class="story-dialogue">"I am Alice, requesting permit pass."</div></div><div class="real-side"><div class="proto-block">C→AS: IDc ‖ IDtgs ‖ TS1 (plaintext)</div></div></div></div>
    <div class="step-card"><div class="step-header"><div class="step-num">1.2</div><div class="step-title-area"><div class="step-title">AS Generates TGT & Session Key</div></div><div class="step-phase-tag tag-as">AS</div></div><div class="step-body"><div class="story-side"><div class="story-dialogue">"Creating 'BlueTiger' and sealed permit-pass."</div></div><div class="real-side"><div class="proto-block">Kc,tgs = random(); Ticket_tgs = E(Ktgs, Kc,tgs‖IDc…)</div></div></div></div>
    <div class="step-card"><div class="step-header"><div class="step-num">1.3</div><div class="step-title-area"><div class="step-title">Alice Decrypts & Discards Kc</div></div></div><div class="step-body"><div class="story-side"><div class="story-dialogue">"I open my envelope, learn 'BlueTiger', return seal to lockbox."</div></div><div class="real-side"><div class="proto-block">Decrypt Part_A with Kc → extract Kc,tgs; discard Kc.</div></div></div></div>

    <div class="phase-divider"><div class="phase-badge">Phase 2 — TGS Exchange</div></div>
    <div class="step-card"><div class="step-header"><div class="step-num">2.1</div><div class="step-title-area"><div class="step-title">Request Service Ticket</div></div><div class="step-phase-tag tag-tgs">TGS</div></div><div class="step-body"><div class="story-side"><div class="story-dialogue">"Treasury access, here is permit-pass and declaration sealed with BlueTiger."</div></div><div class="real-side"><div class="proto-block">C→TGS: IDv, Ticket_tgs, Auth_c=E(Kc,tgs, IDc‖TS2)</div></div></div></div>
    <div class="step-card"><div class="step-header"><div class="step-num">2.2</div><div class="step-title-area"><div class="step-title">TGS Verifies & Issues Ticket_v</div></div></div><div class="step-body"><div class="story-side"><div class="story-dialogue">"Pass valid. Creating 'GoldenKey' and Treasury pass."</div></div><div class="real-side"><div class="proto-block">Decrypt TGT→Kc,tgs; verify Auth; Kc,v=new; Ticket_v=E(Kv, Kc,v…)</div></div></div></div>

    <div class="phase-divider"><div class="phase-badge">Phase 3 — Service Access</div></div>
    <div class="step-card"><div class="step-header"><div class="step-num">3.1</div><div class="step-title-area"><div class="step-title">Client Presents Ticket to V</div></div><div class="step-phase-tag tag-svc">Service</div></div><div class="step-body"><div class="story-side"><div class="story-dialogue">"Treasury pass and declaration sealed with GoldenKey."</div></div><div class="real-side"><div class="proto-block">C→V: Ticket_v, Auth_c'=E(Kc,v, IDc‖TS3)</div></div></div></div>
    <div class="step-card"><div class="step-header"><div class="step-num">3.2</div><div class="step-title-area"><div class="step-title">Server V Verifies & Grants</div></div></div><div class="step-body"><div class="story-side"><div class="story-dialogue">"Pass and declaration match. Alice is genuine."</div></div><div class="real-side"><div class="proto-block">Decrypt Ticket_v→Kc,v; verify Auth_c'; cross-check IDc.</div></div></div></div>
    <div class="step-card"><div class="step-header"><div class="step-num">3.3</div><div class="step-title-area"><div class="step-title">Mutual Authentication</div></div><div class="step-phase-tag tag-svc">Mutual</div></div><div class="step-body"><div class="story-side"><div class="story-dialogue">Guard echoes "12:11" sealed with GoldenKey. Alice trusts the room.</div></div><div class="real-side"><div class="proto-block">V→C: E(Kc,v, TS3+1) — proves server holds Kv.</div></div></div></div>

    <div class="phase-divider"><div class="phase-badge">Phase 4 — Replay Attack</div></div>
    <div class="step-card"><div class="step-header"><div class="step-num">4.1</div><div class="step-title-area"><div class="step-title">Why Replay Fails</div></div><div class="step-phase-tag tag-threat">Threat</div></div><div class="step-body"><div class="story-side"><div class="story-dialogue">"Yesterday's pass and declaration? Expired and stale!"</div></div><div class="real-side"><div class="proto-block">Ticket expired, timestamp >5min old, replay cache hit.</div><div class="warn-box"><strong>Pass-the-Ticket:</strong> steal both ticket & session key while valid.</div></div></div></div>

    <div class="flow-box"><h3>Flow Summary</h3><div class="flow-step"><div class="flow-n">1</div><div class="flow-text">AS→TGT+session key</div></div><div class="flow-arrow">↓</div><div class="flow-step"><div class="flow-n">2</div><div class="flow-text">TGS→service ticket</div></div><div class="flow-arrow">↓</div><div class="flow-step"><div class="flow-n">3</div><div class="flow-text">V verifies offline, mutual auth</div></div></div>
    <div class="guarantee-grid"><div class="guarantee-card"><div class="gc-icon">🔐</div><div class="gc-title">Password Never Sent</div><div class="gc-body">Implicit verification via decryption.</div></div><div class="guarantee-card"><div class="gc-icon">⏱️</div><div class="gc-title">Automatic Expiry</div><div class="gc-body">Tickets expire, no revocation needed.</div></div></div>
  </div>

  <script>
    (function() {
      const body = document.body;
      const toggleBtn = document.getElementById('themeToggle');
      const iconSpan = toggleBtn.querySelector('.toggle-icon');
      const textSpan = toggleBtn.querySelector('span:last-child');

      function setTheme(theme) {
        if (theme === 'dark') {
          body.classList.add('dark');
          body.classList.remove('light');
          iconSpan.textContent = '🌙';
          textSpan.textContent = 'Dark';
          localStorage.setItem('kerberosTheme', 'dark');
        } else {
          body.classList.remove('dark');
          body.classList.add('light');
          iconSpan.textContent = '☀️';
          textSpan.textContent = 'Light';
          localStorage.setItem('kerberosTheme', 'light');
        }
      }

      // default light
      const savedTheme = localStorage.getItem('kerberosTheme') || 'light';
      setTheme(savedTheme);

      toggleBtn.addEventListener('click', () => {
        if (body.classList.contains('dark')) {
          setTheme('light');
        } else {
          setTheme('dark');
        }
      });
    })();
  </script>
</body>
</html>
```