---
origin: "wshobson/agents"
origin_skill: "javascript-testing-patterns"
origin_version: "1.0.0"
forked_date: "2026-03-02"
sections_kept: "Vitest setup, Unit Testing Patterns (pure functions, classes, async), Mocking Patterns (module mocking, dependency injection, spies), Frontend Testing with React Testing Library (component testing, hook testing), Test Fixtures with faker.js, Best Practices"
sections_removed: "Jest setup (we use Vitest), Integration testing with supertest (too API-specific per findings.md), Snapshot testing (controversial pattern per findings.md), Database integration tests"
---

# JavaScript Testing Patterns

Unit testing, mocking, and React Testing Library patterns. Uses Vitest as the primary framework.

> See also: `test-driven-development.md` for TDD methodology (Red-Green-Refactor, Iron Law, when to write tests). This skill covers mechanics.

## Vitest Setup

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: ['**/*.d.ts', '**/*.config.ts', '**/dist/**'],
      thresholds: {
        branches: 80,
        functions: 80,
        lines: 80,
        statements: 80,
      },
    },
    setupFiles: ['./src/test/setup.ts'],
  },
})
```

```json
// package.json scripts
{
  "test": "vitest",
  "test:coverage": "vitest --coverage",
  "test:ui": "vitest --ui"
}
```

## Unit Testing Patterns

### Testing Pure Functions

```typescript
// utils/calculator.ts
export function divide(a: number, b: number): number {
  if (b === 0) throw new Error('Division by zero')
  return a / b
}

// utils/calculator.test.ts
import { describe, it, expect } from 'vitest'
import { divide } from './calculator'

describe('divide', () => {
  it('divides two numbers', () => {
    expect(divide(10, 2)).toBe(5)
  })

  it('handles decimal results', () => {
    expect(divide(5, 2)).toBe(2.5)
  })

  it('throws on division by zero', () => {
    expect(() => divide(10, 0)).toThrow('Division by zero')
  })
})
```

### Testing Classes

```typescript
// services/user.service.test.ts
import { describe, it, expect, beforeEach } from 'vitest'
import { UserService } from './user.service'

describe('UserService', () => {
  let service: UserService

  beforeEach(() => {
    service = new UserService()  // Fresh instance per test
  })

  describe('create', () => {
    it('creates a new user', () => {
      const user = { id: '1', name: 'John', email: 'john@example.com' }
      const created = service.create(user)
      expect(created).toEqual(user)
    })

    it('throws if user already exists', () => {
      const user = { id: '1', name: 'John', email: 'john@example.com' }
      service.create(user)
      expect(() => service.create(user)).toThrow('User already exists')
    })
  })
})
```

### Testing Async Functions

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest'

global.fetch = vi.fn()

describe('ApiService', () => {
  beforeEach(() => vi.clearAllMocks())

  it('fetches user successfully', async () => {
    const mockUser = { id: '1', name: 'John' }
    vi.mocked(fetch).mockResolvedValueOnce({
      ok: true,
      json: async () => mockUser,
    } as Response)

    const user = await service.fetchUser('1')
    expect(user).toEqual(mockUser)
  })

  it('throws on 404', async () => {
    vi.mocked(fetch).mockResolvedValueOnce({ ok: false } as Response)
    await expect(service.fetchUser('999')).rejects.toThrow('User not found')
  })
})
```

## Mocking Patterns

### Mocking Modules

```typescript
// Mock nodemailer entirely
vi.mock('nodemailer', () => ({
  default: {
    createTransport: vi.fn(() => ({
      sendMail: vi.fn().mockResolvedValue({ messageId: '123' }),
    })),
  },
}))

describe('EmailService', () => {
  it('sends email', async () => {
    await service.sendEmail('test@example.com', 'Subject', '<p>Body</p>')
    expect(service['transporter'].sendMail).toHaveBeenCalledWith(
      expect.objectContaining({ to: 'test@example.com' })
    )
  })
})
```

### Dependency Injection (Preferred over Module Mocking)

```typescript
// services/user.service.ts
export interface IUserRepository {
  findById(id: string): Promise<User | null>
  create(user: User): Promise<User>
}

export class UserService {
  constructor(private userRepository: IUserRepository) {}

  async getUser(id: string): Promise<User> {
    const user = await this.userRepository.findById(id)
    if (!user) throw new Error('User not found')
    return user
  }
}

// services/user.service.test.ts
describe('UserService', () => {
  let service: UserService
  let mockRepository: IUserRepository

  beforeEach(() => {
    mockRepository = {
      findById: vi.fn(),
      create: vi.fn(),
    }
    service = new UserService(mockRepository)
  })

  it('returns user if found', async () => {
    const mockUser = { id: '1', name: 'John', email: 'john@example.com' }
    vi.mocked(mockRepository.findById).mockResolvedValue(mockUser)

    const user = await service.getUser('1')

    expect(user).toEqual(mockUser)
    expect(mockRepository.findById).toHaveBeenCalledWith('1')
  })

  it('throws if user not found', async () => {
    vi.mocked(mockRepository.findById).mockResolvedValue(null)
    await expect(service.getUser('999')).rejects.toThrow('User not found')
  })
})
```

### Spying on Functions

```typescript
import { vi, beforeEach, afterEach } from 'vitest'
import { logger } from '../utils/logger'

describe('OrderService', () => {
  let loggerSpy: ReturnType<typeof vi.spyOn>

  beforeEach(() => {
    loggerSpy = vi.spyOn(logger, 'info')
  })

  afterEach(() => loggerSpy.mockRestore())

  it('logs order processing', async () => {
    await service.processOrder('123')
    expect(loggerSpy).toHaveBeenCalledWith('Processing order 123')
    expect(loggerSpy).toHaveBeenCalledTimes(2)
  })
})
```

## React Testing Library

### Component Testing

```typescript
// components/UserForm.test.tsx
import { render, screen, fireEvent } from '@testing-library/react'
import { describe, it, expect, vi } from 'vitest'
import userEvent from '@testing-library/user-event'
import { UserForm } from './UserForm'

describe('UserForm', () => {
  it('renders form inputs', () => {
    render(<UserForm onSubmit={vi.fn()} />)
    expect(screen.getByPlaceholderText('Name')).toBeInTheDocument()
    expect(screen.getByPlaceholderText('Email')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Submit' })).toBeInTheDocument()
  })

  it('calls onSubmit with form data', async () => {
    const user = userEvent.setup()
    const onSubmit = vi.fn()
    render(<UserForm onSubmit={onSubmit} />)

    await user.type(screen.getByTestId('name-input'), 'John Doe')
    await user.type(screen.getByTestId('email-input'), 'john@example.com')
    await user.click(screen.getByRole('button', { name: 'Submit' }))

    expect(onSubmit).toHaveBeenCalledWith({
      name: 'John Doe',
      email: 'john@example.com',
    })
  })
})
```

**Query priority (use semantic queries):**
```typescript
// ✅ Preferred (accessible)
screen.getByRole('button', { name: 'Submit' })
screen.getByLabelText('Email')
screen.getByPlaceholderText('Search...')
screen.getByText('Welcome')

// Use sparingly
screen.getByTestId('submit-button')
```

### Testing Hooks

```typescript
import { renderHook, act } from '@testing-library/react'
import { useCounter } from './useCounter'

describe('useCounter', () => {
  it('initializes with default value', () => {
    const { result } = renderHook(() => useCounter())
    expect(result.current.count).toBe(0)
  })

  it('increments count', () => {
    const { result } = renderHook(() => useCounter())
    act(() => { result.current.increment() })
    expect(result.current.count).toBe(1)
  })

  it('resets to initial value', () => {
    const { result } = renderHook(() => useCounter(10))
    act(() => { result.current.increment() })
    act(() => { result.current.reset() })
    expect(result.current.count).toBe(10)
  })
})
```

## Test Fixtures with Faker

```typescript
// tests/fixtures/user.fixture.ts
import { faker } from '@faker-js/faker'

export function createUserFixture(overrides?: Partial<User>): User {
  return {
    id: faker.string.uuid(),
    name: faker.person.fullName(),
    email: faker.internet.email(),
    createdAt: faker.date.past(),
    ...overrides,
  }
}

export function createUsersFixture(count: number): User[] {
  return Array.from({ length: count }, () => createUserFixture())
}

// Usage
const user = createUserFixture({ name: 'John Doe' })  // Known name, random rest
const users = createUsersFixture(10)                   // 10 random users
```

## Testing Timers

```typescript
import { vi } from 'vitest'

it('calls function after delay', () => {
  vi.useFakeTimers()
  const callback = vi.fn()
  setTimeout(callback, 1000)

  expect(callback).not.toHaveBeenCalled()
  vi.advanceTimersByTime(1000)
  expect(callback).toHaveBeenCalled()

  vi.useRealTimers()
})
```

## Best Practices

1. **AAA Pattern**: Arrange, Act, Assert — clear test structure
2. **One assertion per test** (or logically related assertions)
3. **Test behavior, not implementation** — test what, not how
4. **Use `beforeEach` for fresh setup** — prevent test pollution
5. **Mock external dependencies** — keep tests fast and isolated
6. **Test edge cases** — empty arrays, null, max/min values
7. **Use factories for test data** — consistent, minimal setup
8. **Keep tests fast** — mock I/O operations
9. **Prefer semantic queries** — `getByRole` over `getByTestId`
10. **Aim for 80%+ coverage** — enforce with `coverageThresholds`
11. **No `console.log` in tests** — use assertions to verify state
