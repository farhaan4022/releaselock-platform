# ReleaseLock

ReleaseLock is an AWS secure-release engineering project built around a real
InvenTree workload running on ECS Fargate.

The core engineering question is:

Can a compromised or over-privileged build/release identity bypass independent
approval, deploy an unauthorized container digest, or select a more privileged
ECS task role?

The project deliberately separates:

- candidate build identity
- independent approval identity
- release requester identity
- AWS release authority
- application runtime identity

The project is complete only after the five defined before/after experiments
have been executed against real AWS authorization controls and a legitimate
approved release still succeeds.

## Core experiments

1. GitHub OIDC trust that is too broad
2. Scan image A but deploy image B through a mutable tag
3. Bypass a green pipeline using direct ECS APIs
4. Reduce compromised-workload IAM blast radius
5. Fail closed when security evidence is missing, stale or invalid

## Out of scope

- Kubernetes
- multi-account security architecture
- deployment portals
- general-purpose release platforms
- DynamoDB deployment state machines
- advanced revocation/replay systems
- full incident-response platform
- advanced egress security
- additional observability stacks
- disaster-recovery engineering
