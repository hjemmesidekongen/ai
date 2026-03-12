import { blogSource } from '@/lib/source';
import { notFound } from 'next/navigation';
import { getMDXComponents } from '@/mdx-components';
import type { Metadata } from 'next';

interface Props {
  params: Promise<{ slug: string }>;
}

export default async function BlogPostPage(props: Props) {
  const params = await props.params;
  const post = blogSource.getPage([params.slug]);
  if (!post) notFound();

  const MDX = post.data.body;

  return (
    <article className="mx-auto w-full max-w-3xl px-6 pt-20 pb-24">
      <header className="mb-10">
        <div className="flex items-center gap-3 text-sm text-fd-muted-foreground mb-4">
          <time dateTime={post.data.date}>
            Last updated{' '}
            {new Date(post.data.date).toLocaleDateString('en-US', {
              year: 'numeric',
              month: 'long',
              day: 'numeric',
            })}
          </time>
          {post.data.read_time && (
            <>
              <span className="text-fd-border">·</span>
              <span>{post.data.read_time}</span>
            </>
          )}
        </div>

        <h1 className="text-3xl font-bold tracking-tight sm:text-4xl leading-tight mb-4">
          {post.data.title}
        </h1>

        {post.data.description && (
          <p className="text-lg text-fd-muted-foreground leading-relaxed">
            {post.data.description}
          </p>
        )}

        <div className="flex items-center gap-3 mt-6 pt-6 border-t border-fd-border">
          <span className="text-sm font-medium">{post.data.author}</span>
          {post.data.target_audience && (
            <>
              <span className="text-fd-border">·</span>
              <span className="text-sm text-fd-muted-foreground capitalize">
                For {post.data.target_audience}
              </span>
            </>
          )}
        </div>
      </header>

      <div className="prose prose-neutral dark:prose-invert max-w-none [&>h2]:text-xl [&>h2]:font-bold [&>h2]:mt-12 [&>h2]:mb-4 [&>p]:leading-relaxed [&>p]:text-fd-muted-foreground [&>ul]:text-fd-muted-foreground [&>ol]:text-fd-muted-foreground [&_code]:text-sm [&_code]:bg-fd-muted/50 [&_code]:px-1.5 [&_code]:py-0.5 [&_code]:rounded [&_strong]:text-fd-foreground [&>pre]:bg-fd-card [&>pre]:border [&>pre]:border-fd-border">
        <MDX components={getMDXComponents({})} />
      </div>

      {post.data.tags && post.data.tags.length > 0 && (
        <div className="flex flex-wrap gap-2 mt-12 pt-8 border-t border-fd-border">
          {post.data.tags.map((tag: string) => (
            <span
              key={tag}
              className="rounded-full bg-fd-primary/10 px-3 py-1 text-xs text-fd-primary"
            >
              {tag}
            </span>
          ))}
        </div>
      )}
    </article>
  );
}

export function generateStaticParams() {
  return blogSource.getPages().map((page) => ({
    slug: page.slugs[0],
  }));
}

export async function generateMetadata(props: Props): Promise<Metadata> {
  const params = await props.params;
  const post = blogSource.getPage([params.slug]);
  if (!post) notFound();

  return {
    title: post.data.title,
    description: post.data.description,
  };
}
