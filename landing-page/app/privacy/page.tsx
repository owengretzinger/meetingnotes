export default function PrivacyPolicy() {
  return (
    <div className="min-h-screen bg-black text-white">
      <div className="container mx-auto px-4 py-16 max-w-4xl">
        <h1 className="text-4xl font-bold mb-8">Privacy Policy</h1>
        <p className="text-gray-400 mb-8">
          <strong>Effective Date:</strong> {new Date().toLocaleDateString()}
        </p>
        
        <div className="prose prose-invert max-w-none">
          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">1. Introduction</h2>
            <p className="text-gray-300 mb-4">
              Welcome to Meetingnotes ("we," "our," or "us"). This Privacy Policy explains how we collect, use, and protect your information when you use our free, open-source AI meeting notetaker application for macOS.
            </p>
            <p className="text-gray-300 mb-4">
              Meetingnotes is developed by Owen Gretzinger, an individual developer based in Burlington, Ontario, Canada.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">2. Information We Collect</h2>
            
            <h3 className="text-xl font-semibold mb-3">2.1 Audio Data</h3>
            <p className="text-gray-300 mb-4">
              Meetingnotes captures audio from your device's microphone and system audio during meetings. This audio data is processed locally on your device and is sent to OpenAI's services for transcription and AI summary generation.
            </p>
            
            <h3 className="text-xl font-semibold mb-3">2.2 Meeting Data</h3>
            <p className="text-gray-300 mb-4">
              All meeting transcripts, AI-generated summaries, and related meeting data are stored locally on your device. We do not have access to this data, and it is never stored on our servers or any cloud service we control.
            </p>
            
            <h3 className="text-xl font-semibold mb-3">2.3 Usage Analytics</h3>
            <p className="text-gray-300 mb-4">
              We collect anonymous usage data through PostHog, which may include:
            </p>
            <ul className="text-gray-300 mb-4 list-disc list-inside">
              <li>App installations and opens</li>
              <li>Number of meetings created</li>
              <li>Device and operating system information</li>
              <li>App version information</li>
              <li>Other anonymous usage metrics</li>
            </ul>
            <p className="text-gray-300 mb-4">
              This data is completely anonymous and cannot be used to identify individual users.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">3. How We Use Your Information</h2>
            
            <h3 className="text-xl font-semibold mb-3">3.1 Audio Processing</h3>
            <p className="text-gray-300 mb-4">
              Audio data is sent to OpenAI's Speech-to-Text (STT) API for transcription. The resulting transcript is then sent to OpenAI's language models for AI summary generation. According to OpenAI's data usage policy, they may securely retain API inputs and outputs for up to 30 days to identify abuse.
            </p>
            
            <h3 className="text-xl font-semibold mb-3">3.2 Analytics</h3>
            <p className="text-gray-300 mb-4">
              Anonymous usage data is used to understand how the app is being used and to improve the product. This data helps us make informed decisions about feature development and app improvements.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">4. Data Sharing and Third Parties</h2>
            
            <h3 className="text-xl font-semibold mb-3">4.1 OpenAI</h3>
            <p className="text-gray-300 mb-4">
              Audio recordings and transcripts are sent to OpenAI for processing. OpenAI's handling of this data is governed by their privacy policy and terms of service. OpenAI may retain data for up to 30 days for abuse detection purposes.
            </p>
            <p className="text-gray-300 mb-4">
              For more information about OpenAI's data handling practices, please refer to their{" "}
              <a 
                href="https://platform.openai.com/docs/guides/your-data" 
                className="text-blue-400 hover:text-blue-300 underline"
                target="_blank"
                rel="noopener noreferrer"
              >
                Data Controls in the OpenAI Platform
              </a>{" "}
              documentation.
            </p>
            
            <h3 className="text-xl font-semibold mb-3">4.2 PostHog</h3>
            <p className="text-gray-300 mb-4">
              Anonymous usage data is sent to PostHog for analytics purposes. PostHog's handling of this data is governed by their privacy policy.
            </p>
            
            <h3 className="text-xl font-semibold mb-3">4.3 Sparkle</h3>
            <p className="text-gray-300 mb-4">
              We use Sparkle for automatic app updates. Sparkle may collect anonymous update-related data as described in their privacy policy.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">5. Data Security</h2>
            <p className="text-gray-300 mb-4">
              We implement appropriate technical and organizational security measures to protect your information. However, no method of transmission over the internet or electronic storage is 100% secure.
            </p>
            <p className="text-gray-300 mb-4">
              Since the app is open source, you can inspect the code to verify how your data is handled. The source code is available on GitHub.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">6. Your Rights</h2>
            <p className="text-gray-300 mb-4">
              Since all meeting data is stored locally on your device, you have complete control over this data. You can:
            </p>
            <ul className="text-gray-300 mb-4 list-disc list-inside">
              <li>Delete any meeting data directly from the app</li>
              <li>Uninstall the app to remove all local data</li>
              <li>Disable analytics in the app settings (if available)</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">7. Children's Privacy</h2>
            <p className="text-gray-300 mb-4">
              Our app is not intended for use by children under 13. We do not knowingly collect personal information from children under 13.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">8. International Data Transfers</h2>
            <p className="text-gray-300 mb-4">
              When you use our app, your audio data may be transferred to and processed by OpenAI, which may be located in different countries. This transfer is necessary for the app's functionality.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">9. Changes to This Privacy Policy</h2>
            <p className="text-gray-300 mb-4">
              We may update this Privacy Policy from time to time. We will notify you of any material changes by posting the new Privacy Policy on this page and updating the "Effective Date" above.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">10. Contact Information</h2>
            <p className="text-gray-300 mb-4">
              If you have any questions about this Privacy Policy, please contact us at:
            </p>
            <p className="text-gray-300 mb-4">
              Owen Gretzinger<br />
              Burlington, Ontario, Canada<br />
              Email: <a href="mailto:owengretzinger@gmail.com" className="text-blue-400 hover:text-blue-300">owengretzinger@gmail.com</a>
            </p>
          </section>
        </div>
      </div>
    </div>
  );
} 