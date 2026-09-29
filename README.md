# CENTRAL GROUP SPRINT — TMS Design System & Design Pipeline

Design system and AI-assisted design pipeline for the **Central Group Sprint**
transportation & logistics management system (TMS).

This repository holds two things:

1. **The Design System** — design tokens, component contracts and the rules
   that keep every TMS screen looking like one product.
2. **The design pipeline** — three Claude Code agents that turn the owner's
   source material (prototype, user journey, API reference) into a BRD, a UX
   model and finally a hi-fi HTML Screen Flow.

---

## Documents

| File | What it is | Read it when |
| --- | --- | --- |
| **[DESIGN.md](./DESIGN.md)** | Design System contract — principles, tokens, component contracts, states, accessibility, governance | Building or reviewing any UI |
| **[CLAUDE.md](./CLAUDE.md)** | Operating rules for AI agents — design rules, design-generation mode (§6), module boundaries (§7), pipeline (§8), status & blockers (§9) | Loaded automatically by Claude Code |
| **[.claude/agents/](./.claude/agents/)** | The three pipeline agents: `ba-analyst`, `ux-designer`, `ui-designer` | Running or changing the pipeline |
| **[styles/tokens.css](./styles/tokens.css)** | The tokens themselves, as CSS custom properties | Wiring tokens into a mockup or the app |
| **[Ref/](./Ref/)** | Production screenshot used to calibrate DESIGN.md | Checking how the real product looks |

---

## Design pipeline

```text
projects/01-input-from-po/<Feature>/   Source from the owner (prototype, journey, HAR, API spec, PROC)
        │
        ▼  ba-analyst
projects/02-ba-output/<Feature>/       BA_BRD.md — requirement, AC, API list / suggestion, To Do (SA · API · FE · QA)
        │  [owner sets status: APPROVED]
        ▼  ux-designer
projects/03-ux-output/<Feature>/       Template & reuse mapping, screen-registry.json, UX model
        │  [owner sets status: APPROVED]
        ▼  ui-designer
projects/04-ui-output/<Feature>/       ScreenFlow.html (final deliverable) + hi-fi .dc screens
           [owner sets status: APPROVED]
```

- **One feature = one folder name in UpperCamelCase** (e.g. `SetupConfigTimeSlot`), identical in every stage.
- Each agent writes **only** to its own stage folder ([CLAUDE.md §7](./CLAUDE.md)).
- Every main output starts with a YAML frontmatter `status`. Agents set `IN_REVIEW`;
  **only the owner sets `APPROVED`**. The next agent will not start until the
  previous stage is `APPROVED` ([CLAUDE.md §9](./CLAUDE.md)).
- When an agent hits a missing input or a high-impact ambiguity it stops and writes
  `<Module>_Blockers.md` listing the options and **the data the owner must prepare**.
- `_archive/` folders hold superseded outputs — agents do not use them.

**Source folder layout** (`projects/01-input-from-po/`):

```text
<Feature>/
├── prototype/     # Prototype HTML (mock data — contains no real API paths)
├── journey/       # User journey / swimlane
├── api_spec/      # Existing API spec or endpoint list
├── har/           # Network export (sanitized HAR)
├── proc_spec/     # PROC / SQL
└── report/        # Example report outputs (xlsx)
_shared/           # Screens and specs not tied to one feature — also used by UX as reuse templates
```

Only the sub-folders a feature actually needs are created.
Case `REUSE` needs at least one of `api_spec/` or `har/`.

**Running a stage** (Claude Code):

```text
@ba-analyst  feature: SetupConfigTimeSlot · case: REUSE
@ux-designer feature: SetupConfigTimeSlot
@ui-designer feature: SetupConfigTimeSlot
```

`case: REUSE` = an existing menu/screen is reused (BA lists the API paths in use);
`case: NEW` = a new feature (BA suggests the APIs that should exist).

---

## Design language in one paragraph

A **light**, soft enterprise application. White sidebar and white top bar — not
a dark shell — with white content cards floating on a `#fafafa` page,
separated by soft ambient shadows rather than outlines. Navy `#334d6e` is the
only action colour: logo, page title, sidebar labels and solid buttons. Thai-
first typography at 13px, comfortable density (36px controls, 48px minimum
table rows that grow when Thai names wrap), 4px corner radius, and hard 1px
lines used only for table row dividers. Status is an inline coloured icon plus a
plain Thai label — never a pill badge. No gradients, no glassmorphism, no
oversized rounded cards, no decorative colour.

> Originally calibrated against `Ref/Screenshot 2026-08-25 114037.png`
> (การจัดการงานขนส่ง). Token status (approved vs proposed) is listed in
> DESIGN.md §3.5.

---

## Two ways this repo is used

**Designing** — the pipeline agents generate BRDs, UX models, HTML mockups and
screen flows from these documents. The token block from `styles/tokens.css` is
pasted inline into every mockup so a design and its implementation share the
exact same values. Rules: [CLAUDE.md §6](./CLAUDE.md).

**Implementing** — the same tokens are consumed by Angular components. A design
that used tokens converts to code with no visual translation step.

---

## Technical foundation (target application)

- **Angular 22**, standalone components only — no NgModules
- **Angular Material** as the component base (`mat-form-field` outline,
  `mat-select`, `mat-datepicker`, `mat-paginator`, `mat-checkbox`), themed
  **once** by mapping `--mat-sys-*` to our tokens in `styles/tokens.css` §11.
  Never `::ng-deep` a Material component inside a feature.
- **Signals** for local reactive state, `computed()` for derived state
- `input()` / `output()` function APIs on component boundaries
- Modern control flow — `@if`, `@for`, `@switch` (never `*ngIf` / `*ngFor`)
- **Reactive Forms** for anything with more than two fields
- **Strict TypeScript** — `strict: true`, no `any`
- `ChangeDetectionStrategy.OnPush` on every component
- Global tokens via CSS custom properties; component-scoped styles otherwise
- Semantic HTML and full keyboard operability

---

## Project structure

```text
.
├── README.md
├── DESIGN.md
├── CLAUDE.md
├── .claude/agents/         # ba-analyst.md · ux-designer.md · ui-designer.md
├── Ref/                    # production screenshot (calibration reference)
├── styles/
│   └── tokens.css          # design tokens — the single source of truth
└── projects/
    ├── 01-input-from-po/   # owner sources, one folder per feature (+ _shared/)
    ├── 02-ba-output/       # ba-analyst
    ├── 03-ux-output/       # ux-designer
    └── 04-ui-output/       # ui-designer
```

The application code is not in this repository yet. When it is added, it follows
this shape:

```text
src/app/
├── core/          # layout (shell, sidebar, top bar, breadcrumb), services
├── shared/
│   ├── ui/        # design system primitives (button, input, select, date-picker,
│   │              #   card, filter-bar, table, status, dialog, pagination, empty-state)
│   └── models/    # shared types, enums, DTO contracts
└── features/<domain>/
    ├── pages/ · components/ · services/ · models/
    └── <domain>.routes.ts
```

---

## Using the tokens

Reference tokens in any stylesheet or mockup:

```css
.card {
  background: var(--surface-default);
  border-radius: var(--radius-sm);
  box-shadow: var(--shadow-card);   /* no border — shadow only */
  padding: var(--layout-card-padding-y) var(--layout-card-padding-x);
}

.card__header {
  height: var(--layout-card-header-height);
  font-size: var(--font-size-2xl);
  font-weight: var(--font-weight-semibold);
  color: var(--text-secondary);
  border-bottom: var(--border-width-hairline) solid var(--border-divider);
}
```

---

## The rules that matter most

1. **No hardcoded visual values.** No hex colours, no raw px for spacing,
   radius, font-size or shadow inside a component. Use a token.
2. **Consume semantic tokens, not primitives.** `var(--text-secondary)`, not
   `var(--color-slate-500)`.
3. **The shell is light.** White sidebar, white top bar, `#fafafa` page. Never
   render a navy or dark sidebar.
4. **Separate with shadow, not borders.** Cards and the sidebar have no
   outline. Hard 1px lines are for table dividers only.
5. **Reuse before you create.** If a pattern exists, use it. A second button
   style, card style or status colour is a defect, not a feature.
6. **Preserve existing screens.** When modifying a screen, change only what was
   asked and keep its structure and visual language intact.
7. **Thai-first.** Never uppercase or letter-space Thai. Let cells wrap; never
   truncate a Thai name with an ellipsis.
8. **Comfortable density.** 36px controls, 48px minimum rows, 13px text — not a
   compact 32/36 system, and not an airy consumer one.
9. **Every interactive element is keyboard reachable** and shows
   `--focus-ring` when focused.

The full definition of done is in DESIGN.md §21.

---

## Contributing a new UI primitive

1. Confirm no existing component contract in DESIGN.md §12 covers the need.
2. Define its token map first — reuse existing tokens.
3. Build it as a standalone, OnPush component under `shared/ui/`.
4. Cover every state in DESIGN.md §13: default, hover, focus, active, disabled,
   error, loading, empty.
5. Document variants, inputs/outputs and accessibility notes in a README beside
   the component.
6. Add the component contract to DESIGN.md §12 following the governance steps in
   DESIGN.md §16.

---

## Conventions

| Thing | Convention | Example |
| --- | --- | --- |
| Feature folder (pipeline) | UpperCamelCase, same in every stage | `SetupConfigTimeSlot` |
| Component selector | `tms-` prefix, kebab-case | `tms-data-table` |
| Component class | PascalCase + `Component` | `DataTableComponent` |
| File | kebab-case | `data-table.component.ts` |
| CSS class in component | BEM-ish, block = component | `.table__cell--numeric` |
| Token | `--category-role-variant-state` | `--action-primary-bg-hover` |
| Signal | plain noun | `rows`, `selectedId` |
| Computed | derived noun | `visibleRows` |
| Output | past-tense event | `rowSelected`, `filterChanged` |

---

## Status

**DESIGN.md version 2.0.0** — Design System contract. Change history: DESIGN.md §23.
