# IOEL V6 — Candidate-Blind Probe

**Status:** Non-canonical experimental protocol

## Purpose

Test whether the IOEL observation path can record and preserve an externally generated candidate-bearing event without the observer being given the candidate's identity or expected result in advance.

## Blindness condition

The observer must receive only an externally generated event payload. It must not receive:

- the candidate's identity;
- the candidate's expected value;
- an instruction that the event is expected to support or refute a candidate;
- an AI assertion about what the event should contain.

## Pass condition

The resulting observation artifact must contain the externally observable event and its provenance while containing no pre-supplied candidate identity or expected-result assertion.

## Invalidating conditions

V6 is invalid if the observer input contains the candidate identity or expected result, or if the observation artifact can only be produced after such information is supplied.

## Scope

This is an instrument-blindness test only. It does not establish that the candidate is true, false, necessary, causal, or canonical.
