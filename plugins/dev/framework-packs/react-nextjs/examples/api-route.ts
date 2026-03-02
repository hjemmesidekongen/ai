/**
 * Example: Next.js Route Handler
 * Pack: react-nextjs
 * Tags: nextjs, api, validation
 *
 * Demonstrates type-safe request/response, Zod input validation,
 * structured error handling, and the standard API response envelope.
 */

import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { requireAuth } from '@/lib/auth'

// --- Request / Response types -------------------------------------------------

const CreateProjectSchema = z.object({
  name: z.string().min(1).max(100),
  description: z.string().max(500).optional(),
  status: z.enum(['active', 'archived']).default('active'),
})

type CreateProjectInput = z.infer<typeof CreateProjectSchema>

// Standard API response envelope: { success, data?, error?, meta? }
type ApiResponse<T> =
  | { success: true; data: T }
  | { success: false; error: string; details?: unknown }

// --- Route handlers -----------------------------------------------------------

export async function GET(request: NextRequest) {
  const session = await requireAuth(request)
  if (!session) {
    return NextResponse.json<ApiResponse<never>>(
      { success: false, error: 'Unauthorized' },
      { status: 401 },
    )
  }

  const { searchParams } = new URL(request.url)
  const page = Math.max(1, Number(searchParams.get('page') ?? 1))
  const limit = Math.min(50, Math.max(1, Number(searchParams.get('limit') ?? 20)))

  const [projects, total] = await Promise.all([
    prisma.project.findMany({
      where: { ownerId: session.userId },
      orderBy: { createdAt: 'desc' },
      take: limit,
      skip: (page - 1) * limit,
      select: { id: true, name: true, status: true, createdAt: true },
    }),
    prisma.project.count({ where: { ownerId: session.userId } }),
  ])

  return NextResponse.json({
    success: true,
    data: projects,
    meta: { total, page, limit },
  })
}

export async function POST(request: NextRequest) {
  const session = await requireAuth(request)
  if (!session) {
    return NextResponse.json<ApiResponse<never>>(
      { success: false, error: 'Unauthorized' },
      { status: 401 },
    )
  }

  let body: unknown
  try {
    body = await request.json()
  } catch {
    return NextResponse.json<ApiResponse<never>>(
      { success: false, error: 'Invalid JSON body' },
      { status: 400 },
    )
  }

  const parsed = CreateProjectSchema.safeParse(body)
  if (!parsed.success) {
    return NextResponse.json<ApiResponse<never>>(
      { success: false, error: 'Validation failed', details: parsed.error.flatten() },
      { status: 422 },
    )
  }

  const input: CreateProjectInput = parsed.data

  const project = await prisma.project.create({
    data: { ...input, ownerId: session.userId },
    select: { id: true, name: true, status: true, createdAt: true },
  })

  return NextResponse.json<ApiResponse<typeof project>>(
    { success: true, data: project },
    { status: 201 },
  )
}
