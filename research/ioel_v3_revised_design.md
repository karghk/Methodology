# IOEL V3 — Revised Trial Design

**Status:** Design correction / Non-canonical
**Prior V3:** Invalid and not adjudicated

## Purpose

Test whether the IOEL records an externally observable event even when the AI operational-state record contains no corresponding assertion.

## Required Independence

The positive event must originate independently of the AI operation under test.

The AI must not:

- create the event;
- select the event after learning it occurred;
- encode the event into repository state;
- request an observer run specifically to manufacture the positive event;
- write the event into the observation channel.

## Admissible Event Source

The event source must already exist or arise from an independent process whose occurrence is not controlled by the AI trial action.

Examples include:

- a scheduled external event;
- an independently operated test runner;
- an external clock-triggered event;
- an independently maintained repository or service event;
- a human-controlled event performed without communicating its occurrence to the AI until after observation.

## Trial Sequence

```text
Independent source generates event
        ↓
IOEL records observable event
        ↓
AI operational-state record is checked
        ↓
No corresponding prior AI assertion
        ↓
Compare records
```

## Invalidating Conditions

The trial is invalid if the AI:

1. directly causes the event;
2. learns the event before the independent record is secured;
3. instructs the source to generate the event;
4. uses a repository mutation as a surrogate for the independent event;
5. retroactively labels an AI action as the external source.

## Evidence Boundary

A successful V3 establishes only that an event independently observable by the IOEL can be recorded without a corresponding AI assertion.

It does not establish general instrument independence or structural necessity.

## Current Disposition

```text
Prior V3                     INVALID
Revised V3 design            ESTABLISHED
Independent event source     NOT YET AVAILABLE
V3 execution                 BLOCKED
Instrument admission         PENDING
C0–C4                        BLOCKED
Structural necessity         NOT ESTABLISHED
```
