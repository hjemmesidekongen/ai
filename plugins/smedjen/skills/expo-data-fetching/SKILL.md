---
name: expo-data-fetching
description: >
  Data fetching in Expo — fetch, React Query, SWR, offline support, and
  caching strategies
user_invocable: false
interactive: false
model_tier: senior
depends_on: []
triggers:
  - "expo data fetching"
  - "react native fetch"
  - "expo react query"
  - "expo offline"
reads: []
writes: []
checkpoint:
  type: data_validation
  required_checks:
    - name: "no_fetch_in_useeffect"
      verify: "Data fetching does not use bare useEffect + fetch — React Query or SWR manages remote state"
      fail_action: "Replace useEffect fetch patterns with useQuery or useSWR"
    - name: "error_and_loading_states_handled"
      verify: "Every query has explicit loading and error handling — no unguarded data access"
      fail_action: "Add isLoading and error guards before rendering fetched data"
    - name: "query_keys_typed"
      verify: "React Query keys are defined as typed constants — no inline string keys"
      fail_action: "Extract query keys to a typed constants file and reference from hooks"
  on_fail: "Data fetching has structural issues — fix before merging"
  on_pass: "Data fetching patterns are sound"
_source:
  origin: "smedjen"
  inspired_by: "original"
  ported_date: "2026-03-10"
  iteration: 1
  changes: "New discipline skill for smedjen"
---

# Expo Data Fetching

React Native has `fetch` built in — but raw `fetch` in `useEffect` creates unreliable, verbose patterns. React Query is the standard for server state in Expo apps.

## React Query Setup

Wrap the root layout in `QueryClientProvider`. Set `staleTime`, `retry`, and `refetchOnWindowFocus: false` in defaults — mobile apps don't have browser windows, so the default focus refetch fires unexpectedly without this.

## Query and Mutation

```tsx
const { data, isLoading, error } = useQuery({
  queryKey: queryKeys.users.detail(userId),
  queryFn: () => fetchUser(userId),
  enabled: !!userId,
});

const mutation = useMutation({
  mutationFn: updateUser,
  onSuccess: (user) =>
    queryClient.invalidateQueries({ queryKey: queryKeys.users.all }),
});
```

## Key Rules

- Use React Query for all remote server state. Local UI state stays in `useState`.
- Define query keys as typed constants — never inline strings across files.
- Always handle `isLoading` and `error` before accessing `data`.
- Set `staleTime` in defaults to reduce unnecessary refetches on screen focus.
- For offline-first, persist the query cache with MMKV or AsyncStorage.

See `references/process.md` for SWR patterns, offline strategies (AsyncStorage, MMKV, WatermelonDB), optimistic updates, infinite queries, cache persistence, error handling, type-safe fetching, and anti-patterns.
