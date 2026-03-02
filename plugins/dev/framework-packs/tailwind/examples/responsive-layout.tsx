/**
 * Example: Responsive grid layout with Tailwind v4
 * Pack: tailwind
 * Tags: tailwind, responsive, layout
 *
 * Demonstrates mobile-first responsive breakpoints and Tailwind v4
 * container queries for component-level responsiveness.
 */

interface Project {
  id: string
  name: string
  description: string
  status: 'active' | 'archived'
  memberCount: number
}

interface ProjectGridProps {
  projects: Project[]
  isLoading?: boolean
}

// Page-level responsive grid — breakpoints control column count globally
export function ProjectGrid({ projects, isLoading }: ProjectGridProps) {
  if (isLoading) {
    return (
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
        {Array.from({ length: 8 }).map((_, i) => (
          <div key={i} className="h-40 rounded-[--radius-lg] bg-[--color-muted] animate-pulse" />
        ))}
      </div>
    )
  }

  return (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
      {projects.map((project) => (
        <ProjectCard key={project.id} project={project} />
      ))}
    </div>
  )
}

// Component with @container query — responds to its own width, not viewport
// Useful when the card appears in both a wide grid and a narrow sidebar
function ProjectCard({ project }: { project: Project }) {
  return (
    // Mark as a container so children can use @container queries
    <article className="@container rounded-[--radius-lg] border border-[--color-border] bg-[--color-card] p-4 shadow-sm">
      {/* Stack vertically at narrow widths, row at wider @container sizes */}
      <div className="flex flex-col gap-3 @sm:flex-row @sm:items-start">
        <div className="flex-1 min-w-0">
          <h3 className="truncate font-medium text-[--color-card-foreground]">
            {project.name}
          </h3>
          {/* Description visible only when container is at least @sm wide */}
          <p className="mt-1 hidden text-sm text-[--color-muted-foreground] line-clamp-2 @sm:block">
            {project.description}
          </p>
        </div>

        <StatusBadge status={project.status} />
      </div>

      <footer className="mt-3 flex items-center justify-between text-xs text-[--color-muted-foreground]">
        <span>{project.memberCount} members</span>
      </footer>
    </article>
  )
}

function StatusBadge({ status }: { status: Project['status'] }) {
  return (
    <span
      className={`shrink-0 rounded-full px-2 py-0.5 text-xs font-medium ${
        status === 'active'
          ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400'
          : 'bg-[--color-muted] text-[--color-muted-foreground]'
      }`}
    >
      {status}
    </span>
  )
}
