/**
 * Example: Playwright E2E test
 * Pack: testing
 * Tags: testing, e2e, playwright
 *
 * Demonstrates the Page Object Model for reusable page interactions,
 * intelligent waiting (no fixed timeouts), and network mocking for
 * deterministic API responses.
 */

import { test, expect, type Page, type Route } from '@playwright/test'

// --- Page Object Model -------------------------------------------------------

class ProjectsPage {
  constructor(private readonly page: Page) {}

  async goto() {
    await this.page.goto('/projects')
    // Wait for meaningful content — not a fixed timeout
    await this.page.waitForSelector('[data-testid="project-grid"]')
  }

  async searchFor(query: string) {
    await this.page.getByRole('textbox', { name: /search projects/i }).fill(query)
    // Wait for debounced results to settle
    await this.page.waitForResponse((r) => r.url().includes('/api/projects'))
  }

  async filterByStatus(status: 'all' | 'active' | 'archived') {
    await this.page.getByRole('tab', { name: new RegExp(status, 'i') }).click()
  }

  async getVisibleProjectNames(): Promise<string[]> {
    return this.page.getByTestId('project-name').allTextContents()
  }

  async openProject(name: string) {
    await this.page.getByRole('link', { name }).click()
    await this.page.waitForURL(/\/projects\/[^/]+$/)
  }
}

// --- Network mock helpers ----------------------------------------------------

function mockProjectsApi(route: Route, projects: Array<{ id: string; name: string; status: string }>) {
  return route.fulfill({
    status: 200,
    contentType: 'application/json',
    body: JSON.stringify({ success: true, data: projects, meta: { total: projects.length, page: 1, limit: 20 } }),
  })
}

// --- Tests -------------------------------------------------------------------

test.describe('Projects page', () => {
  test('displays projects returned by the API', async ({ page }) => {
    // Arrange — intercept before navigation so no real network call fires
    await page.route('**/api/projects*', (route) =>
      mockProjectsApi(route, [
        { id: '1', name: 'Auth Service', status: 'active' },
        { id: '2', name: 'Design System', status: 'active' },
      ]),
    )

    const projectsPage = new ProjectsPage(page)
    await projectsPage.goto()

    // Assert
    const names = await projectsPage.getVisibleProjectNames()
    expect(names).toEqual(['Auth Service', 'Design System'])
  })

  test('filters projects by search query', async ({ page }) => {
    const projects = [
      { id: '1', name: 'Auth Service', status: 'active' },
      { id: '2', name: 'Design System', status: 'active' },
      { id: '3', name: 'Auth Middleware', status: 'active' },
    ]

    await page.route('**/api/projects*', (route) => {
      const url = new URL(route.request().url())
      const query = url.searchParams.get('query') ?? ''
      const filtered = projects.filter((p) => p.name.toLowerCase().includes(query))
      return mockProjectsApi(route, filtered)
    })

    const projectsPage = new ProjectsPage(page)
    await projectsPage.goto()
    await projectsPage.searchFor('auth')

    const names = await projectsPage.getVisibleProjectNames()
    expect(names).toEqual(['Auth Service', 'Auth Middleware'])
  })

  test('shows empty state when no projects match', async ({ page }) => {
    await page.route('**/api/projects*', (route) => mockProjectsApi(route, []))

    const projectsPage = new ProjectsPage(page)
    await projectsPage.goto()

    // Intelligent wait — locator retries until condition is met or timeout
    await expect(page.getByText(/no projects found/i)).toBeVisible()
  })

  test('navigates to project detail page', async ({ page }) => {
    await page.route('**/api/projects*', (route) =>
      mockProjectsApi(route, [{ id: 'proj_abc', name: 'Core API', status: 'active' }]),
    )

    const projectsPage = new ProjectsPage(page)
    await projectsPage.goto()
    await projectsPage.openProject('Core API')

    await expect(page).toHaveURL(/\/projects\/proj_abc/)
  })
})
