---
origin: "wshobson/agents"
origin_skill: "react-state-management"
origin_version: "1.0.0"
forked_date: "2026-03-02"
sections_kept: "State selection criteria (Core Concepts section 2), Zustand patterns (Quick Start + Pattern 2), Jotai patterns (Pattern 3), React Query patterns (Pattern 4), combining client+server state (Pattern 5), Best Practices"
sections_removed: "Redux Toolkit deep dive (Pattern 1 — too project-specific per findings.md), Migration guides, Resources list"
---

# React State Management

State selection criteria and Zustand/Jotai patterns. For Redux Toolkit, see the full upstream skill.

> See also: `react-best-practices.md` Category 5 (Re-render Optimization) for selector patterns, `useMemo`, and `useCallback` — directly related to how you subscribe to state. `composition-patterns.md` for component API design.

## When to Use This Skill

- Choosing between state management solutions
- Setting up global state in a React app
- Managing server state with React Query

## State Selection Criteria

```
Small app, simple global state  → Zustand or Jotai
Large app, complex state logic  → Redux Toolkit
Heavy server data fetching      → React Query + light client state (Zustand)
Atomic/granular subscriptions   → Jotai
Form state                      → React Hook Form (not global state)
URL/route state                 → nuqs or React Router
```

| Type | Description | Solutions |
|------|-------------|-----------|
| Local State | Component-specific, UI state | useState, useReducer |
| Global State | Shared across components | Redux Toolkit, Zustand, Jotai |
| Server State | Remote data, caching | React Query, SWR, RTK Query |
| URL State | Route parameters, search | React Router, nuqs |
| Form State | Input values, validation | React Hook Form, Formik |

## Zustand (Recommended for Most Cases)

**Simple store:**
```typescript
// store/useStore.ts
import { create } from 'zustand'
import { devtools, persist } from 'zustand/middleware'

interface AppState {
  user: User | null
  theme: 'light' | 'dark'
  setUser: (user: User | null) => void
  toggleTheme: () => void
}

export const useStore = create<AppState>()(
  devtools(
    persist(
      (set) => ({
        user: null,
        theme: 'light',
        setUser: (user) => set({ user }),
        toggleTheme: () => set((state) => ({
          theme: state.theme === 'light' ? 'dark' : 'light'
        })),
      }),
      { name: 'app-storage' }
    )
  )
)
```

**Scalable slice pattern (large apps):**
```typescript
// store/slices/createUserSlice.ts
export const createUserSlice: StateCreator<UserSlice & CartSlice, [], [], UserSlice> = (set) => ({
  user: null,
  isAuthenticated: false,
  login: async (credentials) => {
    const user = await authApi.login(credentials)
    set({ user, isAuthenticated: true })
  },
  logout: () => set({ user: null, isAuthenticated: false }),
})

// store/index.ts
export const useStore = create<UserSlice & CartSlice>()((...args) => ({
  ...createUserSlice(...args),
  ...createCartSlice(...args),
}))

// Selective subscriptions — prevents unnecessary re-renders
export const useUser = () => useStore((state) => state.user)
export const useIsAuthenticated = () => useStore((state) => state.isAuthenticated)
```

**Best practice:** Always use selectors, never subscribe to the whole store:
```typescript
// ❌ Re-renders on any state change
const state = useStore()
const user = state.user

// ✅ Re-renders only when user changes
const user = useStore((state) => state.user)
```

## Jotai (Atomic State — Granular Subscriptions)

Best when you need fine-grained reactivity or derived state.

```typescript
// atoms/userAtoms.ts
import { atom } from 'jotai'
import { atomWithStorage } from 'jotai/utils'

export const userAtom = atom<User | null>(null)
export const isAuthenticatedAtom = atom((get) => get(userAtom) !== null)  // Derived
export const themeAtom = atomWithStorage<'light' | 'dark'>('theme', 'light')

// Async atom (Suspense-enabled)
export const userProfileAtom = atom(async (get) => {
  const user = get(userAtom)
  if (!user) return null
  return fetch(`/api/users/${user.id}/profile`).then(r => r.json())
})

// Write-only action atom
export const logoutAtom = atom(null, (get, set) => {
  set(userAtom, null)
  localStorage.removeItem('token')
})

// Usage
function Profile() {
  const [user] = useAtom(userAtom)
  const [, logout] = useAtom(logoutAtom)
  return (
    <Suspense fallback={<Skeleton />}>
      <ProfileContent onLogout={logout} />
    </Suspense>
  )
}
```

## React Query (Server State)

Use for all remote data fetching. Handles caching, background refresh, optimistic updates.

```typescript
// hooks/useUsers.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'

// Query key factory — consistent, type-safe keys
export const userKeys = {
  all: ['users'] as const,
  lists: () => [...userKeys.all, 'list'] as const,
  list: (filters: UserFilters) => [...userKeys.lists(), filters] as const,
  detail: (id: string) => [...userKeys.all, 'detail', id] as const,
}

export function useUsers(filters: UserFilters) {
  return useQuery({
    queryKey: userKeys.list(filters),
    queryFn: () => fetchUsers(filters),
    staleTime: 5 * 60 * 1000, // 5 minutes
  })
}

// Mutation with optimistic update
export function useUpdateUser() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: updateUser,
    onMutate: async (newUser) => {
      await queryClient.cancelQueries({ queryKey: userKeys.detail(newUser.id) })
      const previousUser = queryClient.getQueryData(userKeys.detail(newUser.id))
      queryClient.setQueryData(userKeys.detail(newUser.id), newUser) // Optimistic
      return { previousUser }
    },
    onError: (err, newUser, context) => {
      queryClient.setQueryData(userKeys.detail(newUser.id), context?.previousUser)
    },
    onSettled: (data, error, variables) => {
      queryClient.invalidateQueries({ queryKey: userKeys.detail(variables.id) })
    },
  })
}
```

## Combining Client + Server State

```typescript
// Zustand for UI state (sidebar, modal, theme)
const useUIStore = create<UIState>((set) => ({
  sidebarOpen: true,
  modal: null,
  toggleSidebar: () => set((s) => ({ sidebarOpen: !s.sidebarOpen })),
  openModal: (modal) => set({ modal }),
  closeModal: () => set({ modal: null }),
}))

// React Query for server data
function Dashboard() {
  const { sidebarOpen, toggleSidebar } = useUIStore()
  const { data: users, isLoading } = useUsers({ active: true })

  if (isLoading) return <DashboardSkeleton />
  return (
    <div className={sidebarOpen ? 'with-sidebar' : ''}>
      <Sidebar open={sidebarOpen} onToggle={toggleSidebar} />
      <main><UserTable users={users} /></main>
    </div>
  )
}
```

## Best Practices

**Do:**
- Colocate state as close to where it's used as possible
- Use selectors to prevent unnecessary re-renders
- Separate server state (React Query) from client state (Zustand)
- Type everything — full TypeScript coverage

**Don't:**
- Over-globalize — not everything needs global state
- Duplicate server state in Zustand — let React Query manage it
- Mutate state directly — always use immutable updates
- Store derived data — compute it instead
