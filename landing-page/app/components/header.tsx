import { Button } from "@/components/ui/button"
import { Github, Download } from "lucide-react"

export default function Header() {
  return (
    <header className="border-b border-gray-800 bg-black/95 backdrop-blur-sm sticky top-0 z-50">
      <div className="container mx-auto px-4 py-4 flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <div className="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
            <span className="text-white font-bold text-sm">MN</span>
          </div>
          <span className="text-xl font-bold">Meetingnotes</span>
        </div>

        <nav className="hidden md:flex items-center space-x-8">
          <a href="#features" className="text-gray-300 hover:text-white transition-colors">
            Features
          </a>
          <a href="#how-it-works" className="text-gray-300 hover:text-white transition-colors">
            How it Works
          </a>
          <a href="#pricing" className="text-gray-300 hover:text-white transition-colors">
            Pricing
          </a>
          <a
            href="https://github.com/meetingnotes/meetingnotes"
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
          >
            <Github className="w-4 h-4 mr-2" />
            Star
          </Button>
          <Button size="sm" className="bg-blue-600 hover:bg-blue-700">
            <Download className="w-4 h-4 mr-2" />
            Download
          </Button>
        </div>
      </div>
    </header>
  )
}
