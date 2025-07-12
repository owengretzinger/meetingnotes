import { Card, CardContent } from "@/components/ui/card";
import { Mic, Lightbulb, Settings, FolderOpen } from "lucide-react";

export default function Features() {
  const features = [
    {
      icon: <Mic className="w-8 h-8 text-blue-400" />,
      title: "Live Transcription",
      description:
        "Records mic + system audio and uses OpenAI for real-time transcripts. No meeting bots required.",
      image: "/transcript.png",
    },
    {
      icon: <Lightbulb className="w-8 h-8 text-yellow-400" />,
      title: "AI-Enhanced Notes",
      description:
        "Generates summaries from transcripts plus your manual notes, powered by OpenAI.",
      image: "/notes.png",
    },
    {
      icon: <Settings className="w-8 h-8 text-green-400" />,
      title: "Customization & Privacy",
      description:
        "Edit the system prompt and bring your own API key. Everything is stored locally.",
      image: "/settings.png",
    },  
    {
      icon: <FolderOpen className="w-8 h-8 text-purple-400" />,
      title: "Easy Management",
      description:
        "Search, delete, and copy your notes & transcripts, and auto-update the app.",
      image: "/search.png",
    },
  ];

  return (
    <section id="features" className="py-6 px-4 bg-gray-900">
      <div className="container mx-auto">
        {/* <div className="text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6">Powerful Features, All Free and Open Source</h2>
          <p className="text-xl text-gray-300 max-w-3xl mx-auto">
            Meetingnotes handles your meeting notes effortlessly, from live transcription to AI-generated summaries.
            Customize it to fit your workflow, and contribute to make it even better.
          </p>
        </div> */}

        <div className="grid md:grid-cols-2 gap-8 mb-12">
          {features.map((feature, index) => (
            <Card
              key={index}
              className="bg-black/50 border-gray-800 hover:border-gray-700 transition-colors"
            >
              <CardContent className="p-8">
                <div className="flex-1">
                  <div className="flex items-start space-x-4">
                    <div className="flex-shrink-0">{feature.icon}</div>
                    <h3 className="text-2xl font-bold mb-3 text-white">
                      {feature.title}
                    </h3>
                  </div>
                  <p className="text-gray-300 mb-4 leading-relaxed">
                    {feature.description}
                  </p>
                  <img
                    src={feature.image || "/placeholder.svg"}
                    alt={`${feature.title} screenshot`}
                    className="w-full"
                  />
                </div>
              </CardContent>
            </Card>
          ))}
        </div>

        <div className="bg-gradient-to-r from-blue-600/20 to-purple-600/20 rounded-xl p-8 border border-blue-600/30">
          <h3 className="text-2xl font-bold mb-4 text-center">Coming Soon</h3>
          <p className="text-gray-300 text-center mb-4">
            Google Calendar integration, note templates, AI chat for questions,
            and more integrations (email, Slack).
          </p>
          <p className="text-blue-400 text-center font-semibold">
            Contribute on GitHub to help build these features!
          </p>
        </div>
      </div>
    </section>
  );
}
