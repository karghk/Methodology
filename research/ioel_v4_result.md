# IOEL V4 — Result

**Status:** INVALID — not adjudicated
**Canonical status:** Non-canonical

## Evidence inspected

The V4 observer run `31549708624` completed successfully and produced artifact `ioel-observation-31549708624-1`.

The recorded observation contains:

```text
INPUT_REFERENCE: null
```

## Why this is insufficient

The current observer implementation constructs `INPUT_REFERENCE` as `None` in its own recording logic. Therefore the observed `null` value does not demonstrate that the observer encountered an unknown field and preserved it faithfully. It may simply be the observer's predefined default.

The V4 fixture also did not introduce an independently generated unknown schema field into the observer's input. It merely described the intended condition in a repository text file.

Consequently, the successful workflow and artifact establish execution and preservation of the observer's output, but they do not establish the V4 unknown-field integrity property.

## Disposition

```text
V1  Known event                  PASSED
V2  Assertion without event     PASSED — scoped
V3  Event without AI assertion  PASSED — scoped
V4  Unknown field               INVALID / NOT ADJUDICATED
V5  Correction integrity        NOT EXECUTED
V6  Candidate blindness          NOT EXECUTED
V7  Independent inspection      NOT EXECUTED

IOEL admission                  PENDING
C0–C4                            PAUSED
Structural necessity             NOT ESTABLISHED
Canonical integration            NONE
```

## Required correction

A valid V4 must first modify the observer or its input schema so that an actually unknown/unmodeled field can reach the recorder, then test whether that field is preserved or explicitly rejected without silent inference.

No V4 pass is claimed from this run.
