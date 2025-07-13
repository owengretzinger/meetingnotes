export default function TermsOfService() {
  return (
    <div className="min-h-screen bg-black text-white">
      <div className="container mx-auto px-4 py-16 max-w-4xl">
        <h1 className="text-4xl font-bold mb-8">Terms of Service</h1>
        <p className="text-gray-400 mb-8">
          <strong>Effective Date:</strong> {new Date().toLocaleDateString()}
        </p>
        
        <div className="prose prose-invert max-w-none">
          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">1. Acceptance of Terms</h2>
            <p className="text-gray-300 mb-4">
              By downloading, installing, or using Meetingnotes ("the App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, do not use the App.
            </p>
            <p className="text-gray-300 mb-4">
              These Terms constitute a legal agreement between you and Owen Gretzinger ("we," "us," or "our"), the developer of Meetingnotes, located in Burlington, Ontario, Canada.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">2. Description of Service</h2>
            <p className="text-gray-300 mb-4">
              Meetingnotes is a free, open-source AI meeting notetaker application for macOS that:
            </p>
            <ul className="text-gray-300 mb-4 list-disc list-inside">
              <li>Captures audio from your device's microphone and system audio</li>
              <li>Transcribes meetings using AI technology</li>
              <li>Generates enhanced AI summaries of meetings</li>
              <li>Stores all data locally on your device</li>
            </ul>
            <p className="text-gray-300 mb-4">
              The App is provided "as is" and we make no warranties about its availability, functionality, or suitability for any particular purpose.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">3. User Responsibilities</h2>
            
            <h3 className="text-xl font-semibold mb-3">3.1 Consent and Recording Laws</h3>
            <p className="text-gray-300 mb-4">
              <strong>IMPORTANT:</strong> You are solely responsible for ensuring that you have proper consent from all participants before recording any meeting or conversation. You must comply with all applicable laws regarding audio recording in your jurisdiction, including but not limited to:
            </p>
            <ul className="text-gray-300 mb-4 list-disc list-inside">
              <li>Obtaining explicit consent from all participants</li>
              <li>Complying with one-party or two-party consent laws</li>
              <li>Following workplace policies regarding meeting recordings</li>
              <li>Respecting privacy rights of all participants</li>
            </ul>
            <p className="text-gray-300 mb-4">
              We are not responsible for any legal consequences resulting from your use of the App without proper consent or in violation of applicable laws.
            </p>
            
            <h3 className="text-xl font-semibold mb-3">3.2 Appropriate Use</h3>
            <p className="text-gray-300 mb-4">
              You agree to use the App only for lawful purposes and in accordance with these Terms. You will not:
            </p>
            <ul className="text-gray-300 mb-4 list-disc list-inside">
              <li>Use the App to record conversations without proper consent</li>
              <li>Use the App for any illegal or unauthorized purpose</li>
              <li>Attempt to reverse engineer, modify, or distribute the App (except as permitted by the open source license)</li>
              <li>Use the App in a manner that could harm, disable, or impair the service</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">4. AI and Technology Limitations</h2>
            
            <h3 className="text-xl font-semibold mb-3">4.1 AI Accuracy Disclaimer</h3>
            <p className="text-gray-300 mb-4">
              The App uses artificial intelligence for transcription and summary generation. <strong>AI-generated content may contain errors, inaccuracies, or misinterpretations.</strong> You acknowledge that:
            </p>
            <ul className="text-gray-300 mb-4 list-disc list-inside">
              <li>Transcriptions may not be 100% accurate</li>
              <li>AI summaries are interpretations and may miss important details</li>
              <li>You should review and verify all AI-generated content</li>
              <li>The App should not be relied upon for critical decisions without verification</li>
            </ul>
            
            <h3 className="text-xl font-semibold mb-3">4.2 Third-Party Services</h3>
            <p className="text-gray-300 mb-4">
              The App relies on third-party services (OpenAI) for AI processing. We are not responsible for the availability, accuracy, or performance of these third-party services.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">5. Open Source License</h2>
            <p className="text-gray-300 mb-4">
              Meetingnotes is released under the LGPL-3.0 License. The source code is available on GitHub, and you may inspect, modify, and distribute the code in accordance with the terms of this license.
            </p>
            <p className="text-gray-300 mb-4">
              While the App is open source, these Terms of Service still apply to your use of the compiled application.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">6. Privacy and Data</h2>
            <p className="text-gray-300 mb-4">
              Your privacy is important to us. Please review our Privacy Policy, which explains how we collect, use, and protect your information. By using the App, you agree to the collection and use of information as described in our Privacy Policy.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">7. Limitation of Liability</h2>
            <p className="text-gray-300 mb-4">
              TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO:
            </p>
            <ul className="text-gray-300 mb-4 list-disc list-inside">
              <li>Loss of data or information</li>
              <li>Legal consequences from unauthorized recordings</li>
              <li>Damages resulting from AI inaccuracies</li>
              <li>Business interruption or loss of profits</li>
              <li>Any other damages arising from your use of the App</li>
            </ul>
            <p className="text-gray-300 mb-4">
              OUR TOTAL LIABILITY SHALL NOT EXCEED THE AMOUNT YOU PAID FOR THE APP (WHICH IS ZERO, AS THE APP IS FREE).
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">8. Disclaimer of Warranties</h2>
            <p className="text-gray-300 mb-4">
              THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT ANY WARRANTIES OF ANY KIND, INCLUDING BUT NOT LIMITED TO:
            </p>
            <ul className="text-gray-300 mb-4 list-disc list-inside">
              <li>Warranties of merchantability or fitness for a particular purpose</li>
              <li>Warranties that the App will be uninterrupted or error-free</li>
              <li>Warranties regarding the accuracy of AI-generated content</li>
              <li>Warranties that the App will meet your specific requirements</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">9. Indemnification</h2>
            <p className="text-gray-300 mb-4">
              You agree to indemnify and hold us harmless from any claims, damages, or expenses arising from:
            </p>
            <ul className="text-gray-300 mb-4 list-disc list-inside">
              <li>Your use of the App without proper consent</li>
              <li>Your violation of any applicable laws or regulations</li>
              <li>Your breach of these Terms</li>
              <li>Any unauthorized recordings made using the App</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">10. Updates and Modifications</h2>
            <p className="text-gray-300 mb-4">
              We may update the App from time to time to improve functionality, fix bugs, or add new features. The App uses Sparkle for automatic updates. You can disable automatic updates in your system settings if preferred.
            </p>
            <p className="text-gray-300 mb-4">
              We may also modify these Terms from time to time. Material changes will be posted on our website, and continued use of the App after such changes constitutes acceptance of the new Terms.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">11. Termination</h2>
            <p className="text-gray-300 mb-4">
              You may stop using the App at any time by uninstalling it from your device. These Terms will remain in effect until terminated.
            </p>
            <p className="text-gray-300 mb-4">
              We may terminate your right to use the App if you violate these Terms, though we have no obligation to monitor your use of the App.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">12. Governing Law</h2>
            <p className="text-gray-300 mb-4">
              These Terms are governed by the laws of Ontario, Canada, without regard to conflict of law principles. Any disputes arising from these Terms or your use of the App will be resolved in the courts of Ontario, Canada.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">13. Severability</h2>
            <p className="text-gray-300 mb-4">
              If any provision of these Terms is found to be unenforceable, the remaining provisions will continue to be valid and enforceable.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">14. Contact Information</h2>
            <p className="text-gray-300 mb-4">
              If you have any questions about these Terms, please contact us at:
            </p>
            <p className="text-gray-300 mb-4">
              Owen Gretzinger<br />
              Burlington, Ontario, Canada<br />
              Email: <a href="mailto:owengretzinger@gmail.com" className="text-blue-400 hover:text-blue-300">owengretzinger@gmail.com</a>
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">15. Acknowledgment</h2>
            <p className="text-gray-300 mb-4">
              By using Meetingnotes, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.
            </p>
          </section>
        </div>
      </div>
    </div>
  );
} 