# Scoped threat-model template

Use this template for a milestone, feature, interface, integration, deployment
profile, or security-relevant dependency change. Follow the
[threat-modeling process](threat-modeling.md). Delete instructional prose only
after its requirement is represented by concrete content or linked evidence.

This template supports a scoped review; completing it does not establish that
the whole system has a complete threat model.

## Record

| Field | Required content |
| --- | --- |
| Model ID and title | Stable local identifier and descriptive title. |
| Scope and change | Boundary being reviewed and the security-relevant change. |
| Status | Current review state without implying approval before evidence exists. |
| Model owner | Person or role accountable for maintaining this record. |
| Security reviewer | Person or role accountable for the security disposition. |
| Change owner | Person or role accountable for implementation and evidence. |
| Created and reviewed | Relevant dates and the revision reviewed. |
| Related authority | Plan, accepted ADRs, policies, contracts, and prior scoped models. |

## Question 1: What are we working on?

### Scope and exclusions

Describe the in-scope behavior, deployment profile, configuration, and exact
dependency identities where they exist. Name explicit exclusions and open
decisions. Do not infer a database, API style, privacy jurisdiction, retention
period, runtime version, or deployment mechanism.

### Actors and assets

| ID | Actor or asset | Owner | Security interest or capability | In-scope interactions |
| --- | --- | --- | --- | --- |

### Components, flows, and trust boundaries

Document the coarse component view and number every material data or control
flow. For each trust boundary, explain why trust changes there and what
validates crossing it.

| Flow ID | Source | Destination | Data or operation | Trust boundary | Protection and failure behavior |
| --- | --- | --- | --- | --- | --- |

### Security assumptions

Every assumption requires current validation evidence and an observable
invalidation condition. If evidence is unavailable, record the resulting work
as open or blocked rather than treating the assumption as true.

| Assumption ID | Assumption | Validation evidence | Invalidation condition | Consequence if false | Owner and next action |
| --- | --- | --- | --- | --- | --- |

### Entry-point and access-control inventory

Record every human, service, administrative, background, and externally
reachable entry point. A protected operation must identify the application-code
enforcement point and the decision source. Record unauthenticated,
unauthorized, unavailable, timeout, malformed, and indeterminate outcomes where
applicable.

| Entry ID | Entry point and operation | Authentication requirement | Permitted actors | Authorization decision and enforcement | Privileged behavior | Denial or failure outcome | Fail-closed negative evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |

Use the access-control matrix to expose operations that share an entry point
but differ in subject, resource, or permission.

| Access ID | Identity or actor | Resource | Operation | Decision authority | Enforcement point | Denial behavior | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |

### Sensitive-data inventory

Privacy jurisdiction and retention remain open unless an approved decision
establishes them. Record that open status and the evidence required before use;
do not supply a convenient value.

| Data ID | Data and classification | Owner | Sources and sinks | Transit and at-rest protection | Logging and redaction | Retention and deletion status | Evidence or open-decision link |
| --- | --- | --- | --- | --- | --- | --- | --- |

### Credential lifecycle

Do not place credential values in this record. Follow the
[secrets-handling policy](../policies/secrets-handling.md).

| Credential ID | Service identity and purpose | Environments and least-privilege scope | Storage, injection, and authorized readers | Rotation | Revocation and retirement | Log-redaction checks | Validation evidence and owner |
| --- | --- | --- | --- | --- | --- | --- | --- |

## Question 2: What can go wrong?

Identify threats across every flow, entry point, asset, assumption, credential,
and sensitive-data item. Include abuse by permitted actors, confused ownership,
dependency failure, partial state, and recovery paths, not only hostile ingress.

| Threat ID | Threat or abuse case | Affected items and boundary | Preconditions | Likelihood basis | Impact | Existing controls | Evidence gap |
| --- | --- | --- | --- | --- | --- | --- | --- |

## Question 3: What are we going to do about it?

Assign each threat exactly one current disposition: mitigate, avoid, transfer,
or accept. Requirements must name an owner and trace to a plan or change.

| Threat ID | Disposition | Rationale | Requirement or transferred responsibility | Owner | Positive evidence | Negative or fail-closed evidence | Delivery link |
| --- | --- | --- | --- | --- | --- | --- | --- |

### Accepted residual risks

Every accepted risk requires all fields below. If any field is missing, keep
the threat unresolved rather than marking it accepted.

| Risk ID and threat | Accountable owner | Acceptance rationale | Remaining impact and exposed scope | Validation evidence | Compensating controls | Re-review trigger or expiry |
| --- | --- | --- | --- | --- | --- | --- | --- |

## Question 4: Did we do a good enough job?

### Evidence and traceability

| Requirement or threat ID | Plan or change | Implementation evidence | Test or review evidence | Operational evidence | Result and reviewer |
| --- | --- | --- | --- | --- | --- |

Confirm and record the scoped result:

- the implementation matches the documented components, flows, entry points,
  access controls, data handling, and credential lifecycle;
- negative evidence covers unauthenticated and unauthorized access, dependency
  failure, malformed or indeterminate outcomes, and safe partial-state or
  recovery behavior where applicable;
- every protected operation fails closed with no protected state change when
  authorization cannot be established;
- no credential or unapproved sensitive data appears in tracked examples,
  logs, fixtures, recordings, screenshots, or evidence;
- every threat has a disposition and every accepted residual risk has an owner,
  impact, evidence, and re-review trigger or expiry;
- assumptions remain validated for the exact reviewed revision, configuration,
  dependency identities, and deployment profile;
- derived requirements and evidence trace to the implementing plan and the
  [definition of done](../project/definition-of-done.md); and
- gaps, open decisions, expired acceptances, and new triggers remain visible
  and block any claim they invalidate.

### Re-review conditions

List the model-specific changes, dates, incidents, failed assumptions,
dependency changes, or risk expiries that reopen this review. Include the next
review owner and the evidence that must be reproduced.
