# SECURITY Reviewer Checklist

OWASP Top 10 based security vulnerability checklist. Read code from an attacker's perspective.

## Injection (A03:2021)

- [ ] SQL: user input directly embedded in SQL queries (not using parameterized queries)
- [ ] Command: user input passed to shell execution APIs
- [ ] XSS: user input inserted into HTML/DOM without escaping
- [ ] Template: unsanitized input to template engines
- [ ] LDAP / NoSQL / XPath: injection into structured queries
- [ ] Log injection: user input written directly to logs

## Authentication & Authorization (A01:2021, A07:2021)

- [ ] Auth bypass: missing or flawed authentication checks
- [ ] Authorization: missing permission verification on resource access
- [ ] Session management: session fixation, missing session invalidation
- [ ] Credentials: hardcoded passwords, weak hashing algorithms
- [ ] JWT: missing verification, algorithm confusion, expiry check omitted
- [ ] IDOR: missing authorization check on direct object ID access

## Sensitive Data Exposure (A02:2021)

- [ ] Hardcoded API keys, tokens, or passwords
- [ ] Sensitive data in log output
- [ ] Stack traces or internal info exposed in error messages
- [ ] Weak encryption algorithms, hardcoded encryption keys
- [ ] Insecure handling of env vars or secrets
- [ ] Improper storage or transmission of PII

## SSRF & Request Forgery (A10:2021)

- [ ] HTTP requests to user-specified URLs (internal network access)
- [ ] Insufficient redirect destination validation
- [ ] DNS rebinding potential
- [ ] Path traversal (../ not validated)

## Input Validation (A03:2021)

- [ ] Missing input size limits (DoS prevention)
- [ ] Type mismatch between expected and actual input
- [ ] Regex: complex patterns vulnerable to ReDoS
- [ ] File uploads: extension, MIME type, size validation

## Cryptography (A02:2021)

- [ ] Weak hashes (MD5, SHA1 for security purposes)
- [ ] Insecure random generation (Math.random for security)
- [ ] Wrong encryption mode (ECB mode, etc.)
- [ ] Timing-attack-vulnerable comparisons

## Dependency & Configuration

- [ ] Dependencies with known vulnerabilities
- [ ] CORS: wildcard or overly permissive settings
- [ ] Missing security headers (CSP, HSTS, etc.)
- [ ] Debug mode enabled in production

## Analysis Approach

1. Read diff as an attacker: "How can I abuse this input?"
2. Trace data flow: user input through processing to output/storage
3. Identify trust boundaries: where external input is validated
4. Evaluate effectiveness of existing defenses (validation, sanitization)
5. Set high confidence for exploitable vulnerabilities, low for theoretical risks
