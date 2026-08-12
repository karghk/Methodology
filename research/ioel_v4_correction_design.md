# IOEL V4 — Correction Design

**Status:** Non-Canonical / Design Correction
**Prior V4:** INVALID / NOT ADJUDICATED

## Purpose

Correct the V4 probe so that an actually unmodeled field reaches the IOEL observer through its event input boundary and can be inspected for preservation without inference.

## Observed Defect

The prior V4 observer loaded:

`research/ioel_v4_probe_input.json`

directly from repository state.

Therefore the prior `UNMODELED_FIELD` did not constitute an unknown field arriving through the observer input. The observer was explicitly instructed to read the fixture.

The prior V4 result remains invalid / not adjudicated.

## Corrected Input Boundary

The corrected V4 will use a GitHub `repository_dispatch` event.

The event's `client_payload` will contain an intentionally unmodeled field.

The field must enter the observer through the actual GitHub event payload.

The observer must not construct the test field itself.

## Test Payload

The V4 dispatch payload will contain:

```json
{
  "event_type": "ioel_v4_unknown_field",
  "client_payload": {
    "probe": "V4",
    "UNMODELED_FIELD": {
      "name": "v4_unknown_field",
      "value": "intentionally-unmodeled",
      "purpose": "test explicit preservation of an unmodeled field"
    }
  }
}
