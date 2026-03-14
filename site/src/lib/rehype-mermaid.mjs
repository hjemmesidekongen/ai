/**
 * Rehype plugin that transforms ```mermaid code blocks into
 * <mermaid-diagram> elements before Shiki syntax highlighting runs.
 * The Mermaid React component picks these up client-side.
 */
import { visit } from 'unist-util-visit';

export function rehypeMermaid() {
  return (tree) => {
    visit(tree, 'element', (node, index, parent) => {
      // Match: <pre><code class="language-mermaid">...</code></pre>
      if (
        node.tagName === 'pre' &&
        node.children?.length === 1 &&
        node.children[0].tagName === 'code'
      ) {
        const code = node.children[0];
        const className = code.properties?.className;

        if (
          Array.isArray(className) &&
          className.includes('language-mermaid')
        ) {
          // Extract the raw text content
          const text = code.children
            ?.map((child) => (child.type === 'text' ? child.value : ''))
            .join('');

          // Replace the pre block with a custom element
          parent.children[index] = {
            type: 'element',
            tagName: 'mermaid-diagram',
            properties: { chart: text.trim() },
            children: [],
          };
        }
      }
    });
  };
}
