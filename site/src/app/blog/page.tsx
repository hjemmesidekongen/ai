import type { Metadata } from 'next';
import Link from 'next/link';
import { blogSource } from '@/lib/source';

export const metadata: Metadata = {
  title: 'Blog',
  description:
    'Practical guides for developers, designers, PMs, and marketers using Claude Code plugins.',
};

const audienceColors: Record<string, string> = {
  developers: 'bg-fd-primary/10 text-fd-primary',
  designers: 'bg-teal-500/10 text-teal-400',
  'seo specialists': 'bg-blue-500/10 text-blue-400',
  'project managers': 'bg-purple-500/10 text-purple-400',
  'brand/marketing': 'bg-rose-500/10 text-rose-400',
  everyone: 'bg-fd-muted text-fd-muted-foreground',
};

// Gradient backgrounds for cards
const cardGradients = [
  'from-fd-primary/20 to-fd-primary/5',
  'from-amber-900/30 to-amber-800/10',
  'from-orange-900/20 to-yellow-900/10',
  'from-stone-800/30 to-stone-700/10',
  'from-fd-primary/15 to-amber-900/10',
];

function PostMeta({ post }: { post: { data: { date: string; read_time?: string; target_audience?: string } } }) {
  return (
    <div className="flex items-center gap-3 text-xs text-fd-muted-foreground">
      <time dateTime={post.data.date}>
        {new Date(post.data.date).toLocaleDateString('en-US', {
          year: 'numeric',
          month: 'short',
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
  );
}

function AudienceBadge({ audience }: { audience: string }) {
  const colors = audienceColors[audience] || audienceColors.everyone;
  return (
    <span className={`rounded-full px-2.5 py-0.5 text-xs font-medium capitalize ${colors}`}>
      {audience}
    </span>
  );
}

export default function BlogPage() {
  const posts = blogSource
    .getPages()
    .sort(
      (a, b) =>
        new Date(b.data.date).getTime() - new Date(a.data.date).getTime(),
    );

  const [featured, ...rest] = posts;

  return (
    <main className="flex flex-col items-center">
      <div className="w-full max-w-6xl px-6 pt-20 pb-16">
        {/* Header */}
        <h1 className="text-3xl font-bold tracking-tight mb-2">Blog</h1>
        <p className="text-fd-muted-foreground mb-12">
          Workflow guides, plugin deep-dives, and lessons from building with
          Claude Code.
        </p>

        {/* Featured post — hero layout */}
        {featured && (
          <Link
            href={featured.url}
            className="group block rounded-2xl border border-fd-border bg-fd-card/50 overflow-hidden mb-10 hover:border-fd-primary/40 hover:shadow-lg transition-all"
          >
            <div className="grid md:grid-cols-2">
              <div className={`h-48 md:h-full min-h-[240px] bg-gradient-to-br ${cardGradients[0]}`} />
              <div className="p-6 sm:p-8 flex flex-col justify-center">
                <div className="flex items-center gap-3 mb-4">
                  {featured.data.target_audience && (
                    <AudienceBadge audience={featured.data.target_audience} />
                  )}
                  <PostMeta post={featured} />
                </div>
                <h2 className="text-xl sm:text-2xl font-bold group-hover:text-fd-primary transition-colors mb-3">
                  {featured.data.title}
                </h2>
                {featured.data.description && (
                  <p className="text-sm text-fd-muted-foreground leading-relaxed line-clamp-3">
                    {featured.data.description}
                  </p>
                )}
              </div>
            </div>
          </Link>
        )}

        {/* Card grid — desktop: 3 cols, mobile: compact list */}
        <div className="hidden sm:grid sm:grid-cols-2 lg:grid-cols-3 gap-5">
          {rest.map((post, i) => (
            <Link
              key={post.url}
              href={post.url}
              className="group rounded-xl border border-fd-border bg-fd-card/50 overflow-hidden hover:border-fd-primary/40 hover:shadow-md transition-all"
            >
              <div className={`h-32 bg-gradient-to-br ${cardGradients[(i + 1) % cardGradients.length]}`} />
              <div className="p-5">
                <div className="flex items-center gap-2 mb-3">
                  {post.data.target_audience && (
                    <AudienceBadge audience={post.data.target_audience} />
                  )}
                </div>
                <h3 className="text-sm font-semibold group-hover:text-fd-primary transition-colors mb-2 line-clamp-2">
                  {post.data.title}
                </h3>
                <PostMeta post={post} />
              </div>
            </Link>
          ))}
        </div>

        {/* Mobile: compact card list */}
        <div className="flex flex-col gap-4 sm:hidden">
          {rest.map((post, i) => (
            <Link
              key={post.url}
              href={post.url}
              className="group flex gap-4 rounded-xl border border-fd-border bg-fd-card/50 p-4 hover:border-fd-primary/40 transition-all"
            >
              <div className={`shrink-0 w-20 h-20 rounded-lg bg-gradient-to-br ${cardGradients[(i + 1) % cardGradients.length]}`} />
              <div className="flex flex-col justify-center min-w-0">
                <h3 className="text-sm font-semibold group-hover:text-fd-primary transition-colors line-clamp-2 mb-1">
                  {post.data.title}
                </h3>
                <div className="flex items-center gap-2 text-xs text-fd-muted-foreground">
                  <time dateTime={post.data.date}>
                    {new Date(post.data.date).toLocaleDateString('en-US', {
                      month: 'short',
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
              </div>
            </Link>
          ))}
        </div>
      </div>
    </main>
  );
}
