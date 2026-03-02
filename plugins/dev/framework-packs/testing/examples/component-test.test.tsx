/**
 * Example: React Testing Library component test
 * Pack: testing
 * Tags: testing, component, rtl
 *
 * Demonstrates render + screen queries, user-event simulation for realistic
 * interactions, and accessibility assertions.
 */

import { describe, it, expect, vi } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { ProjectFilters } from '@/components/project-filters'

// userEvent.setup() returns a user instance with a realistic event simulation
// (fires pointer/keyboard events, handles delays — prefer over fireEvent)

describe('ProjectFilters', () => {
  it('calls onFilterChange with updated query when user types', async () => {
    const user = userEvent.setup()
    const onFilterChange = vi.fn()

    render(<ProjectFilters onFilterChange={onFilterChange} />)

    const searchInput = screen.getByRole('textbox', { name: /search projects/i })
    await user.type(searchInput, 'auth')

    // Called once per keystroke — last call has the full query
    expect(onFilterChange).toHaveBeenLastCalledWith(
      expect.objectContaining({ query: 'auth' }),
    )
  })

  it('applies the selected status tab', async () => {
    const user = userEvent.setup()
    const onFilterChange = vi.fn()

    render(<ProjectFilters onFilterChange={onFilterChange} />)

    // Accessibility: tabs use role="tab" and aria-selected
    const activeTab = screen.getByRole('tab', { name: /active/i })
    await user.click(activeTab)

    expect(activeTab).toHaveAttribute('aria-selected', 'true')
    expect(onFilterChange).toHaveBeenCalledWith(
      expect.objectContaining({ status: 'active' }),
    )
  })

  it('shows clear button when filters are active and resets on click', async () => {
    const user = userEvent.setup()
    const onFilterChange = vi.fn()

    render(<ProjectFilters onFilterChange={onFilterChange} />)

    // No clear button while filters are at default
    expect(screen.queryByRole('button', { name: /clear filters/i })).toBeNull()

    // Type to activate a filter
    await user.type(screen.getByRole('textbox', { name: /search/i }), 'api')
    expect(screen.getByRole('button', { name: /clear filters/i })).toBeInTheDocument()

    // Clear resets to defaults
    await user.click(screen.getByRole('button', { name: /clear filters/i }))

    await waitFor(() => {
      expect(onFilterChange).toHaveBeenLastCalledWith(
        expect.objectContaining({ query: '', status: 'all' }),
      )
    })

    // Clear button disappears after reset
    expect(screen.queryByRole('button', { name: /clear filters/i })).toBeNull()
  })

  it('renders all status options with correct accessible roles', () => {
    render(<ProjectFilters onFilterChange={vi.fn()} />)

    const tablist = screen.getByRole('tablist', { name: /project status/i })
    expect(tablist).toBeInTheDocument()

    const tabs = screen.getAllByRole('tab')
    expect(tabs).toHaveLength(3)
    expect(tabs.map((t) => t.textContent)).toEqual(['all', 'active', 'archived'])
  })
})
