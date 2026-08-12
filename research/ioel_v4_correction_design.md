# IOEL V4 — Correction Design

**Status:** Correction design / Non-canonical
**Prior V4:** Invalid and not adjudicated

## Purpose

Define the minimum methodological correction required before V4 can be
executed as a valid unknown-field integrity test.

## Established Finding

The existing V4 fixture contains an intentionally unmodeled field:

`UNMODELED_FIELD`

However, the current observer reads the committed fixture directly from:

`research/ioel_v4_probe_input.json`

and copies that object into the observation record.

Therefore the existing implementation demonstrates fixture serialization,
not observation of an actually unknown field at the observer input boundary.

## Current Boundary

```text
V4 fixture
    |
    | contains UNMODELED_FIELD
    v
observer reads committed fixture
    |
    v
V4_PROBE
    |
    v
observation artifact
