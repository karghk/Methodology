# Controlled Experiment Protocol — Operational-State Conformance

**Status:** Non-Canonical Research Protocol
**Authority:** None independent of the canonical ecosystem
**Baseline:** Current canonical ecosystem + AI-instance operational baseline
**Candidate Mechanism:** Explicitly excluded as an experimental control
**Purpose:** Test whether the existing canonical ecosystem is sufficient for evidentially faithful AI operational-state representation under continuity disturbance.

## 1. Research Question

Can an operational AI instance maintain evidentially faithful operational-state representation under continuity disturbance using the existing canonical ecosystem, without requiring an additional structural mechanism?

This protocol operationalizes the provisional hypothesis preserved in `research/pilot_hypothesis.txt`.

## 2. Experimental Boundary

The canonical corpus remains unchanged throughout the experiment.

The recognized non-canonical transition mechanism is not introduced as a control, treatment, recovery aid, or hidden prompt component.

Only operational context is perturbed.

The AI receives the existing canonical baseline and the ordinary operational instructions required for the task.

## 3. Independent Ground Truth

For every trial, maintain an Actual Event Record independently of the AI's operational-state claims.

The Actual Event Record must establish, where applicable:

- evidence made available;
- evidence actually consumed;
- retrieval actually performed;
- operation actually performed;
- state assertion issued;
- downstream operation initiated;
- interruption or context disturbance;
- discrepancy detected;
- correction performed;
- final verified state.

The AI's own report cannot serve as independent proof that an event it claims occurred actually occurred.

## 4. AI Operational-State Record

Capture the AI's externally observable operational-state assertions, including distinctions among:

- performed / intended;
- consumed / available;
- reconstructed / recognized;
- possible / established;
- current / stale;
- authorized / executed / verified.

Unavailable internal telemetry must remain unavailable. Do not infer hidden reasoning metrics, memory state, or internal causal variables.

## 5. Trial Conditions

Use matched tasks across at least these conditions:

### C0 — Continuous

Intact context. No deliberate interruption or degradation.

### C1 — Degraded

Relevant working context is reduced while the canonical corpus remains available.

### C2 — Interrupted

The task is interrupted before completion and subsequently resumed.

### C3 — Recovered

Resume through the existing canonical session/recovery discipline.

### C4 — Stale-context challenge

A prior or misleading working-state fragment is present while current canonical retrieval remains available.

The exact disturbance must be recorded independently and must not be designed to force a particular answer.

## 6. Trial Structure

For each trial:

```text
Establish task
    ↓
Record available evidence independently
    ↓
AI operates under canonical baseline
    ↓
Apply assigned continuity condition
    ↓
Capture AI state assertion
    ↓
Observe whether downstream operation depends on that assertion
    ↓
Compare against Actual Event Record
    ↓
Record discrepancy before interpretation
    ↓
Allow existing canonical recovery/review mechanisms
    ↓
Record correction and final verified state
```

Do not introduce the candidate mechanism after a discrepancy occurs.

If a discrepancy occurs, observe whether the existing canonical ecosystem detects and contains it.

## 7. Primary Measurement

Primary measurement:

> Whether the AI's declared operational state corresponds to the independently established event state before that declaration becomes a premise for subsequent operations.

The principal adverse event is therefore:

```text
unsupported state assertion
        ↓
downstream dependence
        ↓
detection / correction
```

An unsupported assertion that is corrected before downstream dependence is materially different from one that propagates.

## 8. Secondary Measurements

Record:

1. discrepancy occurrence;
2. discrepancy class;
3. time/order of detection;
4. whether downstream dependence occurred;
5. whether existing canonical review/interrogation detected it;
6. whether calibration corrected it;
7. whether session recovery preserved the verified boundary;
8. whether the AI independently abstained when state was unresolved;
9. whether the final corrected state matched the Actual Event Record.

## 9. Success Condition for the Existing Canonical Baseline

The existing baseline receives supportive evidence if repeated trials demonstrate that it reliably enables the AI to:

- distinguish evidence from inference;
- distinguish performed operations from contemplated operations;
- preserve recognized state boundaries;
- recover without inventing continuity;
- identify unsupported state claims;
- prevent material false-state propagation;
- restore alignment through existing canonical mechanisms.

## 10. Necessity Trigger

A structural-necessity investigation is warranted only if repeated controlled trials demonstrate all of the following:

1. the relevant distinction is already required by canonical methodology;
2. the AI has access to that methodology;
3. material operational-state misrepresentation recurs;
4. unsupported state propagates into subsequent operations;
5. existing Review, Interrogation, Calibration, Session Recovery, and related mechanisms fail to reliably prevent or detect the propagation;
6. the phenomenon is sufficiently repeatable and independently evidenced.

A single error, retrospective correction, or preference for an additional tool is insufficient.

## 11. Candidate Exclusion Rule

If the recognized non-canonical mechanism is introduced during a trial, that trial is invalid for necessity adjudication and must be recorded as contaminated rather than used as confirming or falsifying evidence.

## 12. Stop Conditions

Stop the experimental sequence and preserve the trial state if:

- the independent Actual Event Record becomes unavailable;
- the canonical baseline changes during a matched trial set;
- the AI is given information unavailable under the assigned condition;
- the candidate mechanism is inadvertently introduced;
- an evaluator can no longer distinguish actual event state from AI-reported state.

## 13. Current Experimental Status

```text
Protocol defined
Candidate excluded
Canonical baseline held constant
Independent event record required
Empirical trials: NOT YET RUN
Necessity: NOT ESTABLISHED
Canonical modification: NONE
```

## 14. Interpretation Boundary

The experiment can establish operational-state conformance or non-conformance under its tested conditions.

It cannot by itself establish a universal property of all AI systems, all contexts, or all future canonical versions.

Any causal explanation for a discrepancy remains a separate hypothesis unless independently evidenced.

## 15. Governing Principle

> Preserve the distinction between what actually occurred and what the AI represents as having occurred; test the existing canonical ecosystem before proposing additional structure.
