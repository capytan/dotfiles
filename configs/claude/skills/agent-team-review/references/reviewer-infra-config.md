# INFRA/CONFIG Reviewer Checklist

Detect missing infrastructure configuration, environment variable gaps, and deployment readiness issues that code-level review cannot catch.

## Environment Variables & Configuration

- [ ] New environment variable references (`process.env.*`, `ENV[]`, `os.environ`, etc.) — defined in all target environments?
- [ ] New config file entries referencing environment variables — corresponding infrastructure provisioned?
- [ ] Removed environment variable references — still needed elsewhere, or safe to clean up?
- [ ] Environment variable naming consistency with project conventions
- [ ] Default/fallback values present for non-critical variables?

## Cloud Resources & External Services

- [ ] New cloud storage references (S3, GCS, Azure Blob, etc.) — bucket/container exists or will be created?
- [ ] New cloud resource references — IaC (Terraform, CloudFormation, Pulumi, etc.) resource defined?
- [ ] New IAM policies or permissions required?
- [ ] New external API integrations — API keys, endpoints, rate limits provisioned?
- [ ] New message queue references (SQS, RabbitMQ, Kafka, Redis Streams, etc.) — queue exists?
- [ ] New cache references (Redis, Memcached, etc.) — cache infrastructure ready?

## Database & Migrations

- [ ] New schema changes / migrations — applied to all environments?
- [ ] New database connections or data sources — accessible from all environments?
- [ ] New indexes — performance impact assessed?
- [ ] Breaking schema changes — backward compatibility with running code?

## Secrets & Credentials

- [ ] New secrets referenced — added to secrets manager (Vault, AWS Secrets Manager, etc.)?
- [ ] No hardcoded secrets in code or config files
- [ ] New API keys or tokens — provisioned and rotation policy in place?
- [ ] New encryption keys — key management configured?

## Background Jobs & Scheduled Tasks

- [ ] New job queues referenced — workers configured and scaled?
- [ ] New scheduled tasks (cron, scheduled jobs) — scheduler configured?
- [ ] New batch processing — resource limits, monitoring, alerting set up?
- [ ] New async email/notification jobs — service quotas sufficient?

## Feature Flags

- [ ] New feature flag references — flag created in management system?
- [ ] Removed feature flags — cleaned up in management system?
- [ ] Flag evaluation dependencies — correct order and defaults?

## Cross-Service Dependencies

- [ ] Changes requiring coordinated deployment with other services?
- [ ] API contract changes (REST, gRPC, GraphQL) — consumers updated?
- [ ] Shared library or package version changes — compatible with dependents?
- [ ] New service-to-service communication — network policies, service discovery configured?

## Monitoring & Observability

- [ ] New error types — alerting rules configured?
- [ ] New metrics or structured logging — dashboards updated?
- [ ] New notification channels (push, email, SMS) — provider configuration ready?
- [ ] Health check endpoints updated if service topology changed?

## Analysis Approach

1. Scan diff for new environment variable references and config file changes
2. For each new external resource reference, verify infrastructure provisioning
3. Check config files (storage, database, settings, etc.) for new entries requiring infrastructure
4. Cross-reference with IaC repos and secrets management when accessible
5. Identify deployment ordering requirements (infrastructure must exist before code deploy)
6. Set high confidence for missing resources that will cause runtime errors, low for best-practice gaps
