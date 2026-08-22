import type { Metadata, Viewport } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "paullm-ssh — Your AI coding agent lives on a real machine",
  description: "Connect directly to Ubuntu or Mac over SSH, run CLI coding agents on your own machine, and pick up the work anywhere from iPhone, iPad, or Mac.",
  keywords: ["iOS SSH client", "Mac SSH client", "iPad SSH terminal", "SFTP client iPhone", "Ghostty terminal iOS", "Mosh SSH app", "Tailscale SSH client", "Cloudflare Access SSH client", "Claude Code SSH", "Codex CLI SSH", "OpenCode SSH", "vibe coding terminal", "remote AI coding"],
  authors: [{ name: "paullm" }],
  metadataBase: new URL("https://paullm.com"),
  openGraph: {
    type: "website",
    title: "paullm-ssh — Your AI coding agent lives on a real machine",
    description: "Connect directly to Ubuntu or Mac over SSH, run CLI coding agents on your own machine, and pick up the work anywhere from iPhone, iPad, or Mac.",
    url: "/",
    siteName: "paullm-ssh",
    images: [{ url: "/og.png" }],
  },
  twitter: {
    card: "summary_large_image",
    title: "paullm-ssh — Your AI coding agent lives on a real machine",
    description: "Connect directly to Ubuntu or Mac over SSH, run CLI coding agents on your own machine, and pick up the work anywhere from iPhone, iPad, or Mac.",
    images: ["/og.png"],
    site: "@paullm",
  },
  appleWebApp: {
    title: "paullm-ssh",
    statusBarStyle: "default",
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <head>
        <link rel="icon" type="image/png" href="/logo.png" />
        <link rel="canonical" href="https://paullm.com/" />
        <meta name="theme-color" content="#f4f4ef" />
      </head>
      <body>
        {children}
      </body>
    </html>
  );
}
