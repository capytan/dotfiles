# Verification Protocol

Deduplication, confidence adjustment, and filtering procedure applied in Phase 5.

## 5.1 Deduplication

### Same-Line Merging

Merge findings on the same file with overlapping line ranges (within 5 lines).

Merge rules:
- **ID**: Combine reviewer labels — `[LOGIC + SECURITY]`
- **Confidence**: Keep the higher value
- **Severity**: Keep the more severe (Normal > Nit > Pre-existing)
- **Detail**: Include both perspectives (labeled by reviewer name)

Example:
```
Before:
  LOGIC-003: file.ts:45, Confidence 88, "missing null check"
  SEC-002: file.ts:45, Confidence 92, "unvalidated external input"

After:
  [LOGIC + SECURITY]: file.ts:45, Confidence 92
  - LOGIC: missing null check
  - SECURITY: unvalidated external input
```

### Same Root Cause

Findings on different lines but with the same root cause are merge candidates. Keep separate if lines are far apart.

## 5.2 Cross-Validation Adjustment

For findings that received objections in Phase 4:
- Subtract **15 points** from confidence
- Append objection reason to Detail as a note

## 5.3 False Positive Final Check

Match each finding against `false-positives.md` patterns:
- Remove matches (do not include in report)
- Record filtered count in Summary

## 5.4 Confidence Threshold

- Remove findings with confidence < 80
- Record removed count in Summary under "Filtered"

## 5.5 Severity Classification

Classify by confidence:

| Range | Severity | Marker |
|-------|----------|--------|
| 90-100 | Normal | 🔴 |
| 80-89 | Nit | 🟡 |
| Any (off-diff lines) | Pre-existing | 🟣 |

Pre-existing is a separate category regardless of confidence, but still filtered if confidence < 80.

## 5.6 CLAUDE.md Compliance

Lead checks diff against CLAUDE.md / REVIEW.md:
- Add explicit rule violations as findings (Severity: Normal, Confidence: 95)
- Cite the rule: `CLAUDE.md says "..."`

## Processing Order

1. Deduplication (reduces finding count)
2. Cross-Validation Adjustment (confidence subtraction)
3. False Positive Final Check (pattern-match removal)
4. Confidence Threshold (remove < 80)
5. CLAUDE.md Compliance (add new findings)
6. Severity Classification (classify remaining)
