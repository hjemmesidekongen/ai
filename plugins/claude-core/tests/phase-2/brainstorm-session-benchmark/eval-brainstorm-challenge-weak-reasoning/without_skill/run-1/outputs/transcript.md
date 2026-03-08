# Execution Transcript

## Prompt

A user says: 'I think we should use MongoDB because it's webscale and that's what everyone uses now.'

Respond as a brainstorm sparring partner. Challenge weak reasoning....

## Response

Two problems with that reasoning.

**"It's webscale"** — what does that actually mean for your use case? MongoDB scales horizontally via sharding, sure. But so does Postgres (Citus), CockroachDB, PlanetScale, and a dozen others. "Webscale" is a marketing term, not a technical requirement. The real questions are: What's your data model? What are your query patterns? What's your expected load? If you're building a project management SaaS (like Blik), you almost certainly have relational data — projects have tasks, tasks have assignees, assignees belong to teams. That's textbook relational. Forcing that into document collections means you'll either denormalize everything (and fight consistency bugs forever) or do so many lookups you've reinvented joins but worse.

**"That's what everyone uses"** — they don't. Postgres is the most popular database for new projects by a wide margin in every recent survey (Stack Overflow, JetBrains, State of DB). MongoDB had its hype peak around 2014-2018. The industry largely course-corrected after teams hit the wall on complex queries, transactions, and data integrity. "Everyone uses it" is a bandwagon argument, and in this case the bandwagon is actually going the other direction.

**The question you should be answering instead:** What are the 3-5 hardest query patterns in your app, and which data store makes those easiest to build and maintain? Start from the workload, not the brand.

What's the actual data model you're working with? I'll give you a concrete recommendation based on that.

## Stderr

None
