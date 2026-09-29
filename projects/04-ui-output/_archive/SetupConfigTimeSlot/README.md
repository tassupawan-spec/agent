# UI Design: Setup Config Time Slot (Pool Time-Slot Configuration)

Hi-fi visual design handoff, produced from the PO-approved UX Screen Flow
(`projects/03-ux-output/SetupConfigTimeSlot/TMS_SetupConfigTimeSlot_ScreenFlow.md`).
This is the final artefact of this design pipeline — next stop is
`angular-implementer`.

## 0. ⚠️ Important gap in the input material

**`Ref/` does not exist in this repository checkout** (confirmed by directory
listing — no `Ref/` folder at all, not even empty). `shared/ui/` also does not
exist. Per the task's own fallback instruction, this design was produced
**entirely from `DESIGN.md`'s token contract and the standard page skeleton in
CLAUDE.md §6**, with no production screenshot to visually cross-check against.
Every token used is a real token from `styles/tokens.css` (pasted inline in
each artboard), so the design is contract-compliant, but it has **not** been
visually verified against a real screen. Flag this to PO/design-system-guardian
before this goes further — ideally `Ref/` should be populated before
`angular-implementer` builds from this handoff.

The UX Screen Flow's own §4 wireframe notes only covered S1 structurally, with
no WCAG mapping produced at the UX stage. Per the task brief this is treated as
an expected gap, not a blocker — full WCAG verification for all 8 screens is
done in this handoff (§3 below) as this role's own responsibility.

## 1. Artboards

| File | Screen | State | Size |
|---|---|---|---|
| `S1_PoolEdit_Default.dc.html` | S1 แก้ไขข้อมูล Pool | Default, มีข้อมูล, 10 rows | 1920×1080 |
| `S2_PoolEdit_Empty.dc.html` | S2 แก้ไขข้อมูล Pool | Empty (0 slots) | 1920×1080 |
| `S3_FilterPanel_Expanded.dc.html` | S3 Filter panel | Expanded + applied (Slot Type=VIP), annotated | 2280×1080 (1920 screen + 360 annotation rail) |
| `S4_AddTimeSlotModal_Default.dc.html` | S4 เพิ่มเวลารอบจัดส่ง | Default, empty form, annotated | 1300×780 (960 stage + 340 annotation rail) |
| `S4_AddTimeSlotModal_Error.dc.html` | S4 เพิ่มเวลารอบจัดส่ง | Error — Slot Time + Load Time overlap, annotated | 1300×830 |
| `S5_EditTimeSlotModal_Default.dc.html` | S5 แก้ไขเวลารอบจัดส่ง | Default, pre-filled from row 1, annotated | 1300×780 |
| `S6_RowActions_DeactivateViaToggle.dc.html` | S6 (delete → deactivate) | Row-actions column without "ลบ", annotated | 2300×1080 |
| `S7_RowStatusToggle_SuccessToast.dc.html` | S7 สถานะ toggle | ปิด→เปิด transition + success toast, annotated | 2300×1080 |
| `S8_SaveConfirmDialog.dc.html` | S8 ยืนยันการเปลี่ยนแปลงข้อมูล | Default, annotated | 1300×600 |

All 9 files are self-contained `.dc.html` — no external CSS/JS/fonts, the full
`:root` token block pasted inline, inline SVG icons only. Open directly in a
browser.

**States explicitly covered across the set:** default (S1, S4, S5, S8), empty
(S2), loading — see §5 note below, error (S4), row selected/highlighted (S7),
filter panel expanded + applied (S3), disabled fields (S1 รหัส Pool
read-only), the new deactivate-via-toggle interaction (S6), success
confirmation (S7 toast).

## 2. Primitives used (all existing, per DESIGN.md §10)

- App shell — sidebar + top bar (light, no border, `--shadow-shell`)
- Page header (title + breadcrumb)
- Card (white, `--radius-sm`, `--shadow-card`, no border, header + divider rule)
- Filter bar (bare on `--surface-page`, label-above pattern, 12-col grid)
- Button — primary / secondary / ghost-icon
- Input / Select (`mat-form-field` outline pattern, label above, error variant)
- Table (48px rows/header, `--border-default` dividers, last row no divider,
  sentence-case Thai headers, tabular-numeric right-aligned quantity columns)
- Table toolbar (primary button left, filter toggle)
- Paginator
- Status indicator anatomy, adapted (see §4 — toggle replaces the static icon
  here because the column is an actionable control, not a read-only state)
- Dialog **[proposed — unverified, DESIGN.md §0]** — used as-is for S4/S5/S8

## 3. New / [proposed] patterns — not yet formalised in DESIGN.md §10

None of these introduce a new **token**. All are built purely from existing
tokens; they are new **component anatomies** that should be reviewed by
`design-system-guardian` and (if approved) added to DESIGN.md §10 formally,
since this feature is very likely not the only screen in the system that needs
a toggle switch or a toast.

| Component | Where used | Token map | Why new |
|---|---|---|---|
| **Toggle switch** | S1/S2 "สถานะการใช้งาน" (Pool), S1/S3/S6/S7 row "สถานะ" | Track 36×20px `--radius-full`; ON `background: --action-primary-bg`; OFF `background: --color-neutral-300`; thumb 16×16 `--surface-default` + `--shadow-card`; focus `--focus-ring` | DESIGN.md §10 lists `mat-checkbox` but no toggle-switch anatomy. The UX Screen Flow already establishes this as the real control (not a new invention by this role) — this handoff just gives it a token map |
| **Active filter chip** | S3 "Slot Type: VIP" | `background: --surface-selected`; `color: --text-brand`; `border-radius: --radius-sm`; height 28px; `padding: 0 var(--space-5)` | Distinct from the forbidden "pill-shaped status badge" — this is a removable filter-value chip, a different pattern. No new token |
| **Filter count suffix** | S3 "ตัวกรอง (1)" | Plain text suffix in the existing button label, `background: --surface-selected` on the button when active | Deliberately **not** a circular counter badge, to avoid any resemblance to a status pill |
| **Inline field error** | S4 error state | `border-color: --border-danger`, `border-width: --border-width-thick`; error text `sm/400/--text-danger` below field | This anatomy **is** already defined in DESIGN.md §10 (Input component: "error `--border-danger`") — flagged here only because no prototype screen showed it in use, not because it is new |
| **Alert / banner (region-level error)** | S4 error state, top of dialog body | `background: --status-danger-bg`; icon `--status-danger-icon`; text `--text-danger`; `--radius-sm` | §3.4 already reserves `--status-*-bg` for "the rare case where a whole cell/region must be flagged" — this is that case, applied at dialog-body level rather than a table cell |
| **Toast (success)** | S7, after ปิด→เปิด | `background: --surface-raised`; `box-shadow: --shadow-lg`; left accent `border-width-thick` in `--status-success-icon` **[proposed]**; `z-index: --z-toast` (already reserved, unused until now) | No toast anatomy exists in DESIGN.md §10 at all. Built to match the "icon, not solid fill" philosophy used for status indicators system-wide, rather than a solid-color toast. **Relies on the [proposed] success ramp** — flagged per CLAUDE.md §3.8 |

## 4. [proposed] tokens relied on

| Token | Where used | What would confirm it |
|---|---|---|
| `--color-success-500` / `--status-success-icon` / `--status-success-bg` | S7 toast (icon, left accent, aria-live confirmation) | A production screenshot showing any success/completed state (e.g. "ล็อครถแล้ว", "Delivered") in `Ref/`, per DESIGN.md §0 open question 2 |
| Dialog anatomy (`--radius-lg`, `--shadow-lg`, `--layout-dialog-width-*`) | S4, S5, S8 | A production screenshot of any modal/dialog — DESIGN.md §0 explicitly lists this as unverified |
| Empty-state anatomy | S2 | A production screenshot of any empty table/list state |

None of these are new tokens — all three are already declared (tagged
`[proposed]`) in `tokens.css`/DESIGN.md. This handoff just consumes them, per
the explicit gap DESIGN.md §0 already documents.

## 5. WCAG Compliance — measured values

Contrast ratios below are computed via the WCAG relative-luminance formula
from each token's actual hex value in `tokens.css` (no screenshot tool was
available in this pass; recommend `accessibility-reviewer` re-verify with a
contrast checker against the rendered artboards as a final gate).

| Screen/Component | WCAG criterion | Value UX specified | Value used | Pass/Fail |
|---|---|---|---|---|
| Table cell value / body text | 1.4.3 Contrast (text) ≥4.5:1 | ≥4.5:1 | `--text-primary #212121` on `--surface-default #fff` → **16.1:1** | ✅ |
| Card section header / breadcrumb | 1.4.3 ≥4.5:1 | ≥4.5:1 | `--text-secondary #5a6b7f` on white → **5.5:1** | ✅ |
| Field label / helper text | 1.4.3 ≥4.5:1 (13px counts as normal text) | ≥4.5:1 | `--text-tertiary #707683` on white → **4.6:1** | ✅ (marginal — do not darken background under labels) |
| Error message text (S4) | 1.4.3 ≥4.5:1 | ≥4.5:1 | `--text-danger #c04a4a` on white / on `--status-danger-bg #fdf0f0` → **4.9:1 / 4.8:1** | ✅ |
| Danger field border (S4) | 1.4.3 ≥3:1 (non-text UI) | ≥3:1 | `--border-danger #da6060` on white → **3.6:1** | ✅ |
| Warning icon (S8 dialog) | 1.4.3 ≥3:1 (non-text UI) | ≥3:1 | `--status-warning-icon #ffb946` on white → **1.8:1** | ❌ — **known, pre-existing system issue**, already documented in DESIGN.md §3.5 as an accepted exception because the icon is always paired with a high-contrast text label/heading immediately beside it, never the sole signal. Not introduced by this feature; flagged per DESIGN.md's own carve-out, not re-litigated here |
| Success toast icon (S7) | 1.4.3 ≥3:1 (non-text UI) | ≥3:1 | `--status-success-icon #2e9e6b` on `--surface-raised #fff` → **3.4:1** | ✅ |
| Filter chip text (S3) | 1.4.3 ≥4.5:1 | ≥4.5:1 | `--text-brand #334d6e` on `--surface-selected #eef1f5` → **7.6:1** | ✅ |
| Primary button label | 1.4.3 ≥4.5:1 | ≥4.5:1 | `--action-primary-text #fff` on `--action-primary-bg #334d6e` → **8.4:1** | ✅ |
| Row "แก้ไข" icon button | 2.5.5 Touch target | ≥44×44px (per task brief) | **32×32px**, `gap: --space-4` (8px) between adjacent controls | ⚠️ **Partial** — 32×32 is DESIGN.md §7's own documented system-wide minimum ("Minimum hit target is 32×32 for anything clicked repeatedly"), not a new deviation from this feature. WCAG 2.5.5 (44×44) is an **AAA** criterion; DESIGN.md's own target is AA (§3.5). Under WCAG 2.2's AA-level 2.2.5.8 (24×24 min, with adequate spacing) this passes. Not fixed here because it would mean changing a system-wide control-sizing token outside this task's scope (CLAUDE.md §7) — escalate to design-system-guardian if 44×44 is actually required |
| Toggle switch (สถานะ) | 2.5.5 Touch target | ≥44×44px | Track 36×20px, but the whole `status-cell` row area (toggle + label, full row height ≥48px per `--table-row-min-height`) is clickable in the real component — recommend `angular-implementer` bind the click handler to the full flex row, not just the 36×20 track | ⚠️ Same as above — mitigated by generous row height, but flag for `angular-implementer` to confirm the hit area, not just the visual track |
| Focus indicator, all interactive elements | 2.4.7 Focus visible | Must be visible | `--focus-ring: 0 0 0 2px var(--color-primary-200)` applied via `:focus-visible` on every button/input/toggle in the mockups | ✅ (visually specified; verify with real keyboard nav once implemented) |
| Text resize (all screens) | 1.4.4 Reflow @200% | Must not break | All layout uses `rem`-free token `px` but grid columns are flexible (`fr`/`%`), table cells wrap rather than truncate — not stress-tested at 200% zoom in a static mockup; flag for `accessibility-reviewer` to verify in the built screen | ⚠️ Not verifiable from a static HTML mockup — defer to implementation-stage check |
| Status conveyed by colour alone | General (§3.4) | Icon + label always | Every status in S1/S3/S6/S7 pairs a toggle/icon with a Thai text label (เปิด/ปิด); S4 error pairs icon + full sentence, never colour-only | ✅ |

## 6. ⚠️ Points requiring adjustment from the UX Screen Flow (flagging, not changing)

Per CLAUDE.md, screen flow/wireframe structure was **not** altered. The
following are things this role had to make a concrete call on because the
Screen Flow intentionally left them open — flagged for PO/BA, not silently
decided:

1. **"ลบ" icon removal (S6) — the Screen Flow's own §5 item 1 open
   question.** This handoff defaults to the **recommended safe option**: the
   delete icon is removed from the row-actions column entirely; only "แก้ไข"
   (edit) remains, and deactivation happens via the existing "สถานะ" toggle.
   `S6_RowActions_DeactivateViaToggle.dc.html` shows this as the design, with
   a ghosted/dashed icon slot on row 1 illustrating the **rejected**
   alternative (keep "ลบ" but restrict it to slots with zero historical
   usage) for PO/BA to compare against. **This is not yet confirmed — see
   Open below.**
2. **Toggle switch and toast anatomy** are new component patterns not yet in
   DESIGN.md §10 (see §3 above) — used here because the interaction requires
   them and no closer existing primitive fits, not because this role wanted to
   invent something new.

## Handoff contract (AGENT.md §5)

**1. Done**
- 9 artboards under `projects/04-ui-output/SetupConfigTimeSlot/*.dc.html`
  (listed in §1), covering all 8 screens/states S1–S8 plus the required error
  state for S4.
- This README as the handoff document (primitives, new/[proposed] tokens,
  measured WCAG compliance table, state coverage).
- Token contract followed throughout: `:root` block copied verbatim from
  `styles/tokens.css` into every artboard; zero hardcoded hex/px in any
  component rule — every visual value is `var(--token)`.

**2. Decisions**
- Defaulted the delete-icon question (Screen Flow §5 item 1) to "remove
  entirely" as instructed, with the rejected alternative shown ghosted for
  comparison — see §6.1 and Open below.
- Built toggle switch, filter chip, and toast as new component anatomies from
  existing tokens only (no new primitives/tokens added to `tokens.css` or
  DESIGN.md — those files were not touched, per CLAUDE.md §7).
- Used the `[proposed]` success ramp for the S7 toast and `[proposed]` dialog
  anatomy for S4/S5/S8, since no alternative exists in the token contract and
  the feature requires them — flagged in §4, not silently used.
- Rendered S3/S6/S7 as annotated full-page artboards with a side annotation
  rail (per CLAUDE.md §6 "keep annotations in a side column"), rather than
  overlaying callouts on the design.

**3. Open**
- **Blocking for final sign-off:** the "ลบ" icon scope question (remove
  entirely vs. restrict to zero-usage slots) — Screen Flow §5 item 1 — is
  still not resolved by PO/BA. This design ships the "remove entirely"
  option as the working default per this task's explicit instruction, but
  it must be confirmed before `angular-implementer` builds it as final.
- `Ref/` is missing from this repository entirely — this whole design has
  **zero** visual cross-check against a real production screen. Recommend
  populating `Ref/` (or at minimum getting one screenshot of any screen using
  a toggle switch, a dialog, or a toast, if one already exists in production)
  before build starts.
- Toggle switch, filter chip, and toast anatomies should go to
  `design-system-guardian` for formal DESIGN.md §10 entries — they are very
  likely reused elsewhere in the system already or will be needed again.
- The clipboard-write side effect PO flagged in Screen Flow §5 item 8 needs a
  quick confirmation from whoever built the original prototype — not a design
  concern, but noted so it doesn't get lost before `angular-implementer`
  starts.

**4. Next**
- PO reviews this handoff, resolves the "ลบ" icon open item, and confirms
  the `[proposed]` success/dialog/empty-state token usage is acceptable to
  ship without further verification (or blocks until `Ref/` evidence exists).
- On approval → `angular-implementer` builds S1–S8 as Angular 22 standalone
  components per AGENT.md §2.4, using this handoff's primitives table and
  token map, and asks `design-system-guardian` to formalise the three new
  component anatomies in §3 before or alongside the build.
