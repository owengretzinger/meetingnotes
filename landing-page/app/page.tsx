import Header from "./components/header"
import Hero from "./components/hero"
import Features from "./components/features"
import HowItWorks from "./components/how-it-works"
import Privacy from "./components/privacy"
import Pricing from "./components/pricing"
import Community from "./components/community"
import FinalCTA from "./components/final-cta"
import Footer from "./components/footer"

export default function Home() {
  return (
    <div className="min-h-screen bg-black text-white">
      <Header />
      <Hero />
      <Features />
      <HowItWorks />
      <Privacy />
      <Pricing />
      <Community />
      <FinalCTA />
      <Footer />
    </div>
  )
}
