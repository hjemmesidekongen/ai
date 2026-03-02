/**
 * Example: React Client Component
 * Pack: react-nextjs
 * Tags: react, client-component, state
 *
 * Demonstrates the 'use client' directive, state management with useReducer
 * for complex state, event handlers, and targeted memoization.
 */

'use client'

import { useReducer, useCallback, memo } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'

interface FilterState {
  query: string
  status: 'all' | 'active' | 'archived'
  sortBy: 'name' | 'date'
}

type FilterAction =
  | { type: 'SET_QUERY'; query: string }
  | { type: 'SET_STATUS'; status: FilterState['status'] }
  | { type: 'SET_SORT'; sortBy: FilterState['sortBy'] }
  | { type: 'RESET' }

const initialState: FilterState = { query: '', status: 'all', sortBy: 'date' }

function filterReducer(state: FilterState, action: FilterAction): FilterState {
  switch (action.type) {
    case 'SET_QUERY':
      return { ...state, query: action.query }
    case 'SET_STATUS':
      return { ...state, status: action.status }
    case 'SET_SORT':
      return { ...state, sortBy: action.sortBy }
    case 'RESET':
      return initialState
    default:
      return state
  }
}

interface ProjectFiltersProps {
  onFilterChange: (filters: FilterState) => void
}

export function ProjectFilters({ onFilterChange }: ProjectFiltersProps) {
  const [filters, dispatch] = useReducer(filterReducer, initialState)

  // Memoize only handlers passed to child components that re-render frequently
  const handleQueryChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const next = { ...filters, query: e.target.value }
      dispatch({ type: 'SET_QUERY', query: e.target.value })
      onFilterChange(next)
    },
    [filters, onFilterChange],
  )

  const handleReset = useCallback(() => {
    dispatch({ type: 'RESET' })
    onFilterChange(initialState)
  }, [onFilterChange])

  return (
    <div className="flex flex-wrap gap-3 items-center">
      <Input
        placeholder="Search projects..."
        value={filters.query}
        onChange={handleQueryChange}
        className="w-56"
        aria-label="Search projects"
      />

      <StatusTabs
        value={filters.status}
        onChange={(status) => {
          dispatch({ type: 'SET_STATUS', status })
          onFilterChange({ ...filters, status })
        }}
      />

      {(filters.query || filters.status !== 'all') && (
        <Button variant="ghost" size="sm" onClick={handleReset}>
          Clear filters
        </Button>
      )}
    </div>
  )
}

// memo prevents re-render when parent updates but props are unchanged
const StatusTabs = memo(function StatusTabs({
  value,
  onChange,
}: {
  value: FilterState['status']
  onChange: (status: FilterState['status']) => void
}) {
  const options: FilterState['status'][] = ['all', 'active', 'archived']

  return (
    <div role="tablist" aria-label="Project status" className="flex gap-1">
      {options.map((option) => (
        <button
          key={option}
          role="tab"
          aria-selected={value === option}
          onClick={() => onChange(option)}
          className={`px-3 py-1 rounded text-sm capitalize ${
            value === option ? 'bg-primary text-primary-foreground' : 'hover:bg-muted'
          }`}
        >
          {option}
        </button>
      ))}
    </div>
  )
})
