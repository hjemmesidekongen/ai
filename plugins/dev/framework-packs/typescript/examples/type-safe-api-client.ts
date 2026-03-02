/**
 * Example: Type-safe API client
 * Pack: typescript
 * Tags: typescript, api, generics
 *
 * Demonstrates generic type parameters for request/response, discriminated
 * unions for success/error results, and type inference from function parameters.
 */

// --- Response envelope -------------------------------------------------------

type ApiSuccess<T> = { success: true; data: T; meta?: PaginationMeta }
type ApiError = { success: false; error: string; details?: unknown }
type ApiResult<T> = ApiSuccess<T> | ApiError

interface PaginationMeta {
  total: number
  page: number
  limit: number
}

// --- Client -------------------------------------------------------------------

interface RequestOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE'
  body?: unknown
  headers?: Record<string, string>
}

class ApiClient {
  constructor(
    private readonly baseUrl: string,
    private readonly defaultHeaders: Record<string, string> = {},
  ) {}

  async request<TResponse>(
    path: string,
    options: RequestOptions = {},
  ): Promise<ApiResult<TResponse>> {
    const { method = 'GET', body, headers = {} } = options

    const response = await fetch(`${this.baseUrl}${path}`, {
      method,
      headers: {
        'Content-Type': 'application/json',
        ...this.defaultHeaders,
        ...headers,
      },
      body: body !== undefined ? JSON.stringify(body) : undefined,
    })

    const json = (await response.json()) as ApiResult<TResponse>

    if (!response.ok && json.success) {
      // Defensive: treat non-2xx with success:true as an error
      return { success: false, error: `HTTP ${response.status}` }
    }

    return json
  }

  // Convenience methods — body type inferred from TBody
  get<TResponse>(path: string) {
    return this.request<TResponse>(path)
  }

  post<TResponse, TBody = unknown>(path: string, body: TBody) {
    return this.request<TResponse>(path, { method: 'POST', body })
  }

  patch<TResponse, TBody = unknown>(path: string, body: TBody) {
    return this.request<TResponse>(path, { method: 'PATCH', body })
  }

  delete<TResponse>(path: string) {
    return this.request<TResponse>(path, { method: 'DELETE' })
  }
}

// --- Usage examples (compile-time checked) -----------------------------------

interface Project {
  id: string
  name: string
  status: 'active' | 'archived'
}

const client = new ApiClient('/api', { Authorization: `Bearer ${process.env.API_TOKEN}` })

async function fetchProject(id: string): Promise<Project | null> {
  const result = await client.get<Project>(`/projects/${id}`)

  // Discriminated union — TypeScript narrows the type in each branch
  if (!result.success) {
    console.error('Failed to fetch project:', result.error)
    return null
  }

  return result.data // typed as Project
}

async function createProject(name: string): Promise<Project | null> {
  const result = await client.post<Project, { name: string }>('/projects', { name })

  if (!result.success) return null
  return result.data
}

export { ApiClient, fetchProject, createProject }
export type { ApiResult, ApiSuccess, ApiError, PaginationMeta }
