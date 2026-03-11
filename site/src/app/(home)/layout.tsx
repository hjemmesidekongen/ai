import { HomeLayout } from 'fumadocs-ui/layouts/home';
import { baseOptions } from '@/lib/layout.shared';

function Footer() {
  return (
    <footer className="border-t border-fd-border bg-fd-card/30">
      <div className="max-w-5xl mx-auto px-6 py-10 flex flex-col sm:flex-row items-center justify-between gap-4">
        <div className="flex items-center gap-2 text-sm text-fd-muted-foreground">
          <span className="font-mono font-semibold text-fd-foreground">
            <span className="text-fd-primary">{'{'}</span>
            hjemmesidekongen
            <span className="text-fd-primary">{'}'}</span>
          </span>
          <span>/ai</span>
        </div>
        <div className="flex items-center gap-6 text-sm text-fd-muted-foreground">
          <a
            href="https://hjemmesidekongen.dk"
            className="hover:text-fd-foreground transition-colors"
          >
            hjemmesidekongen.dk
          </a>
          <a
            href="https://github.com/hjemmesidekongen/ai"
            className="hover:text-fd-foreground transition-colors"
          >
            GitHub
          </a>
        </div>
      </div>
    </footer>
  );
}

export default function Layout({ children }: LayoutProps<'/'>) {
  return (
    <HomeLayout {...baseOptions()}>
      {children}
      <Footer />
    </HomeLayout>
  );
}
