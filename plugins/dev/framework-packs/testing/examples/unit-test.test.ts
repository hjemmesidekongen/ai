/**
 * Example: Vitest unit test
 * Pack: testing
 * Tags: testing, unit, vitest
 *
 * Demonstrates the AAA pattern (Arrange/Act/Assert), vi.fn() for mocking
 * dependencies, and descriptive test names that read as specifications.
 */

import { describe, it, expect, vi, beforeEach } from 'vitest'
import { ProjectService } from '@/services/project-service'
import type { ProjectRepository } from '@/repositories/project-repository'

// --- System under test -------------------------------------------------------

// Mock the repository interface — tests own behavior, not the DB
function makeRepository(overrides: Partial<ProjectRepository> = {}): ProjectRepository {
  return {
    findById: vi.fn(),
    findAll: vi.fn(),
    create: vi.fn(),
    update: vi.fn(),
    delete: vi.fn(),
    ...overrides,
  }
}

describe('ProjectService', () => {
  let repository: ProjectRepository
  let service: ProjectService

  beforeEach(() => {
    repository = makeRepository()
    service = new ProjectService(repository)
  })

  describe('archiveProject', () => {
    it('updates status to archived when project exists', async () => {
      // Arrange
      const projectId = 'proj_123'
      const existing = { id: projectId, name: 'Alpha', status: 'active' as const }
      vi.mocked(repository.findById).mockResolvedValue(existing)
      vi.mocked(repository.update).mockResolvedValue({ ...existing, status: 'archived' })

      // Act
      const result = await service.archiveProject(projectId)

      // Assert
      expect(result.status).toBe('archived')
      expect(repository.update).toHaveBeenCalledWith(projectId, { status: 'archived' })
    })

    it('throws NotFoundError when project does not exist', async () => {
      // Arrange
      vi.mocked(repository.findById).mockResolvedValue(null)

      // Act + Assert
      await expect(service.archiveProject('missing_id')).rejects.toThrow('Project not found')
    })

    it('does not call update when project is already archived', async () => {
      // Arrange
      const already = { id: 'proj_456', name: 'Beta', status: 'archived' as const }
      vi.mocked(repository.findById).mockResolvedValue(already)

      // Act
      const result = await service.archiveProject('proj_456')

      // Assert — idempotent, no redundant write
      expect(result.status).toBe('archived')
      expect(repository.update).not.toHaveBeenCalled()
    })
  })

  describe('createProject', () => {
    it('persists project with active status by default', async () => {
      // Arrange
      const input = { name: 'New Project', ownerId: 'user_1' }
      const saved = { id: 'proj_789', ...input, status: 'active' as const }
      vi.mocked(repository.create).mockResolvedValue(saved)

      // Act
      const result = await service.createProject(input)

      // Assert
      expect(repository.create).toHaveBeenCalledWith({ ...input, status: 'active' })
      expect(result.id).toBe('proj_789')
    })
  })
})
