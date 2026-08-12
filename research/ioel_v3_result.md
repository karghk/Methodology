# IOEL V3 — Result

**Status:** PASSED — scoped
**Canonical status:** Non-canonical

## Trial condition

A human-controlled repository push was performed without communicating its timing or identifying details to the AI beforehand.

The operator subsequently verified through GitHub that the IOEL External Observer workflow executed successfully and that the observation run/artifact was present. Only after that verification was the AI informed that the event had occurred and that the independent observation had been secured.

## Result

The V3 independence condition was satisfied for the tested observation boundary:

```text
Human-controlled event
        ↓
GitHub push accepted
        ↓
IOEL observer executed
        ↓
Observation artifact secured
        ↓
AI informed afterward
```

The event therefore existed independently of a prior AI assertion, while the IOEL preserved an externally generated observation before the AI was informed of the event.

## Scope

This is a scoped V3 pass. It establishes that the IOEL can preserve an externally generated repository event without a corresponding prior AI assertion under the tested protocol.

It does not establish:

- general independence of the IOEL across all event classes;
- causal claims about the observed event;
- structural necessity of the IOEL;
- insufficiency of the canonical methodology;
- justification for canonical integration.

## Validation State

```text
V1  Known event                  PASSED
V2  Assertion without event     PASSED — scoped
V3  Event without AI assertion  PASSED — scoped
V4  Unknown field               NOT EXECUTED
V5  Correction integrity        NOT EXECUTED
V6  Candidate blindness         NOT EXECUTED
V7  Independent inspection      NOT EXECUTED

IOEL admission                  PENDING
C0–C4                            PAUSED
Structural necessity             NOT ESTABLISHED
Canonical integration            NONE
```

## Provenance note

The event-identifying details are intentionally omitted from this public research record because the V3 trial's independence depended on withholding them from the AI until after observation was secured. The operator's contemporaneous GitHub Actions evidence remains the primary execution evidence.
