import type React from "react"
import type { Metadata } from "next"
import { Inter } from "next/font/google"
import "./globals.css"

const inter = Inter({ subsets: ["latin"] })

export const metadata: Metadata = {
  metadataBase: new URL("https://meetingnotes.owengretzinger.com"),
  title: "Meetingnotes - Free Open-Source AI Meeting Notetaker",
  description:
    "Free, open-source macOS app for AI-powered meeting notes. Transcribe, summarize, and store everything locally with complete privacy. Created by Owen Gretzinger.",
  keywords: "meeting notes, AI transcription, open source, privacy, macOS, free, Granola alternative, Owen Gretzinger",
  authors: [{ name: "Owen Gretzinger" }],
  openGraph: {
    title: "Meetingnotes - Free Open-Source AI Meeting Notetaker",
    description:
      "Free, open-source macOS app for AI-powered meeting notes. Created by Owen Gretzinger for privacy-focused professionals.",
    type: "website",
    url: "https://meetingnotes.owengretzinger.com",
    images: [
      {
        url: "/ogimage.png",
        width: 1200,
        height: 630,
        alt: "Meetingnotes - Free Open-Source AI Meeting Notetaker",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "Meetingnotes - Free Open-Source AI Meeting Notetaker",
    description: "Free, open-source macOS app for AI-powered meeting notes by Owen Gretzinger.",
    images: [
      {
        url: "/ogimage.png",
        width: 1200,
        height: 630,
        alt: "Meetingnotes - Free Open-Source AI Meeting Notetaker",
      },
    ],
  },
    generator: 'v0.dev'
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" className="scroll-smooth">
      <body className={`${inter.className} antialiased`}>{children}</body>
    </html>
  )
}
