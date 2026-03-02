/**
 * Example: Common Prisma query patterns
 * Pack: prisma
 * Tags: prisma, queries, crud
 *
 * Demonstrates CRUD with select/include, transactions, and cursor-based
 * pagination — patterns adapted for Prisma v7 with adapter-based setup.
 */

import { prisma } from '@/lib/prisma'
import type { ProjectStatus } from '../generated/client'

// --- CRUD ---------------------------------------------------------------------

// Create — return only needed fields
export async function createProject(data: {
  name: string
  description?: string
  ownerId: string
}) {
  return prisma.project.create({
    data,
    select: { id: true, name: true, status: true, createdAt: true },
  })
}

// Read — include related owner
export async function getProjectWithOwner(projectId: string) {
  return prisma.project.findUniqueOrThrow({
    where: { id: projectId },
    include: {
      owner: { select: { id: true, name: true, avatarUrl: true } },
      members: {
        include: { user: { select: { id: true, name: true } } },
        orderBy: { joinedAt: 'asc' },
      },
    },
  })
}

// Update — selective field update
export async function updateProjectStatus(projectId: string, status: ProjectStatus) {
  return prisma.project.update({
    where: { id: projectId },
    data: { status },
    select: { id: true, status: true, updatedAt: true },
  })
}

// Delete with cascade handled at schema level
export async function deleteProject(projectId: string) {
  return prisma.project.delete({ where: { id: projectId } })
}

// --- Pagination (cursor-based) ------------------------------------------------
// Prefer over offset pagination for large datasets — no skipped rows on inserts

interface CursorPage<T> {
  items: T[]
  nextCursor: string | null
}

export async function getProjectsPage(
  ownerId: string,
  { cursor, limit = 20 }: { cursor?: string; limit?: number },
): Promise<CursorPage<{ id: string; name: string; createdAt: Date }>> {
  const take = limit + 1 // fetch one extra to detect next page

  const items = await prisma.project.findMany({
    where: { ownerId },
    orderBy: { createdAt: 'desc' },
    take,
    ...(cursor ? { skip: 1, cursor: { id: cursor } } : {}),
    select: { id: true, name: true, createdAt: true },
  })

  const hasNextPage = items.length > limit
  if (hasNextPage) items.pop()

  return {
    items,
    nextCursor: hasNextPage ? (items.at(-1)?.id ?? null) : null,
  }
}

// --- Transaction --------------------------------------------------------------
// Use $transaction for atomic multi-step operations

export async function transferProjectOwnership(
  projectId: string,
  newOwnerId: string,
  previousOwnerId: string,
) {
  return prisma.$transaction(async (tx) => {
    // 1. Verify new owner is already a member
    const membership = await tx.projectMember.findUnique({
      where: { projectId_userId: { projectId, userId: newOwnerId } },
    })

    if (!membership) {
      throw new Error('New owner must be an existing project member')
    }

    // 2. Update project owner
    const project = await tx.project.update({
      where: { id: projectId },
      data: { ownerId: newOwnerId },
      select: { id: true, ownerId: true },
    })

    // 3. Downgrade previous owner to editor (atomic — all or nothing)
    await tx.projectMember.update({
      where: { projectId_userId: { projectId, userId: previousOwnerId } },
      data: { role: 'editor' },
    })

    return project
  })
}
