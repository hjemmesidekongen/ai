# /skjalden:content-write

Draft brand-aware written content with automated quality checks.

## Usage

```
/skjalden:content-write
/skjalden:content-write README
/skjalden:content-write landing-page
/skjalden:content-write blog-post
/skjalden:content-write social linkedin
/skjalden:content-write email newsletter
/skjalden:content-write marketing
```

## Behavior

Dispatches to the `content-writer` agent, which orchestrates intake, brand loading,
knowledge skill activation, drafting, and quality gates. If no content type is
specified, the agent asks interactively.

The agent loads brand context automatically when a brand exists at `.ai/brand/`.
It activates knowledge skills based on content type (web-copywriting, seo-fundamentals,
brand-voice-implementation, content-strategy-patterns, marketing-psychology-patterns,
or social-media-patterns) and runs 5 quality gate checks (voice, AI patterns, structure,
claims, scannability) before delivering the draft.
