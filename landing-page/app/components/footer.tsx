import { Github, Twitter, Mail, Heart } from "lucide-react";

export default function Footer() {
  return (
    <footer className="bg-black border-t border-gray-800 py-12 px-4">
      <div className="container mx-auto">
        <div className="grid md:grid-cols-4 gap-8 mb-8">
          <div>
            <div className="flex items-center space-x-2 mb-4">
              <img
                src="/logo.svg"
                alt="Meetingnotes logo"
                className="w-8 h-8"
              />
              <span className="text-xl font-bold">Meetingnotes</span>
            </div>
            <p className="text-gray-400 mb-4">
              Free Open-Source AI Notetaker for macOS
            </p>
            <div className="flex space-x-4">
              <a
                href="https://github.com/owengretzinger/meetingnotes"
                className="text-gray-400 hover:text-white transition-colors"
              >
                <Github className="w-5 h-5" />
              </a>
              <a
                href="https://x.com/owengretzinger"
                className="text-gray-400 hover:text-white transition-colors"
              >
                <Twitter className="w-5 h-5" />
              </a>
              <a
                href="mailto:owengretzinger@gmail.com"
                className="text-gray-400 hover:text-white transition-colors"
              >
                <Mail className="w-5 h-5" />
              </a>
            </div>
          </div>

          <div>
            <h4 className="font-semibold mb-4">Product</h4>
            <ul className="space-y-2 text-gray-400">
              <li>
                <a
                  href="#features"
                  className="hover:text-white transition-colors"
                >
                  Features
                </a>
              </li>
              <li>
                <a
                  href="#how-it-works"
                  className="hover:text-white transition-colors"
                >
                  How it Works
                </a>
              </li>
              <li>
                <a
                  href="/download"
                  className="hover:text-white transition-colors"
                >
                  Download
                </a>
              </li>
              <li>
                <a
                  href="/changelog"
                  className="hover:text-white transition-colors"
                >
                  Changelog
                </a>
              </li>
            </ul>
          </div>

          <div>
            <h4 className="font-semibold mb-4">Community</h4>
            <ul className="space-y-2 text-gray-400">
              <li>
                <a
                  href="https://github.com/owengretzinger/meetingnotes"
                  className="hover:text-white transition-colors"
                >
                  GitHub Repo
                </a>
              </li>
              <li>
                <a
                  href="https://github.com/owengretzinger/meetingnotes/blob/main/README.md"
                  className="hover:text-white transition-colors"
                >
                  Documentation
                </a>
              </li>
              <li>
                <a
                  href="https://github.com/owengretzinger/meetingnotes/blob/main/CONTRIBUTING.md"
                  className="hover:text-white transition-colors"
                >
                  Contribute
                </a>
              </li>
              <li>
                <a
                  href="https://github.com/owengretzinger/meetingnotes/issues"
                  className="hover:text-white transition-colors"
                >
                  Report Issues
                </a>
              </li>
            </ul>
          </div>

          <div>
            <h4 className="font-semibold mb-4">Legal</h4>
            <ul className="space-y-2 text-gray-400">
              <li>
                <a
                  href="/privacy"
                  className="hover:text-white transition-colors"
                >
                  Privacy Policy
                </a>
              </li>
              <li>
                <a href="/terms" className="hover:text-white transition-colors">
                  Terms of Service
                </a>
              </li>
              <li>
                <a
                  href="https://github.com/owengretzinger/meetingnotes/blob/main/LICENSE"
                  className="hover:text-white transition-colors"
                >
                  LGPL-3.0 License
                </a>
              </li>
              <li>
                <a
                  href="/contact"
                  className="hover:text-white transition-colors"
                >
                  Contact
                </a>
              </li>
            </ul>
          </div>
        </div>

        <div className="border-t border-gray-800 pt-8 flex flex-col items-center space-y-4 md:flex-row md:justify-between md:space-y-0">
          <p className="text-gray-400 text-sm mb-0 text-center">
            Copyright © Owen Gretzinger {new Date().getFullYear()}. Licensed
            under LGPL-3.0 License. All rights reserved.
          </p>
          <p className="text-gray-400 text-sm text-center">
            Created by Owen Gretzinger with ❤️ for the community
          </p>
        </div>
      </div>
    </footer>
  );
}
