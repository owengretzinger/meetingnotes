import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Star, GitFork, Users, Heart } from "lucide-react";

export default function Community() {
  return (
    <section id="community" className="py-20 px-4 bg-black">
      <div className="container mx-auto">
        <div className="text-center mb-8">
          <h2 className="text-4xl md:text-5xl font-bold mb-6">
            Join the Open-Source Community
          </h2>
          <p className="text-xl text-gray-300 max-w-3xl mx-auto">
            Give a star on GitHub, contribute features, or report issues.
          </p>
        </div>

        {/* <div className="grid md:grid-cols-3 gap-8 mb-12">
          <Card className="bg-gray-900/50 border-gray-800 text-center">
            <CardContent className="p-8">
              <Star className="w-12 h-12 text-yellow-400 mx-auto mb-4" />
              <h3 className="text-2xl font-bold mb-2">1.2k</h3>
              <p className="text-gray-300">GitHub Stars</p>
            </CardContent>
          </Card>

          <Card className="bg-gray-900/50 border-gray-800 text-center">
            <CardContent className="p-8">
              <GitFork className="w-12 h-12 text-blue-400 mx-auto mb-4" />
              <h3 className="text-2xl font-bold mb-2">180</h3>
              <p className="text-gray-300">Forks</p>
            </CardContent>
          </Card>

          <Card className="bg-gray-900/50 border-gray-800 text-center">
            <CardContent className="p-8">
              <Users className="w-12 h-12 text-green-400 mx-auto mb-4" />
              <h3 className="text-2xl font-bold mb-2">50+</h3>
              <p className="text-gray-300">Contributors</p>
            </CardContent>
          </Card>
        </div> */}

        <div className="bg-gradient-to-r from-purple-600/20 to-pink-600/20 rounded-xl p-8 border border-purple-600/30 text-center mb-12"> 
          <Heart className="w-12 h-12 text-pink-400 mx-auto mb-4" />
          <h3 className="text-2xl font-bold mb-4">Help Build the Future</h3>
          <p className="text-gray-300 mb-4">
            Add integrations, templates, or custom models! Every contribution
            makes Meetingnotes better for everyone.
          </p>
          {/* <blockquote className="text-lg font-medium text-gray-200 mb-4">
            "As an open-source project, Meetingnotes is transparent and
            customizable—perfect for privacy-focused users."
          </blockquote>
          <cite className="text-purple-400 font-semibold">
            – Developer & Contributor
          </cite> */}
        </div>

        <div className="flex flex-col sm:flex-row gap-4 justify-center">
          <Button
            size="lg"
            className="bg-gray-800 hover:bg-gray-700 border border-gray-600"
            asChild
          >
            <a href="https://github.com/owengretzinger/meetingnotes">
              <Star className="w-5 h-5 mr-2" />
              Star on GitHub
            </a>
          </Button>
          <Button size="lg" className="bg-blue-600 hover:bg-blue-700" asChild>
            <a href="https://github.com/owengretzinger/meetingnotes/fork">
              <GitFork className="w-5 h-5 mr-2" />
              Fork & Contribute
            </a>
          </Button>
        </div>
      </div>
    </section>
  );
}
