/**
 * Example: Server-side data fetching patterns
 * Pack: react-nextjs
 * Tags: nextjs, data-fetching, performance
 *
 * Demonstrates parallel fetching with Promise.all to eliminate waterfalls,
 * and the preload pattern to kick off fetches before the component renders.
 */

import { cache } from 'react'
import { prisma } from '@/lib/prisma'
import { notFound } from 'next/navigation'

// --- Types --------------------------------------------------------------------

interface DashboardData {
  user: { id: string; name: string; email: string }
  projects: Array<{ id: string; name: string; status: string }>
  recentActivity: Array<{ id: string; action: string; createdAt: Date }>
  stats: { projectCount: number; completedCount: number }
}

// --- Preload pattern ----------------------------------------------------------
// Call preload() in a parent layout to start fetching before the child renders.
// React deduplicates the underlying cache() call — no double fetch.

export function preloadDashboard(userId: string) {
  void getDashboardData(userId)
}

// --- Parallel fetch -----------------------------------------------------------
// All four queries run concurrently — no waterfall.

export const getDashboardData = cache(async (userId: string): Promise<DashboardData> => {
  const [user, projects, recentActivity, stats] = await Promise.all([
    prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, name: true, email: true },
    }),
    prisma.project.findMany({
      where: { ownerId: userId },
      orderBy: { updatedAt: 'desc' },
      take: 10,
      select: { id: true, name: true, status: true },
    }),
    prisma.activityLog.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 5,
      select: { id: true, action: true, createdAt: true },
    }),
    prisma.project.aggregate({
      where: { ownerId: userId },
      _count: { id: true },
    }).then(async (all) => ({
      projectCount: all._count.id,
      completedCount: await prisma.project.count({
        where: { ownerId: userId, status: 'completed' },
      }),
    })),
  ])

  if (!user) notFound()

  return { user, projects, recentActivity, stats }
})

// --- Dependent fetch (partial dependency) ------------------------------------
// When you need one result before starting the next, use sequential awaits
// only for the dependent part — parallelize everything else.

export async function getProjectWithOwner(projectId: string) {
  const project = await prisma.project.findUnique({
    where: { id: projectId },
    select: { id: true, name: true, ownerId: true, status: true },
  })

  if (!project) notFound()

  // Now we have ownerId — fetch owner and project members in parallel
  const [owner, members] = await Promise.all([
    prisma.user.findUnique({
      where: { id: project.ownerId },
      select: { id: true, name: true, avatarUrl: true },
    }),
    prisma.projectMember.findMany({
      where: { projectId },
      include: { user: { select: { id: true, name: true } } },
    }),
  ])

  return { ...project, owner, members }
}
