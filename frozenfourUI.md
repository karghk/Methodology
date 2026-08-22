============================================================
MUSIC CONVERTER
CANONICAL UI SPECIFICATION

Status:
Frozen

Version:
1.0

Purpose:
Canonical recovery of the finalized terminal UI.

This document defines the complete visual language,
behavior, layout philosophy, and structural grammar of the
Music Converter interface.

This specification is implementation-independent.

============================================================



############################################################
CORE DESIGN PHILOSOPHY
############################################################

The interface is not designed to impress.

It is designed to disappear.

Every visible element must justify its existence.

Nothing decorative is permitted.

Nothing redundant is permitted.

Nothing should compete for attention.

The user already intentionally launched the application by
executing:

./flac2mp3.sh

Therefore the interface never attempts to introduce itself.


============================================================
FOUNDATIONAL PRINCIPLES
============================================================

1.
Continuity over screens.

The application does not transition between screens.

It continuously transforms.


Greeting

↓

Library Scan

↓

Track Conversion

↓

Summary


The application feels like one continuously evolving terminal
session.


------------------------------------------------------------

2.
Persistent Anchor

Artist:

never changes position.

Everything else is attached to it.

The user always knows where they are.


------------------------------------------------------------

3.
One Moving Object

Every stage contains exactly one primary animated element.

Greeting

Cursor

Library Scan

Filename

Track Conversion

Track progress bar

Summary

Nothing

Everything else remains visually stable.


------------------------------------------------------------

4.
Truthful Progress

The application never invents certainty.

Every progress indicator represents something real.

Scanning therefore uses changing filenames instead of fake
percentages.


------------------------------------------------------------

5.
Cold Tool Philosophy

The interface behaves like a deterministic utility.

Never like an assistant.

Never like a dashboard.

Never like a wizard.


############################################################
GLOBAL COLOR PHILOSOPHY
############################################################

Neutral dominates.

Green

Only confirmed success.

Yellow

Only warnings.

Red

Only actual failures.

Gray / Dim

Context that should exist without drawing attention.

No celebratory colors.

No gradients.

No decorative emphasis.


############################################################
GLOBAL SPACING
############################################################

Blank lines exist only to separate conceptual groups.

Never decorative.

Every blank line communicates a boundary.

No random vertical whitespace.


############################################################
STAGE 1
GREETING
############################################################

Purpose

Establish orientation.

Accept artist input.

Create the application's permanent anchor.


Visual

Source      : ~/storage/shared/Music/FLAC
Destination : ~/storage/shared/Music/MP3

Artist:


Responsibilities

1.
Display storage locations.

2.
Accept artist input.

3.
Establish persistent anchor.


Visual Rules

No title.

No branding.

No separator.

No animation.

No statistics.

No prompts.

No confirmation.

The executable name already fulfilled that role.


Transition

Press Enter.

Cursor disappears.

No screen clear.

No flash.

No empty frame.

Scanning immediately overwrites from the same coordinate
system.


############################################################
STAGE 2
LIBRARY SCAN
############################################################

Purpose

Create confidence that deterministic work has already begun.

The user should never ask:

Did it freeze?


Visual

Artist: Mili

Scanning...
Mili - 雨と体液と匂い - 02 - 雨と体液と匂い(instrumental).flac

Found: 367 tracks
         8 albums


Scanning Philosophy

Scanning...

survived all alternatives because it communicates immediate
activity while remaining almost invisible.


Progress Philosophy

There is NO progress bar.

The filename itself is the progress indicator.

Every filename change represents genuine movement through the
library.


Statistics

Found:

acts as the anchor.

The eye naturally reads:

Found

↓

367

↓

tracks

↓

albums


Animation

Only the filename changes.

Nothing else animates.

Redraw frequency remains low enough to avoid wasting CPU while
still communicating continuous activity.


Spacing

Artist

(blank)

Scanning

Filename

Found


No additional separation.


############################################################
STAGE 3
TRACK CONVERSION
############################################################

Purpose

Display the current deterministic operation while separating
current work from overall library progress.


Visual

Artist: Mili > Album 2/68 > Track 59/367 >
Mili - 雨と体液と匂い - 02 - 雨と体液と匂い(instrumental).flac

██████████████████████████████████████████████████████████35%

Encoding...

Bitrate:         254 kb/s
Size:            35.0 MiB / 70.0 MiB
Track Duration:  20:45
Elapsed:         04m19s
ETA:             08m07s

████████████████████████████████████-------------------------

30% Complete


Header

One continuous context sentence.

Artist

>

Album

>

Track

>

Filename

Filename never repeats.


Conversion Progress Bar

Full terminal width.

Filled portion grows naturally.

Unfilled portion uses identical visual language.

Percentage remains fixed against terminal right edge.

The bar dynamically shortens so the percentage never wraps.


Never:

██████████35%----------

Never:

██████████----------35%

Always:

██████████████████████████████████████████████████████35%


Encoding

Encoding...

appears immediately beneath the bar.

No blank line.


Runtime Metrics

Canonical order:

Bitrate

Size

Track Duration

Elapsed

ETA


Overall Progress

Separate visual object.

No embedded percentage.

Completion reported beneath the bar.

30% Complete


Visual Groups

1.

Context

Header

2.

Current Work

Conversion bar

Encoding

Metrics

3.

Overall Progress

Overall bar

Completion label


############################################################
STAGE 4
SUMMARY
############################################################

Purpose

Verification.

Not celebration.

Confirm exactly what happened.


Visual

Artist: Mili

06m42s elapsed

> 100% [367/367]
> [0] failed ; [0] skipped
> [367/367] images embedded
> [140/140] extra files copied

[3.14 GiB] Source FLACs + extras
████████████████████████████████████████████████████

[812 MiB] Converted MP3s + extras
████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

> 2.32 GiB reduced

──────────────────────────────────────────

[C] Convert another artist
[Q] Quit


Conditional

[V] View error log

Appears ONLY when failures exist.


Verification Philosophy

Summary is expressed as checklist items.

Never paragraphs.

Never prose.

Every completed operation receives one line.


Zero-State Philosophy

When:

[0] failed

or

[0] skipped

these values become visually subdued.


Storage Comparison

Bars communicate comparison.

Numbers annotate.

Users should not perform mental arithmetic.

Application reports:

> 2.32 GiB reduced


Interaction

Divider separates:

Results

↓

Actions


############################################################
VISUAL LANGUAGE
############################################################

Greeting answers:

Who?

Library Scan answers:

What exists?

Track Conversion answers:

What is happening?

Summary answers:

What happened?


Every stage answers exactly one question.

Nothing overlaps.


############################################################
APPLICATION FLOW
############################################################

Greeting

↓

Library Scan

↓

Track Conversion

↓

Summary

No screen replacement.

Continuous transformation.


############################################################
CANONICAL UI LAWS
############################################################

• Persistent Artist anchor.

• Exactly one primary moving object per stage.

• Deterministic information hierarchy.

• Truthful progress.

• Minimal redraws.

• No decorative elements.

• Neutral color philosophy.

• Full-width progress bars.

• Runtime metrics remain vertically aligned.

• Summary expressed as verification.

• Error options appear only when required.

• Every visual element has exactly one responsibility.


############################################################
STATUS
############################################################

Document

Music Converter
Canonical UI Specification

Recovery Status

Complete

Confidence

100%

Design Status

Frozen

Ready for implementation.

============================================================
