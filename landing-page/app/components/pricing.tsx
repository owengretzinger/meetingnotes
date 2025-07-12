import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Check, DollarSign, Key, Shield } from "lucide-react"

export default function Pricing() {
  return (
    <section id="pricing" className="py-20 px-4 bg-black">
      <div className="container mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-bold mb-6">Pricing That Makes Sense</h2>
          <p className="text-xl text-gray-300 max-w-3xl mx-auto">
            No subscriptions, no hidden fees, no premium tiers. Just bring your own API keys and enjoy unlimited
            AI-powered meeting notes.
          </p>
        </div>

        <div className="max-w-4xl mx-auto">
          <Card className="bg-gradient-to-r from-green-600/20 to-blue-600/20 border-2 border-green-500/50 relative overflow-hidden">
            <div className="absolute top-0 left-0 right-0 bg-green-500 text-black text-center py-2 font-bold">
              ✨ COMPLETELY FREE FOREVER
            </div>
            <CardContent className="p-8 mt-8">
              <div className="text-center mb-8">
                <div className="flex items-center justify-center mb-4">
                  <DollarSign className="w-16 h-16 text-green-400" />
                  <span className="text-6xl font-bold text-green-400">0</span>
                </div>
                <h3 className="text-3xl font-bold mb-2">Free Forever</h3>
                <p className="text-gray-300 text-lg">No costs, no subscriptions, no limits</p>
              </div>

              <div className="grid md:grid-cols-2 gap-8 mb-8">
                <div>
                  <h4 className="text-xl font-bold mb-4 flex items-center">
                    <Shield className="w-5 h-5 text-blue-400 mr-2" />
                    Core Features
                  </h4>
                  <ul className="space-y-3">
                    <li className="flex items-start space-x-3">
                      <Check className="w-5 h-5 text-green-400 mt-0.5 flex-shrink-0" />
                      <span className="text-gray-300">Real-time transcription</span>
                    </li>
                    <li className="flex items-start space-x-3">
                      <Check className="w-5 h-5 text-green-400 mt-0.5 flex-shrink-0" />
                      <span className="text-gray-300">AI-enhanced notes</span>
                    </li>
                    <li className="flex items-start space-x-3">
                      <Check className="w-5 h-5 text-green-400 mt-0.5 flex-shrink-0" />
                      <span className="text-gray-300">Local storage & privacy</span>
                    </li>
                    <li className="flex items-start space-x-3">
                      <Check className="w-5 h-5 text-green-400 mt-0.5 flex-shrink-0" />
                      <span className="text-gray-300">Unlimited meetings</span>
                    </li>
                    <li className="flex items-start space-x-3">
                      <Check className="w-5 h-5 text-green-400 mt-0.5 flex-shrink-0" />
                      <span className="text-gray-300">Search & export</span>
                    </li>
                  </ul>
                </div>

                <div>
                  <h4 className="text-xl font-bold mb-4 flex items-center">
                    <Key className="w-5 h-5 text-yellow-400 mr-2" />
                    Your API Keys
                  </h4>
                  <ul className="space-y-3">
                    <li className="flex items-start space-x-3">
                      <Check className="w-5 h-5 text-green-400 mt-0.5 flex-shrink-0" />
                      <span className="text-gray-300">Bring your own OpenAI key</span>
                    </li>
                    <li className="flex items-start space-x-3">
                      <Check className="w-5 h-5 text-green-400 mt-0.5 flex-shrink-0" />
                      <span className="text-gray-300">~$0.20/hour usage cost</span>
                    </li>
                    <li className="flex items-start space-x-3">
                      <Check className="w-5 h-5 text-green-400 mt-0.5 flex-shrink-0" />
                      <span className="text-gray-300">Full control over your data</span>
                    </li>
                    <li className="flex items-start space-x-3">
                      <Check className="w-5 h-5 text-green-400 mt-0.5 flex-shrink-0" />
                      <span className="text-gray-300">No middleman or markup</span>
                    </li>
                    <li className="flex items-start space-x-3">
                      <Check className="w-5 h-5 text-green-400 mt-0.5 flex-shrink-0" />
                      <span className="text-gray-300">Stored securely on-device</span>
                    </li>
                  </ul>
                </div>
              </div>

              <div className="bg-gray-900/50 rounded-lg p-6 mb-8">
                <h4 className="text-lg font-bold mb-3 text-center">💰 Cost Breakdown</h4>
                <div className="grid grid-cols-2 gap-4 text-center">
                  <div>
                    <div className="text-2xl font-bold text-green-400">$0</div>
                    <div className="text-sm text-gray-400">App Cost</div>
                  </div>
                  <div>
                    <div className="text-2xl font-bold text-blue-400">~$0.20</div>
                    <div className="text-sm text-gray-400">Per Hour (OpenAI)</div>
                  </div>
                </div>
                <div className="mt-4 text-center text-sm text-gray-400">
                  <strong>Example:</strong> 10 hours of meetings = ~$2.00 total
                </div>
              </div>

              <Button size="lg" className="bg-green-600 hover:bg-green-700 text-lg px-8 py-4" asChild>
                <a href="/download">
                  Download Free Now
                </a>
              </Button>

              <p className="text-sm text-gray-400 mt-4">
                No credit card required • No account needed • No data collection
              </p>
            </CardContent>
          </Card>
        </div>
      </div>
    </section>
  )
}
