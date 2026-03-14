import defaultMdxComponents from 'fumadocs-ui/mdx';
import type { MDXComponents } from 'mdx/types';
import { Mermaid } from '@/components/mermaid';

export function getMDXComponents(components?: MDXComponents): MDXComponents {
  return {
    ...defaultMdxComponents,
    'mermaid-diagram': (props: { chart?: string }) => {
      if (!props.chart) return null;
      return <Mermaid chart={props.chart} />;
    },
    ...components,
  };
}
