# react-patterns — Process Reference

## Hook Patterns

### useState

Keep state minimal. Never store what can be derived.

```tsx
// Bad: syncing derived state
const [fullName, setFullName] = useState('');
useEffect(() => setFullName(`${first} ${last}`), [first, last]);

// Good: derive at render time
const fullName = `${first} ${last}`;
```

For arrays and objects, prefer functional updates to avoid stale closures:

```tsx
setItems(prev => [...prev, newItem]);
setUser(prev => ({ ...prev, name: 'updated' }));
```

### useReducer

Use when state transitions have logic that belongs together:

```tsx
type Action =
  | { type: 'fetch_start' }
  | { type: 'fetch_success'; data: Item[] }
  | { type: 'fetch_error'; error: string };

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'fetch_start':  return { ...state, loading: true, error: null };
    case 'fetch_success': return { loading: false, error: null, data: action.data };
    case 'fetch_error':  return { ...state, loading: false, error: action.error };
  }
}

const [state, dispatch] = useReducer(reducer, initialState);
```

Prefer `useReducer` over multiple related `useState` calls that always update together.

### useEffect

Effects synchronize React state with external systems. The question is always: "what external system am I syncing with?"

```tsx
// Good: syncing with a subscription
useEffect(() => {
  const sub = store.subscribe(setState);
  return () => sub.unsubscribe(); // cleanup is mandatory for subscriptions
}, [store]);

// Bad: reacting to state changes that should be computed or handled in events
useEffect(() => {
  if (count > 10) setOverLimit(true); // derive this instead
}, [count]);
```

**Dependency array rules:**
- Empty array `[]` — run once on mount, cleanup on unmount.
- No array — run every render. Rarely correct.
- With deps — run when any dep changes. Every value used inside should be listed.
- Never lie to the deps array. Exhaustive-deps lint rule exists for a reason.

**Common effect patterns:**

```tsx
// Abort fetch on cleanup
useEffect(() => {
  const controller = new AbortController();
  fetch('/api/data', { signal: controller.signal })
    .then(r => r.json())
    .then(setData)
    .catch(err => { if (err.name !== 'AbortError') setError(err); });
  return () => controller.abort();
}, []);

// Interval
useEffect(() => {
  const id = setInterval(tick, 1000);
  return () => clearInterval(id);
}, [tick]);

// Event listener
useEffect(() => {
  window.addEventListener('resize', handler);
  return () => window.removeEventListener('resize', handler);
}, [handler]);
```

### useCallback

Only stabilize a function reference when it matters:

```tsx
// Useful: callback passed to memoized child
const handleSubmit = useCallback(() => {
  onSubmit(formData);
}, [onSubmit, formData]);

// Wasteful: function used only in this component with no memoized consumers
const handleClick = useCallback(() => setCount(c => c + 1), []); // pointless
```

### useMemo

Only memoize when computation cost or referential instability has been confirmed:

```tsx
// Useful: expensive computation
const sortedList = useMemo(
  () => items.slice().sort(compareFn),
  [items, compareFn]
);

// Useful: stable reference for a memoized child's prop
const config = useMemo(() => ({ theme, locale }), [theme, locale]);

// Wasteful: trivial computation
const label = useMemo(() => `Hello ${name}`, [name]); // just write the template literal
```

### useRef

Persistent mutable container — does not trigger re-renders:

```tsx
// DOM access
const inputRef = useRef<HTMLInputElement>(null);
inputRef.current?.focus();

// Storing a timer ID
const timerRef = useRef<ReturnType<typeof setTimeout>>();
timerRef.current = setTimeout(callback, delay);
clearTimeout(timerRef.current);

// Tracking previous value
function usePrevious<T>(value: T) {
  const ref = useRef<T>();
  useEffect(() => { ref.current = value; });
  return ref.current;
}
```

### Custom Hooks

Extract when logic is reused or when a component function is doing too much:

```tsx
// Data fetching hook
function useFetch<T>(url: string) {
  const [state, dispatch] = useReducer(reducer, { loading: true, data: null, error: null });

  useEffect(() => {
    const controller = new AbortController();
    dispatch({ type: 'fetch_start' });
    fetch(url, { signal: controller.signal })
      .then(r => r.json())
      .then(data => dispatch({ type: 'fetch_success', data }))
      .catch(error => {
        if (error.name !== 'AbortError') dispatch({ type: 'fetch_error', error: error.message });
      });
    return () => controller.abort();
  }, [url]);

  return state;
}

// Form hook
function useField(initial: string) {
  const [value, setValue] = useState(initial);
  return { value, onChange: (e: React.ChangeEvent<HTMLInputElement>) => setValue(e.target.value) };
}

// Local storage hook
function useLocalStorage<T>(key: string, initial: T) {
  const [value, setValue] = useState<T>(() => {
    try { return JSON.parse(localStorage.getItem(key) ?? '') ?? initial; }
    catch { return initial; }
  });

  const set = useCallback((next: T) => {
    setValue(next);
    localStorage.setItem(key, JSON.stringify(next));
  }, [key]);

  return [value, set] as const;
}
```

---

## Context Patterns

### When to Use Context

Context is for state that needs to be accessible across a component subtree without explicit prop threading. Classic cases: auth user, theme, locale, feature flags.

Context is **not** a state management solution. It does not batch updates; every context value change re-renders all consumers.

### When NOT to Use Context

- When props would only thread through 1–2 levels — just pass props.
- When the state changes frequently (e.g., mouse position, scroll offset) — all consumers re-render.
- When you need selective subscription (only re-render when a specific slice changes) — use Zustand, Jotai, or Redux.

### Context Implementation

Split context creation from usage. Always provide a custom hook with an invariant:

```tsx
interface AuthContextValue {
  user: User | null;
  signIn: (credentials: Credentials) => Promise<void>;
  signOut: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);

  const signIn = useCallback(async (credentials: Credentials) => {
    const user = await authService.login(credentials);
    setUser(user);
  }, []);

  const signOut = useCallback(() => {
    authService.logout();
    setUser(null);
  }, []);

  const value = useMemo(() => ({ user, signIn, signOut }), [user, signIn, signOut]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
```

### Splitting Context to Prevent Over-Rendering

Split state and dispatch into separate contexts when consumers need one but not both:

```tsx
const StateCtx = createContext<State | null>(null);
const DispatchCtx = createContext<Dispatch<Action> | null>(null);

// Components that only dispatch don't re-render on state changes
export function useDispatch() {
  const ctx = useContext(DispatchCtx);
  if (!ctx) throw new Error('useDispatch must be used within Provider');
  return ctx;
}
```

---

## Component Composition

### Children Props (Most Common)

Pass JSX as children. The container handles layout/behavior; the content is injected:

```tsx
function Card({ children, title }: { children: ReactNode; title: string }) {
  return (
    <div className="card">
      <h2>{title}</h2>
      <div className="card-body">{children}</div>
    </div>
  );
}

// Usage
<Card title="Profile"><UserProfile user={user} /></Card>
```

### Render Props (Inversion of Control)

Pass a function as a prop when the consumer needs to control what's rendered inside a behavior container:

```tsx
function DataFetcher<T>({ url, render }: { url: string; render: (data: T) => ReactNode }) {
  const { data, loading, error } = useFetch<T>(url);
  if (loading) return <Spinner />;
  if (error) return <Error message={error} />;
  return <>{data && render(data)}</>;
}

// Usage
<DataFetcher url="/api/users" render={(users) => <UserList users={users} />} />
```

Render props are less common since hooks solved most reuse problems, but still useful for components that manage DOM interactions or measurement.

### Compound Components

For tightly coupled UI that needs to share internal state without prop drilling:

```tsx
interface TabsContext { active: string; setActive: (id: string) => void; }
const TabsCtx = createContext<TabsContext | null>(null);
function useTabsContext() {
  const ctx = useContext(TabsCtx);
  if (!ctx) throw new Error('Must be used within Tabs');
  return ctx;
}

function Tabs({ children, defaultTab }: { children: ReactNode; defaultTab: string }) {
  const [active, setActive] = useState(defaultTab);
  return (
    <TabsCtx.Provider value={{ active, setActive }}>
      <div className="tabs">{children}</div>
    </TabsCtx.Provider>
  );
}

function Tab({ id, label }: { id: string; label: string }) {
  const { active, setActive } = useTabsContext();
  return (
    <button
      className={active === id ? 'active' : ''}
      onClick={() => setActive(id)}
    >{label}</button>
  );
}

function TabPanel({ id, children }: { id: string; children: ReactNode }) {
  const { active } = useTabsContext();
  return active === id ? <div>{children}</div> : null;
}

Tabs.Tab = Tab;
Tabs.Panel = TabPanel;

// Usage
<Tabs defaultTab="profile">
  <Tabs.Tab id="profile" label="Profile" />
  <Tabs.Tab id="settings" label="Settings" />
  <Tabs.Panel id="profile"><ProfileForm /></Tabs.Panel>
  <Tabs.Panel id="settings"><SettingsForm /></Tabs.Panel>
</Tabs>
```

### HOCs (Higher-Order Components)

Legacy pattern — use hooks instead. Only reach for HOCs when wrapping class components or integrating with libraries that expect them:

```tsx
// Modern equivalent with hooks
function withAuth<P extends object>(Component: ComponentType<P>) {
  return function AuthGuard(props: P) {
    const { user } = useAuth();
    if (!user) return <Navigate to="/login" />;
    return <Component {...props} />;
  };
}
```

---

## Performance

### React.memo

Prevents re-renders when parent re-renders but props haven't changed:

```tsx
const UserCard = React.memo(function UserCard({ user }: { user: User }) {
  return <div>{user.name}</div>;
});

// With custom equality check for complex props
const List = React.memo(ItemList, (prev, next) =>
  prev.items.length === next.items.length &&
  prev.items.every((item, i) => item.id === next.items[i].id)
);
```

`React.memo` is only useful if the parent re-renders frequently and the child's render is expensive. Profile before adding.

### Code Splitting with React.lazy + Suspense

Split route-level or heavy feature components out of the initial bundle:

```tsx
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Settings = lazy(() => import('./pages/Settings'));

function App() {
  return (
    <Suspense fallback={<PageSpinner />}>
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/settings" element={<Settings />} />
      </Routes>
    </Suspense>
  );
}
```

Split at route boundaries first. Only go deeper (component-level) if the component is conditionally shown and large.

### Virtualization

Render only visible rows for long lists:

```tsx
import { useVirtualizer } from '@tanstack/react-virtual';

function VirtualList({ items }: { items: Item[] }) {
  const parentRef = useRef<HTMLDivElement>(null);
  const rowVirtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 48,
  });

  return (
    <div ref={parentRef} style={{ height: '600px', overflow: 'auto' }}>
      <div style={{ height: rowVirtualizer.getTotalSize() }}>
        {rowVirtualizer.getVirtualItems().map(row => (
          <div
            key={row.key}
            style={{ position: 'absolute', top: row.start, height: row.size, width: '100%' }}
          >
            <ItemRow item={items[row.index]} />
          </div>
        ))}
      </div>
    </div>
  );
}
```

Threshold: virtualize when rendering 100+ rows causes visible jank. Measure first.

---

## State Management Decision Tree

```
Is state only used in one component?
  → useState / useReducer (colocated)

Is state shared between sibling components?
  → Lift to common parent

Is state needed across a deep subtree?
  → Context (if infrequent changes) OR external store (if frequent changes)

Does state change frequently (< 100ms intervals, many consumers)?
  → Zustand / Jotai (subscription-based, avoids context re-render cascade)

Is state server-derived and cacheable?
  → React Query / TanStack Query (not useState + useEffect)

Is state complex with many transitions and shared globally?
  → Redux Toolkit (if team already uses it) or Zustand slice pattern
```

---

## Common Anti-Patterns with Fixes

### Syncing Derived State

```tsx
// Bad
const [total, setTotal] = useState(0);
useEffect(() => setTotal(items.reduce((s, i) => s + i.price, 0)), [items]);

// Good
const total = items.reduce((s, i) => s + i.price, 0);
```

### Effect as Event Handler

```tsx
// Bad: effect fires on every render where condition is true
useEffect(() => {
  if (submitted) sendAnalyticsEvent('form_submit');
}, [submitted]);

// Good: fire in the handler
function handleSubmit() {
  setSubmitted(true);
  sendAnalyticsEvent('form_submit');
}
```

### Missing Cleanup

```tsx
// Bad: subscription leaks if component unmounts
useEffect(() => {
  socket.on('message', handleMessage);
}, []);

// Good
useEffect(() => {
  socket.on('message', handleMessage);
  return () => socket.off('message', handleMessage);
}, [handleMessage]);
```

### Stale Closure in Effect

```tsx
// Bad: count is captured from first render
useEffect(() => {
  const id = setInterval(() => console.log(count), 1000);
  return () => clearInterval(id);
}, []); // count never updates inside

// Good: use functional update or include dep
useEffect(() => {
  const id = setInterval(() => setCount(c => c + 1), 1000);
  return () => clearInterval(id);
}, []);
```

### Index as Key

```tsx
// Bad: causes incorrect reconciliation when list order changes
items.map((item, i) => <Item key={i} {...item} />)

// Good: use stable unique ID
items.map(item => <Item key={item.id} {...item} />)
```

### Premature Memoization

```tsx
// Bad: wrapping everything "just in case"
const label = useMemo(() => item.name.toUpperCase(), [item.name]);
const onClick = useCallback(() => setSelected(item.id), [item.id]);

// Good: only when a child is memoized and the reference matters
const onClick = useCallback(() => setSelected(item.id), [item.id]); // fine if <Item> is React.memo'd
```

### Direct State Mutation

```tsx
// Bad
state.items.push(newItem); // mutation — React won't detect the change
setState(state);

// Good
setState(prev => ({ ...prev, items: [...prev.items, newItem] }));
```

### Overusing Context for Frequent Updates

```tsx
// Bad: mouse position in context re-renders every consumer on every mousemove
const MouseCtx = createContext({ x: 0, y: 0 });
function Provider() {
  const [pos, setPos] = useState({ x: 0, y: 0 });
  return <MouseCtx.Provider value={pos}>...</MouseCtx.Provider>;
}

// Good: use a local ref + RAF, or a library like use-mouse that subscribes per-component
```
