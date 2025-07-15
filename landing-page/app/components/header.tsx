"use client"

import { Button } from "@/components/ui/button"
import { Github, Download } from "lucide-react"
import { downloadAndNavigate } from "@/lib/utils"

export default function Header() {
  return (
    <header className="border-b border-gray-800 bg-black/95 backdrop-blur-sm sticky top-0 z-50">
      <div className="container mx-auto px-4 py-4 flex items-center justify-between">
        <a href="/" className="flex items-center space-x-2 hover:opacity-80 transition-opacity">
          <img
            src="/logo.svg"
            alt="Meetingnotes logo"
            className="w-8 h-8"
          />
          <span className="text-xl font-bold">Meetingnotes</span>
        </a>

        <nav className="hidden md:flex items-center space-x-8">
          <a href="/#features" className="text-gray-300 hover:text-white transition-colors">
            Features
          </a>
          <a href="/#pricing" className="text-gray-300 hover:text-white transition-colors">
            Pricing
          </a>
          <a
            href="https://github.com/owengretzinger/meetingnotes"
            className="text-gray-300 hover:text-white transition-colors"
          >
            GitHub
          </a>
        </nav>

        <div className="flex items-center space-x-3">
          <Button
            variant="outline"
            size="sm"
            className="border-gray-600 text-gray-300 hover:bg-gray-800 bg-transparent"
            asChild
          >
            <a href="https://github.com/owengretzinger/meetingnotes">
              <Github className="w-4 h-4 md:mr-2" />
              <span className="hidden md:inline">Star</span>
            </a>
          </Button>
          <Button size="sm" className="bg-blue-600 hover:bg-blue-700" onClick={downloadAndNavigate}>
            <Download className="w-4 h-4 md:mr-2" />
            <span className="hidden md:inline">Download</span>
          </Button>
        </div>
      </div>
    </header>
  )
}
