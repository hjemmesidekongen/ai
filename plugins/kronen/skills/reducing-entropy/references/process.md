# Reducing Entropy — Process Reference

## Additional Red Flags

- Adding a new file when an existing one could absorb the logic.
- Creating infrastructure "for consistency" when the use case is singular.

## When This Doesn't Apply

- First implementation of genuinely new functionality (you're adding, not maintaining).
- Security fixes that require additional validation code.
- Test coverage for untested critical paths (tests are an acceptable entropy cost).
- Legal/compliance requirements that mandate specific code.

Even in these cases, write the minimum viable version first.
