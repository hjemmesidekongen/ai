import Link from 'next/link';

export function Footer() {
  return (
    <footer className="w-full bg-fd-background px-4 py-6 sm:px-6 sm:py-8">
      <div className="mx-auto max-w-6xl rounded-2xl bg-fd-card/50 border border-fd-border px-6 py-10 sm:px-10">
        <div className="flex flex-col gap-8 sm:flex-row sm:items-start sm:justify-between">
          {/* Brand */}
          <div className="flex flex-col gap-3">
            <span className="font-mono font-semibold text-fd-foreground">
              <span className="text-fd-primary">{'{'}</span>
              hjemmesidekongen
              <span className="text-fd-primary">{'}'}</span>
              <span className="text-fd-muted-foreground font-normal">/ai</span>
            </span>
            <p className="text-sm text-fd-muted-foreground max-w-xs">
              Five Claude Code plugins for structured, repeatable workflows.
            </p>
          </div>

          {/* Link columns */}
          <div className="flex gap-16">
            <div className="flex flex-col gap-2">
              <span className="text-xs font-semibold uppercase tracking-wider text-fd-muted-foreground mb-1">
                Product
              </span>
              <Link href="/docs" className="text-sm text-fd-muted-foreground hover:text-fd-foreground transition-colors">
                Documentation
              </Link>
              <Link href="/blog" className="text-sm text-fd-muted-foreground hover:text-fd-foreground transition-colors">
                Blog
              </Link>
              <Link href="/docs/install" className="text-sm text-fd-muted-foreground hover:text-fd-foreground transition-colors">
                Get started
              </Link>
            </div>
            <div className="flex flex-col gap-2">
              <span className="text-xs font-semibold uppercase tracking-wider text-fd-muted-foreground mb-1">
                Community
              </span>
              <a href="https://github.com/hjemmesidekongen/ai" className="text-sm text-fd-muted-foreground hover:text-fd-foreground transition-colors">
                GitHub
              </a>
              <a href="https://hjemmesidekongen.dk" className="text-sm text-fd-muted-foreground hover:text-fd-foreground transition-colors">
                hjemmesidekongen.dk
              </a>
            </div>
          </div>
        </div>

        {/* Bottom bar */}
        <div className="mt-8 pt-6 border-t border-fd-border flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <span className="text-xs text-fd-muted-foreground">
            &copy; {new Date().getFullYear()} hjemmesidekongen. Open source.
          </span>
        </div>
      </div>
    </footer>
  );
}
