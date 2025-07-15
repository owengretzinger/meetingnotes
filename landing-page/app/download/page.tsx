"use client";

import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import {
  Download,
  AlertTriangle,
  Calendar,
  DollarSign,
  Shield,
  MessageSquare,
} from "lucide-react";
import Header from "../components/header";
import { downloadAndNavigate } from "@/lib/utils";

function triggerDownload() {
  // Just trigger the download without navigation since we're already on the download page
  window.open(
    "https://github.com/owengretzinger/meetingnotes/releases/latest/download/Meetingnotes.dmg",
    "_blank"
  );
}

export default function DownloadPage() {
  return (
    <div className="min-h-screen bg-black text-white">
      <Header />
      <div className="container mx-auto px-4 py-20">
        <div className="max-w-4xl mx-auto">
          <div className="grid md:grid-cols-3 gap-8 mb-8">
            <Card className="bg-gray-900/50 border-gray-800">
              <CardContent className="p-8">
                <div className="w-16 h-16 bg-yellow-500/20 rounded-full flex items-center justify-center mb-4">
                  <svg
                    className="w-8 h-8 text-yellow-400"
                    fill="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
                  </svg>
                </div>
                <h2 className="text-2xl font-bold mb-4">Star on GitHub</h2>
                <p className="text-gray-300 mb-6">
                  Consider starring the project to show support and help others
                  discover it.
                </p>
                <Button
                  size="lg"
                  className="bg-yellow-600 hover:bg-yellow-700 w-full"
                  asChild
                >
                  <a
                    href="https://github.com/owengretzinger/meetingnotes"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    <svg
                      className="w-5 h-5 mr-2"
                      fill="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
                    </svg>
                    Star on GitHub
                  </a>
                </Button>
              </CardContent>
            </Card>

            <Card className="bg-gray-900/50 border-gray-800">
              <CardContent className="p-8">
                <div className="w-16 h-16 bg-blue-500/20 rounded-full flex items-center justify-center mb-4">
                  <Calendar className="w-8 h-8 text-blue-400" />
                </div>
                <h2 className="text-2xl font-bold mb-4">Book a Call</h2>
                <p className="text-gray-300 mb-6">
                  I would love to walk you through the setup and hear your
                  thoughts.
                </p>
                <Button
                  size="lg"
                  className="bg-blue-600 hover:bg-blue-700 w-full"
                  asChild
                >
                  <a
                    href="https://cal.com/owengretzinger"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    <Calendar className="w-5 h-5 mr-2" />
                    Schedule a Call
                  </a>
                </Button>
              </CardContent>
            </Card>

            <Card className="bg-gray-900/50 border-gray-800">
              <CardContent className="p-8">
                <div className="w-16 h-16 bg-green-500/20 rounded-full flex items-center justify-center mb-4">
                  <DollarSign className="w-8 h-8 text-green-400" />
                </div>
                <h2 className="text-2xl font-bold mb-4">Get API Key</h2>
                <p className="text-gray-300 mb-6">
                  You'll need it to transcribe and generate enhanced notes.
                  (~$0.20/hour)
                </p>
                <Button
                  size="lg"
                  className="bg-green-600 hover:bg-green-700 w-full"
                  asChild
                >
                  <a
                    href="https://platform.openai.com/api-keys"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    <DollarSign className="w-5 h-5 mr-2" />
                    Get API Key
                  </a>
                </Button>
              </CardContent>
            </Card>
          </div>

          <p className="text-center text-gray-400 text-sm mb-12">
            <a
              href="https://github.com/owengretzinger/meetingnotes/releases/latest/download/Meetingnotes.dmg"
              className="text-blue-400 hover:text-blue-300 underline transition-colors"
            >
              Download didn't start automatically?{" "}
            </a>
          </p>

          <div className="text-center">
            <h2 className="text-3xl font-bold mb-4">Questions?</h2>
            <p className="text-gray-300 mb-8">
              If you run into any issues or have questions about the setup,
              don't hesitate to reach out.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Button
                size="lg"
                className="bg-blue-600 hover:bg-blue-700"
                asChild
              >
                <a
                  href="https://cal.com/owengretzinger"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  <Calendar className="w-5 h-5 mr-2" />
                  Schedule a Call
                </a>
              </Button>
              <Button
                variant="outline"
                size="lg"
                className="border-gray-600 text-gray-300 hover:bg-gray-800 bg-transparent"
                asChild
              >
                <a href="mailto:owengretzinger@gmail.com">Contact Me</a>
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
