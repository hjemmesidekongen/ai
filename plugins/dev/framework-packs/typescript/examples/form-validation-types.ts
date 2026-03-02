/**
 * Example: Type-safe form validation
 * Pack: typescript
 * Tags: typescript, forms, validation
 *
 * Demonstrates Zod schema with inferred types and conditional types
 * for per-field error state that mirrors the schema shape.
 */

import { z } from 'zod'

// --- Schema ------------------------------------------------------------------

export const ProjectFormSchema = z.object({
  name: z.string().min(1, 'Name is required').max(100, 'Name is too long'),
  description: z.string().max(500, 'Description is too long').optional(),
  status: z.enum(['active', 'archived'], { message: 'Invalid status' }),
  dueDate: z
    .string()
    .refine((v) => !v || !isNaN(Date.parse(v)), 'Invalid date')
    .optional(),
  tags: z.array(z.string().min(1).max(30)).max(10, 'Too many tags').default([]),
})

// Infer the form values type — stays in sync with the schema automatically
export type ProjectFormValues = z.infer<typeof ProjectFormSchema>

// --- Conditional types for field errors --------------------------------------

// Maps every field in a schema to string | undefined — matches react-hook-form shape
type FieldErrors<T extends z.ZodRawShape> = {
  [K in keyof T]?: string
}

export type ProjectFormErrors = FieldErrors<typeof ProjectFormSchema.shape>

// --- Validation helpers ------------------------------------------------------

interface ValidationResult<T> {
  success: true
  data: T
  errors: null
}

interface ValidationFailure<T extends z.ZodRawShape> {
  success: false
  data: null
  errors: FieldErrors<T>
}

type ValidateResult<T, S extends z.ZodRawShape> =
  | ValidationResult<T>
  | ValidationFailure<S>

export function validateProjectForm(
  raw: unknown,
): ValidateResult<ProjectFormValues, typeof ProjectFormSchema.shape> {
  const result = ProjectFormSchema.safeParse(raw)

  if (result.success) {
    return { success: true, data: result.data, errors: null }
  }

  // Flatten Zod errors to { fieldName: firstErrorMessage }
  const flat = result.error.flatten().fieldErrors
  const errors: ProjectFormErrors = {}

  for (const [key, messages] of Object.entries(flat)) {
    if (messages?.[0]) {
      errors[key as keyof ProjectFormErrors] = messages[0]
    }
  }

  return { success: false, data: null, errors }
}

// --- Default values ----------------------------------------------------------

export const projectFormDefaults: ProjectFormValues = {
  name: '',
  description: undefined,
  status: 'active',
  dueDate: undefined,
  tags: [],
}
