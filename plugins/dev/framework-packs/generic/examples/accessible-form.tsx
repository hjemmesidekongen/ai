/**
 * Example: Accessible form component
 * Pack: generic
 * Tags: accessibility, forms, wcag
 *
 * Demonstrates proper labels and ARIA attributes, live region error
 * announcements for screen readers, keyboard navigation, and focus
 * management on submission — all per WCAG 2.1 AA.
 */

import { useId, useRef, useState } from 'react'
import { validateProjectForm, type ProjectFormValues } from '@/lib/form-validation'

interface ProjectFormProps {
  onSubmit: (values: ProjectFormValues) => Promise<void>
}

export function ProjectForm({ onSubmit }: ProjectFormProps) {
  // useId ensures stable, unique IDs across SSR and client — no collision risk
  const nameId = useId()
  const descriptionId = useId()
  const statusId = useId()
  const nameErrorId = useId()
  const descriptionErrorId = useId()
  const statusErrorId = useId()
  const formMessageId = useId()

  const [errors, setErrors] = useState<Partial<Record<keyof ProjectFormValues, string>>>({})
  const [formMessage, setFormMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)

  // Focus ref — move focus to the form heading on validation failure
  const headingRef = useRef<HTMLHeadingElement>(null)

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()

    const formData = new FormData(event.currentTarget)
    const raw = Object.fromEntries(formData)
    const result = validateProjectForm(raw)

    if (!result.success) {
      setErrors(result.errors)
      setFormMessage({ type: 'error', text: 'Please fix the errors below.' })
      // Move focus to the heading so screen readers re-read the form state
      headingRef.current?.focus()
      return
    }

    setErrors({})
    setIsSubmitting(true)

    try {
      await onSubmit(result.data)
      setFormMessage({ type: 'success', text: 'Project created successfully.' })
    } catch {
      setFormMessage({ type: 'error', text: 'Something went wrong. Please try again.' })
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} noValidate aria-labelledby="form-heading">
      {/* tabIndex={-1} allows programmatic focus without appearing in tab order */}
      <h2 id="form-heading" ref={headingRef} tabIndex={-1} className="text-lg font-semibold mb-4 focus:outline-none">
        Create Project
      </h2>

      {/* Live region — announced immediately by screen readers when content changes */}
      {formMessage && (
        <div
          id={formMessageId}
          role="alert"
          aria-live="assertive"
          className={`mb-4 rounded p-3 text-sm ${
            formMessage.type === 'success' ? 'bg-green-50 text-green-800' : 'bg-red-50 text-red-800'
          }`}
        >
          {formMessage.text}
        </div>
      )}

      <div className="space-y-4">
        {/* Name field — label + input explicitly associated via htmlFor/id */}
        <div>
          <label htmlFor={nameId} className="block text-sm font-medium mb-1">
            Project name <span aria-hidden="true">*</span>
            <span className="sr-only">(required)</span>
          </label>
          <input
            id={nameId}
            name="name"
            type="text"
            required
            aria-required="true"
            aria-describedby={errors.name ? nameErrorId : undefined}
            aria-invalid={!!errors.name}
            className="w-full rounded border border-border px-3 py-2 text-sm"
          />
          {errors.name && (
            <p id={nameErrorId} role="alert" className="mt-1 text-xs text-destructive">
              {errors.name}
            </p>
          )}
        </div>

        {/* Description — optional, no aria-required */}
        <div>
          <label htmlFor={descriptionId} className="block text-sm font-medium mb-1">
            Description
          </label>
          <textarea
            id={descriptionId}
            name="description"
            rows={3}
            aria-describedby={errors.description ? descriptionErrorId : undefined}
            aria-invalid={!!errors.description}
            className="w-full rounded border border-border px-3 py-2 text-sm"
          />
          {errors.description && (
            <p id={descriptionErrorId} role="alert" className="mt-1 text-xs text-destructive">
              {errors.description}
            </p>
          )}
        </div>

        {/* Status select */}
        <div>
          <label htmlFor={statusId} className="block text-sm font-medium mb-1">
            Status
          </label>
          <select
            id={statusId}
            name="status"
            defaultValue="active"
            aria-describedby={errors.status ? statusErrorId : undefined}
            aria-invalid={!!errors.status}
            className="w-full rounded border border-border px-3 py-2 text-sm"
          >
            <option value="active">Active</option>
            <option value="archived">Archived</option>
          </select>
          {errors.status && (
            <p id={statusErrorId} role="alert" className="mt-1 text-xs text-destructive">
              {errors.status}
            </p>
          )}
        </div>
      </div>

      <button
        type="submit"
        disabled={isSubmitting}
        aria-busy={isSubmitting}
        className="mt-6 rounded bg-primary px-4 py-2 text-sm font-medium text-primary-foreground disabled:opacity-50"
      >
        {isSubmitting ? 'Creating...' : 'Create project'}
      </button>
    </form>
  )
}
