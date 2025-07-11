import { Shield, Laptop, Lock } from "lucide-react"

export default function Privacy() {
  const platforms = [
    { name: "macOS", logo: "/placeholder.svg?height=40&width=40" },
    { name: "Google Meet", logo: "/placeholder.svg?height=40&width=40" },
    { name: "Zoom", logo: "/placeholder.svg?height=40&width=40" },
    { name: "Microsoft Teams", logo: "/placeholder.svg?height=40&width=40" },
    { name: "Slack", logo: "/placeholder.svg?height=40&width=40" },
  ]

  return (
    <section className="py-20 px-4 bg-gray-900">
      <div className="container mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6">Works on macOS with Full Privacy – No Bots, No Cloud</h2>
          <p className="text-xl text-gray-300 max-w-4xl mx-auto mb-8">
            Meetingnotes transcribes directly from your computer's audio. No meeting bots join your calls, and all data
            stays on your device.
          </p>
        </div>

        <div className="flex flex-wrap justify-center items-center gap-8 mb-16">
          {platforms.map((platform, index) => (
            <div key={index} className="flex flex-col items-center space-y-2">
              <img
                src={platform.logo || "/placeholder.svg"}
                alt={`${platform.name} logo`}
                className="w-12 h-12 rounded-lg"
              />
              <span className="text-sm text-gray-400">{platform.name}</span>
            </div>
          ))}
        </div>

        <div className="grid md:grid-cols-3 gap-8">
          <div className="text-center">
            <div className="w-16 h-16 bg-green-600/20 rounded-full flex items-center justify-center mx-auto mb-4">
              <Shield className="w-8 h-8 text-green-400" />
            </div>
            <h3 className="text-xl font-bold mb-3">Your Data, Your Control</h3>
            <p className="text-gray-300">
              Nothing leaves your machine. All transcripts and notes are stored locally on your device.
            </p>
          </div>

          <div className="text-center">
            <div className="w-16 h-16 bg-blue-600/20 rounded-full flex items-center justify-center mx-auto mb-4">
              <Laptop className="w-8 h-8 text-blue-400" />
            </div>
            <h3 className="text-xl font-bold mb-3">No Meeting Bots</h3>
            <p className="text-gray-300">
              Records directly from your computer's audio without joining any bots to your meetings.
            </p>
          </div>

          <div className="text-center">
            <div className="w-16 h-16 bg-purple-600/20 rounded-full flex items-center justify-center mx-auto mb-4">
              <Lock className="w-8 h-8 text-purple-400" />
            </div>
            <h3 className="text-xl font-bold mb-3">Secure API Keys</h3>
            <p className="text-gray-300">
              Your Deepgram and OpenAI API keys are stored securely on your device, never shared.
            </p>
          </div>
        </div>
      </div>
    </section>
  )
}
