/**
 * Example: Next.js App Router Server Component
 * Pack: react-nextjs
 * Tags: react, nextjs, server-component, data-fetching
 *
 * Demonstrates async data fetching at the component level, Suspense boundaries
 * for streaming, and the error.tsx pattern for error handling.
 */

import { Suspense } from 'react'
import { notFound } from 'next/navigation'
import { PostList } from '@/components/post-list'
import { UserProfile } from '@/components/user-profile'
import { Skeleton } from '@/components/ui/skeleton'
import { getUser, getPostsByUser } from '@/lib/data'

interface UserPageProps {
  params: Promise<{ userId: string }>
}

// Top-level component — awaits params (Next.js 15+)
export default async function UserPage({ params }: UserPageProps) {
  const { userId } = await params
  const user = await getUser(userId)

  if (!user) {
    notFound()
  }

  return (
    <main className="container mx-auto py-8">
      <UserProfile user={user} />

      {/* Suspense boundary — streams posts independently */}
      <Suspense fallback={<Skeleton className="h-64 w-full mt-6" />}>
        <UserPosts userId={userId} />
      </Suspense>
    </main>
  )
}

// Nested async component — streams when ready
async function UserPosts({ userId }: { userId: string }) {
  const posts = await getPostsByUser(userId)

  return <PostList posts={posts} />
}

// Next.js metadata — also async in v15+
export async function generateMetadata({ params }: UserPageProps) {
  const { userId } = await params
  const user = await getUser(userId)

  return {
    title: user ? `${user.name} — Profile` : 'User Not Found',
    description: user?.bio ?? undefined,
  }
}
