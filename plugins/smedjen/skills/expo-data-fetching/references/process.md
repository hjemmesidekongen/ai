# Expo Data Fetching — Process Reference

## fetch in React Native

React Native bundles a `fetch` implementation — no polyfill needed. Basic usage is identical to browser `fetch`, but there are RN-specific behaviors to know:

- No automatic cookie handling — manage tokens manually with `Authorization` headers.
- `XMLHttpRequest` is available but avoid it; `fetch` is the standard.
- File uploads use `FormData` — works the same as in browsers.

```ts
async function fetchUser(id: string): Promise<User> {
  const token = await SecureStore.getItemAsync('auth_token');

  const res = await fetch(`https://api.example.com/users/${id}`, {
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  });

  if (!res.ok) {
    throw new Error(`Request failed: ${res.status}`);
  }

  return res.json() as Promise<User>;
}
```

Wrap all API calls in typed functions — don't call `fetch` directly from components.

## React Query

### QueryClient Configuration

```tsx
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60,       // 1 min — don't refetch if data is fresh
      gcTime: 1000 * 60 * 5,      // 5 min — keep in cache after unmount
      retry: 2,                    // retry failed requests twice
      refetchOnWindowFocus: false, // RN apps aren't "windows" — disable
    },
  },
});
```

In React Native, `refetchOnWindowFocus` and `refetchOnReconnect` behave differently than in browsers. React Query v5 has AppState integration for focus detection on mobile.

### Query Keys

Define keys as typed constants — this prevents typos, enables type-safe invalidation, and makes refactoring easy:

```ts
// lib/query-keys.ts
export const queryKeys = {
  users: {
    all: ['users'] as const,
    detail: (id: string) => ['users', id] as const,
    posts: (userId: string) => ['users', userId, 'posts'] as const,
  },
  products: {
    all: ['products'] as const,
    filtered: (filters: ProductFilters) => ['products', filters] as const,
  },
};
```

Usage:

```ts
useQuery({
  queryKey: queryKeys.users.detail(userId),
  queryFn: () => fetchUser(userId),
});

// Invalidate all user queries
queryClient.invalidateQueries({ queryKey: queryKeys.users.all });
```

### Custom Query Hooks

Encapsulate query logic in custom hooks — components shouldn't know about fetch implementation details:

```ts
// hooks/use-user.ts
import { useQuery } from '@tanstack/react-query';
import { queryKeys } from '@/lib/query-keys';

export function useUser(userId: string) {
  return useQuery({
    queryKey: queryKeys.users.detail(userId),
    queryFn: () => fetchUser(userId),
    enabled: !!userId,  // don't run until userId is available
  });
}

// hooks/use-update-user.ts
import { useMutation, useQueryClient } from '@tanstack/react-query';

export function useUpdateUser() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: UpdateUserInput) => updateUser(data),
    onSuccess: (user) => {
      // Update the specific user in cache
      queryClient.setQueryData(queryKeys.users.detail(user.id), user);
      // Invalidate list queries
      queryClient.invalidateQueries({ queryKey: queryKeys.users.all });
    },
    onError: (error) => {
      console.error('Update failed:', error);
    },
  });
}
```

### Optimistic Updates

```ts
export function useUpdateUser() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: updateUser,
    onMutate: async (newData) => {
      // Cancel in-flight queries for this user
      await queryClient.cancelQueries({ queryKey: queryKeys.users.detail(newData.id) });

      // Snapshot the current value
      const previousUser = queryClient.getQueryData<User>(queryKeys.users.detail(newData.id));

      // Optimistically update
      queryClient.setQueryData(queryKeys.users.detail(newData.id), (old: User) => ({
        ...old,
        ...newData,
      }));

      // Return context with previous value for rollback
      return { previousUser };
    },
    onError: (_err, newData, context) => {
      // Rollback on error
      queryClient.setQueryData(
        queryKeys.users.detail(newData.id),
        context?.previousUser
      );
    },
    onSettled: (data) => {
      // Always refetch to sync with server
      queryClient.invalidateQueries({ queryKey: queryKeys.users.detail(data!.id) });
    },
  });
}
```

### Pagination — Infinite Queries

```ts
// hooks/use-posts.ts
import { useInfiniteQuery } from '@tanstack/react-query';

export function usePosts() {
  return useInfiniteQuery({
    queryKey: queryKeys.posts.all,
    queryFn: ({ pageParam }) => fetchPosts({ cursor: pageParam, limit: 20 }),
    initialPageParam: undefined as string | undefined,
    getNextPageParam: (lastPage) => lastPage.nextCursor,
  });
}

// In component
function PostList() {
  const { data, fetchNextPage, hasNextPage, isFetchingNextPage } = usePosts();

  const posts = data?.pages.flatMap((page) => page.items) ?? [];

  return (
    <FlatList
      data={posts}
      keyExtractor={(item) => item.id}
      renderItem={({ item }) => <PostCard post={item} />}
      onEndReached={() => hasNextPage && fetchNextPage()}
      onEndReachedThreshold={0.5}
      ListFooterComponent={isFetchingNextPage ? <ActivityIndicator /> : null}
    />
  );
}
```

### Background Refetch

React Query refetches on query mount by default. For mobile apps, also trigger refetch when the app returns to the foreground:

```ts
import { useEffect } from 'react';
import { AppState, AppStateStatus } from 'react-native';
import { focusManager } from '@tanstack/react-query';

export function useAppStateRefetch() {
  useEffect(() => {
    const subscription = AppState.addEventListener('change', (status: AppStateStatus) => {
      focusManager.setFocused(status === 'active');
    });
    return () => subscription.remove();
  }, []);
}
```

Call this once in the root layout.

## SWR

SWR is a lighter alternative to React Query — good for simpler apps where full mutation management isn't needed.

```bash
npx expo install swr
```

```tsx
import useSWR from 'swr';

const fetcher = (url: string) =>
  fetch(url).then((res) => {
    if (!res.ok) throw new Error('Fetch failed');
    return res.json();
  });

function Profile({ userId }: { userId: string }) {
  const { data, error, isLoading } = useSWR(`/api/users/${userId}`, fetcher);

  if (isLoading) return <ActivityIndicator />;
  if (error) return <Text>Error: {error.message}</Text>;
  return <ProfileCard user={data} />;
}
```

SWR mutation:

```ts
import useSWRMutation from 'swr/mutation';

async function updateUser(url: string, { arg }: { arg: UpdateUserInput }) {
  return fetch(url, { method: 'PATCH', body: JSON.stringify(arg) }).then((r) => r.json());
}

function EditProfile({ userId }: { userId: string }) {
  const { trigger, isMutating } = useSWRMutation(`/api/users/${userId}`, updateUser);

  return (
    <Button
      onPress={() => trigger({ name: 'New Name' })}
      disabled={isMutating}
    />
  );
}
```

SWR vs React Query: prefer React Query when you need complex invalidation, optimistic updates, or infinite queries. SWR works well for read-heavy screens with simple caching needs.

## Offline-First Strategies

### AsyncStorage Cache Persistence (React Query)

```bash
npx expo install @react-native-async-storage/async-storage @tanstack/query-async-storage-persister @tanstack/react-query-persist-client
```

```tsx
import AsyncStorage from '@react-native-async-storage/async-storage';
import { createAsyncStoragePersister } from '@tanstack/query-async-storage-persister';
import { PersistQueryClientProvider } from '@tanstack/react-query-persist-client';

const persister = createAsyncStoragePersister({ storage: AsyncStorage });

export default function RootLayout() {
  return (
    <PersistQueryClientProvider
      client={queryClient}
      persistOptions={{ persister, maxAge: 1000 * 60 * 60 * 24 }} // 24h
    >
      {children}
    </PersistQueryClientProvider>
  );
}
```

With this setup, queries survive app restarts — stale data renders immediately while a background refetch runs.

### MMKV (Faster Alternative)

```bash
npx expo install react-native-mmkv
```

```ts
import { MMKV } from 'react-native-mmkv';

const storage = new MMKV();

const mmkvPersister = createAsyncStoragePersister({
  storage: {
    getItem: (key) => Promise.resolve(storage.getString(key) ?? null),
    setItem: (key, value) => { storage.set(key, value); return Promise.resolve(); },
    removeItem: (key) => { storage.delete(key); return Promise.resolve(); },
  },
});
```

MMKV is synchronous and ~30x faster than AsyncStorage — prefer it for frequently read cache data.

### WatermelonDB (Heavy Offline, Relational Data)

For apps that need real relational offline storage, full sync, and conflict resolution:

```bash
npx expo install @nozbe/watermelondb
```

WatermelonDB works alongside React Query — use WatermelonDB as the local source of truth and React Query to sync with the remote. Components observe WatermelonDB records via `withObservables`; React Query mutations write to both WatermelonDB and the remote.

Use WatermelonDB when: the app must work fully offline, data is relational, or you need bidirectional sync with conflict resolution. It's heavy — don't add it for simple read caching.

## Error Handling and Retry

React Query retries failed queries automatically (`retry: 2` by default). Customize per-query:

```ts
useQuery({
  queryKey: queryKeys.users.detail(id),
  queryFn: fetchUser,
  retry: (failureCount, error) => {
    // Don't retry 4xx errors — they won't succeed
    if (error.status >= 400 && error.status < 500) return false;
    return failureCount < 3;
  },
  retryDelay: (attempt) => Math.min(1000 * 2 ** attempt, 30000), // exponential backoff
});
```

Surface errors in a boundary:

```tsx
import { useQueryErrorResetBoundary } from '@tanstack/react-query';
import { ErrorBoundary } from 'react-error-boundary';

function QueryErrorBoundary({ children }: { children: React.ReactNode }) {
  const { reset } = useQueryErrorResetBoundary();

  return (
    <ErrorBoundary
      onReset={reset}
      fallbackRender={({ resetErrorBoundary, error }) => (
        <View>
          <Text>Something went wrong: {error.message}</Text>
          <Button onPress={resetErrorBoundary} title="Retry" />
        </View>
      )}
    >
      {children}
    </ErrorBoundary>
  );
}
```

## Type-Safe Fetching

Define typed fetcher functions and let TypeScript infer query return types:

```ts
// api/users.ts
import type { User, CreateUserInput } from '@/types/api';

export async function fetchUser(id: string): Promise<User> {
  const res = await apiFetch(`/users/${id}`);
  return res.json();
}

export async function createUser(input: CreateUserInput): Promise<User> {
  const res = await apiFetch('/users', { method: 'POST', body: JSON.stringify(input) });
  return res.json();
}
```

The `useQuery<User>` type parameter is inferred from `queryFn` return type — no need to annotate explicitly when fetchers are typed.

For remote-first type safety (types generated from the actual API), combine with `openapi-typescript` to generate types from an OpenAPI spec and use them as the source of truth for both fetchers and components.

## Common Anti-Patterns

**fetch inside useEffect**
```tsx
// Bad — no caching, no deduplication, no refetch on focus, manual loading state
useEffect(() => {
  setLoading(true);
  fetch('/api/users').then(r => r.json()).then(setUsers).finally(() => setLoading(false));
}, []);

// Good — React Query handles all of this
const { data: users, isLoading } = useQuery({
  queryKey: queryKeys.users.all,
  queryFn: fetchUsers,
});
```

**Inline query keys**
```ts
// Bad — typo-prone, hard to invalidate
useQuery({ queryKey: ['user', userId], ... });
queryClient.invalidateQueries({ queryKey: ['users'] }); // mismatched key, won't invalidate

// Good — typed constants
useQuery({ queryKey: queryKeys.users.detail(userId), ... });
queryClient.invalidateQueries({ queryKey: queryKeys.users.all });
```

**No staleTime set**
Without `staleTime`, React Query considers all data immediately stale and refetches on every screen focus. Set a sensible default (60s for most data) in `QueryClient` defaults.

**Accessing data.property without guards**
`data` is `undefined` while loading. Always check `isLoading` and `error` before rendering.

**Over-fetching by not using `enabled`**
If a query depends on a param that may not be available yet (userId, route param), use `enabled: !!param` to prevent the query from running with undefined inputs.

**Persisting sensitive data in AsyncStorage/MMKV without encryption**
Query cache persistence stores full API responses. If responses contain PII or tokens, use an encrypted storage backend or exclude sensitive queries from persistence with `meta: { persist: false }`.
