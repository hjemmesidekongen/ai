import type { Metadata } from 'next';
import Link from 'next/link';
import { blogSource } from '@/lib/source';

export const metadata: Metadata = {
  title: 'Blog',
  description:
    'Practical guides for developers, designers, PMs, and marketers using Claude Code plugins.',
};

export default function BlogPage() {
  const posts = blogSource
    .getPages()
    .sort(
      (a, b) =>
        new Date(b.data.date).getTime() - new Date(a.data.date).getTime(),
    );

  return (
    <main className="flex flex-col items-center">
      <div className="w-full max-w-3xl px-6 pt-20 pb-16">
        <h1 className="text-3xl font-bold tracking-tight mb-2">Blog</h1>
        <p className="text-fd-muted-foreground mb-12">
          Workflow guides, plugin deep-dives, and lessons from building with
          Claude Code.
        </p>

        <div className="flex flex-col gap-8">
          {posts.map((post) => (
            <Link
              key={post.url}
              href={post.url}
              className="group block rounded-xl border border-fd-border bg-fd-card/50 p-6 hover:border-fd-primary/40 hover:shadow-md transition-all"
            >
              <div className="flex items-center gap-3 text-xs text-fd-muted-foreground mb-3">
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
                {post.data.target_audience && (
                  <>
                    <span className="text-fd-border">·</span>
                    <span className="capitalize">
                      {post.data.target_audience}
                    </span>
                  </>
                )}
              </div>

              <h2 className="text-lg font-semibold group-hover:text-fd-primary transition-colors mb-2">
                {post.data.title}
              </h2>

              {post.data.description && (
                <p className="text-sm text-fd-muted-foreground leading-relaxed">
                  {post.data.description}
                </p>
              )}

              {post.data.tags && post.data.tags.length > 0 && (
                <div className="flex flex-wrap gap-1.5 mt-4">
                  {post.data.tags.map((tag: string) => (
                    <span
                      key={tag}
                      className="rounded-full bg-fd-primary/10 px-2.5 py-0.5 text-xs text-fd-primary"
                    >
                      {tag}
                    </span>
                  ))}
                </div>
              )}
            </Link>
          ))}
        </div>
      </div>
    </main>
  );
}
