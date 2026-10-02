# Helping Hand App Design Guide

Visual audit and proposed direction — October 2, 2026.

**Status: Home, authentication, Alphabet, Numbers, and Words implemented; research screens proposed.** This supersedes
the previous calm forest-green direction. The original audit changed no code;
the subsequent dashboard implementation is described below.

### Home implementation

The dashboard now adopts the ivory/teal/mint palette through a scoped
`HelpingHandTheme`. Authentication is the visual source of truth. Home reuses its compact
single-line Fraunces wordmark and curved motion trail, with a flat mint practice invitation,
open progress and learning-path sections, adaptive wide-screen composition,
and scrollable account settings. Bottom navigation uses the same palette. Existing callbacks, shell navigation, state management, and
backend behavior are preserved. Research screens keep their existing theme until their own redesign passes. Flutter-rendered review covered phone, tablet,
landscape, 3× text scaling, sync states, and navigation/settings callbacks.

### Learning implementation

Alphabet, Numbers, and Words use the same ivory/teal/mint theme as Home and
authentication, with open headers and the shared curved brand trail. Alphabet and Numbers are lesson pickers with progress and a target grid.
Tapping any letter, number, or word opens a separate, scrollable live-practice
page. Back returns to the same picker; no practice panel remains in the grid. Shared outlined
tiles use teal for selection and mint plus a check for learned targets; grid
columns and tile heights adapt to available width and system text size.

Live practice is one mint surface with a large target, unchanged connection,
prediction/confidence, hold progress, feedback, and Retry behavior. Target fades
respect reduced motion. Words uses tappable divided vocabulary rows without a coming-soon notice.
Letters, numbers, and words each open a dedicated live-practice page with
a target title and Back control. Word pages share the practice UI and glove
connection state; the static recognition tracker remains limited to A-Z and 0-9. Home also opens the Words destination.
No new recognition model was added. The preceding visual redesign was reviewed
on phone, landscape, tablet, 3x text scaling, target callbacks, and idle/complete
states. The separate-route update passed targeted Flutter analysis; its new
on-device navigation and live BLE procedures remain Not run. See
[BETA_BUILD_STATUS.md](BETA_BUILD_STATUS.md) for the current evidence boundary.

### Authentication implementation

Login and signup use a prominent text-only Helping Hand wordmark in bundled
Fraunces italic, weight 600, paired with DM Sans form typography. The wordmark
uses 64 logical pixels on login and 48 in the compact signup header; it fits
within available bounds while form copy honors system text scaling. This is a
brand-specific display exception to the original single-font proposal. No logo
image appears anywhere in the runtime app UI.

Login has a centered ivory introduction; signup has a compact, left-aligned
mint header. Wide layouts place branding beside the form. Both reuse shared
input decoration, wordmark, motion-trail accent, controls, and accessible
feedback. Forms sit directly on the canvas. Controllers, validators,
auth-service calls, account switching, anonymous-progress notice, and password
reset remain intact. Mode-specific field keys clear stale validation
presentation while retaining controller values. Review included phone/tablet,
landscape, 3× text scaling, keyboard insets, and authentication callbacks.

## 1. Product and evidence

Helping Hand is a wearable-assisted ASL learning app. Its central experience is
choosing a sign, practicing with the glove, receiving understandable feedback,
and seeing real learning progress. The proposed identity welcomes beginners
and feels appropriate for teens and adults; this audience framing is a design
assumption, not a researched demographic claim.

The requested personality is **fun, bright, friendly, energetic, approachable,
and modern**. Express it through hands, movement, confident typography,
intentional color, and clear feedback. Avoid childish visuals, excessive
gradients, generic dashboard templates, indiscriminate cards, glass effects,
heavy shadows, and competing colors.

### Inspection coverage

- All current screens: `account_screen.dart`, `main_shell.dart`, and Home,
  Alphabet, Numbers, Words, Developer tools, Record Signs, and BLE Testing
  in `flutter_app/lib/screens/`.
- Sign-in/create-account modes, password-reset feedback, account/settings sheet,
  reset confirmation, startup loading/failure, and practice feedback states.
- Shared theme and components: `warm_clay_theme.dart`, `warm_components.dart`,
  `stable_prediction_practice_card.dart`, and `hand_visualizer_widget.dart`.
- `test_hand_page.dart`: experimental 3D tester, imported by `main.dart` but
  not presented by the current root or shell navigation.
- Logo, glove, both backgrounds, and login illustration; all six images in
  `app_glove_pictures_and_vids/`; combined historical Figma mockups; and the
  three hand-model development images.
- Existing guide, app entry point, and asset/dependency declarations.

This is a source-and-assets audit with visual inspection of existing images.
The six app screenshots depict an **older orange/serif interface and recording
flow**, not the current green/DM Sans code. Historical Figma screens include
proposed features. No fresh app run or device screenshots were produced;
current cropping, overflow, text scaling, and device appearance remain
unverified. Layout risks inferred from code are not confirmed runtime defects.

## 2. Biggest visual weaknesses

| Priority | Finding and evidence | Proposed response |
| --- | --- | --- |
| High | The imagery lacks a shared identity. Background/login assets use pale foliage and watercolor-like washes; the glove is a detailed orange robotic rendering; the logo is dark green; the live hand painter uses unrelated blue. | Use hands and motion as the common language. Retire foliage from operational backgrounds and distinguish hardware imagery from sign instruction. |
| High | Repeated containers flatten hierarchy. Home progress and each path, curriculum summaries, every Words row, developer introduction, recording stages, and telemetry all use `WarmCard`. Practice nests a tinted target panel and white target box inside another card. | Make open sections and divided rows the default. Reserve a strong surface for active practice, capture, or a genuinely separate overlay. |
| High | The current palette is coherent but subdued. Forest green `#285847`, pale gray-green, white, and muted text dominate nearly every role. | Use vivid teal for action, fresh mint for supporting surfaces, and a small yellow celebration accent. |
| High | Home leads with two general encouragement lines and sync status before the learning action. Progress and path rows repeat similar completion information. | Bring practice near the top, consolidate progress, and make healthy sync secondary. Elevate sync failures when recovery is needed. |
| High | Practice shows a target character more clearly than how to form its sign. The 3D experiment and diagnostic hand are not integrated instructional references. | Give practice a visual stage. Reviewed instructional media is a future content dependency, not an assumed available asset. |
| Medium | Type and spacing escape the theme: 34 px authentication branding, 36 px practice targets, 24 px letters versus 30 px numbers, a 10 px shared stat label, and gaps of 6/10/14/18/22/26. Alphabet and Numbers arrange their progress differently. | Define named type/spacing roles and use one curriculum composition. |
| Medium | Controls are only partly themed. Filled buttons have a specification; outlined/text buttons, chips, sheets, and dialogs largely inherit defaults. Sign-in alone adds a gradient with a transparent disabled button over it. | Specify all control families and states. Use solid primary actions with distinct disabled treatment. |
| Medium | Headers depend on `extendBodyBehindAppBar`, a raster background, `SafeArea`, and `kToolbarHeight - 50` padding. Most pages lack an overall maximum width. | Define a stable header/content boundary and responsive widths. Verify overlap and crop on-device. |
| Medium | BLE starts with a fixed 220 × 340 hand before connection controls. Telemetry nests metric boxes inside a card and uses fixed grid aspect ratios. | Lead with connection/recovery; make the hand secondary and metrics aligned and adaptable. |
| Medium | Practice tells learners to connect through BLE Testing, hidden behind Developer mode. A necessary learning prerequisite has a confusing visual and navigation hierarchy. | Propose a learner-facing connection entry point while keeping diagnostics in developer tools. This is a later flow change. |
| Medium | Words repeats eight numbered cards and eight “Coming soon” chips, internal validation prose, and a sparkle icon. Home marks Words unavailable while navigation exposes the preview. | Use one honest availability notice and divided vocabulary rows; consistently distinguish preview browsing from practice. |

Heavy shadows and glassmorphism are not current problems; retain their absence.
The strongest local pattern is the learning tile: clear target, stable selection
animation, and completion check. Retain DM Sans, familiar native controls,
honest saved progress, and the separation of research tools from learning.

## 3. Visual direction: Hands in motion

Create a bright contemporary practice studio: warm ivory canvas, dark ink,
confident teal controls, fresh mint practice areas, and small sunflower-yellow
moments of accomplishment. Most content sits directly on the canvas. A large
target, short instruction, and understandable feedback form the practice focal
point. Layout and type create hierarchy before color does.

The memorable brand detail is a simple hand contour with one curved motion
trail and a small endpoint dot. Use it sparingly on entry and learning headers.
It connects the identity to gestures and spatial movement. Decorative trails
must look distinct from instructional arrows that describe actual signs.

| Personality | Visible expression |
| --- | --- |
| Fun | Expressive hand contours and a brief completion mark. |
| Bright | Mostly light surfaces, crisp ink, vivid teal, limited yellow. |
| Friendly | DM Sans, sentence case, clear labels, supportive feedback. |
| Energetic | Decisive primary action, strong target type, short transitions. |
| Approachable | Few competing controls, familiar patterns, easy recovery. |
| Modern | Flat color, open sections, consistent alignment, purposeful shapes. |

Avoid mascots, faces on hands, rainbow category colors, stickers, emoji controls,
neon glows, and ambient animation. The energy comes from composition and
feedback. Do not introduce KPI mosaics or decorative charts.

## 4. Small design system

Measurements are Flutter logical pixels. Type sizes are unscaled bases that
must honor system text scaling. These are proposed tokens, not current values.

### Color roles

| Role / token | Value | Use |
| --- | --- | --- |
| Primary `primary` | `#007A70` | Main actions, active navigation, selected targets, progress. |
| Pressed `primaryPressed` | `#00645C` | Pressed primary action without elevation. |
| Secondary `secondary` | `#C8F0DD` | Mint practice stage and navigation indicator; dark text. |
| Accent `accent` | `#FFD166` | Small milestone or celebration detail; dark text. |
| Canvas `background` | `#FFFCF5` | Solid warm ivory on every screen. |
| Surface `surface` | `#FFFFFF` | Inputs, occasional containers, sheets, dialogs. |
| Text `textPrimary` | `#183B36` | Headings, body, labels, numeric values. |
| Supporting text `textSecondary` | `#526560` | Helpers, counts, inactive labels. |
| Divider `divider` | `#D9E2DC` | Noninteractive separators and decorative boundaries. |
| Control boundary `outline` | `#81958C` | Essential input/control outlines. |
| Success / surface | `#23754D` / `#EAF5ED` | Verified completion with a check and text. |
| Warning / surface | `#7A4A00` / `#FFF0CF` | Caution with icon and recovery text. |
| Error / surface | `#B33B36` / `#FCEDEA` | Input/save/connection failure and destructive confirmation. |
| Information | `#007A70` | Neutral connection/sync information with a label. |
| Disabled surface / text | `#E7ECE8` / `#526560` | Unavailable controls with disabled semantics. |

Keep the viewport predominantly ivory/white. Teal owns action; mint supports
the main practice area; yellow appears in at most one small decorative or
milestone region per screen. Semantic colors appear only when warranted.
All learning categories share this palette rather than receiving unique colors.

Calculated solid-color contrast: white on teal **5.23:1**, dark ink on ivory
**11.93:1**, supporting text on ivory **6.05:1**, ink on mint **9.88:1**, and
ink on yellow **8.48:1**. Use dark ink on mint/yellow, never pale text on white.
The outline on white is **3.18:1**; quiet dividers must not define essential
controls alone. Verify final rendered states, imagery, and overlays separately.

### Background

Use solid ivory and an opaque matching app bar. Do not cover screens with raster
backgrounds, leaves, gradients, or texture behind labels/grids/telemetry. One
flat contour motif may occupy unused authentication or Home header space; it
must not compromise readability or depend on unpredictable image crops.
Bottom navigation is white with a quiet top divider and zero shadow.

This remains a light-only direction, matching current theme capability. A
future dark theme requires its own semantic palette and state review.

### Typography

Use **DM Sans for interface text**, with **Fraunces italic reserved for the
Helping Hand wordmark on authentication and Home**. Use proportion and weight for character without
comic fonts, bubble lettering, or additional display faces.

| Role | Size / line height | Weight | Usage |
| --- | --- | --- | --- |
| Login wordmark | 64 / 65 | 600 italic | Fraunces, centered login identity. |
| Compact wordmark | 48 / 49 | 600 italic | Fraunces, left-aligned signup identity. |
| Home wordmark | 36 / 37 | 600 italic | Fraunces, single line; scales down to fit narrow headers. |
| Page heading | 28 / 34 | 700 | Main page title or Home heading. |
| Section heading | 20 / 26 | 700 | Paths, saved samples, target selection. |
| Compact app-bar title | 20 / 26 | 600 | Detail/developer chrome. |
| Item title | 18 / 24 | 600 | Path and vocabulary rows. |
| Body | 16 / 24 | 400 | Instructions and meaningful feedback. |
| Button / field label | 16 / 20 | 600 | Short actions; input values use regular weight. |
| Supporting text | 14 / 20 | 400–500 | Counts, units, status, helpers. |
| Navigation label | 12 / 16 | 600 | Fixed navigation only. |
| Learning tile target | 28 / 34 | 700 | Both letters and numbers. |
| Active practice target | 64 / 70 | 700 | Single character; future words use 28 / 34 and wrap. |

Use tabular figures for timers and live metrics. Use monospace only for raw
packets/file/debug output. Avoid tracked uppercase headings; “Live practice”
can use the supporting role. Remove the 10 px stat-label pattern. Wrap essential
instructions, vocabulary, errors, and status instead of truncating them.

### Border radius and elevation

| Radius | Use |
| --- | --- |
| 0 | Open sections, divided rows, page structure. |
| 8 | Learning tiles and compact segmented controls. |
| 12 | Buttons, fields, occasional contained groups. |
| 20 | Primary practice stage, sheet top corners, dialogs. |
| Fully round | Status dots, progress tracks, small badges, native navigation indicator. |

Do not use the largest radius everywhere or nest three rounded surfaces.
Standard content has zero elevation. Reserve native elevation and scrims for
actual overlays; no decorative shadow stacks or translucent glass surfaces.

### Spacing and responsive structure

Use **4, 8, 12, 16, 24, 32, 48**: 4 for optical adjustment, 8 for icon/text,
12 for grid gaps, 16 for related controls/container padding, 24 for gutters
and larger groups, 32 between sections, and 48 for major entry composition.

- Phone gutters: 24; reduce to 16 below 360 logical pixels.
- Standard toolbar plus system safe area; start content 16 below the header.
  Avoid compensating offsets for overlapping app bars.
- Form/practice maximum width: 560. General page maximum width: 960, centered.
- At 600+ width use 32 gutters. Pickers have a 960 maximum width; separate
  practice pages use a 560 maximum width and one scroll region.
- Derive grid columns from available width and 12 gaps, with minimum 48 × 48
  hit areas; prefer roughly 56–72 tiles on phones. Permit height growth with
  text scaling; do not constrain multiline metrics to fixed aspect ratios.
- Keep one main scroll region. Reserve safe-area/fixed-bar insets so the last
  tile, row, and action remain accessible. Forms accommodate the keyboard.

### Buttons and fields

Primary: solid teal, white label, 12 radius, minimum 52 height, 24 horizontal
padding, no gradient/shadow. Use one dominant task action in each current state:
practice on Home, Start capture when idle, Stop & save while recording.

Secondary: transparent/white, teal label, 1 pixel control outline, 12 radius,
minimum 48 height. Tertiary: teal text with a minimum 48 hit area. Icon controls
use 24 glyphs in 48 hit areas. Put directional arrows after action labels
consistently. Destructive confirmation uses error color and explicit text;
routine Sign out remains secondary.

Use stable pressed feedback, a visible focus ring with offset, explicit disabled
colors, and an in-place loading indicator that preserves button width. Inputs
use white fill, 12 radius, 16 padding, visible labels, outline boundaries, and
a 2 pixel teal focus border. Put actionable validation by its field.

### Cards and containers

Default sections sit on the canvas; repeated items use divided rows. Progress
is a count and labeled track rather than several KPI cards. Add a container
only for a distinct task or content needing isolation.

- **Practice stage:** mint, 20 radius, 24 padding, no shadow. Target, instruction,
  feedback, and hold progress share one surface without inner cards.
- **Learning tile:** white neutral fill, 8 radius, visible outline. Selected is
  teal/white plus selected semantics. Completed is success tint plus a check;
  preserve the check when a completed tile is selected.
- **Path/vocabulary row:** open layout, 16 vertical padding, optional divider,
  title and useful count. Chevron only when the row opens something.
- **Diagnostic group:** open heading and aligned metrics/units; one white
  bounded area where raw packets or complex controls need separation.
- **Sheets/dialogs:** opaque white, 20 radius, native scrim, common type/actions.

### Icons, illustrations, and decoration

Use existing Material icons, outlined for ordinary controls. Filled variants
indicate selected navigation/completion at the same optical size. Standard
glyphs are 24; inline status glyphs 20; small completion marks 16 and not separate
tap targets. Avoid emoji and generic sparkle decoration.

Use flat vector hand contours with round stroke ends, approximately 2 logical
pixels at a 96-pixel illustration size. Decorative fills use teal, mint, ivory,
and a small yellow detail. Avoid anthropomorphic hands and repeated glossy
robot imagery. Use the shared text wordmark and small curved trail for brand
identity on authentication and Home. The old image logo has no runtime UI
references. Keep detailed glove imagery for hardware explanation.

Instructional ASL media requires review for handshape, orientation, handedness,
motion, and framing before use. Decorative gestures and the sensor hand painter
are not verified sign references. Telemetry visualization needs readable
boundaries and a labeled sensor scale alongside exact values.

### Motion

Use 150–220 ms press/selection fades and approximately 220–280 ms native
navigation transitions. Keep bounds stable and inputs available. Real completion
may reveal one brief check or motion trail; no looping celebration. Reduced
motion removes movement. Text always communicates essential feedback; sound
and haptics remain optional supplements.

## 5. Identity across every screen

| Screen / state | Primary job | Proposed composition |
| --- | --- | --- |
| Sign in | Return to practice | Prominent centered Fraunces wordmark above an open ivory form, teal Sign in action, secondary reset/account links, and a small motion-trail accent. No image logo, form card, or gradient button. |
| Create account | Save progress | Compact left-aligned wordmark on mint, open ivory form below; shared fields, buttons, and feedback with login. Accommodate confirmation/errors and preserve the anonymous-progress notice. |
| Password reset / auth error | Recover access | Feedback near the form action; invalid input by its field; success with icon/text rather than a separate celebratory screen. |
| Startup loading / failure | Enter or retry | Ivory, compact brand, labeled loading state; failure with padded recovery text and one Retry action. |
| Home | Start or resume practice | Compact shared wordmark and trail, flat mint practice invitation with a prominent teal action, compact saved-progress band, open path rows. Healthy sync stays quiet; failure exposes Retry. Do not invent a last-practiced target if not stored. |
| Alphabet | Choose a lesson | Open completion count/track and letter tiles. Tapping a letter opens its separate mint live-practice page. |
| Numbers | Choose a lesson | Same progress and tile states as Alphabet, with a compact numeric grid. Each number opens separate live practice. |
| Live practice | Understand the next step | Idle: choose target. Disconnected: connection recovery. Waiting: readable state. Holding: labeled hold track. Low confidence/mismatch: supportive correction. Complete: check and saved-progress status. Distinguish hold progress from learning progress. |
| Words | Choose a lesson | Tappable divided vocabulary rows with forward arrows; no coming-soon notice. Each word opens its practice page; word recognition is not yet integrated. |
| Account/settings sheet | Manage preferences | White sheet, aligned rows, readable email, native switch, separated reset/sign-out actions; no illustration or promotion. |
| Reset confirmation | Choose knowingly | Clear consequences, secondary Cancel, error-colored Reset; preserve confirmation behavior. |
| Developer tools | Open research tasks | Common canvas/type/controls, compact Research mode context, two divided tool rows. Denser grouping rather than a separate brand. |
| Record Signs | Capture labeled samples | Small connection strip, open signer/target section, focused capture stage with large countdown/timer, saved-data/export rows. Preserve pseudonym guidance, data-integrity notes, warnings, cancel, save, and export states. |
| BLE Testing | Connect and diagnose | Connection controls first, hand secondary, aligned metrics with exact units/tabular figures, selectable monospace packet area. Preserve scan/manual-connect/disconnect and parser feedback. Avoid metric-card mosaics. |
| Experimental 3D tester | Inspect poses | If retained, common app bar and labeled selector in content, constrained model stage; later fix hardcoded black-on-dark dropdown styling. Not currently a learner destination. |

A learner-facing connection entry point is a proposed dependency of the practice
redesign. It should expose necessary connection controls without Developer mode;
raw packet inspection remains in research tools. No new screen exists yet.

Future session results and word lessons reuse this system: reviewed sign media,
one primary action, open breakdown rows, and real completion data. Historical
mockups' streaks, accuracy, battery, and session metrics must not appear unless
backed by supported data. Word lesson pages use the live-practice UI; word recognition still requires model validation.

## 6. Later implementation acceptance and rollout

Use at least 48 × 48 logical pixels for controls, readable contrast, meaningful
screen-reader labels, non-color state signals, and useful layouts at large text
scales, following [Flutter accessibility guidance](https://docs.flutter.dev/ui/accessibility).

When implementation is authorized, inspect every screen on small/large phones,
tablet, and landscape, including safe areas and keyboard. Review auth, sync,
practice, scan, capture, save, and export states. Verify focus, semantics,
reduced motion, and rendered contrast. Live updates must not move controls or
flood screen-reader announcements. Palette calculations alone are insufficient.

Suggested later rollout:

1. Shared theme, controls, and responsive layout foundations.
2. Home and Alphabet pilot, including connection recovery and practice states.
3. Remaining settings and confirmations, after the implemented learning/authentication passes.
4. Recording, BLE diagnostics, and the experimental tester if retained.
5. Reviewed instructional media and word lessons as content/models become ready.

Further rollout requires a subsequent implementation request. Preserve existing
data, sync, capture behavior, and the static 36-class regression baseline.

## 7. Method notes

The audit used frontend-design-pro's full review references and bundled
design-system/Flutter searches. The search suggested vibrant color blocks but
also returned a store landing layout, child-oriented fonts, and a competing
blue/orange/pink palette; those do not fit this brief and were rejected.
Retained guidance covered intentional color hierarchy, stable type, semantics,
and consistent states. The specific palette and hand-motion concept are design
judgments based on the inspected product, not external research claims.
