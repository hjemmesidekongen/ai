import type { Metadata } from 'next';
import Link from 'next/link';

export const metadata: Metadata = {
  title: 'hjemmesidekongen/ai',
  description:
    'One developer\'s operating system for AI-assisted code. Wave planning, specialist agent dispatch, verification gates, and cross-session memory.',
};

const plugins = [
  {
    name: 'claude-core',
    version: '0.3.0',
    tagline: 'The Foundation',
    description:
      'Planning engine, brainstorm sessions, verification gates, cross-session memory, error investigation, learning pipelines, and workplace integrations.',
    stats: '41 skills · 14 commands · 12 agents',
    href: '/docs/claude-core',
    icon: '{}',
  },
  {
    name: 'dev-engine',
    version: '0.2.0',
    tagline: 'Development Execution',
    description:
      'Multi-agent pipeline that decomposes tasks, dispatches specialist agents in parallel, and enforces a 10-point quality gate before anything ships.',
    stats: '62 skills · 6 agents · 2 commands',
    href: '/docs/dev-engine',
    icon: '>_',
  },
  {
    name: 'taskflow',
    version: '0.1.0',
    tagline: 'Task Management',
    description:
      'Bridges Jira, Confluence, and Bitbucket with your CLI. Contradiction detection, structured PR descriptions, and QA handover generation.',
    stats: '9 skills · 8 commands',
    href: '/docs/taskflow',
    icon: '[]',
  },
];

const features = [
  {
    title: 'Verification, not vibes',
    description:
      'Every task goes through a verification gate with proof. The system runs tests, checks the build, reads the output — and only then marks it done.',
  },
  {
    title: 'Parallel agents, zero conflicts',
    description:
      'File ownership isolation ensures no two agents write to the same file. Interface contracts are defined at boundaries before implementation starts.',
  },
  {
    title: 'Contradiction detection',
    description:
      'taskflow reads every Jira comment and flags where later discussions contradict the original spec. You find out before coding, not after.',
  },
  {
    title: 'Cross-session memory',
    description:
      'State files, handoff documents, and snapshots survive session boundaries. Pick up exactly where you left off — context intact.',
  },
  {
    title: 'Learning pipeline',
    description:
      'claude-core observes patterns in how you work, extracts recurring behaviors as instincts, and promotes high-confidence patterns into rules or skills.',
  },
  {
    title: '100+ framework skills',
    description:
      'React, Next.js, Vue, Nuxt, NestJS, Prisma, Expo, TypeScript, Tailwind, and more — verified, version-specific knowledge baked into each agent.',
  },
];

export default function HomePage() {
  return (
    <main className="flex flex-col items-center">
      {/* Hero */}
      <section className="w-full max-w-4xl px-6 pt-28 pb-20 text-center">
        <div className="inline-flex items-center gap-2 rounded-full border border-fd-border bg-fd-card px-4 py-1.5 text-xs font-medium text-fd-muted-foreground mb-8">
          <span className="inline-block h-1.5 w-1.5 rounded-full bg-fd-primary" />
          Open-source Claude Code plugins
        </div>

        <h1 className="text-4xl font-bold tracking-tight sm:text-5xl lg:text-6xl">
          <span className="font-mono">hjemmesidekongen</span>
          <span className="text-fd-muted-foreground font-light">/ai</span>
        </h1>

        <p className="mt-6 text-lg text-fd-muted-foreground max-w-2xl mx-auto leading-relaxed">
          One developer&apos;s operating system for AI-assisted code. Not
          autocomplete — structured development partners that plan, build,
          verify, and learn.
        </p>

        <div className="mt-10 flex gap-4 justify-center flex-wrap">
          <Link
            href="/docs"
            className="inline-flex items-center justify-center rounded-lg bg-fd-primary px-7 py-3 text-sm font-semibold text-fd-primary-foreground shadow-sm hover:opacity-90 transition-opacity"
          >
            Read the docs
          </Link>
          <Link
            href="/docs/install"
            className="inline-flex items-center justify-center rounded-lg border border-fd-border px-7 py-3 text-sm font-medium text-fd-foreground hover:bg-fd-accent transition-colors"
          >
            Get started
          </Link>
        </div>
      </section>

      {/* Divider accent */}
      <div className="w-16 h-0.5 bg-fd-primary rounded-full" />

      {/* Plugin cards */}
      <section className="w-full max-w-5xl px-6 py-20">
        <p className="text-xs font-mono text-fd-muted-foreground uppercase tracking-widest text-center mb-10">
          Three plugins, one workflow
        </p>
        <div className="grid gap-6 md:grid-cols-3">
          {plugins.map((plugin) => (
            <Link
              key={plugin.name}
              href={plugin.href}
              className="group relative rounded-xl border border-fd-border bg-fd-card/50 p-6 hover:border-fd-primary/40 hover:shadow-md transition-all"
            >
              <div className="flex items-center gap-3 mb-3">
                <span className="inline-flex items-center justify-center h-9 w-9 rounded-lg bg-fd-primary/10 font-mono text-sm font-bold text-fd-primary">
                  {plugin.icon}
                </span>
                <div>
                  <h2 className="font-mono text-base font-semibold group-hover:text-fd-primary transition-colors">
                    {plugin.name}
                  </h2>
                  <span className="text-xs text-fd-muted-foreground">
                    v{plugin.version}
                  </span>
                </div>
              </div>
              <p className="text-sm font-medium text-fd-primary mb-2">
                {plugin.tagline}
              </p>
              <p className="text-sm text-fd-muted-foreground mb-4 leading-relaxed">
                {plugin.description}
              </p>
              <p className="text-xs font-mono text-fd-muted-foreground">
                {plugin.stats}
              </p>
            </Link>
          ))}
        </div>
      </section>

      {/* Features */}
      <section className="w-full bg-fd-card/50 border-y border-fd-border">
        <div className="max-w-5xl mx-auto px-6 py-20">
          <p className="text-xs font-mono text-fd-muted-foreground uppercase tracking-widest text-center mb-4">
            How it works differently
          </p>
          <h2 className="text-2xl font-bold text-center mb-14">
            Built for verification, not hope
          </h2>
          <div className="grid gap-10 md:grid-cols-2 lg:grid-cols-3">
            {features.map((feature) => (
              <div key={feature.title}>
                <h3 className="text-sm font-semibold mb-2">{feature.title}</h3>
                <p className="text-sm text-fd-muted-foreground leading-relaxed">
                  {feature.description}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Bottom CTA */}
      <section className="w-full max-w-3xl px-6 py-24 text-center">
        <h2 className="text-2xl font-bold mb-4">
          Ready to structure your AI workflow?
        </h2>
        <p className="text-fd-muted-foreground mb-8 max-w-lg mx-auto">
          Install the plugins, read the architecture docs, or browse
          the full skill reference. Everything is open source.
        </p>
        <div className="flex gap-4 justify-center flex-wrap">
          <Link
            href="/docs/install"
            className="inline-flex items-center justify-center rounded-lg bg-fd-primary px-7 py-3 text-sm font-semibold text-fd-primary-foreground shadow-sm hover:opacity-90 transition-opacity"
          >
            Install guide
          </Link>
          <Link
            href="/docs/architecture"
            className="inline-flex items-center justify-center rounded-lg border border-fd-border px-7 py-3 text-sm font-medium hover:bg-fd-accent transition-colors"
          >
            Architecture overview
          </Link>
        </div>
      </section>
    </main>
  );
}
