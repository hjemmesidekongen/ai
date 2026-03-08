# Execution Transcript

## Prompt

You are executing the 'brainstorm-session' skill. Follow these instructions:

# SKILL.md

---
name: brainstorm-session
user_invocable: false
interactive: true
depends_on: []
reads: []
writes:
  - ".ai/brainstorm/{topic}/brainstorm-state.yml"
  - ".ai/brainstorm/{topic}/brainstorm-transcript-{date}.md"
checkpoint: data_validation
model_tier: principal
_source:
  origin: "claude-core"
  inspired_by: "task-planner/brainstorm-session"
  iteration: 1
  changes: "Optional context loading, cleaner stat...

## Response

Alright, let me skip the file setup for now and get straight into the brainstorm. I'll save state once we're done.

---

Honestly? You're framing this as three equal options, and they're not. JWT, session cookies, and OAuth aren't even in the same category — they solve different problems, and two of them often work together.

**OAuth** is an authorization framework. It answers "how does a third-party get access on behalf of a user." If you're not doing third-party login (Google, GitHub sign-in) or building an API that other apps consume, OAuth isn't really a choice here — it's a non-requirement.

**JWT vs session cookies** is the real question, and it comes down to: where does your session state live?

- **Session cookies**: state lives on the server. The cookie is just an opaque ID. You get easy revocation, simple invalidation on logout, and the browser handles the security for you (HttpOnly, SameSite, Secure flags). The tradeoff is server-side storage and stickiness if you scale horizontally.

- **JWT**: state lives in the token itself. Stateless, scales easily across services, no session store needed. But revocation is a nightmare — the token is valid until it expires. You end up building a token blacklist, which is just... a session store with extra steps.

So before I push harder in either direction: what are you actually building? Is this a single web app, a multi-service architecture, a mobile + web situation? And do you need third-party login?

The answer to those questions changes the recommendation completely.

## Stderr

None
