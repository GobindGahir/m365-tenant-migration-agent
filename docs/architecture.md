# Architecture

## Flow

```mermaid
flowchart LR
    Config["Agent config"] --> Source["Source tenant discovery"]
    Source --> Inventory["Inventory model"]
    Inventory --> Plan["Migration plan engine"]
    Plan --> DryRun["Dry-run reports"]
    Plan --> Execute{"-Execute?"}
    Execute -->|No| DryRun
    Execute -->|Yes| Target["Target tenant provisioning"]
    Target --> Audit["Audit log"]
    DryRun --> Audit
```

## Design Principles

- Read-only source tenant access.
- Target tenant writes only when `-Execute` is specified.
- Plan first, execute second.
- Idempotency checks before supported writes.
- Reports are generated for review and approval.
- Data migration is intentionally out of scope.

