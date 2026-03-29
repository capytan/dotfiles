# Confidence Scoring Rubric

Score this issue on a scale from 0-100, indicating your level of confidence:

- 0: Not confident at all. This is a false positive that doesn't stand up to
  light scrutiny, or is a pre-existing issue.
- 25: Somewhat confident. This might be a real issue, but may also be a false
  positive. You weren't able to verify that it's real. If stylistic, it was
  not explicitly called out in the relevant CLAUDE.md.
- 50: Moderately confident. You were able to verify this is a real issue, but
  it might be a nitpick or not happen very often in practice. Relative to the
  rest of the changes, it's not very important.
- 75: Highly confident. You double checked the issue, and verified that it is
  very likely real and will be hit in practice. The existing approach is
  insufficient. Very important and will directly impact functionality, or is
  directly mentioned in the relevant CLAUDE.md.
- 100: Absolutely certain. You double checked the issue, and confirmed that it
  is definitely real and will happen frequently in practice. The evidence
  directly confirms this.

For issues flagged due to CLAUDE.md instructions: double check that the CLAUDE.md
actually calls out that issue specifically.
