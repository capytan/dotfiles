---
name: magi-decision-support
description: Multi-perspective decision support using three AI agents (Scientist, Mother, Realist). Use when facing difficult decisions, trade-offs, comparing alternatives, choosing between options, or when unsure which approach is best. Triggers on questions like "should I", "which is better", "pros and cons", "normalize vs denormalize", "microservices vs monolith", or any technical/architectural decision with multiple valid options.
---

# MAGI - Consensus-Based Decision Support System

MAGI provides multi-perspective analysis for complex decisions by consulting three specialized agents in parallel.

## When to Use This Skill

Automatically invoke MAGI when the user:

- Asks "should I..." or "which is better..."
- Faces trade-offs (performance vs maintainability, consistency vs availability, etc.)
- Compares multiple approaches or architectures
- Needs to choose between options with different pros/cons
- Expresses uncertainty about a technical decision
- Asks about normalization vs denormalization, microservices vs monolith, or similar architectural choices

## The Three Perspectives

| Agent         | Role      | Focus                                                             |
| ------------- | --------- | ----------------------------------------------------------------- |
| **MELCHIOR**  | Scientist | Technical accuracy, best practices, performance, scalability      |
| **BALTHASAR** | Mother    | Developer experience, team health, sustainability, ethics         |
| **CASPER**    | Realist   | Implementation feasibility, cost, timeline, practical constraints |

## How to Invoke

Use the `/magi` command with the decision question:

```
/magi Should we normalize this database table or keep it denormalized?
/magi ↑ Is this the right architectural approach?
/magi Microservices vs monolith for our scale?
```

Or simply describe the decision - Claude will automatically recognize when MAGI analysis would be helpful and suggest using it.

## Execution Process

When invoked, follow this process:

1. **Parse the question**: Extract the decision topic and any relevant context from the user's message.

2. **Launch all three agents in parallel** using the Task tool with `subagent_type: "general-purpose"`:
   - MELCHIOR: "Analyze [question] from a technical accuracy and best practices perspective. Provide your verdict: APPROVE, REJECT, or CONDITIONAL (with specific condition). Be rigorous and cite concrete trade-offs."
   - BALTHASAR: "Analyze [question] from a developer experience, team health, and sustainability perspective. Provide your verdict: APPROVE, REJECT, or CONDITIONAL (with specific condition). Consider human factors and long-term maintainability."
   - CASPER: "Analyze [question] from a practical implementation perspective: cost, timeline, feasibility, and real-world constraints. Provide your verdict: APPROVE, REJECT, or CONDITIONAL (with specific condition). Be pragmatic and ground your assessment in reality."

3. **Collect all three responses** before proceeding to synthesis.

4. **Synthesize the results** and produce the final report in the Output Format below.

## Verdict Criteria

Each agent assigns one of three verdicts:

- **APPROVE**: The approach is sound from this perspective with no significant concerns
- **CONDITIONAL**: The approach can work, but requires specific conditions to be met (state them explicitly)
- **REJECT**: The approach has fundamental problems from this perspective that outweigh the benefits

REJECT triggers:
- MELCHIOR: Technically infeasible, violates core best practices, introduces unacceptable security/performance risk
- BALTHASAR: Unsustainable long-term, causes significant team harm, ethical concerns
- CASPER: Not implementable within realistic constraints, cost/complexity far exceeds benefit

## Consensus Rules

Determine consensus from the three verdicts (APPROVE=1, CONDITIONAL=0.5, REJECT=0):

| Verdicts | Result |
|----------|--------|
| 3× APPROVE | **UNANIMOUS APPROVAL** — Proceed confidently |
| 2× APPROVE + 1× CONDITIONAL | **MAJORITY APPROVAL** — Proceed with noted conditions |
| 2× APPROVE + 1× REJECT | **MAJORITY APPROVAL (contested)** — Proceed, but address the dissent |
| 1× APPROVE + 2× CONDITIONAL | **CONDITIONAL APPROVAL** — Proceed only if conditions are met |
| Any 2× REJECT | **MAJORITY REJECTION** — Do not proceed without major revision |
| 3× REJECT | **UNANIMOUS REJECTION** — Abandon this approach |
| 1× each APPROVE/CONDITIONAL/REJECT | **SPLIT DECISION** — No consensus; present trade-offs and let user decide |

## Output Format

MAGI produces a structured analysis report:

1. **Individual Agent Analysis**: Each agent provides their perspective and verdict (APPROVE/REJECT/CONDITIONAL with reasoning)
2. **Consensus**: Apply the Consensus Rules table above to determine the result
3. **Key Trade-offs**: Areas where perspectives differ significantly
4. **Final Recommendation**: Synthesized recommendation with reasoning and next steps

## Best Practices

- Provide sufficient context (code, requirements, constraints) before invoking
- Use `↑` to reference previous messages or code blocks
- Consider all three verdicts, not just the majority
- Pay special attention to dissenting opinions - they often reveal blind spots
