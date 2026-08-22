"use client";

import Image from "next/image";
import { useState, type ReactNode } from "react";
import {
  ArrowRight,
  ArrowUpRight,
  Bot,
  Check,
  ChevronDown,
  ChevronRight,
  CircleDot,
  Cloud,
  Code2,
  Command,
  FileCode2,
  FolderOpen,
  Github,
  KeyRound,
  Laptop,
  LockKeyhole,
  Menu,
  Network,
  Play,
  Server,
  Smartphone,
  Sparkles,
  Terminal,
  Wifi,
  Workflow,
  X,
  Zap,
} from "lucide-react";

const APP_STORE_URL = "https://apps.apple.com/app/paullm-ssh/id6757482822";
const GITHUB_URL = "https://github.com/paullm/paullm-ssh";
const HOST_SETUP_URL = `${GITHUB_URL}/blob/main/docs/AI_CODING_HOST_SETUP.md`;

const features = [
  {
    icon: Terminal,
    number: "01",
    title: "A real terminal",
    copy: "Ghostty-powered rendering, tabs, split panes, reconnect handling, rich paste, and the keys a terminal actually needs.",
  },
  {
    icon: Bot,
    number: "02",
    title: "CLI agents on your box",
    copy: "Run Claude, Codex, OpenCode, Antigravity, or your own tools where your code and dependencies already live.",
  },
  {
    icon: FolderOpen,
    number: "03",
    title: "Files beside the shell",
    copy: "Browse remote directories, preview files, upload, download, rename, move, and share without changing apps.",
  },
  {
    icon: Network,
    number: "04",
    title: "The connection you already trust",
    copy: "Use direct SSH, Mosh, Tailscale SSH, or Cloudflare Access. Choose the network path that fits your setup.",
  },
  {
    icon: KeyRound,
    number: "05",
    title: "Secrets stay local",
    copy: "Passwords, keys, passphrases, and service tokens are kept in Keychain while useful server metadata syncs with iCloud.",
  },
  {
    icon: Sparkles,
    number: "06",
    title: "Make it yours",
    copy: "Themes, presets, keyboard actions, voice-to-command, server stats, and workspaces shaped around the way you work.",
  },
];

const faqs = [
  {
    question: "What is paullm-ssh actually running?",
    answer: "paullm-ssh is the native client. Your code, packages, Git repositories, services, and CLI agents run on the Ubuntu server, Mac mini, workstation, homelab machine, or cloud VM you connect to over SSH.",
  },
  {
    question: "How do I use it for vibe coding?",
    answer: "Install your preferred CLI agent on the remote machine, connect it in paullm-ssh, and start a typed coding session or a persistent tmux session. That gives you a recognizable place to return to from iPhone, iPad, or Mac.",
  },
  {
    question: "Do I need a special backend or subscription from an AI lab?",
    answer: "No. paullm-ssh uses standard SSH and works with the tools you already install. You can switch between Claude, Codex, OpenCode, Antigravity, local scripts, and ordinary shell work without moving your project into a proprietary mobile wrapper.",
  },
  {
    question: "Can I connect to a Mac and Ubuntu?",
    answer: "Yes. Use Remote Login on macOS or OpenSSH on Ubuntu, then add the host in paullm-ssh. For private networks, Tailscale SSH is a clean option; Mosh is useful when the network is intermittent.",
  },
  {
    question: "What does the free version include?",
    answer: "Free includes one workspace, three servers, one connection tab, the terminal, SFTP browser, iCloud metadata sync, Keychain security, and the supported connection methods. Pro removes the workspace, server, and tab limits.",
  },
];

function SectionLabel({ children }: { children: ReactNode }) {
  return (
    <div className="section-label">
      <span className="section-label-mark">{"//"}</span>
      <span>{children}</span>
    </div>
  );
}

function CheckLine({ children }: { children: ReactNode }) {
  return (
    <li className="check-line">
      <span className="check-icon"><Check size={13} strokeWidth={2.5} /></span>
      <span>{children}</span>
    </li>
  );
}

export default function Home() {
  const [menuOpen, setMenuOpen] = useState(false);
  const [openFaq, setOpenFaq] = useState(0);

  const closeMenu = () => setMenuOpen(false);

  return (
    <main className="site-page">
      <div className="topline">
        <div className="site-container topline-inner">
          <span><CircleDot size={11} /> Remote-first developer infrastructure</span>
          <span className="topline-right">open source <span className="topline-separator">·</span> free for personal use</span>
        </div>
      </div>

      <header className="site-nav">
        <div className="site-container nav-inner">
          <a className="brand" href="#top" onClick={closeMenu} aria-label="paullm-ssh home">
            <span className="brand-mark"><Terminal size={16} strokeWidth={2.25} /></span>
            <span>paullm<span className="brand-dim">-ssh</span></span>
          </a>

          <nav className={`nav-links ${menuOpen ? "is-open" : ""}`} aria-label="Primary navigation">
            <a href="#why" onClick={closeMenu}>Why SSH</a>
            <a href="#how-it-works" onClick={closeMenu}>How it works</a>
            <a href="#features" onClick={closeMenu}>Features</a>
            <a href="#pricing" onClick={closeMenu}>Pricing</a>
            <a className="nav-mobile-cta" href={APP_STORE_URL} target="_blank" rel="noreferrer" onClick={closeMenu}>Download <ArrowUpRight size={14} /></a>
          </nav>

          <div className="nav-actions">
            <a className="nav-github" href={GITHUB_URL} target="_blank" rel="noreferrer" aria-label="paullm-ssh on GitHub"><Github size={16} /></a>
            <a className="button button-small button-dark" href={APP_STORE_URL} target="_blank" rel="noreferrer">Download <ArrowUpRight size={14} /></a>
            <button className="menu-button" type="button" aria-expanded={menuOpen} aria-label={menuOpen ? "Close menu" : "Open menu"} onClick={() => setMenuOpen(!menuOpen)}>
              {menuOpen ? <X size={20} /> : <Menu size={20} />}
            </button>
          </div>
        </div>
      </header>

      <section className="hero" id="top">
        <div className="site-container hero-grid">
          <div className="hero-copy">
            <SectionLabel>paullm-ssh / 01 — the remote coding terminal</SectionLabel>
            <h1>Your AI coding agent lives on a <em>real machine.</em></h1>
            <p className="hero-lede">Connect directly to your Ubuntu server or Mac, then bring the full operating system with you. paullm-ssh is the clean, flexible way to run CLI agents from anywhere.</p>
            <div className="hero-actions">
              <a className="button button-dark" href={APP_STORE_URL} target="_blank" rel="noreferrer">Get paullm-ssh <ArrowRight size={16} /></a>
              <a className="text-link" href="#how-it-works">See how it works <ChevronRight size={16} /></a>
            </div>
            <div className="hero-footnote"><span className="status-dot" /> iPhone · iPad · Mac <span className="footnote-divider">/</span> SSH · Mosh · Tailscale</div>
          </div>

          <div className="hero-visual" aria-label="paullm-ssh connected to a Mac and iPhone terminal session">
            <div className="hero-grid-lines" />
            <div className="visual-stamp">LIVE / SESSION 03</div>
            <div className="hero-image-frame">
              <div className="window-chrome">
                <span className="window-dots"><i /><i /><i /></span>
                <span className="window-title">paullm-ssh / MacBook / codex</span>
                <span className="window-live"><span className="status-dot" /> connected</span>
              </div>
              <Image src="/preview.png" alt="paullm-ssh running a CLI coding session across Mac, iPad, and iPhone" width={1920} height={1080} priority className="hero-image" />
            </div>
            <div className="floating-card floating-host">
              <span className="floating-icon"><Laptop size={14} /></span>
              <span><strong>MacBook Pro</strong><small>tailnet / active</small></span>
              <span className="floating-signal"><Wifi size={13} /></span>
            </div>
            <div className="floating-card floating-agent">
              <span className="agent-pulse"><Bot size={14} /></span>
              <span><strong>Codex CLI</strong><small>~/development/paullm-ssh</small></span>
              <span className="agent-arrow"><ArrowUpRight size={13} /></span>
            </div>
          </div>
        </div>
      </section>

      <section className="signal-strip" aria-label="paullm-ssh capabilities">
        <div className="site-container signal-grid">
          <div className="signal-cell"><span className="signal-number">01</span><span>Direct SSH</span></div>
          <div className="signal-cell"><span className="signal-number">02</span><span>Full OS access</span></div>
          <div className="signal-cell"><span className="signal-number">03</span><span>Any CLI agent</span></div>
          <div className="signal-cell"><span className="signal-number">04</span><span>Persistent tmux sessions</span></div>
        </div>
      </section>

      <section className="section section-dark why-section" id="why">
        <div className="site-container">
          <div className="section-heading section-heading-dark">
            <div>
              <SectionLabel>02 / the better boundary</SectionLabel>
              <h2>The app is small.<br /><span>The machine is yours.</span></h2>
            </div>
            <p>Mobile coding apps usually give you a narrow window into one hosted workflow. SSH gives you the whole environment: your shell, your packages, your files, your services, and the freedom to switch tools when your work changes.</p>
          </div>

          <div className="comparison-grid">
            <div className="comparison-card comparison-muted">
              <div className="comparison-head"><span className="comparison-icon"><Smartphone size={17} /></span><span>Mobile-only coding surface</span></div>
              <ul>
                <CheckLine>One app’s workflow and model choices</CheckLine>
                <CheckLine>Limited filesystem and process control</CheckLine>
                <CheckLine>Work tied to the app’s hosted context</CheckLine>
                <CheckLine>Harder to keep long-running sessions alive</CheckLine>
              </ul>
            </div>
            <div className="comparison-arrow"><ArrowRight size={20} /></div>
            <div className="comparison-card comparison-accent">
              <div className="comparison-head"><span className="comparison-icon"><Server size={17} /></span><span>paullm-ssh + your machine</span></div>
              <ul>
                <CheckLine>Switch between Claude, Codex, OpenCode, or shell</CheckLine>
                <CheckLine>Full Ubuntu or macOS filesystem and toolchain</CheckLine>
                <CheckLine>Keep your Git repos, packages, and services in place</CheckLine>
                <CheckLine>Reconnect to tmux sessions that never stopped</CheckLine>
              </ul>
            </div>
          </div>

          <div className="principle-row">
            <div><Zap size={16} /><span>Less platform lock-in</span></div>
            <div><Code2 size={16} /><span>More of the OS you already use</span></div>
            <div><Workflow size={16} /><span>One workflow across every device</span></div>
          </div>
        </div>
      </section>

      <section className="section workflow-section" id="how-it-works">
        <div className="site-container">
          <div className="section-heading">
            <div>
              <SectionLabel>03 / current setup</SectionLabel>
              <h2>From a cold boot to a live agent in four moves.</h2>
            </div>
            <p>There is no magic backend to learn. Your machine stays the source of truth; paullm-ssh gives you a fast, native way back into it.</p>
          </div>

          <div className="workflow-grid">
            <div className="workflow-step">
              <div className="workflow-step-top"><span>01</span><Server size={18} /></div>
              <h3>Prepare the host</h3>
              <p>Enable Remote Login on a Mac or install OpenSSH on Ubuntu. For the current Mac setup, use the included host script to configure SSH, keys, and keepalives.</p>
              <code className="code-chip">./scripts/setup-ssh-host.sh --auto</code>
            </div>
            <div className="workflow-step">
              <div className="workflow-step-top"><span>02</span><Network size={18} /></div>
              <h3>Connect your route</h3>
              <p>Add the host in paullm-ssh over your LAN, Tailscale, or Cloudflare Access. Credentials and keys stay protected in Keychain.</p>
              <code className="code-chip">ssh paul@your-box</code>
            </div>
            <div className="workflow-step">
              <div className="workflow-step-top"><span>03</span><Bot size={18} /></div>
              <h3>Start the agent</h3>
              <p>Choose a typed Claude, Codex, OpenCode, Antigravity, or generic tmux session. The command runs on the remote machine, next to your code.</p>
              <code className="code-chip">tmux new -As main</code>
            </div>
            <div className="workflow-step">
              <div className="workflow-step-top"><span>04</span><Smartphone size={18} /></div>
              <h3>Pick up anywhere</h3>
              <p>Close the app, change networks, or move from Mac to iPhone. Reconnect to the same session and keep steering the work.</p>
              <code className="code-chip">tmux attach -t main</code>
            </div>
          </div>

          <div className="workflow-note">
            <div className="workflow-note-icon"><Command size={16} /></div>
            <div><strong>The important part:</strong> paullm-ssh does not replace your server or your agent. It gives you a native window into the environment you already trust.</div>
            <a className="text-link" href={HOST_SETUP_URL} target="_blank" rel="noreferrer">Read the host guide <ArrowUpRight size={14} /></a>
          </div>
        </div>
      </section>

      <section className="section demo-section" id="demo">
        <div className="site-container">
          <div className="section-heading">
            <div>
              <SectionLabel>04 / in the app</SectionLabel>
              <h2>See the work, not a pitch deck.</h2>
            </div>
            <p>One connected workspace for the terminal surface, remote files, and the sessions you want to keep alive.</p>
          </div>

          <div className="demo-grid">
            <div className="demo-window demo-terminal-window">
              <div className="demo-window-bar"><span className="window-dots"><i /><i /><i /></span><span>ubuntu / codex / ~/projects/atlas</span><span className="demo-window-tag">terminal</span></div>
              <div className="demo-terminal-body">
                <div className="demo-sidebar">
                  <div className="mock-sidebar-label">WORKSPACE</div>
                  <div className="mock-workspace"><span className="mock-blue-dot" /> My Servers <span className="mock-count">3</span></div>
                  <div className="mock-sidebar-label mock-sidebar-spaced">SERVERS</div>
                  <div className="mock-server active"><span className="mock-green-dot" /> ubuntu-box <small>prod</small></div>
                  <div className="mock-server"><span className="mock-green-dot" /> Mac mini <small>dev</small></div>
                  <div className="mock-server"><span className="mock-gray-dot" /> cloud-vm <small>staging</small></div>
                  <div className="mock-sidebar-footer">iCloud synced</div>
                </div>
                <div className="mock-terminal-content">
                  <div className="mock-terminal-tabs"><span className="active-tab">codex / main</span><span>shell / logs</span><span className="tab-plus">+</span></div>
                  <div className="terminal-copy">
                    <p><span className="terminal-muted">paul@ubuntu-box</span><span className="terminal-green">:</span><span className="terminal-blue">~/projects/atlas</span><span className="terminal-green">$</span> codex</p>
                    <p className="terminal-title">&gt;_ OpenAI Codex <span>(v0.87.0)</span></p>
                    <div className="terminal-outline"><p>model: <strong>gpt-5.2-codex high</strong></p><p>directory: <strong>~/projects/atlas</strong></p></div>
                    <p className="terminal-tip">Tip: press Tab to queue a message. Enter sends immediately.</p>
                    <div className="terminal-command"><span>›</span> Run tests, inspect the failing route, and fix it</div>
                    <p className="terminal-progress">100% context left <span>·</span> ? for shortcuts <span className="mock-cursor" /></p>
                  </div>
                </div>
              </div>
            </div>

            <div className="demo-side-stack">
              <div className="demo-window demo-files-window">
                <div className="demo-window-bar"><span className="window-dots"><i /><i /><i /></span><span>ubuntu-box / remote files</span><span className="demo-window-tag">sftp</span></div>
                <div className="files-body">
                  <div className="files-breadcrumb"><FolderOpen size={13} /> /home/paul/projects/atlas</div>
                  <div className="file-row file-header"><span>NAME</span><span>MODIFIED</span></div>
                  <div className="file-row"><span><FolderOpen size={14} className="file-folder" /> .git</span><span>today</span></div>
                  <div className="file-row"><span><FolderOpen size={14} className="file-folder" /> Sources</span><span>12m ago</span></div>
                  <div className="file-row"><span><FileCode2 size={14} /> package.json</span><span>12m ago</span></div>
                  <div className="file-row"><span><FileCode2 size={14} /> README.md</span><span>yesterday</span></div>
                </div>
              </div>
              <div className="demo-session-card">
                <div className="session-card-top"><span className="live-label"><span className="status-dot" /> SESSION PICKER</span><span className="session-count">03 active</span></div>
                <div className="session-row session-selected"><span className="session-icon"><Bot size={14} /></span><span><strong>Codex / main</strong><small>ubuntu-box · ~/projects/atlas</small></span><ChevronRight size={14} /></div>
                <div className="session-row"><span className="session-icon session-icon-blue"><Terminal size={14} /></span><span><strong>Claude / review</strong><small>Mac mini · ~/code/paullm</small></span><ChevronRight size={14} /></div>
              </div>
            </div>
          </div>
          <p className="demo-caption"><Play size={13} fill="currentColor" /> Screens shown are representative paullm-ssh workflows: terminal, SFTP, and typed sessions.</p>
        </div>
      </section>

      <section className="section feature-section" id="features">
        <div className="site-container">
          <div className="section-heading">
            <div>
              <SectionLabel>05 / built for the long haul</SectionLabel>
              <h2>Small surface area.<br />Serious depth.</h2>
            </div>
            <p>Everything you need to stay close to the machine without turning the client into another platform you have to manage.</p>
          </div>
          <div className="feature-grid">
            {features.map((feature) => {
              const Icon = feature.icon;
              return (
                <article className="feature-card" key={feature.number}>
                  <div className="feature-card-top"><span className="feature-number">{feature.number}</span><Icon size={19} /></div>
                  <h3>{feature.title}</h3>
                  <p>{feature.copy}</p>
                </article>
              );
            })}
          </div>
        </div>
      </section>

      <section className="section security-section">
        <div className="site-container security-grid">
          <div className="security-art">
            <div className="security-orbit orbit-one" />
            <div className="security-orbit orbit-two" />
            <div className="security-core"><LockKeyhole size={26} /></div>
            <div className="security-node node-key"><KeyRound size={14} /><span>Keychain</span></div>
            <div className="security-node node-cloud"><Cloud size={14} /><span>iCloud metadata</span></div>
            <div className="security-node node-ssh"><Wifi size={14} /><span>SSH tunnel</span></div>
          </div>
          <div className="security-copy">
            <SectionLabel>06 / your infrastructure, your rules</SectionLabel>
            <h2>Sync what helps.<br /><em>Protect what matters.</em></h2>
            <p>Server and workspace metadata can follow you across Apple devices. The credentials that unlock your infrastructure stay in Keychain. The boundary is simple, visible, and native to the platform.</p>
            <ul className="security-list">
              <CheckLine>Keychain-backed passwords, keys, passphrases, and service tokens</CheckLine>
              <CheckLine>CloudKit sync for servers, workspaces, themes, and accessory profiles</CheckLine>
              <CheckLine>Full-app lock, per-server biometrics, and privacy mode</CheckLine>
            </ul>
          </div>
        </div>
      </section>

      <section className="section pricing-section" id="pricing">
        <div className="site-container">
          <div className="section-heading">
            <div>
              <SectionLabel>07 / start small, grow later</SectionLabel>
              <h2>Free for the machine you already own.</h2>
            </div>
            <p>Use the full connection workflow for personal remote work. Upgrade when your server list and session count outgrow the free tier.</p>
          </div>
          <div className="pricing-grid">
            <article className="price-card">
              <div className="price-card-head"><span className="price-eyebrow">PERSONAL</span><span className="price-icon"><Laptop size={16} /></span></div>
              <h3>Free</h3><p>Everything you need to reach one small setup.</p>
              <div className="price"><strong>$0</strong><span>/ forever</span></div>
              <ul><CheckLine>1 workspace</CheckLine><CheckLine>3 servers</CheckLine><CheckLine>1 connection tab</CheckLine><CheckLine>SSH, Mosh, Tailscale, Cloudflare Access</CheckLine></ul>
              <a className="button button-outline button-full" href={APP_STORE_URL} target="_blank" rel="noreferrer">Download free <ArrowUpRight size={14} /></a>
            </article>
            <article className="price-card price-card-featured">
              <div className="price-card-head"><span className="price-eyebrow">UNLIMITED</span><span className="price-badge">PRO</span></div>
              <h3>Pro</h3><p>Unlimited room for the machines and projects that multiply.</p>
              <div className="price"><strong>$6.49</strong><span>/ month</span></div>
              <ul><CheckLine>Unlimited workspaces, servers, and tabs</CheckLine><CheckLine>Custom environments</CheckLine><CheckLine>Priority support</CheckLine><CheckLine>All future features</CheckLine></ul>
              <a className="button button-light button-full" href={APP_STORE_URL} target="_blank" rel="noreferrer">See Pro in the app <ArrowUpRight size={14} /></a>
            </article>
            <article className="price-card">
              <div className="price-card-head"><span className="price-eyebrow">ONE TIME</span><span className="price-icon"><Sparkles size={16} /></span></div>
              <h3>Lifetime</h3><p>Pay once and keep the whole remote workspace.</p>
              <div className="price"><strong>$49.99</strong><span>/ once</span></div>
              <ul><CheckLine>Everything in Pro</CheckLine><CheckLine>All future updates</CheckLine><CheckLine>Priority support</CheckLine><CheckLine>One purchase, no recurring charge</CheckLine></ul>
              <a className="button button-outline button-full" href={APP_STORE_URL} target="_blank" rel="noreferrer">Get lifetime <ArrowUpRight size={14} /></a>
            </article>
          </div>
        </div>
      </section>

      <section className="section faq-section" id="faq">
        <div className="site-container faq-grid">
          <div className="faq-intro">
            <SectionLabel>08 / questions</SectionLabel>
            <h2>No cloud theater.<br />Just a better terminal.</h2>
            <p>If you can SSH into the machine, you can use paullm-ssh to work there. That is the whole point.</p>
            <a className="text-link" href={GITHUB_URL} target="_blank" rel="noreferrer">Read the source on GitHub <ArrowUpRight size={14} /></a>
          </div>
          <div className="faq-list">
            {faqs.map((faq, index) => {
              const isOpen = openFaq === index;
              return (
                <div className={`faq-item ${isOpen ? "is-open" : ""}`} key={faq.question}>
                  <button className="faq-question" type="button" aria-expanded={isOpen} onClick={() => setOpenFaq(isOpen ? -1 : index)}>
                    <span><span className="faq-index">0{index + 1}</span>{faq.question}</span>
                    <ChevronDown size={17} />
                  </button>
                  <div className="faq-answer"><p>{faq.answer}</p></div>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      <section className="closing-section">
        <div className="site-container closing-inner">
          <div className="closing-mark"><Terminal size={20} /></div>
          <SectionLabel>ready when you are</SectionLabel>
          <h2>Bring your whole machine.</h2>
          <p>Connect once. Keep the session. Switch devices, agents, or ideas whenever you want.</p>
          <div className="hero-actions closing-actions"><a className="button button-light" href={APP_STORE_URL} target="_blank" rel="noreferrer">Download paullm-ssh <ArrowUpRight size={15} /></a><a className="closing-github" href={GITHUB_URL} target="_blank" rel="noreferrer"><Github size={15} /> View on GitHub</a></div>
        </div>
      </section>

      <footer className="site-footer">
        <div className="site-container footer-grid">
          <div className="footer-brand"><a className="brand brand-footer" href="#top"><span className="brand-mark"><Terminal size={16} strokeWidth={2.25} /></span><span>paullm<span className="brand-dim">-ssh</span></span></a><p>Native SSH terminal and SFTP client for iPhone, iPad, and Mac.</p></div>
          <div className="footer-links"><div><span className="footer-heading">Product</span><a href="#why">Why SSH</a><a href="#features">Features</a><a href="#pricing">Pricing</a></div><div><span className="footer-heading">Resources</span><a href={HOST_SETUP_URL} target="_blank" rel="noreferrer">Host setup guide</a><a href={GITHUB_URL} target="_blank" rel="noreferrer">GitHub</a><a href="/support">Support</a></div><div><span className="footer-heading">Legal</span><a href="/privacy">Privacy</a><a href="/terms">Terms</a><a href="/refund">Refunds</a></div></div>
        </div>
        <div className="site-container footer-bottom"><span>© {new Date().getFullYear()} paullm</span><span>Built for the machines that do the work.</span></div>
      </footer>
    </main>
  );
}
