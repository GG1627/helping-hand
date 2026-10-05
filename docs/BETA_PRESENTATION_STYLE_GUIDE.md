# Helping Hand Beta Presentation Style Guide

Use this guide when building the HTML slides for the assignment in
[`Beta_Presentation_Guidelines.md`](../Beta_Presentation_Guidelines.md). It adapts
the current learner-facing mobile app identity to a projected 16:9 presentation.
The app source remains the authority if its theme changes.

## Visual direction

Use the app's **Hands in motion** look: a warm ivory canvas, dark green ink,
confident teal, mint supporting areas, and a small golden accent. Keep slides
clear and spacious for a technical audience viewing them from a distance.
Use the same palette for project diagrams, timelines, and status labels so the
deck feels connected to the live app demo.

The Flutter app still has two themes. `WarmClayTheme` is the global fallback,
but Home, authentication, and learning screens use the newer
`HelpingHandTheme`. **Use `HelpingHandTheme` as the presentation reference.**
Do not mix in the older forest green (`#285847`) as a competing primary color.

## Color tokens

| Role | Hex | Presentation use |
| --- | --- | --- |
| Canvas | `#FFFCF5` | Default slide background. |
| Ink | `#183B36` | Titles, body text, chart labels. |
| Teal | `#007A70` | Key figures, section emphasis, links, active steps. |
| Deep teal | `#00645C` | Darker teal option for small text or dense marks. |
| Mint | `#C8F0DD` | A single highlighted region, process stage, or callout. Use dark ink on top. |
| Gold | `#FFD166` | Small milestone or motion-trail endpoint, never body text. |
| White | `#FFFFFF` | Screenshot framing or occasional clean data surface. |
| Supporting text | `#526560` | Secondary labels and source notes. |
| Divider | `#D9E2DC` | Quiet rules and table separators. |
| Success | `#23754D` | Verified completed status, with a text label. |
| Error | `#B33B36` | Actual blocker/failure, with a text label. |

Aim for mostly ivory space. Use teal to direct attention and mint to group one
important idea. Gold should be a small accent, not a large background. For
status, use the words **Completed**, **In progress**, and **Planned**; do not
depend on color alone. Do not use success green to imply a feature was validated
when it was only implemented or proposed.

## Typography and composition

- Use **DM Sans** for slide titles, body text, labels, and figures. Use the
  bundled **Fraunces Italic** only for the “Helping Hand” wordmark on the title
  slide or a restrained section opener. The app uses this pairing.
- Start with a 16:9 slide (for example, 1920 × 1080 CSS pixels), with about
  6–8% outer margins. Keep one clear title and one main visual or content group
  per slide. Use open alignment and thin dividers instead of repeated cards.
- Suggested desktop slide sizes: title 64–76 px, slide heading 46–56 px,
  body 28–34 px, labels/notes 22–26 px. These are presentation starting
  points, not app pixel sizes. Check readability at the actual projector size.
- Use sentence case, short labels, and direct wording. Prefer a diagram,
  screenshot, timeline, or concise comparison over dense paragraphs.
- Use flat color and little or no shadow. If a rounded surface helps isolate
  a screenshot or demo instruction, keep the app's restrained 12–20 px radius.

## Visuals and evidence

- Use current app screenshots from the beta build when showing implemented UI.
  Preserve screenshot proportions and label the platform/state if useful.
  Older orange/serif screenshots and historical mockups are not evidence of
  the current app.
- Use the actual glove photo or hardware image for a hardware explanation.
  A decorative hand contour and short curved trail can echo the app brand;
  they must not be mistaken for an instructional ASL sign or sensor result.
- Show the alpha vertical slice, beta feature status, live demonstration, and
  dated remaining-work plan required by the assignment. Distinguish a working
  screen from working recognition: word practice pages are accessible, but
  dynamic word recognition and word completion are not integrated yet.
- When showing measurements or results, label source, units, and whether the
  test was actually run. Use `Not run` for unexecuted beta procedures. See
  [`BETA_SESSION_HANDOFF.md`](BETA_SESSION_HANDOFF.md) and
  [`BETA_BUILD_STATUS.md`](BETA_BUILD_STATUS.md) for current evidence boundaries.

## HTML starter tokens

```css
:root {
  --canvas: #fffcf5;
  --ink: #183b36;
  --teal: #007a70;
  --teal-deep: #00645c;
  --mint: #c8f0dd;
  --gold: #ffd166;
  --white: #ffffff;
  --muted: #526560;
  --rule: #d9e2dc;
  --success: #23754d;
  --error: #b33b36;
  font-family: "DM Sans", sans-serif;
  color: var(--ink);
  background: var(--canvas);
}
```

Keep the slide source responsive to the presentation viewport and test both
full-screen display and exported/printed output. The source palette is defined
in [`helping_hand_theme.dart`](../flutter_app/lib/theme/helping_hand_theme.dart);
the broader app visual rationale is in [`APP_DESIGN_GUIDE.md`](APP_DESIGN_GUIDE.md).
