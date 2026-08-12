# IOEL V3 Observation-Domain Gap

**Status:** Non-Canonical Research Observation
**Date:** 2026-08-12
**Experiment:** Controlled Operational-State Conformance
**Candidate Mechanism:** Excluded

## Observation

The IOEL V3 independent source and the IOEL external observer currently operate over different GitHub event domains.

The independent source workflow is externally scheduled:

- workflow: `IOEL Independent Event Source`
- trigger: GitHub Actions `schedule`
- schedule: `*/5 * * * *`
- observed source run: `31612828822`

The resulting source record explicitly identifies:

- source: GitHub Actions scheduler
- run ID: `31612828822`
- run attempt: `1`
- purpose: externally scheduled positive event for V3

The external observer workflow is separately triggered by:

- GitHub Actions `push`
- branch: `main`

Its recorder explicitly identifies its observation scope as limited to repository push events.

## Evidentiary Consequence

The scheduled V3 source event cannot presently be treated as independently observed by the existing IOEL observer merely because both systems belong to the same repository or because their executions are temporally related.

The following linkage has therefore NOT been established:

`scheduled source event → IOEL observer event`

Temporal proximity, shared repository membership, shared commit history, or self-declared source records are insufficient to establish that linkage.

## Boundary

This observation does not establish:

- failure of the IOEL concept;
- failure of the canonical methodology;
- structural necessity of a new mechanism;
- insufficiency of the canonical ecosystem;
- validity or invalidity of the C0–C4 experiment.

It establishes only an instrumentation-domain mismatch.

## Required Next Inquiry

Determine whether a minimal non-canonical observation design can produce an event that is independently observable by the required measurement channel without:

1. making the observer consume the source's self-report;
2. introducing the recognized GitHub-locator transition mechanism;
3. changing the canonical corpus;
4. embedding the experimental conclusion into the recorder;
5. converting the instrument into a causal explanation mechanism.

## Current State

```text
V3 source provenance       ESTABLISHED — SCOPED
Observer scope             PUSH ONLY
Scheduled source scope     SCHEDULE
Source → observer linkage  NOT ESTABLISHED
C0–C4                      FROZEN
Candidate mechanism        EXCLUDED
Canonical modification     NONE
Structural necessity       NOT ESTABLISHED
