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
    stats: '35 skills, 13 commands, 12 agents',
    href: '/docs/claude-core',
  },
  {
    name: 'dev-engine',
    version: '0.2.0',
    tagline: 'Development Execution',
    description:
      'Multi-agent pipeline that decomposes tasks, dispatches specialist agents in parallel, and enforces a 10-point quality gate before anything ships.',
    stats: '53 skills, 6 agents, 2 commands',
    href: '/docs/dev-engine',
  },
  {
    name: 'taskflow',
    version: '0.1.0',
    tagline: 'Task Management',
    description:
      'Bridges Jira, Confluence, and Bitbucket with your CLI. Contradiction detection, structured PR descriptions, and QA handover generation.',
    stats: '9 skills, 8 commands',
    href: '/docs/taskflow',
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
    title: '50+ framework skills',
    description:
      'React, Next.js, Vue, Nuxt, NestJS, Prisma, Expo, TypeScript, Tailwind, and more — verified, version-specific knowledge baked into each agent.',
  },
];

export default function HomePage() {
  return (
    <main className="flex flex-col items-center">
      {/* Hero */}
      <section className="w-full max-w-5xl px-6 pt-24 pb-16 text-center">
        <h1 className="font-mono text-4xl font-semibold tracking-tight sm:text-5xl">
          hjemmesidekongen
          <span className="text-fd-muted-foreground font-normal">/ai</span>
        </h1>
        <p className="mt-5 text-base text-fd-muted-foreground max-w-xl mx-auto leading-relaxed">
          One developer&apos;s operating system for AI-assisted code. Not
          autocomplete — structured development partners. Wave planning,
          specialist agent dispatch, verification gates, and cross-session
          memory.
        </p>
        <p className="mt-3 text-sm text-fd-muted-foreground max-w-xl mx-auto">
          Open-source methodology. Three plugins for Claude Code.
        </p>
        <div className="mt-8 flex gap-4 justify-center">
          <Link
            href="/docs"
            className="inline-flex items-center justify-center rounded-lg bg-fd-primary px-6 py-3 text-sm font-medium text-fd-primary-foreground hover:bg-fd-primary/90 transition-colors"
          >
            Read the docs
          </Link>
          <Link
            href="/docs/architecture"
            className="inline-flex items-center justify-center rounded-lg border border-fd-border px-6 py-3 text-sm font-medium hover:bg-fd-accent transition-colors"
          >
            Architecture
          </Link>
        </div>
      </section>

      {/* Plugin cards */}
      <section className="w-full max-w-5xl px-6 pb-16">
        <p className="text-xs font-mono text-fd-muted-foreground uppercase tracking-widest text-center mb-8">
          The plugins
        </p>
        <div className="grid gap-6 md:grid-cols-3">
          {plugins.map((plugin) => (
            <Link
              key={plugin.name}
              href={plugin.href}
              className="group rounded-xl border border-fd-border p-6 hover:border-fd-primary/50 hover:bg-fd-accent/50 transition-all"
            >
              <div className="flex items-baseline gap-2 mb-1">
                <h2 className="font-mono text-lg font-semibold group-hover:text-fd-primary transition-colors">
                  {plugin.name}
                </h2>
                <span className="text-xs text-fd-muted-foreground">
                  v{plugin.version}
                </span>
              </div>
              <p className="text-sm font-medium text-fd-primary mb-3">
                {plugin.tagline}
              </p>
              <p className="text-sm text-fd-muted-foreground mb-4">
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
      <section className="w-full max-w-5xl px-6 pb-24">
        <p className="text-xs font-mono text-fd-muted-foreground uppercase tracking-widest text-center mb-12">
          How it works differently
        </p>
        <div className="grid gap-8 md:grid-cols-2 lg:grid-cols-3">
          {features.map((feature) => (
            <div key={feature.title}>
              <h3 className="text-sm font-semibold mb-2">{feature.title}</h3>
              <p className="text-sm text-fd-muted-foreground">
                {feature.description}
              </p>
            </div>
          ))}
        </div>
      </section>
    </main>
  );
}
