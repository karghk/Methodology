# Operations

Non-canonical operational continuity records.

This directory exists to externalize durable operational state so that transient AI working context does not need to retain unnecessary detail.

## Structure

- `active/` — currently authorized operations.
- `interrupted/` — operations halted unexpectedly or before completion; continuation remains possible after verification.
- `frozen/` — deliberately suspended operations; reopening requires an explicit lawful transition.
- `completed/` — operations that reached their defined endpoint.
- `abandoned/` — operations explicitly discontinued; do not resume without new authorization.

## Operating principle

The repository is a continuity and verification layer, not a substitute for correcting operational drift.

The primary control is minimization of transient AI working-context load. Durable operational records are retrieved when needed rather than continuously carried in working context.

The active context should retain only the minimum operational pointer necessary to operate safely:

- operation ID;
- current state;
- highest verified state;
- next lawful frontier;
- blocking condition, if any.

Detailed history belongs in the operation record.

## State discipline

Operation state must be distinguished from observation/drift records. `operations/` answers where an operation is and what is required for continuity. `observation/` records what was observed, including operational drift.

No operations record changes canonical authority. Canonical state remains governed by the canonical corpus and applicable constitutional/foundational boundaries.
