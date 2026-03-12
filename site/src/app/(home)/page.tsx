import type { Metadata } from 'next';
import Link from 'next/link';
import { blogSource } from '@/lib/source';

export const metadata: Metadata = {
  title: 'hjemmesidekongen/ai — Structured workflows for Claude Code',
  description:
    'Five plugins that turn ad-hoc Claude Code sessions into structured, repeatable workflows. Planning, branding, design, development, and task management. Open source.',
};

const plugins = [
  {
    name: 'kronen',
    version: '0.3.0',
    tagline: 'The Crown',
    description:
      'The foundation. Wave-based planning, brainstorm sessions that produce structured decisions, verification gates, tracing, memory governance, and session recovery.',
    stats: '41 skills · 14 commands · 12 agents',
    href: '/docs/kronen',
    icon: '♔',
  },
  {
    name: 'smedjen',
    version: '0.2.0',
    tagline: 'The Forge',
    description:
      'The execution engine. Task decomposition, parallel agent dispatch with file boundaries, a 10-point quality gate, and 60+ framework knowledge skills.',
    stats: '62 skills · 3 commands · 7 agents',
    href: '/docs/smedjen',
    icon: '⚒',
  },
  {
    name: 'herold',
    version: '0.1.0',
    tagline: 'The Herald',
    description:
      'Bridges Jira, Confluence, and Bitbucket. Ingests tickets, detects contradictions between descriptions and comments, and generates PRs with QA handover notes.',
    stats: '9 skills · 8 commands',
    href: '/docs/herold',
    icon: '📯',
  },
  {
    name: 'våbenskjold',
    version: '0.1.0',
    tagline: 'The Coat of Arms',
    description:
      'Brand strategy as code. Creates brands from scratch, audits existing brands, evolves them over time. Structured YAML guidelines that every other tool can consume.',
    stats: '4 skills · 5 commands',
    href: '/docs/vaabenskjold',
    icon: '🛡',
  },
  {
    name: 'segl',
    version: '0.1.0',
    tagline: 'The Royal Seal',
    description:
      'Visual identity from brand guidelines to production tokens. Color palettes, typography, spacing — exported to CSS, Tailwind, and DTCG JSON.',
    stats: '4 skills · 4 commands',
    href: '/docs/segl',
    icon: '🔏',
  },
];

const features = [
  {
    title: 'Verification, not vibes',
    description:
      'Every task passes a verification gate before it\'s marked done. Implementing agents never grade their own work. A separate reviewer checks against the original spec.',
  },
  {
    title: 'Parallel agents, zero conflicts',
    description:
      'File-ownership boundaries mean multiple agents work simultaneously without overwriting each other. The system assigns exclusive file access per agent.',
  },
  {
    title: 'Contradiction detection',
    description:
      'herold compares Jira ticket descriptions against their comments and flags inconsistencies before you start coding the wrong thing.',
  },
  {
    title: 'Cross-session memory',
    description:
      'State files, session handoffs, and context snapshots mean you don\'t start from zero every time. The compact gate protects context during long sessions.',
  },
  {
    title: '120+ framework skills',
    description:
      'React, Next.js, Vue, Nuxt, Expo, NestJS, Prisma, Tailwind, Playwright — patterns, anti-patterns, and real-world examples. Reference material that agents use during implementation.',
  },
  {
    title: 'Brand-to-code pipeline',
    description:
      'From brand strategy through visual identity to design tokens to Tailwind config. Every step produces structured output the next step consumes.',
  },
];

// Gradient backgrounds for blog cards (since we don't have actual images)
const blogGradients = [
  'from-fd-primary/20 to-fd-primary/5',
  'from-amber-900/30 to-amber-800/10',
  'from-orange-900/20 to-yellow-900/10',
];

export default function HomePage() {
  const recentPosts = blogSource
    .getPages()
    .sort(
      (a, b) =>
        new Date(b.data.date).getTime() - new Date(a.data.date).getTime(),
    )
    .slice(0, 3);

  return (
    <main className="flex flex-col items-center">
      {/* Hero */}
      <section className="w-full max-w-4xl px-6 pt-28 pb-20 text-center">
        <div className="inline-flex items-center gap-2 rounded-full border border-fd-border bg-fd-card px-4 py-1.5 text-xs font-medium text-fd-muted-foreground mb-8">
          <span className="inline-block h-1.5 w-1.5 rounded-full bg-fd-primary" />
          Open source — clone and try
        </div>

        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl lg:text-5xl max-w-3xl mx-auto leading-tight">
          I kept solving the same problems differently every session.
          <span className="text-fd-muted-foreground"> So I built a system.</span>
        </h1>

        <p className="mt-6 text-lg text-fd-muted-foreground max-w-2xl mx-auto leading-relaxed">
          Five Claude Code plugins that turn ad-hoc prompting into structured,
          repeatable workflows. Planning, branding, design, development, and
          task management — each handled by a plugin that knows its job.
        </p>

        <div className="mt-10 flex gap-4 justify-center flex-wrap">
          <Link
            href="/docs/install"
            className="inline-flex items-center justify-center rounded-lg bg-fd-primary px-7 py-3 text-sm font-semibold text-fd-primary-foreground shadow-sm hover:opacity-90 transition-opacity"
          >
            Get started
          </Link>
          <Link
            href="/docs"
            className="inline-flex items-center justify-center rounded-lg border border-fd-border px-7 py-3 text-sm font-medium text-fd-foreground hover:bg-fd-accent transition-colors"
          >
            Read the docs
          </Link>
        </div>
      </section>

      {/* Problem */}
      <section className="w-full bg-fd-card/50 border-y border-fd-border">
        <div className="max-w-3xl mx-auto px-6 py-20">
          <h2 className="text-2xl font-bold mb-6">
            The problem with Claude Code sessions
          </h2>
          <div className="space-y-4 text-fd-muted-foreground leading-relaxed">
            <p>
              Every session starts from scratch. You explain the same context,
              set up the same patterns, and hope you remember what worked last
              time. Plans live in your head. Quality depends on how much you
              feel like typing today.
            </p>
            <p>
              Multi-file changes? Hope your agents don&apos;t overwrite each
              other. Verification? You read the diff and squint. Session
              handoffs? Copy-paste some notes and pray.
            </p>
            <p className="text-fd-foreground font-medium">
              This isn&apos;t a tooling problem. It&apos;s a workflow problem.
              And workflows need structure.
            </p>
          </div>
        </div>
      </section>

      {/* Divider accent */}
      <div className="w-16 h-0.5 bg-fd-primary rounded-full my-0" />

      {/* Plugin cards */}
      <section className="w-full max-w-6xl px-6 py-20">
        <p className="text-xs font-mono text-fd-muted-foreground uppercase tracking-widest text-center mb-3">
          Five plugins, each owns a domain
        </p>
        <h2 className="text-2xl font-bold text-center mb-12">
          Use one, use all five, or build your own
        </h2>
        <div className="grid gap-5 grid-cols-2 lg:grid-cols-3">
          {plugins.map((plugin) => (
            <Link
              key={plugin.name}
              href={plugin.href}
              className="group relative rounded-xl border border-fd-border bg-fd-card/50 p-4 sm:p-6 hover:border-fd-primary/40 hover:shadow-md transition-all"
            >
              <div className="flex items-center gap-2 sm:gap-3 mb-2 sm:mb-3">
                <span className="inline-flex items-center justify-center h-7 w-7 sm:h-9 sm:w-9 rounded-lg bg-fd-primary/10 text-sm sm:text-lg">
                  {plugin.icon}
                </span>
                <div>
                  <h3 className="font-mono text-sm sm:text-base font-semibold group-hover:text-fd-primary transition-colors">
                    {plugin.name}
                  </h3>
                  <span className="text-xs text-fd-muted-foreground hidden sm:inline">
                    v{plugin.version}
                  </span>
                </div>
              </div>
              <p className="text-xs sm:text-sm font-medium text-fd-primary mb-1 sm:mb-2">
                {plugin.tagline}
              </p>
              <p className="text-xs sm:text-sm text-fd-muted-foreground mb-3 sm:mb-4 leading-relaxed hidden sm:block">
                {plugin.description}
              </p>
              <p className="text-[11px] sm:text-xs font-mono text-fd-muted-foreground">
                {plugin.stats}
              </p>
            </Link>
          ))}
        </div>
      </section>

      {/* How it works */}
      <section className="w-full bg-fd-card/50 border-y border-fd-border">
        <div className="max-w-4xl mx-auto px-6 py-20">
          <h2 className="text-2xl font-bold text-center mb-14">
            How it works
          </h2>
          <div className="grid gap-10 md:grid-cols-3">
            <div>
              <div className="inline-flex items-center justify-center h-8 w-8 rounded-full bg-fd-primary/10 text-fd-primary font-mono font-bold text-sm mb-4">
                1
              </div>
              <h3 className="text-sm font-semibold mb-2">Install the plugins</h3>
              <p className="text-sm text-fd-muted-foreground leading-relaxed">
                Clone the repo, point Claude Code at the plugins directory.
                Each plugin auto-registers its skills, commands, hooks, and agents.
              </p>
            </div>
            <div>
              <div className="inline-flex items-center justify-center h-8 w-8 rounded-full bg-fd-primary/10 text-fd-primary font-mono font-bold text-sm mb-4">
                2
              </div>
              <h3 className="text-sm font-semibold mb-2">Run a workflow</h3>
              <p className="text-sm text-fd-muted-foreground leading-relaxed">
                Slash commands invoke structured workflows.{' '}
                <code className="text-xs">/plan:create</code> breaks a task into waves.{' '}
                <code className="text-xs">/dev:run</code> decomposes and dispatches.{' '}
                <code className="text-xs">/brand:create</code> builds a brand from scratch.
              </p>
            </div>
            <div>
              <div className="inline-flex items-center justify-center h-8 w-8 rounded-full bg-fd-primary/10 text-fd-primary font-mono font-bold text-sm mb-4">
                3
              </div>
              <h3 className="text-sm font-semibold mb-2">Everything persists</h3>
              <p className="text-sm text-fd-muted-foreground leading-relaxed">
                Plans, decisions, brand guidelines, design tokens — all stored as
                YAML files that survive session boundaries. Next session picks up
                where you left off.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Features — 2-col on mobile, 3-col on desktop */}
      <section className="w-full max-w-5xl px-6 py-20">
        <h2 className="text-2xl font-bold text-center mb-14">
          What you actually get
        </h2>
        <div className="grid gap-6 sm:gap-10 grid-cols-2 lg:grid-cols-3">
          {features.map((feature) => (
            <div key={feature.title}>
              <h3 className="text-sm font-semibold mb-2">{feature.title}</h3>
              <p className="text-xs sm:text-sm text-fd-muted-foreground leading-relaxed">
                {feature.description}
              </p>
            </div>
          ))}
        </div>
      </section>

      {/* Blog preview */}
      {recentPosts.length > 0 && (
        <section className="w-full border-t border-fd-border bg-fd-card/50">
          <div className="max-w-5xl mx-auto px-6 py-20">
            <div className="flex items-center justify-between mb-10">
              <h2 className="text-2xl font-bold">From the blog</h2>
              <Link
                href="/blog"
                className="text-sm text-fd-primary hover:underline"
              >
                View all posts &rarr;
              </Link>
            </div>

            {/* Desktop: 3-col grid */}
            <div className="hidden sm:grid sm:grid-cols-3 gap-5">
              {recentPosts.map((post, i) => (
                <Link
                  key={post.url}
                  href={post.url}
                  className="group rounded-xl border border-fd-border bg-fd-background overflow-hidden hover:border-fd-primary/40 hover:shadow-md transition-all"
                >
                  <div className={`h-32 bg-gradient-to-br ${blogGradients[i % blogGradients.length]}`} />
                  <div className="p-5">
                    <time className="text-xs text-fd-muted-foreground">
                      {new Date(post.data.date).toLocaleDateString('en-US', {
                        month: 'short',
                        day: 'numeric',
                      })}
                    </time>
                    <h3 className="text-sm font-semibold mt-2 group-hover:text-fd-primary transition-colors line-clamp-2">
                      {post.data.title}
                    </h3>
                    {post.data.read_time && (
                      <span className="text-xs text-fd-muted-foreground mt-2 block">
                        {post.data.read_time}
                      </span>
                    )}
                  </div>
                </Link>
              ))}
            </div>

            {/* Mobile: horizontal scroll with snap */}
            <div className="sm:hidden">
              <div
                className="flex gap-4 overflow-x-auto snap-x snap-mandatory pb-4 -mx-6 px-6 scrollbar-none"
                role="region"
                aria-label="Recent blog posts"
                tabIndex={0}
              >
                {recentPosts.map((post, i) => (
                  <Link
                    key={post.url}
                    href={post.url}
                    className="group snap-start shrink-0 w-[280px] rounded-xl border border-fd-border bg-fd-background overflow-hidden hover:border-fd-primary/40 transition-all"
                  >
                    <div className={`h-28 bg-gradient-to-br ${blogGradients[i % blogGradients.length]}`} />
                    <div className="p-4">
                      <time className="text-xs text-fd-muted-foreground">
                        {new Date(post.data.date).toLocaleDateString('en-US', {
                          month: 'short',
                          day: 'numeric',
                        })}
                      </time>
                      <h3 className="text-sm font-semibold mt-1.5 group-hover:text-fd-primary transition-colors line-clamp-2">
                        {post.data.title}
                      </h3>
                    </div>
                  </Link>
                ))}
              </div>
              {/* Scroll indicator dots */}
              <div className="flex justify-center gap-2 mt-3">
                {recentPosts.map((post, i) => (
                  <span
                    key={post.url}
                    className={`h-2.5 w-2.5 rounded-full ${i === 0 ? 'bg-fd-primary' : 'bg-fd-border'}`}
                  />
                ))}
              </div>
            </div>
          </div>
        </section>
      )}

      {/* Bottom CTA */}
      <section className="w-full bg-fd-card/50 border-t border-fd-border">
        <div className="max-w-3xl mx-auto px-6 py-24 text-center">
          <h2 className="text-2xl font-bold mb-4">Try it</h2>
          <p className="text-fd-muted-foreground mb-8 max-w-lg mx-auto">
            It&apos;s open source. Clone it, install it, run{' '}
            <code className="text-xs">/plan:create</code> on something you&apos;re
            building. If it doesn&apos;t save you time in the first session,
            it&apos;s not for you.
          </p>
          <div className="flex gap-4 justify-center flex-wrap">
            <Link
              href="/docs/install"
              className="inline-flex items-center justify-center rounded-lg bg-fd-primary px-7 py-3 text-sm font-semibold text-fd-primary-foreground shadow-sm hover:opacity-90 transition-opacity"
            >
              Get started
            </Link>
            <Link
              href="https://github.com/hjemmesidekongen/ai"
              className="inline-flex items-center justify-center rounded-lg border border-fd-border px-7 py-3 text-sm font-medium hover:bg-fd-accent transition-colors"
            >
              Browse the source
            </Link>
          </div>
        </div>
      </section>
    </main>
  );
}
