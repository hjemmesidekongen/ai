import type { Metadata } from 'next';
import { RootProvider } from 'fumadocs-ui/provider/next';
import './global.css';
import { Lato, JetBrains_Mono } from 'next/font/google';

const lato = Lato({
  subsets: ['latin'],
  weight: ['300', '400', '700', '900'],
  variable: '--font-lato',
});

const jetbrainsMono = JetBrains_Mono({
  subsets: ['latin'],
  variable: '--font-mono',
});

export const metadata: Metadata = {
  title: {
    default: 'hjemmesidekongen/ai',
    template: '%s — hjemmesidekongen/ai',
  },
  description:
    'One developer\'s operating system for AI-assisted code. Wave planning, specialist agent dispatch, verification gates, and cross-session memory — built as Claude Code plugins.',
  metadataBase: new URL('https://ai.hjemmesidekongen.dk'),
};

export default function Layout({ children }: { children: React.ReactNode }) {
  return (
    <html
      lang="en"
      className={`${lato.variable} ${jetbrainsMono.variable} ${lato.className}`}
      suppressHydrationWarning
    >
      <body className="flex flex-col min-h-screen">
        <RootProvider>{children}</RootProvider>
      </body>
    </html>
  );
}
