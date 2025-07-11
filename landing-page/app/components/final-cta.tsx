import { Button } from "@/components/ui/button"
import { Download, Github, ArrowRight } from "lucide-react"

export default function FinalCTA() {
  return (
    <section className="py-20 px-4 bg-gradient-to-b from-black to-gray-900">
      <div className="container mx-auto text-center">
        <h2 className="text-4xl md:text-6xl font-bold mb-6 bg-gradient-to-r from-white to-gray-300 bg-clip-text text-transparent">
          Ready for Smarter,
          <br />
          Free Meeting Notes?
        </h2>

        <p className="text-xl md:text-2xl text-gray-300 mb-12 max-w-3xl mx-auto leading-relaxed">
          Download Meetingnotes today and experience AI-powered notes without the cost. It's open source, so make it
          your own.
        </p>

        <div className="flex flex-col sm:flex-row gap-6 justify-center mb-12">
          <Button size="lg" className="bg-blue-600 hover:bg-blue-700 text-lg px-8 py-4 group">
            <Download className="w-5 h-5 mr-2" />
            Download for macOS
            <ArrowRight className="w-4 h-4 ml-2 group-hover:translate-x-1 transition-transform" />
          </Button>
          <Button
            variant="outline"
            size="lg"
            className="border-gray-600 text-gray-300 hover:bg-gray-800 text-lg px-8 py-4 bg-transparent"
          >
            <Github className="w-5 h-5 mr-2" />
            Learn More on GitHub
          </Button>
        </div>

        <div className="grid md:grid-cols-3 gap-8 max-w-4xl mx-auto text-left">
          <div className="bg-gray-900/50 rounded-xl p-6 border border-gray-800">
            <h3 className="text-xl font-bold mb-3 text-green-400">100% Free Forever</h3>
            <p className="text-gray-300">
              No hidden costs, no subscriptions, no premium tiers. Just free, powerful meeting notes.
            </p>
          </div>

          <div className="bg-gray-900/50 rounded-xl p-6 border border-gray-800">
            <h3 className="text-xl font-bold mb-3 text-blue-400">Privacy First</h3>
            <p className="text-gray-300">
              Your data never leaves your device. Complete control over your meeting notes and transcripts.
            </p>
          </div>

          <div className="bg-gray-900/50 rounded-xl p-6 border border-gray-800">
            <h3 className="text-xl font-bold mb-3 text-purple-400">Open Source</h3>
            <p className="text-gray-300">
              Transparent, customizable, and community-driven. Contribute and help shape the future.
            </p>
          </div>
        </div>
      </div>
    </section>
  )
}
