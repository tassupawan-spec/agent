---
feature: MasterPoolTimeSlot
module: BA
type: SPEC_REVIEW
status: IN_REVIEW
version: 1
updatedAt: 2026-09-29
approvedBy:
approvedAt:
openQuestions: 7
sources:
  - SRC1: projects/01-input-from-po/MasterPoolTimeSlot/TMSTops_Master_PoolSlot_DeliverySlotFilter_GET.md (spec v1.1)
  - SRC2: projects/01-input-from-po/_shared/api_spec/TMSTops_Master_PoolSlot_RequestTimeSlot_GET.md (v1.3 — ใช้เทียบ cross-spec)
  - SRC3: ภาพที่เจ้าของแนบ 2 ภาพ (ตาราง Master + dropdown "รอบจัดส่ง") — อ่านจากคำบรรยายใน prompt ไม่ได้เปิดไฟล์ภาพ
---

# Review: GET /master/cfr/api/PoolSlotTemplate/deliverySlotFilter vs Logic ที่เจ้าของต้องการ

> งาน review (ไม่ใช่ BRD เต็ม) — ไม่มี AC / To Do ครบชุด · แยก **[EVIDENCE]** (อ้างจาก Spec/ภาพ) กับ **[ASSUMPTION]** (อนุมาน)

## 0. สรุปผลตรวจ

| Logic ที่ต้องการ | ผล | สรุป |
|---|---|---|
| 1. Overlap ต้อง merge เป็นช่วงเดียว | ❌ **ไม่ตรง** | Spec ทำแค่ตัดแถวที่ StartTime+EndTime **ตรงกันเป๊ะ** (BR005 = DISTINCT) ไม่มีการ merge ช่วงที่ซ้อน/คาบเกี่ยว |
| 2. ไม่ระบุ SlotType = ทุก type (รวม NULL) | ❌ **ไม่ตรง** | Spec บังคับ default = `Normal` (BR001) และกรอง `SlotType = ParamSlotType` (BR004) ดึงได้ทีละ 1 type เสมอ ไม่มีทางดึง "ทุก type" และแถว SlotType = NULL ไม่ถูกดึงเลย |

ภาพ 2 (08:00-12:00 กับ 10:00-12:00 ยังซ้อนกัน) **เป็นผลของ Spec ปัจจุบันจริง** ไม่ใช่ความผิดพลาดของ implement — ดูหัวข้อ 2

## 1. Findings (เรียงตามความรุนแรง)

### F-01 [High] BR005 ไม่ merge overlap
- **[EVIDENCE]** SRC1 BR005: "SELECT DISTINCT StartTime, EndTime" และ Field Mapping map ค่า Start/End ตรงๆ จากแถวเดิม
- ผล: ช่วง 08-12 กับ 10-12 (ซ้อนทั้งหมด), 08-16 กับ 13-18 (ซ้อนบางส่วน) ถูกแสดงเป็นหลายรายการ; แถวที่ช่วงเวลาซ้ำกันเป๊ะเท่านั้นที่ถูกยุบ
- ผลต่อธุรกิจ: dropdown "รอบจัดส่ง" มีตัวเลือกซ้อนกัน ผู้ใช้สับสนว่าเลือกอันไหน และผลกรองรายการ order ต่างกันตามอันที่เลือก
- ตารางกรณีที่ Spec ปัจจุบันจัดการ:

| กรณี | ตัวอย่าง | Spec ปัจจุบัน | ควรเป็น (ตาม Logic 1) |
|---|---|---|---|
| ข้อมูลซ้ำเป๊ะ | 20:00-22:00 x2 | ✅ เหลือ 1 (DISTINCT) | เหมือนเดิม |
| ซ้อนบางส่วน | 08-12 กับ 10-14 | ❌ แสดง 2 | 08-14 |
| ซ้อนทั้งหมด (อยู่ภายใน) | 08-16 กับ 10-12 | ❌ แสดง 2 | 08-16 |
| ชิดกัน (touching) | 12-16 กับ 16-20 | ❌ แสดง 2 | **รอเจ้าของตัดสิน Q-002** |
| ต่างสาขา/Channel แต่ช่วงเดียวกัน | Id1 / Id7 ในตัวอย่าง Spec | ✅ ยุบเป็น 1 | เหมือนเดิม |

### F-02 [High] SlotType: ไม่มีโหมด "ทุก type"
- **[EVIDENCE]** BR001: ค่าใดที่ไม่ใช่ `VIP` (รวมไม่ระบุ/สะกดผิด) → `Normal`; BR004 ข้อ 1: `SlotType = ParamSlotType`; ตาราง 3.2 default = `Normal`
- ผล: ไม่ระบุ slotType → ได้เฉพาะ Normal · ระบุ VIP → ได้เฉพาะ VIP · **แถว SlotType = NULL ไม่มีทางถูกดึง** · ไม่มีค่าที่ใช้สื่อ "ทั้งหมด"
- ขัดกับ Logic ที่เจ้าของต้องการโดยตรง (ไม่ระบุ = ทุก type รวม NULL)

### F-03 [High] ค่า SlotType ในข้อมูลจริงไม่ตรงกับค่าใน Spec
- **[EVIDENCE]** ภาพ 1 ใช้ค่า "ทั่วไป" / VIP / NULL; SRC1 v1.1 เปลี่ยน default เป็น `Normal` (OI-1: Dev #73452 เปลี่ยน constant); SRC2 v1.3 ยังใช้ `ทั่วไป` ทั้ง BR010 และ BR011
- ผล: ถ้า data ยังเป็น "ทั่วไป" และ Spec นี้กรอง `Normal` → ผลลัพธ์เป็น `[]` ทั้งหมด (dropdown ว่าง) จนกว่าจะ migrate data/แก้ spec พี่น้อง — ควรให้ Dev/DBA ตรวจ data จริง และประสานการ deploy
- ถ้าไปทาง "ทุก type" (F-02) ความเสี่ยงนี้ของ endpoint นี้จะหมดไป แต่ SRC2 ยังต้องสอดคล้องกัน

### F-04 [Medium] แถว ChannelCode = NULL ถูกปฏิบัติต่างจาก RequestTimeSlot
- **[EVIDENCE]** SRC1 BR004 ข้อ 3: ระบุ channelCode → `ChannelCode = channelCode` (แถว NULL ถูกตัดออก) · SRC2 BR010 ข้อ 2: ระบุ channel → ดึง "channel ตรง **หรือ NULL**" (NULL = ใช้ได้ทุก channel)
- ผล: ผู้ใช้เลือก Channel = CH000001 → dropdown ไม่มี slot ที่ตั้งเป็น "ทุก Channel" (เช่นแถว ChannelCode=NULL, VIP 08-12 ในภาพ 1) ทั้งที่ระบบจองใช้ slot นั้นได้ → ตัวเลือกใน filter ไม่ครบเมื่อเทียบกับที่ order ถูกจองจริง (Cross-report consistency)

### F-05 [Medium] VIP หมายถึงอะไรต่างจาก RequestTimeSlot
- **[EVIDENCE]** SRC1: `slotType=VIP` → เฉพาะ VIP · SRC2 BR010 ข้อ 3: `VIP` → VIP **และ** ทั่วไป (เพราะ fallback ไป slot ทั่วไปเมื่อ VIP เต็ม)
- ผล: order ที่ถูกจองด้วย slot ทั่วไปแบบ fallback ของลูกค้า VIP จะไม่มีค่าใน dropdown ให้กรอง — ดู Q-003

### F-06 [Low] deliveryOptionCode ว่าง = `DIY` ไม่ใช่ "ทุกค่า"
- **[EVIDENCE]** BR004 ข้อ 4 · ภาพ 1 มีแถว PIC ซึ่งไม่ถูกดึงเมื่อไม่ระบุ — เจ้าของกำหนดเฉพาะ SlotType ให้เป็น "ทุก type" จึงเก็บพฤติกรรมนี้ไว้ก่อน (ยกเป็น Q-006 เผื่อเจ้าของต้องการเหมือนกัน)

### F-07 [Low] ตรวจ M_Pool.IsActive ไม่เหมือน SRC2
- **[EVIDENCE]** SRC1 BR003 ไม่มีเงื่อนไข `M_Pool.IsActive = 1` แต่ SRC2 BR008 มี → สาขาที่ Pool ปิดใช้งานอาจได้ slot ใน filter นี้ · ควรให้ Dev/DBA ตรวจ

### F-08 [Low] Spec ไม่พูดถึงกรณีขอบของเวลาเมื่อจะ merge
- **[EVIDENCE]** ไม่มีกฎเรื่อง Start ≥ End, ช่วงข้ามเที่ยงคืน (เช่น 22:00-02:00), End = 24:00, ค่า NULL ของ StartTime/EndTime · **[ASSUMPTION]** ยังไม่พบในภาพ ถือว่าไม่มีในข้อมูล → ยกเป็น Q-007

## 2. ตัวอย่างจากข้อมูลในภาพ

**อ่านตารางภาพ 1 (ตามคำบรรยาย) — [ASSUMPTION Q-005]:** แถวของ CH000001–CH000003 (DIY) มี SlotType = NULL; CH000004 และ CH000006 = "ทั่วไป"; แถว ChannelCode=NULL 08-12 = VIP; CH000001 PIC 12-16 = VIP. หากอ่านผิด ผลด้านล่างต้องคำนวณใหม่

**(ก) Spec ปัจจุบัน** — เลือก "ทั้งหมด" (ไม่ส่ง slotType → Normal, DIY, DISTINCT)
- ถ้า data ยังเป็น "ทั่วไป" (ภาพ 2) ผลตรงกับภาพ 2 คือ `08-12, 10-12, 13-18, 18-20, 20-22` → 08-12 กับ 10-12 ซ้อนกัน (F-01)
- แถว NULL (08-10, 08-12, 12-16, 08-16) และ VIP (08-12) หายไปทั้งหมด (F-02)
- ถ้า data ถูก migrate/เป็น `Normal` ตาม v1.1 ผลจะขึ้นกับว่าแถวไหนเป็น Normal — ถ้ายังเป็น "ทั่วไป" ผลคือ `[]` (F-03)

**(ข) ผลที่ควรเป็นตาม Logic ที่ต้องการ** — ทุก SlotType รวม NULL, DIY, ทุก Channel/สาขา, merge

| ขั้น | ช่วงที่ได้ |
|---|---|
| รวมทุกแถว DIY (หลัง distinct) | 08-10, 08-12, 10-12, 12-16, 08-16, 13-18, 18-20, 20-22 |
| merge overlap (ไม่ merge ที่ชิดกัน) | **08:00-18:00**, 18:00-20:00, 20:00-22:00 |
| merge overlap + ชิดกัน | **08:00-22:00** (ช่วงเดียว) |

ถ้า scope แค่ SlotType "ทั่วไป": ไม่ merge ชิดกัน = `08-12, 13-18, 18-20, 20-22`; merge ชิดกัน = `08-12, 13-22`

**ข้อสังเกตเชิงธุรกิจ:** ช่วงที่ merge แล้ว (เช่น 08:00-18:00) ไม่ตรงกับ slot จริงใดๆ ใน Master — ต้องนิยามให้ชัดว่าเลือกช่วงนี้แล้วกรอง order อย่างไร (Q-004)

## 3. ข้อเสนอแก้ไข (Suggestion ระดับ Logic — ไม่ใช่ API spec เต็ม)

### 3.1 แก้ BR001 / BR004 ข้อ 1 (SlotType)
- `slotType` ไม่ระบุ/ว่าง/NULL → **ไม่กรอง SlotType** (รวมแถว SlotType = NULL)
- ระบุแล้ว → กรอง `SlotType = ค่าที่ส่ง` (ถ้าเจ้าของเลือกตาม Q-003 อาจเป็น VIP+Normal)
- ยกเลิกกฎ "ค่าที่ไม่รู้จัก → Normal" หรือกำหนดใหม่ (ค่าไม่รู้จัก → Error หรือ ไม่กรอง — Q-001)

### 3.2 แก้ BR005 จาก DISTINCT เป็น Merge Intervals
Pseudo-SQL (T-SQL, ทำหลัง BR004 บน `ParamSlotTemp`; DBA ตรวจ index/performance เพิ่ม):

```sql
WITH d AS (            -- ตัดซ้ำก่อน
  SELECT DISTINCT StartTime, EndTime FROM ParamSlotTemp
),
p AS (                 -- EndTime สูงสุดของช่วงก่อนหน้าทั้งหมด (เรียงตาม Start, End)
  SELECT StartTime, EndTime,
         MAX(EndTime) OVER (ORDER BY StartTime, EndTime
                            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS PrevMaxEnd
  FROM d
),
g AS (                 -- เริ่มกลุ่มใหม่เมื่อไม่ overlap
  SELECT *, SUM(CASE WHEN PrevMaxEnd IS NULL
                          OR StartTime >= PrevMaxEnd   -- Q-002 (A): ชิดกัน "ไม่" merge
                          -- OR StartTime >  PrevMaxEnd -- Q-002 (B): ชิดกัน merge
                     THEN 1 ELSE 0 END)
             OVER (ORDER BY StartTime, EndTime) AS Grp
  FROM p
)
SELECT MIN(StartTime) AS startTime, MAX(EndTime) AS endTime
FROM g GROUP BY Grp
ORDER BY startTime, endTime;
```
- ต้องใช้ `MAX(EndTime)` ของทุกช่วงก่อนหน้า (ไม่ใช่แค่ช่วงก่อนหน้าติดกัน) เพื่อรองรับกรณีช่วงหนึ่งครอบช่วงอื่น เช่น 08-16 ครอบ 10-12 และ 13-14
- `timeSlotName` สร้างจาก start/end ที่ merge แล้ว (รูปแบบ `HH:mm - HH:mm` เดิม) · จะทำใน application layer (LINQ) แทน SQL ก็ได้ — เลือกโดย Dev

### 3.3 ปรับที่ตามมา
- แก้ตาราง 3.2 (default slotType), ตัวอย่างการทำงาน, QA cURL (ตัวอย่างตอบ 08-10 + 10-12 จะเป็น 08-12 ถ้าเลือก Q-002 B), Changelog v1.2
- Response Field ยังใช้ชุดเดิมได้ (startTime, endTime, timeSlotName) — ไม่ต้องเพิ่ม field
- ทบทวน OI-1 (Normal vs "ทั่วไป") ให้สอดคล้องกับ SRC2 (F-03)
- (แนะนำ) ปรับ F-04 ให้รวมแถว ChannelCode = NULL เมื่อระบุ channel เหมือน SRC2 — รอ Q-004b/Q-003 ตัดสิน

## 4. จุดกำกวม / สิ่งที่ต้องตัดสินใจ

### Q-001 [High] ค่า slotType ที่ไม่รู้จัก / ต้องการโหมด "ทั้งหมด" แบบชัดเจนไหม
- **ตัวเลือก:** (A) ไม่ส่ง = ทุก type, ส่ง `VIP`/`Normal` = ระบุ type, ค่าอื่น = Error 400 (B) ไม่ส่ง = ทุก type, ค่าอื่นที่ไม่รู้จัก = ถือเป็นไม่กรอง (C) อื่นๆ — เจ้าของระบุเอง
- **ที่ใช้ไปก่อน:** (A) `[ASSUMPTION Q-001]` เพราะไม่ให้ค่าผิดกลายเป็นผลลัพธ์ที่ดูปกติเงียบๆ
- **ถ้าเลือกทางอื่น ต้องแก้:** §3.1

### Q-002 [High] ช่วงที่ "ชิดกัน" (เช่น 12:00-16:00 กับ 16:00-20:00) นับเป็น overlap ที่ต้อง merge ไหม
- **ตัวเลือก:** (A) ไม่ merge — merge เฉพาะที่เวลาซ้อนกันจริง (B) merge ด้วย → 12:00-20:00 (C) อื่นๆ — เจ้าของระบุเอง
- **ที่ใช้ไปก่อน:** (A) `[ASSUMPTION Q-002]` เพราะคำว่า Overlap ตามตัวอักษรหมายถึงเวลาซ้อน และรักษาเส้นแบ่งรอบที่ธุรกิจตั้งไว้
- **ผลต่อตัวอย่างภาพ:** (A) → 08-18, 18-20, 20-22 · (B) → 08-22 ช่วงเดียว
- **ถ้าเลือกทางอื่น ต้องแก้:** §2(ข), §3.2 (เงื่อนไข `>=` vs `>`)

### Q-003 [Medium] เมื่อ filter = VIP ให้แสดงเฉพาะ VIP หรือ VIP + ทั่วไป/Normal (เหมือน RequestTimeSlot)
- **ตัวเลือก:** (A) เฉพาะ VIP (ตาม Spec ปัจจุบัน) (B) VIP + Normal (สอดคล้อง SRC2 fallback) (C) อื่นๆ
- **ที่ใช้ไปก่อน:** (A) `[ASSUMPTION Q-003]` ตาม SRC1 ที่เป็นข้อความเจ้าของ endpoint นี้
- **ถ้าเลือกทางอื่น ต้องแก้:** §3.1, F-05

### Q-004 [High] Merge ทำข้ามทุกมิติเลยหรือไม่ และ order filter ใช้ช่วงที่ merge แล้วอย่างไร
- **กำกวม:** (ก) merge ข้าม SlotType / Channel / Pool / สาขาหรือไม่ — Spec ปัจจุบัน DISTINCT ข้าม Pool และ Channel อยู่แล้ว ส่วนใหม่คือข้าม SlotType (ข) ช่วงที่ merge (เช่น 08-18) ไม่มีใน Master — เมื่อผู้ใช้เลือกแล้ว order ที่ถูกจอง slot 13-18 หรือ 08-12 ต้องนับว่าอยู่ในช่วงนี้ (แบบ contained) หรือ overlap? Spec ของ endpoint ที่รับ filter นี้ไม่อยู่ในชุด Source
- **ตัวเลือก:** (A) merge ข้ามทุกมิติภายใต้ filter ที่ส่งมา; order match แบบ "slot ของ order อยู่ภายในช่วงที่เลือก" (B) merge เฉพาะภายในแต่ละ SlotType (C) อื่นๆ
- **ที่ใช้ไปก่อน:** (A) `[ASSUMPTION Q-004]` เพราะตรงกับ Logic ข้อ 1 ของเจ้าของ (ส่วนการ match order เป็น [ASSUMPTION] ที่ต้องยืนยัน)
- **ถ้าเลือกทางอื่น ต้องแก้:** §3.2 และ spec ฝั่ง order list

### Q-005 [Medium] ยืนยันการอ่านข้อมูลภาพ 1
- ค่า SlotType ของแถว CH000001–CH000003 เป็น NULL จริงหรือไม่ และ "ทั่วไป" ในข้อมูลจริงจะถูก migrate เป็น `Normal` หรือไม่ (F-03) — ต้องได้ตัวอย่าง data จริง/ยืนยันจาก Dev-DBA
- **ถ้าอ่านผิด ต้องแก้:** §2

### Q-006 [Low] `deliveryOptionCode` ว่างและ `channelCode` (NULL) — ต้องการเหมือน slotType (ทุกค่า) หรือคงเดิม (DIY / ตรง channel เท่านั้น)
- **ที่ใช้ไปก่อน:** คงเดิม `[ASSUMPTION Q-006]` เพราะเจ้าของระบุเฉพาะ slotType · ถ้าเปลี่ยน ต้องแก้ BR004 ข้อ 3–4

### Q-007 [Low] กรณีขอบของเวลา (ข้ามเที่ยงคืน, End=24:00, Start ≥ End, ค่า NULL)
- **ที่ใช้ไปก่อน:** ถือว่าไม่มีในข้อมูล `[ASSUMPTION Q-007]` — ถ้ามี ต้องเพิ่ม rule การ validate/ข้าม

## 5. Handoff

1. **Done** — ตรวจ SRC1 เทียบ Logic 2 ข้อ พบไม่ตรงทั้งคู่ (F-01, F-02) + gap เสริม 6 ข้อ; ยกตัวอย่างจากภาพ; เสนอ pseudo-SQL merge และปรับ BR001/BR004/BR005 (ไฟล์นี้ไฟล์เดียว ไม่แตะ 01-input-from-po)
2. **Decisions** — ใช้ค่าตั้งต้นตาม `[ASSUMPTION]` Q-001..Q-007 (ไม่ merge ชิดกัน, VIP = เฉพาะ VIP, คงพฤติกรรม channel/delivery option เดิม); อ่านภาพจากคำบรรยายของเจ้าของ ไม่ได้เปิดไฟล์ภาพ
3. **Open** — **Blocking การแก้ Spec:** Q-002, Q-004, Q-001 · ไม่ blocking: Q-003, Q-005, Q-006, Q-007 · ต้องให้ Dev/DBA ตรวจ: ค่า SlotType จริงใน data ("ทั่วไป" vs "Normal"), M_Pool.IsActive (F-07), index/performance ของ query merge
4. **Next** — เจ้าของตัดสิน Q ข้างต้น → เจ้าของ spec (Pichamon/Pongskorn) ออก DeliverySlotFilter v1.2 (BR001/BR004/BR005 + ตัวอย่าง + cURL) และปรับ SRC2 ให้สอดคล้อง → Dev/QA; ไฟล์นี้ไม่ส่งต่อ ux-designer (ไม่ใช่ BRD)
