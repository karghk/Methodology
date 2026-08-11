# Non-Canonical Specification — Independent Operational Event Ledger

**Status:** Design / Non-Canonical / Not Yet Operational
**Purpose:** Provide an independent observation instrument for the paused operational-state-conformance experiment.
**Canonical integration:** None
**Candidate transition mechanism:** Excluded

## 1. Designation

**Independent Operational Event Ledger (IOEL)**

The IOEL is a measurement artifact, not a methodological authority and not a solution to the operational-state-conformance hypothesis.

Its sole purpose is to preserve an independently observable event record against which an AI operational-state record can later be compared.

## 2. Problem Established by C0

The C0 pilot demonstrated that external repository evidence can establish repository state, but the present conversational execution channel does not independently record the complete operational event sequence of the AI.

Therefore:

```text
AI assertion
    ≠
independent event record
```

The IOEL is designed to create the missing observational layer without deciding the experimental outcome.

## 3. Independence Requirement

The IOEL must record events without deriving its record from the AI's retrospective operational-state assertions.

It must not accept statements such as:

- "I performed X";
- "I retrieved Y";
- "I verified Z";

as proof that X, Y, or Z occurred.

Instead, it records observable event evidence available through an independently controlled observation path.

## 4. Minimum Event Schema

Each event should contain, where available:

```text
EVENT_ID
TIMESTAMP
SOURCE
OBSERVABLE_OPERATION
INPUT_REFERENCE
OBSERVABLE_RESULT
STATE_CHANGE_REFERENCE
DOWNSTREAM_DEPENDENCE
INDEPENDENT_EVIDENCE_REFERENCE
RECORDER_STATUS
```

Unknown fields remain unknown. The recorder must not infer missing values merely to complete the schema.

## 5. Separation of Records

The experimental system maintains two records:

### A. Independent Event Record

Produced by IOEL from independently observable events.

### B. AI Operational-State Record

Reconstructed from the AI's actual interaction history and operational assertions.

The records must remain separate until comparison.

```text
IOEL event record ───────┐
                         ├── comparison ──> discrepancy assessment
AI state record ─────────┘
```

## 6. No Interpretation Rule

IOEL must not classify an event as:

- hallucination;
- error;
- lawful;
- unlawful;
- causal;
- sufficient;
- necessary.

Those are analytical conclusions belonging to a later review stage.

IOEL records observations and evidence references only.

## 7. No Retroactive Reconstruction Rule

Historical chat material may be used to design and calibrate the IOEL.

Historical chat material must not be silently converted into a supposedly independent IOEL record.

If an event was not independently recorded at the time, it must be marked:

```text
RETROSPECTIVE / NON-INDEPENDENT
```

and excluded from primary independence analysis.

## 8. Provenance Rule

Every event record must identify the observation source and preserve enough provenance for another evaluator to distinguish:

```text
observed event
    ≠
AI assertion
    ≠
analyst interpretation
```

Where provenance is insufficient, the event is marked unresolved rather than upgraded by inference.

## 9. Tamper / Temporal Boundary

Where technically available, the IOEL should preserve append-only or otherwise auditable records with timestamps and immutable identifiers.

If an event record is corrected, the original observation must remain recoverable and the correction must itself be recorded.

The ledger must never silently rewrite history.

## 10. Candidate Exclusion

The recognized non-canonical transition mechanism remains outside the IOEL.

The IOEL must not encode the candidate's conclusions as recording rules.

The experiment must therefore be able to test canonical baseline sufficiency without the candidate being embedded in the measurement instrument.

## 11. Experimental Use

Once independently operational, the IOEL may support the conformance protocol's conditions C0–C4.

For each trial:

```text
actual observable event
        ↓
IOEL record

AI interaction history
        ↓
AI operational-state record

both records
        ↓
comparison
        ↓
discrepancy record
```

The IOEL does not itself determine whether a discrepancy establishes structural necessity.

## 12. Validation Before Use

The IOEL must itself undergo instrument validation before its records can be treated as primary experimental evidence.

At minimum, validation should establish:

1. it records known test events;
2. it does not record AI assertions as events;
3. its timestamps/order are reliable enough for the trial;
4. omitted information remains explicitly omitted;
5. corrections preserve prior observations;
6. the candidate mechanism is absent;
7. an evaluator can independently inspect the resulting record.

## 13. Current Status

```text
Concept/design           COMPLETE
Canonical status         NONE
Candidate integration    NONE
Independent operation    NOT YET ESTABLISHED
Instrument validation    PENDING
Conformance trials       BLOCKED
Structural necessity     NOT ESTABLISHED
```

## 14. Methodological Boundary

The IOEL is deliberately non-canonical.

Its creation does not demonstrate that the canonical ecosystem is insufficient. It merely supplies an instrument for testing that proposition under controlled conditions.

Only empirical results obtained after instrument validation may bear on the necessity question.

## 15. Governing Principle

> Measure the event independently before judging the state representation; preserve observation, assertion, and interpretation as distinct layers.
