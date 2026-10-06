# ReleaseLock Threat Model

## Engineering question

Can a compromised or over-privileged candidate build or release-request
identity bypass independent approval, deploy an unauthorized container digest,
or select a more privileged ECS task role?

ReleaseLock is designed to test that question against real AWS authorization
controls.

## Trust assumptions

ReleaseLock Core trusts:

- the human infrastructure operator
- the protected platform repository
- the independent approval workflow
- the KMS signing authority
- the Lambda release gate implementation

ReleaseLock does not attempt to protect the environment from an AWS account
administrator who is intentionally changing or bypassing those controls.

The candidate repository and normal release requester are treated as
potentially compromised for the purpose of the experiments.

The runtime experiment separately assumes that application code has obtained
the credentials available to its ECS task role.

## Identities and intended permissions

| Identity | Required access | Must not have |
| --- | --- | --- |
| Human infrastructure operator | Terraform, bootstrap, trusted maintenance | Credentials exposed to candidate CI |
| Candidate build role | Push/read designated ECR repositories | ECS mutation, iam:PassRole, IAM changes, KMS signing, approval writes |
| Approval role | Read candidate ECR images, write evidence, KMS Sign | ECS mutation, IAM changes, gate modification |
| Release requester | Invoke the fixed Lambda release gate and read deployment status | RegisterTaskDefinition, UpdateService, RunTask, iam:PassRole, KMS Sign |
| Lambda gate role | Validate approved evidence, KMS Verify, register fixed task definitions, update two fixed ECS services, pass exact runtime/execution roles | KMS Sign, arbitrary RunTask, IAM mutation, stronger maintenance roles, self modification |
| Application task role | Only AWS API permissions actually required by the running application | Unrelated S3, Secrets Manager, IAM, ECS, KMS signing or ECR write access |
| ECS task execution role | Pull approved images, publish logs, obtain runtime startup secrets | Application administration, maintenance database credentials, release authority |
| Maintenance execution role | Trusted initial/bootstrap database operations | Normal release requester access |

## Core security invariants

1. Building a candidate does not authorize its deployment.
2. A security check is useful only if the checked identity cannot bypass it.
3. The artifact that is scanned and approved must be the artifact that runs.
4. The release requester cannot choose the ECS task role, execution role,
   command, secrets, network configuration, or arbitrary task definition.
5. Missing, invalid, stale, mismatched, or failed security evidence must deny a
   new release.
6. Restricting AWS permissions must not break required InvenTree operations.
7. Negative security tests require a positive control proving that an
   authorized operation still works.

## Core experiments

### E1 — OIDC trust boundary

Baseline:
A GitHub build role trusts more repository or branch contexts than intended.

Expected baseline:
An unauthorized feature-branch context can obtain temporary AWS credentials.

Control:
Restrict OIDC audience and subject conditions to the intended repository and
branch/environment.

Success:
The same unauthorized context receives AccessDenied while the authorized
context still succeeds.

### E2 — Mutable artifact identity

Baseline:
Image A is scanned through a mutable tag and the same tag is later deployed.

Expected baseline:
The tag can be moved to harmless image B between scanning and deployment.

Control:
Resolve, scan, approve and deploy exact repository@sha256:digest references.

Success:
Changing the tag cannot change the artifact admitted by ReleaseLock.

### E3 — Direct ECS bypass

Baseline:
A conventional release role has direct ECS deployment permissions and broad
iam:PassRole.

Expected baseline:
The identity can bypass a green pipeline and directly deploy an unauthorized
image or stronger synthetic task role.

Control:
Remove normal ECS mutation authority from builder/requester identities.
Only the constrained Lambda release gate may perform the fixed deployment
operations after validating an approved release.

Success:
Direct RegisterTaskDefinition, UpdateService and RunTask bypass paths are
denied, role substitution is denied, and a legitimate approved deployment
still succeeds.

### E4 — Runtime IAM blast radius

Baseline:
The application task role can read a synthetic AWS resource unrelated to the
application.

Expected baseline:
A diagnostic process using the task role can read the canary resource.

Control:
Remove unnecessary AWS permissions and retain only required application
access.

Success:
The identical canary request becomes AccessDenied while required InvenTree
operations remain functional.

### E5 — Fail closed on invalid security evidence

Baseline:
A failed or missing vulnerability scan is interpreted as no findings.

Expected baseline:
At least one invalid-evidence case can proceed toward deployment.

Control:
Require successful, complete, fresh and digest-bound evidence before approval
and again before ECS mutation.

Success:
Missing, stale, failed, mismatched or tampered evidence prevents a new ECS
deployment while valid evidence still permits an authorized release.

## Explicitly out of scope for Core

- Kubernetes
- multi-account security architecture
- general-purpose deployment platform
- DynamoDB release state machine
- single-use approval/revocation system
- advanced deployment concurrency
- complete incident-response platform
- advanced egress security
- disaster recovery
- additional observability platform
- application penetration testing
- claims that signed or scanned code is inherently safe
