import { Card, CardContent } from "@/components/ui/card"
import { Download, Key, Play, FileText } from "lucide-react"

export default function HowItWorks() {
  const steps = [
    {
      number: "01",
      icon: <Download className="w-6 h-6" />,
      title: "Download & Setup",
      description:
        "Download and install on macOS. Enter your Deepgram and OpenAI API keys (stored securely on-device).",
    },
    {
      number: "02",
      icon: <Play className="w-6 h-6" />,
      title: "Start Recording",
      description: "Start a meeting—Meetingnotes records audio and shows a live transcript in real-time.",
    },
    {
      number: "03",
      icon: <FileText className="w-6 h-6" />,
      title: "Add Your Notes",
      description: "Add your own notes during the call to complement the automatic transcription.",
    },
    {
      number: "04",
      icon: <Key className="w-6 h-6" />,
      title: "Get AI Summary",
      description: "End the meeting—AI generates enhanced notes instantly. Edit, copy, or search later.",
    },
  ]

  return (
    <section id="how-it-works" className="py-20 px-4 bg-black">
      <div className="container mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6">How meetingnotes Works</h2>
          <p className="text-xl text-gray-300 max-w-3xl mx-auto">
            Get started in minutes with our simple, privacy-first approach to meeting notes.
          </p>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8 mb-16">
          {steps.map((step, index) => (
            <Card key={index} className="bg-gray-900/50 border-gray-800 text-center">
              <CardContent className="p-8">
                <div className="text-4xl font-bold text-blue-400 mb-4">{step.number}</div>
                <div className="w-12 h-12 bg-blue-600/20 rounded-full flex items-center justify-center mx-auto mb-4 text-blue-400">
                  {step.icon}
                </div>
                <h3 className="text-xl font-bold mb-3">{step.title}</h3>
                <p className="text-gray-300 leading-relaxed">{step.description}</p>
              </CardContent>
            </Card>
          ))}
        </div>

        <div className="bg-gradient-to-r from-gray-900 to-gray-800 rounded-xl p-8 border border-gray-700 text-center">
          <blockquote className="text-2xl font-medium text-gray-200 mb-4">
            "meetingnotes saves me hours every week—best part? It's free and open source!"
          </blockquote>
          <cite className="text-blue-400 font-semibold">– Open-Source Contributor</cite>
        </div>
      </div>
    </section>
  )
}
