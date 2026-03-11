import type { BaseLayoutProps } from 'fumadocs-ui/layouts/shared';

export const gitConfig = {
  user: 'mvn',
  repo: 'claude-local-workspace',
  branch: 'main',
};

export function baseOptions(): BaseLayoutProps {
  return {
    nav: {
      title: (
        <span className="font-mono font-semibold tracking-tight text-base">
          <span className="text-fd-primary">{'{'}</span>
          hjemmesidekongen
          <span className="text-fd-primary">{'}'}</span>
          <span className="text-fd-muted-foreground font-normal">/ai</span>
        </span>
      ),
    },
    links: [
      {
        text: 'Documentation',
        url: '/docs',
        active: 'nested-url',
      },
    ],
  };
}
