# EDGE Reviewer Checklist

Systematic detection of boundary conditions, empty inputs, concurrent access, and type mismatches. Find "works on my machine" bugs.

## Empty & Null Inputs

- [ ] Empty string "" handling
- [ ] Empty array [] / empty object {} handling
- [ ] null / undefined / None passed as argument
- [ ] Empty file, zero-byte input handling
- [ ] Default behavior when parameters are omitted

## Boundary Values

- [ ] 0, -1, 1 (zero, negative, smallest positive)
- [ ] Integer max/min values (MAX_SAFE_INTEGER, overflow)
- [ ] First / last element access in arrays
- [ ] Pagination: first page, last page, single item
- [ ] String length upper / lower bounds
- [ ] Dates: leap year, month-end, year-end, timezone boundary, DST transition

## Collection Operations

- [ ] Single-element array with reduce / sort / filter
- [ ] Arrays with duplicate elements
- [ ] Very large collections (memory / performance)
- [ ] Off-by-one indexing (0-based vs 1-based)
- [ ] Map / Set with object keys (reference comparison)

## String Handling

- [ ] Unicode: multibyte characters, emoji, combining characters
- [ ] Whitespace: space, tab, newline, zero-width space
- [ ] Special characters: quotes, backslash, NUL byte
- [ ] Encoding: mixed UTF-8 / Latin-1
- [ ] Normalization mismatch (NFC vs NFD)

## Numeric Edge Cases

- [ ] Floating-point precision (0.1 + 0.2 !== 0.3)
- [ ] NaN propagation and comparison (NaN !== NaN)
- [ ] Infinity / -Infinity handling
- [ ] Division by zero
- [ ] Mixed signed / unsigned integers

## Concurrent Access

- [ ] Simultaneous access to same resource (file, DB record)
- [ ] Cache stampede (thundering herd)
- [ ] Duplicate event handler execution
- [ ] Order dependency in async operations

## Environment & Platform

- [ ] OS differences: path separator (/ vs \), line endings (LF vs CRLF)
- [ ] Filesystem: case sensitivity, permissions
- [ ] Network: timeout, connection drop, latency
- [ ] Memory: OOM potential with large datasets

## Analysis Approach

1. Identify input parameters at each change site and apply boundary values
2. Ask "does this break with this input?" for each checklist item
3. Use Read to check type definitions and input constraints in full files
4. Consider differences between dev and production (data volume, concurrency)
5. Set high confidence for "will definitely occur", low for "only in rare environments"
