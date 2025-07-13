import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Download, Github, Star, Shield, Code, Zap } from "lucide-react"

export default function Hero() {
  return (
    <section className="pb-6 pt-12 px-4 bg-gradient-to-b from-black to-gray-900">
      <div className="container mx-auto text-center">
        <Badge variant="secondary" className="mb-8 bg-blue-600/20 text-blue-400 border-blue-600/30">
          ✨ Free Open-Source Alternative to Granola!
        </Badge>

        <h1 className="text-5xl md:text-7xl font-bold mb-6 pb-2 bg-gradient-to-r from-white to-gray-300 bg-clip-text text-transparent">
          The Free, Open-Source
          <br />
          AI Notetaker for Busy
          <br />
          Engineers
        </h1>

        <p className="text-xl md:text-2xl text-gray-300 mb-8 max-w-[52rem] mx-auto leading-relaxed">
          Just you and your OpenAI API key. Go crazy.
        </p>

        <div className="flex flex-wrap justify-center gap-6 mb-12">
          <div className="flex items-center space-x-2 text-green-400">
            <Zap className="w-5 h-5" />
            <span className="font-semibold">100% Free</span>
            <span className="text-gray-400">No subscriptions, ever</span>
          </div>
          <div className="flex items-center space-x-2 text-blue-400">
            <Shield className="w-5 h-5" />
            <span className="font-semibold">100% Private</span>
            <span className="text-gray-400">All data stored locally</span>
          </div>
          <div className="flex items-center space-x-2 text-purple-400">
            <Code className="w-5 h-5" />
            <span className="font-semibold">100% Open Source</span>
            <span className="text-gray-400">Contribute on GitHub</span>
          </div>
        </div>

        <div className="flex flex-col sm:flex-row gap-4 justify-center mb-16">
          <Button size="lg" className="bg-blue-600 hover:bg-blue-700 text-lg px-8 py-4" asChild>
            <a href="/download">
              <Download className="w-5 h-5 mr-2" />
              Download for macOS
            </a>
          </Button>
          <Button
            variant="outline"
            size="lg"
            className="border-gray-600 text-gray-300 hover:bg-gray-800 text-lg px-8 py-4 bg-transparent"
            asChild
          >
            <a href="https://github.com/owengretzinger/meetingnotes">
              <Github className="w-5 h-5 mr-2" />
              View on GitHub
            </a>
          </Button>
        </div>

        <div className="max-w-4xl mx-auto">
          <div className="bg-gray-900/50 rounded-xl p-8 border border-gray-800">
            <div className="aspect-video bg-gray-800 rounded-lg flex items-center justify-center border-2 border-dashed border-gray-600">
              <div className="text-center">
                <div className="w-16 h-16 bg-blue-600/20 rounded-full flex items-center justify-center mx-auto mb-4">
                  <svg className="w-8 h-8 text-blue-400" fill="currentColor" viewBox="0 0 20 20">
                    <path
                      fillRule="evenodd"
                      d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z"
                      clipRule="evenodd"
                    />
                  </svg>
                </div>
                <h3 className="text-xl font-semibold text-white mb-2">Demo Video</h3>
                <p className="text-gray-400">See Meetingnotes in action</p>
              </div>
            </div>
            <p className="text-sm text-gray-400 mt-4 text-center">
              Watch how Meetingnotes transcribes meetings and generates AI-enhanced notes in real-time
            </p>
          </div>
        </div>

        {/* <div className="mt-8 flex items-center justify-center space-x-4 text-sm text-gray-400">
          <div className="flex items-center space-x-1">
            <Star className="w-4 h-4 text-yellow-500" />
            <span>1.2k stars on GitHub</span>
          </div>
          <span>•</span>
          <span>500+ downloads</span>
          <span>•</span>
          <span>50+ contributors</span>
        </div> */}
      </div>
    </section>
  )
}
