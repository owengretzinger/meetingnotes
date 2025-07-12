import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Download, AlertTriangle, Calendar, DollarSign, Shield, MessageSquare } from "lucide-react"

export default function DownloadPage() {
  return (
    <div className="min-h-screen bg-black text-white">
      <div className="container mx-auto px-4 py-20">
        <div className="max-w-4xl mx-auto">
          <div className="text-center mb-16">
            <h1 className="text-4xl md:text-6xl font-bold mb-6 bg-gradient-to-r from-white to-gray-300 bg-clip-text text-transparent">
              Download Meetingnotes
            </h1>
            <p className="text-xl text-gray-300 max-w-3xl mx-auto">
              You can download it right now, but there are some important instructions.
            </p>
          </div>

          <div className="grid md:grid-cols-2 gap-8 mb-12">
            <Card className="bg-gray-900/50 border-gray-800">
              <CardContent className="p-8">
                <div className="flex items-center mb-4">
                  <MessageSquare className="w-8 h-8 text-blue-400 mr-3" />
                  <h2 className="text-2xl font-bold">Let's Talk First</h2>
                </div>
                <p className="text-gray-300 mb-6">
                  Right now I'm trying to gauge interest in Meetingnotes, so I would love to jump on a call to walk you 
                  through the set up and hear your thoughts on it.
                </p>
                <Button size="lg" className="bg-blue-600 hover:bg-blue-700 w-full" asChild>
                  <a href="https://cal.com/owengretzinger" target="_blank" rel="noopener noreferrer">
                    <Calendar className="w-5 h-5 mr-2" />
                    Schedule a Call
                  </a>
                </Button>
              </CardContent>
            </Card>

            <Card className="bg-gray-900/50 border-gray-800">
              <CardContent className="p-8">
                <div className="flex items-center mb-4">
                  <Download className="w-8 h-8 text-green-400 mr-3" />
                  <h2 className="text-2xl font-bold">Download Now</h2>
                </div>
                <p className="text-gray-300 mb-6">
                  Ready to try it out? Download the latest version of Meetingnotes for macOS.
                </p>
                <Button size="lg" className="bg-green-600 hover:bg-green-700 w-full" asChild>
                  <a href="/releases/Notetaker-1.0.dmg" download>
                    <Download className="w-5 h-5 mr-2" />
                    Download v1.0
                  </a>
                </Button>
              </CardContent>
            </Card>
          </div>

          <Card className="bg-red-900/20 border-red-800/50 mb-12">
            <CardContent className="p-8">
              <div className="flex items-start mb-4">
                <AlertTriangle className="w-8 h-8 text-red-400 mr-3 mt-1 flex-shrink-0" />
                <div>
                  <h2 className="text-2xl font-bold text-red-400 mb-2">Important Security Notice</h2>
                  <p className="text-gray-300 mb-4">
                    I haven't paid the Apple developer fee, which means that when you download the app you might have 
                    trouble opening it due to macOS flagging it for security issues.
                  </p>
                  <div className="bg-gray-900/50 rounded-lg p-4">
                    <h3 className="font-bold text-white mb-2">To open the app:</h3>
                    <ol className="text-gray-300 space-y-2 list-decimal list-inside">
                      <li>Right-click the app and select "Open"</li>
                      <li>Click through the security dialogue</li>
                      <li>Go to System Preferences → Privacy & Security</li>
                      <li>Scroll to the bottom and click "Open Anyway"</li>
                    </ol>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          <div className="grid md:grid-cols-2 gap-8 mb-12">
            <Card className="bg-gray-900/50 border-gray-800">
              <CardContent className="p-8">
                <div className="flex items-center mb-4">
                  <DollarSign className="w-8 h-8 text-yellow-400 mr-3" />
                  <h2 className="text-2xl font-bold">API Key Required</h2>
                </div>
                <p className="text-gray-300 mb-4">
                  You will need to grab an OpenAI API key to use the transcription and AI features.
                </p>
                <p className="text-sm text-gray-400 mb-6">
                  <strong>Expected cost:</strong> About $0.20/hour of meeting time
                </p>
                <Button variant="outline" size="lg" className="border-gray-600 text-gray-300 hover:bg-gray-800 w-full bg-transparent" asChild>
                  <a href="https://platform.openai.com/api-keys" target="_blank" rel="noopener noreferrer">
                    Get OpenAI API Key
                  </a>
                </Button>
              </CardContent>
            </Card>

            <Card className="bg-gray-900/50 border-gray-800">
              <CardContent className="p-8">
                <div className="flex items-center mb-4">
                  <Shield className="w-8 h-8 text-purple-400 mr-3" />
                  <h2 className="text-2xl font-bold">Privacy First</h2>
                </div>
                <p className="text-gray-300 mb-4">
                  Your API key and all meeting data stay on your device. Nothing is sent to our servers.
                </p>
                <ul className="text-sm text-gray-400 space-y-2">
                  <li>• API keys stored securely on-device</li>
                  <li>• Meeting recordings never leave your Mac</li>
                  <li>• No data collection or tracking</li>
                  <li>• Open source and transparent</li>
                </ul>
              </CardContent>
            </Card>
          </div>

          <div className="text-center">
            <h2 className="text-3xl font-bold mb-4">Questions?</h2>
            <p className="text-gray-300 mb-8">
              If you run into any issues or have questions about the setup, don't hesitate to reach out.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Button size="lg" className="bg-blue-600 hover:bg-blue-700" asChild>
                <a href="https://cal.com/owengretzinger" target="_blank" rel="noopener noreferrer">
                  <Calendar className="w-5 h-5 mr-2" />
                  Schedule a Call
                </a>
              </Button>
              <Button variant="outline" size="lg" className="border-gray-600 text-gray-300 hover:bg-gray-800 bg-transparent" asChild>
                <a href="mailto:owengretzinger@gmail.com">
                  Contact Me
                </a>
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}