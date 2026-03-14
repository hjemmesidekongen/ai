import defaultMdxComponents from 'fumadocs-ui/mdx';
import type { MDXComponents } from 'mdx/types';
import type { ComponentPropsWithoutRef } from 'react';
import { Mermaid } from '@/components/mermaid';

export function getMDXComponents(components?: MDXComponents): MDXComponents {
  return {
    ...defaultMdxComponents,
    pre: (props: ComponentPropsWithoutRef<'pre'>) => {
      const child = props.children as React.ReactElement<{
        className?: string;
        children?: string;
      }> | undefined;

      if (
        child &&
        typeof child === 'object' &&
        'props' in child &&
        child.props.className === 'language-mermaid'
      ) {
        return <Mermaid chart={String(child.props.children).trim()} />;
      }

      return <defaultMdxComponents.pre {...props} />;
    },
    ...components,
  };
}
