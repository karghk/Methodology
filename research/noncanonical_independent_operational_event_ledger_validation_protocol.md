# Validation Protocol — Independent Operational Event Ledger

**Status:** Non-Canonical / Validation Protocol / Not Yet Passed
**Instrument:** Independent Operational Event Ledger (IOEL)
**Parent Specification:** `research/noncanonical_independent_operational_event_ledger_specification.md`
**Conformance Experiment:** `research/operational_state_conformance_protocol.md`

## 1. Purpose

Validate the IOEL as an observation instrument before any IOEL record is admitted as primary evidence in the operational-state-conformance experiment.

This protocol validates the instrument itself. It does not test the canonical ecosystem and does not test structural necessity.

## 2. Validation Principles

The IOEL must demonstrate that it can preserve observation without importing interpretation.

The validation therefore separates:

```text
known event
    ↓
observable event
    ↓
IOEL record
    ↓
independent inspection
```

from:

```text
AI assertion
    ↓
interpretation
```

The latter is not an acceptable source for establishing the event itself.

## 3. Test V1 — Known Positive Event

Generate a controlled event whose occurrence can be independently established.

Expected result:

- IOEL records the event;
- event identity is preserved;
- timestamp/order is preserved sufficiently for the test;
- evidence reference is retained;
- no interpretation is added.

Failure condition: the known event cannot be recovered reliably from the IOEL record.

## 4. Test V2 — AI Assertion Without Event

Have the AI state that an operation occurred while the controlled environment does not produce the corresponding event.

Expected result:

- IOEL records no event merely because the AI asserted one;
- the AI assertion remains in the separate AI operational-state record;
- later comparison may identify the mismatch.

Failure condition: an AI assertion is promoted into an IOEL event without independent observable evidence.

## 5. Test V3 — Event Without AI Assertion

Cause a known observable event while withholding or delaying the AI's corresponding assertion.

Expected result:

- IOEL records the observable event;
- the record does not depend on the AI acknowledging it;
- the later comparison can identify the difference.

Failure condition: the event disappears from the IOEL because the AI did not report it.

## 6. Test V4 — Unknown Field

Create a controlled event for which one or more schema fields cannot be established.

Expected result:

- known fields are recorded;
- unknown fields remain unknown;
- no inferred value is substituted merely to complete the schema.

Failure condition: the recorder fabricates or silently infers missing values.

## 7. Test V5 — Correction / Append-Only Integrity

Create an event record and subsequently discover a recording error.

Expected result:

- original observation remains recoverable;
- correction is separately recorded;
- chronology of correction is preserved;
- no silent rewrite occurs.

Failure condition: the original observation disappears without an auditable correction record.

## 8. Test V6 — Candidate Blindness

Run the validation while the recognized non-canonical transition mechanism is absent.

Expected result:

- IOEL continues to record observable events;
- no candidate-specific classification appears in the ledger;
- the validation remains usable for later testing of canonical baseline sufficiency.

Failure condition: IOEL recording depends upon, embeds, or reproduces the candidate mechanism's conclusions.

## 9. Test V7 — Independent Inspection

A second evaluator must be able to inspect the IOEL record and identify what was actually recorded without relying on the AI's interpretation of that record.

Expected result:

```text
record
  ↓
independent inspection
  ↓
observable event reconstruction
```

Failure condition: the record is intelligible only through the original AI's explanation.

## 10. Admission Rule

The IOEL is not admitted as an independent experimental instrument merely because the specification is complete.

Admission requires successful demonstration of V1–V7, with any failure preserved and analyzed before redesign.

A failed validation does not establish that the IOEL concept is impossible. It establishes that the current implementation or design is not yet admissible.

## 11. Independence Boundary

The validation protocol itself does not claim that an available current ChatGPT channel is independent.

If the actual implementation is operated inside the same conversational channel as the AI, that fact must be recorded and the resulting trial cannot be represented as independent merely because the artifact is called an IOEL.

## 12. Current State

```text
IOEL specification       PRESERVED
Validation protocol      PRESERVED
V1–V7                    NOT YET EXECUTED
Instrument validation    NOT ESTABLISHED
Conformance trials       BLOCKED
Structural necessity     NOT ESTABLISHED
Canonical integration    NONE
```

## 13. Governing Principle

> Validate the measuring instrument before treating its measurements as evidence.
