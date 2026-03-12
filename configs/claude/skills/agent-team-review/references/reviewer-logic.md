# LOGIC Reviewer Checklist

Specialized checklist for detecting logic errors, control flow issues, null/undefined, and race conditions.

## Control Flow

- [ ] Branch exhaustiveness: all cases covered in if/else, switch/match
- [ ] Dead code after early return
- [ ] Loop termination: infinite loops, off-by-one errors
- [ ] Misplaced break/continue/return causing fallthrough
- [ ] Nested ternary operator precedence mistakes
- [ ] Short-circuit evaluation (&&, ||) with side-effect dependencies

## Null / Undefined / None

- [ ] Accessing nullable values without null checks
- [ ] Optional chaining (?.) silently hiding undefined
- [ ] Array/map element access without existence guarantee
- [ ] Caller not checking when function can return null/undefined
- [ ] Destructuring with inappropriate default values

## Type Coercion & Comparison

- [ ] Implicit type coercion causing unexpected behavior (== vs ===, 0 == false)
- [ ] Mixed string/number arithmetic
- [ ] Falsy value handling in boolean checks (0, "", null, undefined, NaN)
- [ ] Type mismatch in comparisons

## Async / Concurrency

- [ ] Missing await on Promise-returning functions
- [ ] Race conditions: concurrent access to shared state
- [ ] Unhandled Promises (no .catch, outside try-catch)
- [ ] Deadlock potential
- [ ] Leaked event listeners (missing cleanup/unsubscribe)

## State Management

- [ ] State inconsistency: multiple sources of truth out of sync
- [ ] Mutable default arguments (Python mutable default, etc.)
- [ ] Closures capturing unintended variables
- [ ] Implicit dependency on global state

## Data Integrity

- [ ] Mutating operations (push, splice, sort) with unintended side effects on original array
- [ ] Shared object references causing unintended mutations
- [ ] Using shallow copy where deep copy is needed
- [ ] Numeric overflow / precision loss (floating-point arithmetic)

## Analysis Approach

1. Read each changed line sequentially, applying the checklist above
2. Use Read to check surrounding context (50 lines) for suspicious spots
3. Trace callers and callees to assess impact
4. Set high confidence for reproducible bugs, low for code smells
