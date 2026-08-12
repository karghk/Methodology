# IOEL V5 — Correction Lineage Schema

**Status:** Non-canonical experimental protocol

## Purpose

Define the minimum record structure required to test whether an observation can be corrected without silently rewriting its provenance.

## Required lineage fields

- `ORIGINAL_OBSERVATION_ID` — immutable identifier of the observation being corrected.
- `CORRECTION_ID` — unique identifier for the correction record.
- `CORRECTION_REASON` — explicit reason the correction was required.
- `ORIGINAL_VALUE` — preserved original value; never replaced in-place.
- `CORRECTED_VALUE` — value supplied by the correction event.
- `CORRECTED_AT` — timestamp of the correction event.
- `CORRECTED_BY` — attributable correction actor/process.
- `CORRECTION_EVIDENCE_REFERENCE` — externally inspectable evidence supporting the correction.

## Integrity condition

A V5 pass requires all of the following:

1. The original observation remains retrievable unchanged.
2. The correction is represented as a distinct record.
3. The correction explicitly references the original observation.
4. The reason for correction is recorded.
5. The corrected value is distinguishable from the original value.
6. Provenance is preserved for both records.
7. No operation silently overwrites the original observation.

## Invalidating condition

If the only surviving representation is the corrected value, or if the correction cannot be linked unambiguously to the original observation, V5 fails.

## Scope

This test establishes correction-lineage integrity only. It does not establish structural necessity, causal validity, or canonical integration.
