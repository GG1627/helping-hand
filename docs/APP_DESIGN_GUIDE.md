# Helping Hand App Design Guide

## Direction

Make Helping Hand feel like a calm, capable learning tool: warm off-white
surfaces, clear typography, deliberate spacing, and a restrained forest-green
accent. The interface should feel designed and welcoming without looking
decorative, juvenile, or like a generic dashboard.

## Foundations

- Canvas: warm off-white `#F7F7F3`; content surfaces: white `#FFFFFF`.
- Primary: forest green `#285847`; light green tint `#E8F0EB`.
- Main text: charcoal `#222A25`; secondary text: muted green-gray `#68736C`.
- Semantic colors only: success `#2F7854`, information `#4B6F9B`, error
  `#B64C49`. Do not use accent colors as decoration.
- Typography: DM Sans throughout. Use clear weight/size hierarchy rather than
  mixing display fonts or adding oversized slogan text.
- Layout: generous but purposeful whitespace; 22 px screen inset, 12 px common
  section gap, 14 px surface corners. Prefer a few meaningful surfaces over a
  stack of cards.
- Controls: forest-green primary actions, quiet outlined/text secondary actions,
  subtle borders, and visible keyboard/touch focus. Avoid pill-shaped-everything,
  gradients, glow/shadow effects, emoji icons, and ornamental badges.

## Component guidance

- Progress should show real saved learning only. Never invent streaks, activity,
  or completion states.
- A selected learning target uses the primary green; completed targets use a
  pale green surface and a small check. Unstarted targets stay neutral.
- Status colors communicate state (synced, information, failure), with text and
  icons so color is never the only signal.
- Keep account, reset, sign-out, and developer controls available but visually
  secondary to learning.
- Words remain clearly marked as forthcoming until the word-learning flow is
  implemented.

## Scope and rollout

This is a light-only design direction; do not add a dark-mode toggle. Home and
Alphabet are the initial visual pilot. Review those screens on-device before
extending the system to Numbers, Words, authentication, and developer tools.
Preserve app behavior and accessibility while refining presentation.
