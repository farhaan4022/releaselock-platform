# Experiments

All tests run only in our AWS lab with synthetic data and harmless test
resources.

## E1 - OIDC trust

Start with a build role that trusts more GitHub branch contexts than intended.

Test:
- feature branch tries to assume the role
- allowed branch tries the same thing

Then restrict the trust policy and repeat both tests.

Expected final result:
- unauthorized branch: denied
- authorized branch: allowed

## E2 - Image tag vs digest

Start by scanning `app:release` while it points to image A.

Move the same tag to harmless image B before deployment and show that a mutable
tag can make the scanned image different from the deployed image.

Fix:
- scan by digest
- approve by digest
- deploy by digest

Retagging must no longer change the approved release.

## E3 - Direct ECS bypass

This is the main experiment.

The weak release role initially has controlled lab permissions for:

- `ecs:RegisterTaskDefinition`
- `ecs:UpdateService`
- `ecs:RunTask`
- `iam:PassRole`

Use those permissions to bypass the normal pipeline and try to deploy image B
or use a stronger synthetic task role.

Then remove direct ECS deployment access from the requester.

The requester should only be able to invoke the ReleaseLock Lambda gate.

Final checks:

- direct RegisterTaskDefinition: denied
- direct UpdateService: denied
- direct RunTask: denied
- task-role substitution: denied
- valid release through the gate: allowed

## E4 - Runtime IAM

Temporarily allow the application task role to read one unrelated synthetic S3
object.

Confirm the read works.

Remove that permission and repeat the same request.

Final result:
- unrelated S3 object: denied
- normal InvenTree operations: still working

## E5 - Fail closed

Test release attempts with bad evidence such as:

- failed scanner
- missing report
- report for another digest
- stale report
- invalid signature
- expired approval
- wrong S3 evidence version
- blocking vulnerability finding

Invalid evidence must be rejected before ECS is changed.

A valid release must still work.

## Test resources

We will use:

- image A: normal candidate
- image B: harmless variant with a different digest
- one private S3 canary object
- one synthetic canary task role with access only to that object

No malware, real customer data or third-party systems are involved.

## Evidence

For each test, keep the useful raw evidence:

- command
- UTC time
- caller identity
- image digest
- task definition / task role
- AWS response
- CloudTrail event where relevant
- before and after policy
- positive application check

Never publish credentials, JWTs, passwords, secrets or raw Terraform state.
