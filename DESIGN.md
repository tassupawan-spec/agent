# DESIGN.md — CENTRAL GROUP SPRINT · TMS Design System

> **Purpose.** This document is the canonical human-readable Design System Contract for the TMS product.
>
> It defines the product's visual language, design principles, design tokens, component contracts, layout conventions, interaction patterns, accessibility requirements, responsive behavior, and governance rules.
>
> **Authoritative token implementation:** `styles/tokens.css`
>
> **Core rule:** if a visual value is already represented by an approved token, components must use the token rather than hardcoding the value.

**Version:** 2.0.0 · **Status:** Design System Contract · **Owner:** Design System

---

## 0. Design System Scope

The TMS Design System supports a **desktop-first enterprise operations application** for logistics, transportation, order and back-office workflows.

The interface is **Thai-first**. UI labels, headings and operational data are primarily Thai, while mixed Thai, Latin codes and English enum values are supported, for example:

- `Delivery`
- `NORMAL`
- `X-Booster`
- `Planning Unconfirmed Pickup`

### 0.1 Design System responsibilities

This document defines:

- Visual language
- Design principles
- Design tokens
- Typography
- Spacing
- Layout
- Responsive behavior
- Component contracts
- Interaction states
- Accessibility requirements
- Content and localization rules
- Motion and layering
- Design governance

This document does **not** define:

- Business rules
- Product requirements
- User journeys
- Feature-specific navigation
- API behavior
- Validation logic owned by a product or UX specification
- Individual screen requirements
- Screen IDs or screen-specific prototypes

### 0.2 Design System boundaries

The Design System defines **how an interface should be presented**.

Product and UX specifications define **what the interface should do**.

Example:

- Design System: Primary actions use the primary button pattern.
- Product Requirement: A user can lock a vehicle.
- UX Specification: The lock action is available from a specific workflow state.

The Design System must not invent the latter two.

### 0.3 Design Context

The Design System is implemented through the following project context:

```text
DESIGN.md
    ↓
Human-readable Design System Contract

styles/tokens.css
    ↓
Authoritative token implementation

Ref/
    ↓
Optional visual references used for validation and discovery
```

Visual references are supporting evidence. They are not required for the Design System to remain valid.

---

## 1. Design Principles

### 1.1 Enterprise Operations First

Optimize for repeated operational tasks rather than marketing presentation.

### 1.2 Information Dense, Not Visually Dense

Support large datasets and repeated workflows while maintaining sufficient spacing, hierarchy and readability.

### 1.3 Scannability

Wide operational tables may contain many columns. Information hierarchy, alignment, wrapping and consistent column treatment must make data easy to scan.

### 1.4 Predictable Interaction

The same action should look and behave consistently across features.

### 1.5 Reuse Before Reinvention

Prefer existing tokens, components and interaction patterns before introducing new ones.

### 1.6 Soft Visual Separation

Use surfaces, spacing and elevation before introducing heavy borders.

### 1.7 Restrained Visual Language

Avoid decorative visual treatment that does not improve task completion.

The system avoids:

- Gradients
- Glassmorphism
- Decorative color systems
- Marketing-style hero sections
- Excessive outlines
- Excessive pill badges
- Rainbow status systems
- A new button style for each feature

### 1.8 Clear Action Hierarchy

Use a clear primary action within each relevant screen region. Secondary actions should not compete visually with the primary action.

### 1.9 Thai-First

Thai content must remain readable and must not be treated as Latin typography.

Do not use:

- Uppercase transformations on Thai
- Letter-spacing intended for Latin typography on Thai
- Forced truncation of Thai names when wrapping is possible

### 1.10 Accessibility by Default

Accessibility is part of the component contract, not an afterthought.

---

## 2. Visual Language

### 2.1 Overall visual character

The TMS interface uses:

- Light application shell
- White content surfaces
- Soft page background
- Navy primary brand/action language
- Restrained semantic status colors
- Soft elevation
- Minimal borders
- Clear information hierarchy
- Compact but readable operational density

### 2.2 Application shell

The application shell is light.

The sidebar and top bar use the shell surface rather than a dark navigation background.

Navy is reserved primarily for:

- Brand emphasis
- Page titles
- Navigation text
- Primary actions

### 2.3 Surface hierarchy

The default hierarchy is:

```text
Page
└── Surface / Content
    ├── Card
    │   ├── Section Header
    │   ├── Toolbar
    │   ├── Table / Form / Content
    │   └── Paginator
    └── Supporting content
```

Cards use white surfaces and soft elevation rather than heavy borders.

### 2.4 Separation

Cards and the application shell should normally use elevation and surface contrast.

Hard 1px lines are reserved for:

- Table row dividers
- Card section rules
- Form/control outlines
- Other explicitly defined component boundaries

---

## 3. Token Architecture

The Design System uses three token layers.

```text
Layer 1 — PRIMITIVES
Raw palette and base values.
Examples:
--color-primary-500
--color-neutral-300

        ↓

Layer 2 — SEMANTIC
Intent-based values.
Examples:
--surface-default
--text-secondary
--border-default
--action-primary-bg

        ↓

Layer 3 — COMPONENT
Values genuinely specific to a reusable component.
Examples:
--table-row-min-height
--nav-item-height
```

### 3.1 Token rules

Components should normally consume semantic or component tokens.

A component referencing a primitive directly is considered a design-system exception and should have a documented reason.

### 3.2 Token implementation

`styles/tokens.css` is the authoritative implementation of token values.

The relationship is:

```text
DESIGN.md
    ↓
Human-readable rules and token contract

styles/tokens.css
    ↓
Authoritative token values and mappings

Components
    ↓
Consume semantic/component tokens
```

### 3.3 Naming convention

```text
--<category>-<role>-<variant?>-<state?>
```

Examples:

```text
--surface-default
--action-primary-bg-hover
--status-warning-icon
```

### 3.4 Token categories

The current token system includes:

- `color`
- `surface`
- `text`
- `border`
- `action`
- `status`
- `focus`
- `font`
- `space`
- `radius`
- `shadow`
- `control`
- `icon`
- `table`
- `layout`
- `nav`
- `z`
- `duration`
- `easing`
- `transition`
- `mat-sys`

### 3.5 Design System token status

Tokens use the following lifecycle:

- **APPROVED** — part of the active Design System contract
- **PROPOSED** — candidate value requiring validation/approval
- **DEPRECATED** — retained temporarily for migration

A proposed token must be explicitly flagged when used in design handoff.

---

## 4. Color

### 4.1 Primitive colors

#### Primary — Navy

`--color-primary-500` `#334d6e` is the primary brand color.

| Token | Value | Status | Use |
|---|---|---|---|
| `--color-primary-900` | `#16233a` | APPROVED | Deep navy, rare |
| `--color-primary-800` | `#1d2f4a` | APPROVED | Dark-theme selection |
| `--color-primary-700` | `#273b5b` | APPROVED | Navigation emphasis, pressed action |
| `--color-primary-600` | `#2c4463` | APPROVED | Action hover |
| `--color-primary-500` | `#334d6e` | APPROVED | Primary actions, logo, page title |
| `--color-primary-400` | `#4a6284` | APPROVED | Secondary emphasis |
| `--color-primary-300` | `#7488a3` | APPROVED | Secondary/dark-theme link |
| `--color-primary-200` | `#a8b6c8` | APPROVED | Focus halo |
| `--color-primary-100` | `#d5dce5` | APPROVED | Selection border |
| `--color-primary-50` | `#eef1f5` | APPROVED | Selected row |

#### Slate

Slate is the blue-grey layer used for secondary text, icons and control outlines.

| Token | Value | Status | Use |
|---|---|---|---|
| `--color-slate-600` | `#44566c` | APPROVED | Toolbar/filter icon |
| `--color-slate-500` | `#5a6b7f` | APPROVED | Section header, breadcrumb, utility link |
| `--color-slate-400` | `#707683` | APPROVED | Field label, placeholder, input outline, top-bar icon |
| `--color-slate-300` | `#98a1ac` | APPROVED | Disabled slate |

#### Neutral

Neutral is used for structure and general UI content.

| Token | Value | Status | Use |
|---|---|---|---|
| `--color-neutral-900` | `#212121` | APPROVED | Primary text, table cell value |
| `--color-neutral-700` | `#4a4a4a` | APPROVED | Strong body text |
| `--color-neutral-500` | `#777777` | APPROVED | Checkbox/radio outline |
| `--color-neutral-400` | `#9d9d9c` | APPROVED | Disabled text, faint icon |
| `--color-neutral-300` | `#dee2e6` | APPROVED | Table row divider |
| `--color-neutral-250` | `#dfdfdf` | APPROVED | Card section rule |
| `--color-neutral-200` | `#e3e3e3` | APPROVED | Disabled fill |
| `--color-neutral-100` | `#f4f4f4` | APPROVED | Hover/active navigation |
| `--color-neutral-50` | `#fafafa` | APPROVED | Page background |
| `--color-white` | `#ffffff` | APPROVED | Content surfaces and shell |

### 4.2 Semantic status colors

| Family | 600 | 500 | 100 | 50 | Status |
|---|---|---|---|---|---|
| Warning | `#d98f16` | `#ffb946` | `#ffeccb` | `#fff8ec` | APPROVED |
| Danger | `#c04a4a` | `#da6060` | `#f7d9d9` | `#fdf0f0` | APPROVED |
| Success | `#268a5c` | `#2e9e6b` | `#d3ece0` | `#eff8f3` | PROPOSED |
| Info | `#2f74a8` | `#3d8ec7` | `#d6e8f4` | `#eff6fb` | PROPOSED |

### 4.3 Semantic surfaces, text and borders

| Token | Value | Use |
|---|---|---|
| `--surface-page` | `#fafafa` | Application background |
| `--surface-default` | `#ffffff` | Cards, tables, forms |
| `--surface-shell` | `#ffffff` | Sidebar and top bar |
| `--surface-raised` | `#ffffff` | Dialog, dropdown, popover |
| `--surface-hover` | `#f4f4f4` | Row/menu hover |
| `--surface-active` | `#f4f4f4` | Active navigation |
| `--surface-selected` | `#eef1f5` | Selected table row |
| `--surface-overlay` | `rgba(33,33,33,.40)` | Modal scrim |
| `--text-primary` | `#212121` | Body and table values |
| `--text-secondary` | `#5a6b7f` | Section headers and breadcrumb |
| `--text-tertiary` | `#707683` | Labels, metadata, placeholder |
| `--text-brand` | `#334d6e` | Page title and brand |
| `--text-nav` | `#273b5b` | Navigation labels |
| `--text-link` | `#5a6b7f` | Utility link |
| `--border-default` | `#dee2e6` | Table row divider |
| `--border-divider` | `#dfdfdf` | Section rule |
| `--border-control` | `#707683` | Input/select outline |
| `--border-selection` | `#777777` | Checkbox/radio outline |

Cards and the sidebar do not require border tokens for their primary separation; use `--shadow-card` and `--shadow-shell`.

### 4.4 Action tokens

| Variant | Background | Hover | Active | Text | Border |
|---|---|---|---|---|---|
| Primary | `--action-primary-bg` | `--action-primary-bg-hover` | `--action-primary-bg-active` | white | none |
| Secondary | white | `--action-secondary-bg-hover` | — | `#334d6e` | `#334d6e` |
| Ghost / icon | transparent | `--action-ghost-bg-hover` | — | `--action-ghost-text` | none |
| Danger | `#da6060` | `#c04a4a` | — | white | none |

Disabled actions use the disabled surface/text tokens, no hover transition and `cursor: not-allowed`.

Use one primary button per screen region where a clear primary action exists.

### 4.5 Status indicators

The default status pattern is:

```text
[status icon] [plain label]
```

Do not use filled pill badges as the default status presentation.

| Status | Icon | Meaning |
|---|---|---|
| Neutral | `--status-neutral-icon` | Draft, Inactive, `-` |
| Warning | `--status-warning-icon` | Pending, Partial, Delayed |
| Danger | `--status-danger-icon` | Failed, Cancelled, Overdue |
| Success | `--status-success-icon` | Delivered, Completed |
| Info | `--status-info-icon` | In Transit, Processing |

Long workflow states should remain readable plain text when a badge would reduce readability.

### 4.6 Contrast

- Body and label text on any surface: **≥ 4.5:1**
- Text ≥ 18px or bold ≥ 14px: **≥ 3:1**
- Control outlines and focus indicators against adjacent surfaces: **≥ 3:1**
- Status must never be signalled by color alone

The warning color `#ffb946` must not be used as text on white. It may be used as an icon when accompanied by a readable text label.

---

## 5. Typography

### 5.1 Font family

The intended Thai-first stack is:

```text
Prompt → Sarabun → Noto Sans Thai → system
```

The production font selection should be kept consistent across the product once approved.

### 5.2 Type scale

| Token | px | Typical use |
|---|---:|---|
| `--font-size-xs` | 11 | Dense tag, chart axis |
| `--font-size-sm` | 12 | Helper text, paginator |
| `--font-size-md` | 13 | Body, table, input, button, label |
| `--font-size-lg` | 14 | Emphasized value |
| `--font-size-xl` | 16 | Dialog title |
| `--font-size-2xl` | 18 | Section header |
| `--font-size-3xl` | 20 | Page title |
| `--font-size-4xl` | 24 | KPI figure |

Weights:

- `400` Regular
- `500` Medium
- `600` Semibold
- `700` Bold

### 5.3 Role composites

| Role | Size / Weight / Color |
|---|---|
| Page title | `3xl / 600 / --text-brand` |
| Breadcrumb | `md / 400 / --text-secondary` |
| Card section header | `2xl / 600 / --text-secondary` |
| Field label | `md / 400 / --text-tertiary` |
| Table column header | `md / 600 / --text-primary` |
| Table cell value | `md / 400 / --text-primary` |
| Button label | `md / 500` |
| Sidebar item | `md / 500 / --text-nav` |
| Sidebar sub-item | `md / 400 / --text-nav` |
| Utility link | `md / 400 / --text-link` |
| Helper / hint | `sm / 400 / --text-tertiary` |
| Error message | `sm / 400 / --text-danger` |

### 5.4 Thai typography rules

Do not uppercase Thai.

Do not apply Latin-oriented letter-spacing to Thai.

`--letter-spacing-wide` is reserved for Latin-only strings where required.

### 5.5 Numeric typography

Use:

```css
font-variant-numeric: tabular-nums;
```

for:

- Numbers
- Amounts
- Quantities
- Ratios
- Pagination counts

Dates, codes and enum values remain left-aligned unless the component contract states otherwise.

Quantities and monetary values are right-aligned.

---

## 6. Spacing

The system uses a 4px base grid.

`--space-1` (2px) is reserved for optical nudges.

| Token | px | Typical use |
|---|---:|---|
| `--space-2` | 4 | Icon ↔ label |
| `--space-4` | 8 | Control padding, tight stack |
| `--space-5` | 12 | Table cell vertical padding, label ↔ input |
| `--space-6` | 16 | Table cell horizontal padding, form row gap |
| `--space-7` | 20 | Card horizontal padding |
| `--space-8` | 24 | Page vertical padding, form column gap |
| `--space-9` | 28 | Page horizontal gutter |
| `--space-10` | 32 | Top bar → page title |
| `--space-11`–`--space-13` | 40 / 48 / 64 | Large gaps and empty states |

### 6.1 Spacing rhythm

- Inside a control: 8–12px
- Between fields: 16–24px
- Between page blocks: 24–32px

Use tokens rather than raw values.

---

## 7. Border, Radius & Elevation

### 7.1 Radius

Default radius is 4px.

| Token | px | Use |
|---|---:|---|
| `--radius-xs` | 2 | Checkbox |
| `--radius-sm` | 4 | Button, input, select, card, table container |
| `--radius-md` | 4 | Standard controls |
| `--radius-lg` | 8 | Dialog |
| `--radius-full` | ∞ | Avatar, status dot, rounded search field |

### 7.2 Border width

- `--border-width-hairline`: 1px
- `--border-width-thick`: 2px for focused controls

### 7.3 Elevation

Use the lowest elevation that clearly establishes hierarchy.

| Token | Value | Use |
|---|---|---|
| `--shadow-none` | none | Table rows and inline blocks |
| `--shadow-shell` | `0 0 6px rgba(33,33,33,.06)` | Sidebar and top bar |
| `--shadow-card` | `0 1px 6px rgba(33,33,33,.06)` | Content container |
| `--shadow-md` | `0 4px 12px rgba(33,33,33,.12)` | Dropdown, popover, autocomplete |
| `--shadow-lg` | `0 12px 32px rgba(33,33,33,.18)` | Modal dialog |

Do not put a border on a standard card when shadow and surface contrast provide sufficient separation.

---

## 8. Control & Table Sizing

### 8.1 Controls

| Token | px | Use |
|---|---:|---|
| `--control-height-sm` | 32 | Dense toolbar control |
| `--control-height-md` | 36 | Default button/input/select/datepicker |
| `--control-height-lg` | 40 | Low-density primary form |

Icons:

- `--icon-size-sm`: 16px
- `--icon-size-md`: 18px
- `--icon-size-lg`: 20px
- `--icon-size-xl`: 32px
- `--selection-control-size`: 16px

Minimum repeated interaction target: **32 × 32px**.

### 8.2 Table

| Token | px |
|---|---:|
| `--table-header-height` | 48 |
| `--table-row-min-height` | 48 |
| `--table-cell-padding-x` | 16 |
| `--table-cell-padding-y` | 12 |
| `--table-paginator-height` | 56 |

Table rows are content-driven.

Cells should wrap rather than truncate Thai names and operational text.

Do not force a fixed row height when content requires additional lines.

---

## 9. Layout

### 9.1 Application shell

| Token | Value |
|---|---:|
| `--layout-sidebar-width` | 234px |
| `--layout-sidebar-width-collapsed` | 64px |
| `--layout-topbar-height` | 56px |
| `--layout-page-padding-x` | 28px |
| `--layout-page-padding-y` | 24px |
| `--layout-card-header-height` | 64px |
| `--layout-card-padding-x` | 20px |
| `--layout-card-padding-y` | 16px |
| `--layout-content-max-width` | none |
| `--nav-item-height` | 40px |
| `--nav-subitem-height` | 32px |
| `--layout-dialog-width-sm` | 420px |
| `--layout-dialog-width-md` | 600px |
| `--layout-dialog-width-lg` | 880px |

### 9.2 Standard page composition

```text
Application Shell
├── Sidebar
│   ├── Logo
│   ├── Account / Branch
│   └── Navigation
│
├── Top Bar
│   ├── Navigation control
│   └── Utility actions
│
└── Page Content
    ├── Page Title
    ├── Breadcrumb
    ├── Filter / Search Region
    └── Content Region
        ├── Card
        │   ├── Section Header
        │   ├── Toolbar
        │   ├── Table / Form / Content
        │   └── Paginator
        └── Supporting Content
```

### 9.3 Filter region

The standard filter region sits directly on the page surface rather than inside a card when the feature does not require a contained filter panel.

Rules:

- Labels sit above controls.
- Controls align to a consistent baseline.
- The submit action aligns with the control row.
- Supporting utility links may sit below the control row and align right.
- Use the standard form grid.

The exact number of fields is feature-specific and must not be inferred from the Design System.

### 9.4 Card

A standard card uses:

- `--surface-default`
- `--radius-sm`
- `--shadow-card`
- No standard outer border
- Section header height `--layout-card-header-height`
- Section rule `--border-divider`
- Card padding tokens

### 9.5 Form grid

Use a 12-column grid where a form layout benefits from predictable alignment.

Common spans:

- 4 columns: short identifiers and quantities
- 6 columns: standard fields
- 12 columns: long text, address and remarks

These are defaults, not mandatory business rules.

---

## 10. Responsive Design

TMS is desktop-first.

| Breakpoint | Min width | Behavior |
|---|---:|---|
| `sm` | 768px | Not a primary target; tables may scroll horizontally |
| `md` | 1024px | Sidebar collapses; filter grid adapts |
| `lg` | 1280px | Supported desktop layout |
| `xl` | 1920px | Primary wide-screen target |

### 10.1 Responsive principles

At reduced widths:

- Preserve critical information
- Allow tables to scroll horizontally when necessary
- Collapse navigation where defined
- Reduce filter columns
- Preserve readable controls
- Avoid hiding required actions solely to make a layout appear compact

Responsive behavior must not introduce a new visual language.

---

## 11. Z-Index & Motion

### 11.1 Z-index

Use a centralized stacking ladder.

| Token | Value | Use |
|---|---:|---|
| `--z-sticky` | 100 | Sticky content |
| `--z-topbar` | 200 | Top bar |
| `--z-sidebar` | 300 | Sidebar |
| `--z-dropdown` | 400 | Dropdown/popover |
| `--z-overlay` | 500 | Modal overlay |
| `--z-dialog` | 600 | Dialog |
| `--z-toast` | 700 | Toast |
| `--z-tooltip` | 800 | Tooltip |

Do not write raw `z-index` values in feature components.

### 11.2 Motion

Motion is functional rather than decorative.

| Token | Value | Use |
|---|---:|---|
| `--duration-instant` | 80ms | Hover |
| `--duration-fast` | 120ms | Control state |
| `--duration-normal` | 180ms | Dropdown, drawer, navigation |
| `--duration-slow` | 240ms | Dialog |
| `--easing-standard` | system token | Default easing |

Respect `prefers-reduced-motion`.

Under reduced motion, durations collapse to zero.

Do not animate:

- Full table entrances
- Table rows
- Page loads

unless a specific interaction pattern explicitly requires it.

---

## 12. Component Contracts

Each Design System component should define:

1. Purpose
2. When to use
3. When not to use
4. Anatomy
5. Tokens
6. Variants
7. States
8. Interaction
9. Accessibility
10. Content rules
11. Responsive behavior

Only components with sufficient Design System evidence should be documented here.

### 12.1 App Shell — Sidebar

**Purpose:** Primary application navigation.

**Contract:**

- Width: `--layout-sidebar-width`
- Background: `--surface-shell`
- Elevation: `--shadow-shell`
- No hard right border
- Navigation item height: `--nav-item-height`
- Label: `md / 500 / --text-nav`
- Icon: `--icon-size-lg`
- Active item: `--surface-active`
- Sub-item height: `--nav-subitem-height`

The sidebar should support collapsed behavior according to the responsive contract.

### 12.2 App Shell — Top Bar

**Purpose:** Global navigation and utility actions.

**Contract:**

- Height: `--layout-topbar-height`
- Background: `--surface-shell`
- Elevation: `--shadow-shell`
- Navigation control: `--icon-size-lg`
- Utility actions: `--text-tertiary`
- Separator: `--border-default`

### 12.3 Page Header

**Purpose:** Establish page identity and navigation context.

**Anatomy:**

```text
Page Title
Breadcrumb
Optional Page Actions
```

Title:

`3xl / 600 / --text-brand`

Breadcrumb:

`md / 400 / --text-secondary`

Page-level actions are right-aligned when present.

### 12.4 Breadcrumb

**Pattern:**

```text
Home icon › Parent › Current
```

Use consistent separators and readable hierarchy.

### 12.5 Filter Bar

**Purpose:** Filter/search operational datasets.

**Contract:**

- Standard 12-column layout
- Label above control
- `--control-height-md`
- Consistent field gap
- Primary search action uses primary action pattern
- Utility links are secondary visual emphasis

### 12.6 Button

**Purpose:** Trigger an explicit action.

**Contract:**

- Height: `--control-height-md`
- Radius: `--radius-sm`
- Horizontal padding: tokenized
- Font: `--font-size-md / --font-weight-medium`
- Icon gap: `--space-2`
- Colors: action tokens
- Transition: control transition token
- Focus: `--focus-ring`

Variants:

- Primary
- Secondary
- Ghost/Icon
- Danger

Use the least visually dominant variant that communicates the action correctly.

### 12.7 Input / Select / Date Picker

**Purpose:** Collect or select structured user input.

Default form controls use the Angular Material outline pattern where the component library is used.

Contract:

- Height: `--control-height-md`
- Radius: `--radius-sm`
- Background: `--surface-default`
- Outline: `--border-control`
- Focus: `--border-focus`
- Error: `--border-danger`
- Label above the field
- Helper/error text below
- Trailing icons use `--icon-size-md`

Avoid feature-level `::ng-deep` overrides.

### 12.8 Card

**Purpose:** Group related content.

Contract:

- `--surface-default`
- `--radius-sm`
- `--shadow-card`
- No standard outer border
- Section header: `--layout-card-header-height`
- Header title: `2xl / 600 / --text-secondary`
- Header rule: `--border-divider`
- Body padding: card spacing tokens

### 12.9 Table

**Purpose:** Present operational datasets.

Contract:

- Table lives inside a content card when the page composition calls for a card
- Header height: `--table-header-height`
- Header background: `--surface-default`
- Header text: `md / 600 / --text-primary`
- Sentence-case headers
- Row minimum height: `--table-row-min-height`
- Cell padding: table padding tokens
- Row divider: `--border-default`
- Last row normally has no bottom divider
- Hover: `--surface-hover`
- Selected: `--surface-selected`
- Content wraps instead of truncating
- Numeric values use tabular numbers and right alignment where appropriate
- Trailing action column is right-aligned

### 12.10 Table Toolbar

**Purpose:** Provide table-level actions and search.

Typical structure:

```text
Primary Action(s)                         Search
```

Search control may use a rounded field:

- `--control-height-md`
- `--radius-full`
- Leading search icon
- `--text-tertiary`

### 12.11 Status Indicator

**Purpose:** Communicate workflow state.

Default anatomy:

```text
Status icon + Label
```

Rules:

- Do not use a filled pill by default
- Do not communicate state by color alone
- Long workflow states may remain plain text
- Icon and label must remain understandable without color

### 12.12 Paginator

Use the standard pagination component where available.

Contract:

- Height: `--table-paginator-height`
- Right-aligned inside table container
- Text: `--font-size-sm / --text-tertiary`
- Page-size control: `--control-height-sm`
- Navigation icons: `--icon-size-md`
- Disabled controls use disabled tokens

### 12.13 Dialog

**Status:** PROPOSED

Contract:

- Scrim: `--surface-overlay`
- Layer: `--z-overlay`
- Dialog: `--z-dialog`
- Surface: `--surface-raised`
- Radius: `--radius-lg`
- Elevation: `--shadow-lg`
- Width: dialog width tokens
- Header: `xl / 600`
- Footer actions right-aligned

Accessibility:

- Focus is trapped
- `Esc` closes when the interaction allows it
- Focus returns to the trigger
- Dialog has an accessible name

### 12.14 Empty State

**Status:** PROPOSED

Contract:

- Centered within the relevant content region
- Vertical spacing uses large spacing tokens
- Icon: `--icon-size-xl`
- Icon color: `--color-neutral-400`
- Title: `lg / 600 / --text-primary`
- Description: `md / 400 / --text-tertiary`
- At most one primary action unless the workflow requires otherwise

---

## 13. Interaction & State Patterns

### 13.1 Standard visual states

Where applicable, components should support:

- Default
- Hover
- Focus
- Active
- Selected
- Disabled
- Loading
- Error
- Empty
- Read-only

Not every component requires every state.

Each component contract should specify which states are meaningful.

### 13.2 Focus

Focus must remain visible and must use the approved focus tokens.

Do not remove focus indication for aesthetic reasons.

### 13.3 Disabled

Disabled controls:

- Use disabled surface/text tokens
- Do not use hover transitions
- Do not appear actionable
- Must retain sufficient contrast to communicate state

### 13.4 Loading

Loading states must preserve layout stability where possible.

Do not introduce decorative loading animation where a simple state indicator is sufficient.

### 13.5 Error

Errors must be communicated through:

- Text
- Appropriate icon or structural indicator where applicable
- Focus/field state
- Accessible association with the relevant control

Color alone is insufficient.

### 13.6 Empty

Empty states should explain:

1. What is empty
2. Why it may be empty, when useful
3. What the user can do next, when an action exists

---

## 14. Accessibility

The Design System defines accessibility requirements and implementation patterns aligned to the specified WCAG criteria.

It does not claim that every implementation is automatically compliant.

### 14.1 Contrast

Use the color contrast requirements defined in the Color section.

### 14.2 Keyboard

Interactive controls must be reachable and operable using keyboard interaction.

Keyboard order should follow the visual and task hierarchy.

### 14.3 Focus

Focus must be visible.

Use the approved focus-ring token and maintain sufficient contrast against adjacent surfaces.

### 14.4 Target size

Anything clicked repeatedly should meet the Design System minimum target of 32 × 32px unless a documented platform constraint requires another treatment.

### 14.5 Color independence

Never communicate a state using color alone.

### 14.6 Forms

- Labels must be visible and associated with controls.
- Error messages must be associated with the relevant field.
- Required state must not rely solely on color.
- Placeholder text must not replace the label.

### 14.7 Tables

Tables must preserve semantic relationships between:

- Headers
- Cells
- Row selection
- Actions
- Pagination

Do not sacrifice table semantics solely for visual compactness.

### 14.8 Motion

Respect `prefers-reduced-motion`.

### 14.9 Text

- Do not uppercase Thai
- Do not apply inappropriate tracking to Thai
- Do not truncate important Thai operational data when wrapping is possible

---

## 15. Content & Localization

### 15.1 Language

TMS is Thai-first.

Support mixed content where required:

```text
Thai label + Latin code + English enum
```

Examples:

```text
ช่องทางการขาย
Delivery
NORMAL
Planning Unconfirmed Pickup
```

### 15.2 Labels

Labels should be concise and task-oriented.

Do not replace established operational terminology without product/UX evidence.

### 15.3 Table headers

Use sentence-case Thai labels.

Do not uppercase Thai.

### 15.4 Long content

Allow operational content to wrap when necessary.

Do not use ellipsis as the default treatment for important names, addresses or workflow states.

### 15.5 Numeric content

- Dates and codes: normally left-aligned
- Quantities: right-aligned
- Monetary values: right-aligned
- Ratios and counts: use tabular numerals

---

## 16. Design System Governance

### 16.1 Adding a token

Before adding a token:

1. Check whether an existing token is sufficient.
2. Determine whether the need is semantic or component-specific.
3. Add a primitive only when a genuinely new raw value is required.
4. Add the semantic alias.
5. Document the token in this file.
6. Add/update it in `styles/tokens.css`.
7. Validate usage.
8. Promote `PROPOSED` to `APPROVED` after validation.

Never introduce a component hardcoded value first and document it later.

### 16.2 Adding a component

Before adding a component:

1. Check whether an existing component solves the use case.
2. Define its purpose.
3. Define when it should and should not be used.
4. Define tokens.
5. Define variants.
6. Define states.
7. Define accessibility behavior.
8. Define responsive behavior.
9. Document the component.
10. Implement it in the shared component system when applicable.

### 16.3 Deprecating a token

Keep a deprecated token aliased to its replacement for one release where practical.

Mark it in `styles/tokens.css`:

```css
/* @deprecated → --new-token */
```

Remove it after all usages are migrated.

### 16.4 Design decisions

A Design System change must distinguish:

- **System rule** — reusable across features
- **Feature decision** — specific to a product/UX requirement
- **Temporary proposal** — not yet approved

Feature-specific decisions must not be silently promoted into the Design System.

---

## 17. Design System vs Visual Reference

The Design System and visual references serve different purposes.

### 17.1 Design System

Defines reusable:

- Tokens
- Components
- Patterns
- Layout conventions
- Typography
- Accessibility
- Interaction conventions

### 17.2 Visual Reference

May include:

- Production screenshot
- Existing UI capture
- Prototype
- Mockup
- External design reference

A visual reference can be used to:

- Discover existing patterns
- Validate consistency
- Identify visual inconsistencies
- Calibrate proposed tokens
- Compare a design against an existing product experience

### 17.3 Boundary

A visual reference is evidence, not the Design System.

Deleting or moving a reference image must not invalidate this document.

The Design System must describe the reusable rule that a reference helped establish, rather than preserving the reference as a runtime dependency.

---

## 18. Design System vs Product Requirements

The Design System defines presentation and interaction conventions.

It does not define product behavior.

### 18.1 Design System may define

- Button appearance
- Table appearance
- Field appearance
- Status presentation
- Spacing
- Typography
- Focus treatment
- Responsive presentation
- Accessibility patterns

### 18.2 Product/UX sources define

- What actions exist
- When actions are available
- User journey
- Navigation
- Business rules
- Validation logic
- API behavior
- Feature scope

### 18.3 Conflict rule

If a Product/UX decision conflicts with the Design System:

1. Do not silently change the Product/UX requirement.
2. Identify the Design System conflict.
3. Determine whether an existing Design System pattern can support the requirement.
4. If not, propose a Design System change or feature-level exception.
5. Record the decision explicitly.

---

## 19. Design System vs UI Designer

`DESIGN.md` provides rules and constraints.

The UI Designer Agent applies those rules to specific screens.

```text
DESIGN SYSTEM
    ↓
Rules / Tokens / Components / Patterns
    ↓
UI DESIGNER
    ↓
Screen / State / Interaction Design
    ↓
Design Package
```

### 19.1 DESIGN.md should not contain

- Feature-specific Screen IDs
- User Journey IDs
- Requirement IDs
- Individual screen prototypes
- Temporary screen decisions
- Feature-specific validation rules
- Feature-specific navigation flows
- Individual `.dc` artifacts

Those belong in the relevant Design Package.

### 19.2 UI Designer responsibilities

The UI Designer is responsible for applying the Design System to:

- Layout
- Visual hierarchy
- Components
- States
- Interaction presentation
- Responsive behavior
- Accessibility implementation
- Visual prototypes
- UI specifications

The UI Designer must not silently change Product or UX behavior.

---

## 20. Design System Implementation Rules

### 20.1 Token usage

Do not hardcode:

- Colors
- Spacing
- Radius
- Shadows
- Font sizes
- Z-index
- Motion durations

when an approved token exists.

### 20.2 Angular Material

Angular Material is the component base where applicable.

Theme it through the `--mat-sys-*` bridge in `styles/tokens.css`.

Do not use `::ng-deep` in feature-level components to override Material components.

### 20.3 Existing components

Prefer reusable shared components over feature-local reimplementations.

If an existing component cannot support the requirement:

1. Check whether a variant is appropriate.
2. Check whether the Design System needs an extension.
3. Avoid creating a visually similar but technically separate component without justification.

### 20.4 Exceptions

A feature may require an exception.

An exception must state:

- Why the standard pattern cannot be used
- What pattern is being overridden
- Scope of the exception
- Whether the exception should become a Design System enhancement

---

## 21. Definition of Done

A UI implementation following this Design System should satisfy:

- [ ] No hardcoded visual values where approved tokens exist
- [ ] Semantic tokens are used instead of raw primitives where applicable
- [ ] Existing shared components are reused where applicable
- [ ] Angular Material is themed through the approved token bridge
- [ ] No feature-level `::ng-deep`
- [ ] Shell remains light
- [ ] Cards use surface/elevation rather than unnecessary borders
- [ ] Thai text is never uppercased
- [ ] Thai text is not given inappropriate letter-spacing
- [ ] Important cells wrap rather than truncate
- [ ] Focus state is visible
- [ ] Contrast requirements are checked
- [ ] Status is not communicated by color alone
- [ ] Default controls respect the established density
- [ ] Table rows support content-driven height
- [ ] Keyboard path works end to end
- [ ] Responsive behavior is considered
- [ ] Existing Design System patterns are reused before introducing new ones
- [ ] Any PROPOSED token is explicitly flagged
- [ ] Any Design System exception is documented

---

## 22. Design System vs Implementation Source

The following relationship is authoritative:

```text
DESIGN.md
    │
    │ human-readable Design System rules
    ▼
styles/tokens.css
    │
    │ authoritative token implementation
    ▼
Feature UI
```

Do not reverse the relationship.

A feature component must not become the source of truth for a Design System rule without an explicit governance decision.

---

## 23. Change Log

| Version | Date | Change |
|---|---|---|
| 2.0.0 | 2026-09-29 | Reworked DESIGN.md into a reusable Design System Contract. Removed screenshot/JPG dependency, generalized visual rules, formalized Design System boundaries, component contracts, interaction states, accessibility, governance and Design System/Visual Reference separation. |
| 1.1.0 | 2026-08-25 | Previous Design System baseline containing calibrated visual values and component rules. |
| 1.0.0 | 2026-08-25 | Baseline token contract established. |

---

# Revision Notes

## Revision 2.0.0 — Design System Foundation

1. Removed direct dependency on screenshot/JPG/PNG files.
2. Removed screenshot-specific viewport and measurement references.
3. Converted useful visual observations into reusable Design System rules.
4. Preserved the existing token architecture and current token values.
5. Preserved the existing component contracts and layout conventions.
6. Formalized Design Principles.
7. Formalized Design System scope and boundaries.
8. Added explicit Design System vs Visual Reference boundary.
9. Added explicit Design System vs Product Requirement boundary.
10. Added explicit Design System vs UI Designer boundary.
11. Formalized component states.
12. Consolidated accessibility requirements into a dedicated section.
13. Formalized content and localization rules.
14. Formalized token and component governance.
15. Kept `styles/tokens.css` as the authoritative token implementation.
16. Kept the Design System independent from `CLAUDE.md`.
17. Removed feature-specific screen assumptions from the Design System.
18. Kept the document reusable as the primary Design Context for the UI Designer Agent.
