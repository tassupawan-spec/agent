# CLAUDE.md — CENTRAL GROUP SPRINT · TMS

กติกาหลักสำหรับ Claude Code และทุก agent ใน `.claude/agents/` ที่ทำงานใน repo นี้
เลข section ของไฟล์นี้**ถูกอ้างอิงจาก agent และเอกสาร output** (เช่น `CLAUDE.md §6`) — ห้ามเปลี่ยนเลขหรือสลับลำดับ ถ้าจะเพิ่มหัวข้อให้ต่อท้าย

---

## 1. Project context

Repo นี้คือ **Design System + พื้นที่ทำงาน requirement → design** ของระบบ TMS (Transportation Management System) ของ Central Group Sprint
ยังไม่มี source code ของแอป (`src/` ใน README คือโครงสร้างเป้าหมายของ Angular 22 app)

| Path | คืออะไร |
|---|---|
| `DESIGN.md` | Design System contract — token, component contract, state, accessibility, governance |
| `styles/tokens.css` | Token จริงในรูป CSS custom properties — **source of truth ของค่า visual ทั้งหมด** |
| `.claude/agents/` | นิยาม agent 3 ตัว: `ba-analyst`, `ux-designer`, `ui-designer` (ดู §8) |
| `Ref/` | ภาพ production ที่ใช้ calibrate `DESIGN.md` — ไม่ใช่ input ของ pipeline |
| `projects/01-input-from-po/<Feature>/` | Source จากเจ้าของงาน แยกตาม feature — **อ่านอย่างเดียว ห้ามแก้** (โครงด้านล่าง) |
| `projects/01-input-from-po/_shared/` | Source ที่ไม่ผูกกับ feature เดียว — หน้าจอระบบเดิมที่ UX ใช้เป็นแม่แบบ, API spec กลาง, journey กลาง |
| `projects/02-ba-output/<Feature>/` | Output ของ `ba-analyst` |
| `projects/03-ux-output/<Feature>/` | Output ของ `ux-designer` |
| `projects/04-ui-output/<Feature>/` | Output ของ `ui-designer` — ปลายทางของ pipeline (ScreenFlow.html) |
| `projects/*/_archive/` | Output รูปแบบเก่า / ถูกแทนที่ — **agent ไม่ใช้เป็น input** |

**โครงของ Source ต่อ feature** (สร้างเฉพาะโฟลเดอร์ที่มีไฟล์):

```text
01-input-from-po/<Feature>/
├── prototype/   # Prototype HTML (ข้อมูลจำลอง — ไม่มี API path จริง)
├── journey/     # User Journey / swimlane
├── api_spec/    # API spec หรือรายการ endpoint ที่มีอยู่
├── har/         # Network export (HAR แบบ sanitized)
├── proc_spec/   # PROC / SQL
└── report/      # ตัวอย่าง report (xlsx)
```

---

## 2. Look

แอป enterprise ธีม **light**: sidebar และ top bar สีขาว, card สีขาววางบนพื้น `#fafafa` แยกด้วย shadow ไม่ใช่เส้นขอบ
**Navy `#334d6e` เป็นสี action สีเดียว** (logo, page title, sidebar label, solid button)
Thai-first, ตัวอักษร 13px, control สูง 36px, แถวตารางขั้นต่ำ 48px (สูงขึ้นได้เมื่อชื่อภาษาไทย wrap), radius 4px
Status = icon สี + label ภาษาไทย — **ไม่ใช่ pill badge**
ห้าม gradient, glassmorphism, hero, illustration, card มุมโค้งใหญ่, สีตกแต่ง

รายละเอียดทั้งหมดอยู่ใน `DESIGN.md` §1–2 (principles, visual language) และ §9 (layout)

---

## 3. Design rules

1. **ห้าม hardcode ค่า visual** — ห้าม hex, ห้าม raw px สำหรับ spacing / radius / font-size / shadow ใน component ใช้ `var(--token)` เท่านั้น
2. **ใช้ semantic token ไม่ใช่ primitive** — `var(--text-secondary)` ไม่ใช่ `var(--color-slate-500)`
3. **Shell สว่างเสมอ** — ห้าม sidebar สี navy หรือสีเข้ม
4. **แยกด้วย shadow ไม่ใช่ border** — card และ sidebar ไม่มีเส้นขอบ เส้น 1px ใช้กับ divider ของตารางเท่านั้น
5. **Reuse ก่อนสร้างใหม่** — ถ้ามี pattern แล้วให้ใช้ ปุ่ม / card / สี status แบบที่สองถือเป็น defect
6. **คงหน้าจอเดิมไว้** — แก้เฉพาะสิ่งที่ถูกขอ รักษาโครงสร้างและภาษาดีไซน์เดิม
7. **Thai-first** — ห้าม uppercase หรือ letter-spacing ภาษาไทย ให้ cell wrap ห้ามตัดชื่อภาษาไทยด้วย ellipsis
8. **Flag ทุกอย่างที่เป็น [proposed]** — token หรือ pattern ที่ `DESIGN.md` ยังระบุเป็น proposed (เช่น success / info ramp, dialog, drawer, empty state) ใช้ได้เมื่อจำเป็น แต่ต้องเขียน **[proposed]** กำกับทุกครั้งใน output ห้ามใช้เงียบๆ component ใหม่ต้อง flag พร้อม token map
9. **Keyboard ได้ทุก element** — ทุก interactive element เข้าถึงด้วย keyboard ได้และแสดง `--focus-ring`

Definition of Done เต็มอยู่ที่ `DESIGN.md` §21 — ตรวจทุกข้อก่อนส่งงาน UI

---

## 4. Screen spec template

ใช้เมื่อกำหนดหน้าจอใหม่ (ใน UI-SPEC.md หรือเอกสาร handoff) เพื่อให้ developer หยิบไป implement ได้ทันที:

```markdown
### {SCREEN_ID} {ชื่อหน้าจอ}
- **Route:** /path
- **Template:** แม่แบบที่ใช้ (`templateRef` + reuseAction จาก UX)
- **Layout:** ส่วนประกอบตาม DESIGN.md §9.2 ที่ใช้
- **Data:** field / column, ที่มาของข้อมูล (API / PROC)
- **Components used:** primitive + variant
- **New tokens required:** (ไม่มี / รายการพร้อมเหตุผล)
- **[proposed] tokens relied on:** รายการ
- **States:** default / loading / empty / error / disabled / … ที่เกี่ยวข้อง
- **Interactions:** action → ผลลัพธ์
- **Keyboard:** Tab order, Enter / Space / Esc / Arrow
- **Edge cases:** ข้อความยาว, ไม่มีสิทธิ์, ข้อมูลจำนวนมาก, ฯลฯ
```

---

## 5. Handoff contract

ทุก agent จบงานด้วย handoff 4 หัวข้อนี้ (ในเอกสารหลักของ module หรือในข้อความสรุป):

1. **Done** — ไฟล์ที่สร้าง / แก้ พร้อม path และสิ่งที่ครอบคลุม
2. **Decisions** — สิ่งที่ตัดสินใจเองพร้อมเหตุผล รวมถึง [proposed] ที่ใช้และ default ที่เลือกแทน PO
3. **Open** — คำถามค้าง, gap ของ input, สิ่งที่เกินขอบเขต — ระบุว่าอันไหน **blocking**
4. **Next** — ขั้นถัดไปและใครทำ

กติกาการส่งต่อ:
- **Owner review gate** — ทุกขั้นต้องให้เจ้าของงานตรวจและเปลี่ยน status เป็น `APPROVED` ก่อน (§9) ห้ามส่งต่อ agent ถัดไปหรือ developer เองอัตโนมัติ
- ห้ามตั้งสถานะ `APPROVED` เอง
- แต่ละขั้นไม่แก้งานของขั้นก่อน — ถ้าต้องเปลี่ยนให้เขียน Change Request ในเอกสารของตัวเอง (§7)
- ยังไม่มี agent `angular-implementer` และ `design-system-guardian` — งานที่ต้องส่งให้บทบาทนี้ให้ใส่ไว้ใน **Open** เพื่อให้เจ้าของตัดสินใจ

---

## 6. Design-generation mode (Claude Design / mockups / `.dc`)

ใช้กับ mockup, prototype `.dc.html` และ screen flow HTML ทุกชิ้น:

- **Self-contained HTML ไฟล์เดียว** — paste `:root` token block จาก `styles/tokens.css` แบบ verbatim ลงในไฟล์ ห้ามใช้ CDN, web font ภายนอก หรือ icon font — icon เป็น inline SVG
- **Artboard 1920×1080** เป็นหลัก
- **Label ทุก artboard:** `ชื่อหน้าจอ · route · state`
- **Page skeleton** ตาม `DESIGN.md` §9.2: Shell (Sidebar + Top Bar) → Page Title → Breadcrumb → Filter / Search → Card (Section Header, Toolbar, Table / Form, Paginator)
- **State coverage** — ทำทุก state ที่เกี่ยวข้อง: default, hover, focus, active, selected, disabled, loading, empty, error และตามบริบท permission, row-selected, filter expanded (ดู `DESIGN.md` §13)
- **Annotation อยู่ในคอลัมน์ข้างเท่านั้น** — ห้ามวาง callout ทับ design
- **Demo data** — ภาษาไทย + อังกฤษที่สมจริง จำนวนแถว / คอลัมน์สมจริง และติดป้ายว่าเป็น demo data
- **Handoff** — ปิดงานด้วย §5 และ §4 สำหรับหน้าจอใหม่

---

## 7. Scope & change rules

**Module boundary — 1 agent เขียนได้เฉพาะโฟลเดอร์ของตัวเอง**

| Agent | เขียนได้ | อ่านได้ |
|---|---|---|
| `ba-analyst` | `projects/02-ba-output/<Feature>/` | `01-input-from-po/<Feature>/`, `01-input-from-po/_shared/` |
| `ux-designer` | `projects/03-ux-output/<Feature>/` | `01-input-from-po/`, `02-ba-output/<Feature>/`, `DESIGN.md` |
| `ui-designer` | `projects/04-ui-output/<Feature>/` | `01-input-from-po/`, `02-ba-output/<Feature>/`, `03-ux-output/<Feature>/`, `DESIGN.md`, `styles/` |

- **อ่านข้าม module ได้ แต่ห้ามแก้** — ถ้าพบปัญหาในงานของ module อื่น ให้บันทึกในเอกสารของตัวเองหัวข้อ **"Change Request ถึง <Module>"** (อะไร · ทำไม · กระทบอะไร) แล้วให้เจ้าของส่งกลับไปแก้ที่ module นั้น
- เมื่ออ้างอิงข้อมูลของ module อื่น ให้อ้าง **path + version** (เช่น `02-ba-output/X/BA_BRD.md@v2`) ไม่คัดลอกเนื้อหามาแก้ต่อ ยกเว้น `screen-registry.json` ที่ UI ต้องคัดลอกมาเป็นฉบับของตัวเอง (ดูไฟล์ `ui-designer`)
- งาน feature **ห้ามแก้ `styles/tokens.css`, `DESIGN.md`, `CLAUDE.md`** — ถ้าต้องการ token หรือ component ใหม่ในระดับ system ให้สร้างจาก token ที่มีอยู่, flag [proposed] และใส่เป็น Open item (ดู `DESIGN.md` §16 governance)
- ห้ามแก้ไฟล์ใน `projects/01-input-from-po/`
- แก้เฉพาะสิ่งที่ถูกขอ — ไม่ refactor หรือปรับหน้าจอ / เอกสารอื่นที่ไม่เกี่ยวข้อง
- เวอร์ชันเก่าที่ถูกแทนที่ย้ายไป `_archive/` ไม่ลบทิ้ง — และไม่ใช้ของใน `_archive/` เป็น input
- ถ้า requirement ขัดกับ Design System ให้ทำตาม `DESIGN.md` §18.3 (conflict rule) และแจ้งใน Open

---

## 8. Agent pipeline & conventions

**Pipeline** (แต่ละขั้นต้อง `APPROVED` ก่อนไปขั้นถัดไป — §9):

```text
Source (01)                ba-analyst (02)                ux-designer (03)                 ui-designer (04)
Prototype HTML      ──►    BA_BRD.md                ──►   Reuse / Template mapping   ──►   hi-fi .dc
User Journey               · Business Requirement         screen-registry.json             UI-SPEC · WCAG
HAR / endpoint list        · AC (มุมมอง Business)          UX-MODEL (state, wireframe)      ScreenFlow.html ◄ จุดสิ้นสุด
API spec (ถ้ามี)            · API path / Suggestion API
                           · Journey ที่ควรเพิ่ม
                           · To Do: SA / API / FE / QA
                  [Owner APPROVE]                [Owner APPROVE]                  [Owner APPROVE]
```

| Agent | หน้าที่หลัก | ไม่ทำ |
|---|---|---|
| `ba-analyst` | BRD + AC + API (Case REUSE: path ที่ใช้ / Case NEW: Suggestion API) + Journey ที่ควรเพิ่ม + To Do list | UI/UX, API spec เต็มรูป |
| `ux-designer` | จับคู่แต่ละหน้าจอกับแม่แบบที่ระบบมี (REUSE / UPDATE / NEW), state, wireframe low-fi, WCAG requirement | visual design, `ScreenFlow.html` |
| `ui-designer` | hi-fi `.dc`, UI-SPEC, WCAG implementation, **ScreenFlow.html ฉบับสุดท้าย** | เปลี่ยน UX / business rule เอง |

**Case ของงาน** (เจ้าของระบุใน prompt ตอนเรียก `ba-analyst`):
- `REUSE` — ใช้เมนู / หน้าจอที่ระบบมีอยู่แล้ว ต้องแนบ API reference (HAR / รายการ endpoint / API spec) อย่างน้อย 1 อย่าง
- `NEW` — Feature ใหม่ BA เสนอ Suggestion API เอง

**รูปแบบการเรียก agent (ตัวอย่าง)**

```text
@ba-analyst  feature: SetupConfigTimeSlot · case: REUSE
@ux-designer feature: SetupConfigTimeSlot
@ui-designer feature: SetupConfigTimeSlot
```

BA อ่าน Source ทั้งหมดใน `01-input-from-po/<Feature>/` เอง ระบุไฟล์เพิ่มใน prompt ได้ถ้าต้องใช้ไฟล์จาก `_shared/` (เช่น `api: _shared/api_spec/TMSTops_Master_PoolSlot_RequestTimeSlot_GET.md`)

**Conventions**
- หนึ่ง feature = หนึ่งโฟลเดอร์ ใช้ชื่อเดียวกันทุกขั้น เป็น **UpperCamelCase** ไม่มีช่องว่าง (เช่น `SetupConfigTimeSlot`) — เจ้าของเป็นผู้ตั้งชื่อ
- Output ของแต่ละ module:

| Module | ไฟล์ |
|---|---|
| BA | `BA_BRD.md` |
| UX | `UX_Owner-Result.md` · `UX-MODEL.md` · `screen-registry.json` |
| UI | `ScreenFlow.html` · `UI_Owner-Result.md` · `screen-registry.json` · `UI-SPEC.md` · `WCAG.md` · `artifacts/S#/S#__STATE.dc.html` |
| ทุก module | `<Module>_Blockers.md` เมื่อเจอ Blocker |

- `screen-registry.json` เป็น canonical model — UX สร้าง, UI คัดลอกมาต่อยอดใน 04, `ScreenFlow.html` generate จาก registry ของ UI ไม่ใช่แก้มือ
- `.dc.html` เป็น visual prototype ไม่ใช่ production code
- เอกสาร requirement / BA / UX เขียนภาษาไทย ใช้คำศัพท์เทคนิคภาษาอังกฤษได้ ข้อความบน UI เป็นภาษาไทยตาม `DESIGN.md` §15
- แยกสถานะข้อมูลให้ชัด: สิ่งที่เห็นจากหลักฐานจริง vs สิ่งที่อนุมาน / เสนอ — ห้ามแต่งข้อมูลที่ input ไม่ได้ให้มา ให้ระบุ `NOT PROVIDED` หรือเป็นคำถามแทน

---

## 9. Status, Blocker & จุดกำกวม

### 9.1 Status ของเอกสาร

เอกสารหลักของทุก module (`BA_BRD.md`, `UX_Owner-Result.md`, `UI_Owner-Result.md`, `*_Blockers.md`) ต้องมี frontmatter YAML ที่บรรทัดแรก:

```yaml
---
feature: <Feature>
module: BA | UX | UI
status: IN_REVIEW
version: 1
updatedAt: YYYY-MM-DD
approvedBy:
approvedAt:
openQuestions: 0
basedOn:            # input จาก module ก่อนหน้า (UX / UI เท่านั้น)
  - 02-ba-output/<Feature>/BA_BRD.md@v1
---
```

| Status | ความหมาย | ใครตั้ง |
|---|---|---|
| `DRAFT` | กำลังทำ ยังไม่พร้อมรีวิว | Agent |
| `IN_REVIEW` | ส่งมอบแล้ว รอเจ้าของตรวจ | Agent |
| `CHANGES_REQUESTED` | เจ้าของตรวจแล้ว ต้องแก้ | **เจ้าของ** |
| `APPROVED` | เจ้าของอนุมัติ ส่งต่อขั้นถัดไปได้ | **เจ้าของเท่านั้น** — แก้ `status`, `approvedBy`, `approvedAt` ในไฟล์เอง |
| `BLOCKED` | ใช้กับ `*_Blockers.md` — ยังทำงานไม่ได้ | Agent |
| `RESOLVED` | ใช้กับ `*_Blockers.md` — รันใหม่แล้วผ่าน | Agent |

- Agent ห้ามตั้ง `APPROVED` หรือ `CHANGES_REQUESTED` เอง
- เมื่อ agent แก้เอกสารที่เคย `APPROVED` → bump `version` และตั้งกลับเป็น `IN_REVIEW`
- Source ใน `01-input-from-po/` ไม่มี status — ถือว่าผ่านการกลั่นกรองจากเจ้าของแล้ว

### 9.2 Blocker (ช่วงทดสอบทีละ Step)

ก่อนเริ่มงาน agent ต้องตรวจ และ**หยุดทำงาน**เมื่อเจอ:

1. **Input จาก module ก่อนหน้ายังไม่ `APPROVED`** (UX ตรวจ `BA_BRD.md` · UI ตรวจ `UX_Owner-Result.md`)
2. **ไม่มี input ที่บังคับ** ตามที่ไฟล์ agent กำหนด
3. **จุดกำกวมระดับ High** — ถ้าเดาผิดจะต้องทำเอกสารใหม่เกือบทั้งฉบับ หรือเปลี่ยนโครง flow / ขอบเขตงาน

เมื่อหยุด ให้เขียน `<Module>_Blockers.md` ในโฟลเดอร์ output ของตัวเอง (ไม่สร้างเอกสารหลักในรอบนั้น):

```markdown
---
feature: <Feature>
module: BA
status: BLOCKED
updatedAt: YYYY-MM-DD
---

# Blockers: <Feature> (BA)

## B-001 [ประเภท: Input ไม่อนุมัติ | Input ขาด | กำกวม High]
- **ปัญหา:** ...
- **กำกวมอย่างไร / ทำไมทำต่อไม่ได้:** ...
- **ตัวเลือก:**
  - (A) ... → ผลต่องาน: ...
  - (B) ... → ผลต่องาน: ...
  - (C) อื่นๆ — เจ้าของระบุเอง
- **ข้อแนะนำ:** (A) เพราะ ...
- **Data ที่เจ้าของต้องเตรียม:** ไฟล์ / ข้อมูล / การตัดสินใจ ที่ต้องมีก่อนรันใหม่

## Checklist ก่อนรันใหม่
- [ ] ...
```

### 9.3 จุดกำกวมที่ไม่ใช่ Blocker

ระดับ Medium / Low — ทำงานต่อได้ แต่บันทึกในเอกสารหลักหัวข้อ "จุดกำกวม / สิ่งที่ต้องตัดสินใจ":

```markdown
### Q-001 [Medium] <หัวข้อ>
- **กำกวมอย่างไร:** Source A บอก ... แต่ Source B ...
- **ตัวเลือก:** (A) ... (B) ... (C) อื่นๆ — เจ้าของระบุเอง
- **ที่ใช้ในเอกสารนี้ไปก่อน:** (A) `[ASSUMPTION]` เพราะ ...
- **ถ้าเลือกทางอื่น ต้องแก้ส่วน:** §3 AC-04, §4
```

- ทุกจุดในเอกสารที่ขึ้นกับ assumption ต้องติด `[ASSUMPTION Q-001]`
- นับจำนวน Q ที่ยังไม่ตัดสินใส่ `openQuestions` ใน frontmatter
- Module ถัดไป**ห้ามถือว่า `[ASSUMPTION]` ของ module ก่อนหน้าเป็นข้อตกลง** จนกว่าเจ้าของตัดสินใน Q นั้น
