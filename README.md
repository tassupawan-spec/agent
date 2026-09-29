# CENTRAL GROUP SPRINT — TMS Design System

Design system and UI implementation guide for the **Central Group Sprint**
transportation & logistics management system (TMS).

This repository is the single source of truth for how every TMS screen looks
and behaves: design tokens, UI primitives, layout patterns, and the rules that
keep 200 screens looking like one product.

---

## Documents

| File | What it is | Read it when |
| --- | --- | --- |
| **[DESIGN.md](./DESIGN.md)** | The token contract — every colour, size, spacing, radius and component token, calibrated against the production screen | Building or reviewing any UI |
| **[CLAUDE.md](./CLAUDE.md)** | Operating rules for AI assistants — including §6, the design-generation contract for Claude Design mockups | Always loaded automatically by Claude Code / Cowork |
| **[AGENT.md](./AGENT.md)** | Agent roles, task playbooks and handoff contracts | Delegating multi-step design or UI work to agents |
| **[styles/tokens.css](./styles/tokens.css)** | The tokens themselves, as CSS custom properties | Wiring the tokens into the app |
| **[Ref/](./Ref/)** | Production screenshots — the visual ground truth | Before assuming anything about how a screen looks |

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

> This is derived from `Ref/Screenshot 2026-08-25 114037.png`
> (การจัดการงานขนส่ง). Values in DESIGN.md tagged **[measured]** came from that
> file; anything tagged **[proposed]** is still unverified — see
> [DESIGN.md §0](./DESIGN.md#0-reference).

---

## Two ways this repo is used

**Designing** — Claude Design canvases, HTML mockups and screen flows are
generated from these documents. The token block from `styles/tokens.css` is
pasted inline into every mockup so a design and its implementation share the
exact same values. Rules: [CLAUDE.md §6](./CLAUDE.md#6-design-generation-mode-claude-design--mockups).
Roles and workflow: [AGENT.md §2.3 / §3.5](./AGENT.md).

**Implementing** — the same tokens are consumed by Angular components. A design
that used tokens converts to code with no visual translation step.

---

## Technical foundation

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
├── DESIGN.md
├── README.md
├── CLAUDE.md
├── AGENT.md
│
├── Ref/                    # production screenshots — visual ground truth
│   └── Screenshot 2026-08-25 114037.png
│
├── styles/
│   ├── tokens.css          # design tokens — the single source of truth
│   ├── reset.css           # normalisation
│   ├── typography.css      # type role classes built from tokens
│   └── globals.css         # app-level base styles, imports the above
│
└── src/
    └── app/
        ├── core/
        │   ├── layout/     # app shell, sidebar, top bar, breadcrumb
        │   └── services/   # http, auth, notification, config
        │
        ├── shared/
        │   ├── ui/         # design system primitives
        │   │   ├── button/
        │   │   ├── input/
        │   │   ├── select/
        │   │   ├── date-picker/
        │   │   ├── card/
        │   │   ├── filter-bar/
        │   │   ├── table/
        │   │   ├── status/
        │   │   ├── dialog/
        │   │   ├── pagination/
        │   │   └── empty-state/
        │   └── models/     # shared types, enums, DTO contracts
        │
        └── features/       # one folder per business domain
            ├── route-planning/     # ระบบจัดเส้นทาง
            ├── transport-jobs/     # การจัดการงานขนส่ง
            ├── shipments/          # รายการขนส่ง
            ├── sales/              # การขาย
            └── ...
```

**Feature folder shape**

```text
features/<domain>/
├── pages/            # routed page components
├── components/       # components used only by this domain
├── services/         # domain data access
├── models/           # domain types
└── <domain>.routes.ts
```

---

## Getting started

```bash
npm install
npm start          # dev server
npm run build      # production build
npm test           # unit tests
npm run lint       # lint + style rules
```

Import the token layer once, at the top of `styles/globals.css`:

```css
@import "./tokens.css";
@import "./reset.css";
@import "./typography.css";
```

Then reference tokens in any component stylesheet:

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

The full definition of done is in [DESIGN.md §11](./DESIGN.md#11-governance).

---

## Contributing a new UI primitive

1. Check `Ref/` — does a production screen already show this pattern?
2. Confirm no existing primitive covers the need.
3. Define its token map first (see DESIGN.md §10) — reuse existing tokens.
4. Build it as a standalone, OnPush component under `shared/ui/`.
5. Cover every state: default, hover, focus, active, disabled, error, loading,
   empty.
6. Document variants, inputs/outputs and accessibility notes in a README beside
   the component.
7. Add the token map entry to DESIGN.md §10.

---

## Conventions

| Thing | Convention | Example |
| --- | --- | --- |
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

**Version 1.1.0** — token contract calibrated against the production reference.
Open questions (font family, success/info colours, dialog anatomy) are listed in
[DESIGN.md §0](./DESIGN.md#0-reference).
Change history: [DESIGN.md §12](./DESIGN.md#12-change-log).
