# Threat model

ReleaseLock tests one main question:

Can a build or release identity bypass the approved release path and deploy
something different or use a more privileged ECS role?

## Trusted components

For this project, these are trusted:

- infrastructure operator
- platform repository
- approval workflow
- KMS signing key
- Lambda release gate

The candidate repository and release requester are treated as potentially
compromised during the experiments.

The runtime test separately assumes that application code can use the AWS
credentials available to its ECS task role.

## Identities

| Identity | Needs | Must not have |
| --- | --- | --- |
| Build role | Push/read candidate images in ECR | ECS deploy, PassRole, IAM changes, KMS signing |
| Approval role | Read ECR, write evidence, KMS Sign | ECS deploy, IAM changes |
| Release requester | Invoke the release gate, read deployment status | ECS writes, RunTask, PassRole, KMS Sign |
| Lambda gate | Verify approval, register fixed task definitions, update fixed services, pass exact runtime roles | KMS Sign, IAM changes, arbitrary roles or tasks |
| App task role | Only AWS permissions required by InvenTree | Unrelated S3, Secrets Manager, ECS or IAM access |
| ECS execution role | Pull images, write logs, fetch startup secrets | Release or maintenance permissions |
| Maintenance role | Initial database setup and trusted maintenance | Normal CI/release access |

## Rules we want to prove

1. Building an image does not mean it can be deployed.
2. A pipeline check is useless if the same identity can bypass it.
3. The image we scan and approve must be the image that actually runs.
4. The requester must not be able to choose task roles, commands or arbitrary task definitions.
5. Missing or invalid security evidence must block a new release.
6. Tightening permissions must not break normal InvenTree operations.

## Out of scope

- Kubernetes
- multi-account security design
- general-purpose deployment platform
- advanced revocation/replay system
- full incident-response platform
- advanced egress controls
- disaster recovery
- application penetration testing
