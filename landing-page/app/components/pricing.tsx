import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Check, DollarSign, Key, Shield } from "lucide-react"

export default function Pricing() {
  return (
    <section className="py-20 px-4 bg-black">
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

            <CardContent className="pt-16 pb-12 px-12 text-center">
              <div className="mb-8">
                <div className="text-6xl font-bold mb-4 text-green-400">$0</div>
                <div className="text-2xl text-gray-300">Forever and always</div>
              </div>

              <div className="grid md:grid-cols-2 gap-8 mb-12">
                <div>
                  <h3 className="text-2xl font-bold mb-6 text-white">What's Included</h3>
                  <ul className="space-y-4 text-left">
                    <li className="flex items-center space-x-3">
                      <Check className="w-5 h-5 text-green-400 flex-shrink-0" />
                      <span className="text-gray-200">Unlimited meeting recordings</span>
                    </li>
                    <li className="flex items-center space-x-3">
                      <Check className="w-5 h-5 text-green-400 flex-shrink-0" />
                      <span className="text-gray-200">Real-time AI transcription</span>
                    </li>
                    <li className="flex items-center space-x-3">
                      <Check className="w-5 h-5 text-green-400 flex-shrink-0" />
                      <span className="text-gray-200">AI-enhanced meeting summaries</span>
                    </li>
                    <li className="flex items-center space-x-3">
                      <Check className="w-5 h-5 text-green-400 flex-shrink-0" />
                      <span className="text-gray-200">Complete data privacy (local storage)</span>
                    </li>
                    <li className="flex items-center space-x-3">
                      <Check className="w-5 h-5 text-green-400 flex-shrink-0" />
                      <span className="text-gray-200">Full source code access</span>
                    </li>
                    <li className="flex items-center space-x-3">
                      <Check className="w-5 h-5 text-green-400 flex-shrink-0" />
                      <span className="text-gray-200">Customizable AI prompts</span>
                    </li>
                    <li className="flex items-center space-x-3">
                      <Check className="w-5 h-5 text-green-400 flex-shrink-0" />
                      <span className="text-gray-200">Regular updates and improvements</span>
                    </li>
                  </ul>
                </div>

                <div>
                  <h3 className="text-2xl font-bold mb-6 text-white">How It Works</h3>
                  <div className="space-y-6 text-left">
                    <div className="flex items-start space-x-3">
                      <Key className="w-6 h-6 text-blue-400 flex-shrink-0 mt-1" />
                      <div>
                        <h4 className="font-semibold text-white mb-1">Bring Your Own API Keys</h4>
                        <p className="text-gray-300 text-sm">
                          Use your Deepgram and OpenAI API keys. Pay only for what you use, directly to the providers.
                        </p>
                      </div>
                    </div>

                    <div className="flex items-start space-x-3">
                      <Shield className="w-6 h-6 text-green-400 flex-shrink-0 mt-1" />
                      <div>
                        <h4 className="font-semibold text-white mb-1">Your Keys, Your Control</h4>
                        <p className="text-gray-300 text-sm">
                          API keys are stored securely on your device. We never see or store your credentials.
                        </p>
                      </div>
                    </div>

                    <div className="flex items-start space-x-3">
                      <DollarSign className="w-6 h-6 text-purple-400 flex-shrink-0 mt-1" />
                      <div>
                        <h4 className="font-semibold text-white mb-1">Typical Costs</h4>
                        <p className="text-gray-300 text-sm">
                          ~$0.28/hour using Deepgram Nova-3 and GPT-4o-mini. Pay only for what you use, no markup or
                          subscriptions.
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <div className="bg-gray-900/50 rounded-xl p-6 mb-8">
                <h4 className="text-xl font-bold mb-3 text-yellow-400">Compare to Alternatives</h4>
                <div className="grid md:grid-cols-4 gap-4 text-sm">
                  <div className="text-center">
                    <div className="font-semibold text-white">Meetingnotes</div>
                    <div className="text-green-400">$0 + API costs</div>
                    <div className="text-gray-400">~$0.28/hour</div>
                  </div>
                  <div className="text-center">
                    <div className="font-semibold text-white">Granola</div>
                    <div className="text-red-400">$18/month</div>
                    <div className="text-gray-400">Subscription required</div>
                  </div>
                  <div className="text-center">
                    <div className="font-semibold text-white">Fathom</div>
                    <div className="text-red-400">$15/month</div>
                    <div className="text-gray-400">Limited features</div>
                  </div>
                  <div className="text-center">
                    <div className="font-semibold text-white">Fireflies</div>
                    <div className="text-red-400">$10/month</div>
                    <div className="text-gray-400">Usage limits</div>
                  </div>
                </div>
              </div>

              <Button size="lg" className="bg-green-600 hover:bg-green-700 text-lg px-8 py-4">
                Download Free Now
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
