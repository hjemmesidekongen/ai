import { getPageImage, source } from '@/lib/source';
import { notFound } from 'next/navigation';
import { ImageResponse } from '@takumi-rs/image-response';

export const revalidate = false;

export async function GET(_req: Request, { params }: RouteContext<'/og/docs/[...slug]'>) {
  const { slug } = await params;
  const page = source.getPage(slug.slice(0, -1));
  if (!page) notFound();

  return new ImageResponse(
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
        width: '100%',
        height: '100%',
        padding: '60px 80px',
        backgroundColor: '#1c1c19',
        fontFamily: 'sans-serif',
      }}
    >
      {/* Top: brand mark */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
        <span style={{ color: '#e1943d', fontSize: '24px', fontWeight: 700, fontFamily: 'monospace' }}>
          {'{}'}
        </span>
        <span style={{ color: '#faf9f7', fontSize: '20px', fontWeight: 600, fontFamily: 'monospace' }}>
          hjemmesidekongen
        </span>
        <span style={{ color: '#716d66', fontSize: '20px', fontWeight: 400 }}>
          /ai
        </span>
      </div>

      {/* Center: title + description */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
        <h1 style={{ color: '#faf9f7', fontSize: '56px', fontWeight: 700, lineHeight: 1.15, margin: 0 }}>
          {page.data.title}
        </h1>
        {page.data.description && (
          <p style={{ color: '#b0aca4', fontSize: '24px', lineHeight: 1.4, margin: 0, maxWidth: '800px' }}>
            {page.data.description}
          </p>
        )}
      </div>

      {/* Bottom: accent bar */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
        <div style={{ width: '48px', height: '4px', backgroundColor: '#e1943d', borderRadius: '2px' }} />
        <span style={{ color: '#716d66', fontSize: '16px' }}>
          ai.hjemmesidekongen.dk
        </span>
      </div>
    </div>,
    {
      width: 1200,
      height: 630,
      format: 'webp',
    },
  );
}

export function generateStaticParams() {
  return source.getPages().map((page) => ({
    lang: page.locale,
    slug: getPageImage(page).segments,
  }));
}
