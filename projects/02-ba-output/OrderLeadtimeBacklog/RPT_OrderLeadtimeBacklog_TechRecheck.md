# Technical Recheck: Order Lead-Time & Backlog Report (Task #70681)

> เอกสารนี้จัดทำโดย BA เทคนิค (ทำหน้าที่แทน `ba2-tech-analyst` ตามคำสั่ง PO) เป็นการตรวจซ้ำ `RPT_OrderLeadtimeBacklog.sql` และ `RPT_OrderLeadtimeBacklogDetail` (ไฟล์ `RPT_Performance_detail.sql`) แบบ**อิสระจากเอกสาร ba1** — อ่าน SQL และ requirement เองทั้งหมด ใช้เอกสาร ba1 (`RPT_OrderLeadtimeBacklog_BusinessReview.md`) เป็น baseline เปรียบเทียบเท่านั้น ไม่ใช่แหล่งความจริงหลัก
>
> **ข้อจำกัดเหมือนรอบ ba1**: ไม่มี DB connection (ทุก query ในเอกสารนี้เป็นร่าง ยังไม่ execute), ไม่มีไฟล์ export จาก CFW จริงให้เทียบ cell-to-cell, เข้า Azure DevOps Task #70681 ไม่ได้ (ใช้ requirement text ที่ PO สรุปให้ + comment ใน SQL เป็นแหล่งอ้างอิง)

---

## 1. สรุปภาพรวม

ตรวจ business rule ทั้งหมด **16 ข้อ** (10 ข้อฝั่ง List/Summary + 6 ข้อฝั่ง Detail) เทียบ SQL logic จริงทีละบรรทัด ผลสรุป:

| ผลตรวจ                                                                           | จำนวน |
| -------------------------------------------------------------------------------- | ----- |
| ✅ ตรงกับ requirement และตรงกับที่ ba1 สรุปไว้                                    | 9 ข้อ |
| ⚠️ ตรงกับ requirement ในหลักการ แต่มี TBC/คำถามเปิดเดิม (เห็นตรงกับ ba1)         | 4 ข้อ |
| 🔶 ท้าทายข้อสรุปของ ba1 — พบความเสี่ยงเชิงเทคนิคที่ ba1 ไม่ได้ตรวจ/ไม่ได้ลงลึกพอ | 3 ข้อ |
LINK เอกสาร BA1 [[RPT_OrderLeadtimeBacklog_BusinessReview]]

นอกจากตาราง 16 ข้อนี้ การไล่โค้ดเชิงลึก (join key, NULL-handling, race condition, index) พบ**ความเสี่ยงใหม่ที่ ba1 ไม่ได้กล่าวถึงเลย 4 จุด** ซึ่ง **1 จุดจัดเป็น High risk ที่กระทบ core invariant ของทั้งฟีเจอร์** (ข้อ 3.3 — M_Status join เสี่ยง fan-out ทำให้จำนวนแถว Detail ไม่เท่ากับตัวเลขใน List) — ดูหัวข้อ 3 เต็ม

สรุปนับ risk ทั้งหมดที่พบ (รวมของเดิมจาก ba1 + ของใหม่): **High 6 จุด, Medium 6 จุด, Low 3 จุด**

---

## 2. ตารางเทียบ PROC vs Requirement แบบละเอียดเชิงเทคนิค

### 2.1 ฝั่ง List/Summary (`RPT_OrderLeadtimeBacklog.sql`)

| #   | Business Rule                                                 | SQL อ้างอิง                                                                        | ตรวจเอง (technical)                                                                                                                                                                                                                                                                                                                                                                                                                                                            | เทียบกับ ba1                                                                                                                                                              |
| --- | ------------------------------------------------------------- | ---------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | ดึงข้อมูลตาม Start Time                                       | `WHERE o.StartTime >= @DateFrom AND o.StartTime < @DateToExclusive` (บรรทัด 81–82) | ✅ ตรง — half-open interval `[@DateFrom, @DateTo]` ป้องกัน off-by-one ที่ boundary ถูกต้อง (ใช้ `@DateToExclusive = @DateTo+1` แทน `<=@DateTo` ซึ่งถูกต้องกว่าเพราะ `StartTime` เป็น DATETIME ไม่ใช่ DATE — ถ้าใช้ `<= @DateTo` ตรงๆ จะตัด order ที่ StartTime มีเวลา > 00:00:00 ของวันนั้นทิ้งไปผิดๆ)                                                                                                                                                                          | เห็นตรงกับ ba1 (1.1)                                                                                                                                                      |
| 2   | เลือกได้มากกว่า 1 สาขา                                        | `@BranchCode VARCHAR(20)` เป็น scalar (บรรทัด 7)                                   | ⚠️ Known limitation — ยืนยันจาก schema พารามิเตอร์: รองรับได้แค่ 1 ค่า หรือ NULL (ทุกสาขา) จริง ไม่มีช่องทาง technical ให้ pass CSV/table-valued parameter                                                                                                                                                                                                                                                                                                                     | เห็นตรงกับ ba1 (1.1) — PO ปิดเป็น non-blocking แล้ว ไม่ต้องตรวจซ้ำ                                                                                                        |
| 3   | H1/H2/H3 header                                               | บรรทัด 30, 46–55                                                                   | ✅ ตรง ตรวจ string concat แล้วไม่มี NULL-concat risk เพราะ `@BranchName`/`@StoreName` ผ่าน CASE WHEN คุมด้วย NULL check ครบ (บรรทัด 46–50)                                                                                                                                                                                                                                                                                                                                      | เห็นตรงกับ ba1 (1.2)                                                                                                                                                      |
| 4   | Store = Code (เว้นวรรค) Name                                  | บรรทัด 40, 179, 198–202                                                            | ⚠️ ตรงกับที่ ba1 พบ (underscore ไม่ใช่ space) — **เพิ่มเติม**: `MAX(pl.NameLocal)` และ `MAX(pl.BranchName)` ที่บรรทัด 39–40 เป็นค่า MAX ของคนละคอลัมน์ **คำนวณอิสระจากกัน** ถ้า `M_Place` มีมากกว่า 1 แถว active ต่อ `(PlaceCode, BUCode)` (ต่างกันที่ `ProviderCode` ตาม comment บรรทัด 167) ค่าที่ได้อาจมาจากคนละแถวกัน ทำให้ H2/Store เป็นชื่อที่ "ประกอบผิดคู่" ได้ — ดูข้อ 3.5                                                                                            | ท้าทาย ba1 (1.3) — ba1 ตรวจแค่ตัวคั่น (underscore) ไม่ได้ตรวจ row-consistency ของ MAX()                                                                                   |
| 5   | Order Inbound = COUNT(Order ตาม Slot Date)                    | `COUNT(*)` บรรทัด 209                                                              | ✅ ตรง — นับจาก `#ord` ที่มี unique clustered index บน `dOrderID` การันตีไม่มี double count จากฝั่ง temp table เอง                                                                                                                                                                                                                                                                                                                                                              | เห็นตรงกับ ba1 (1.4)                                                                                                                                                      |
| 6   | Order Delivered = COUNT(สถานะจัดส่งสำเร็จ)                    | `IsDelivered` บรรทัด 130–131 (เช็ค 2 ชั้น: log 18000 + StatusCode)                 | ✅ ตรงตาม logic ที่ implement — ⚠️ **แต่ invariant "Delivered = Ontime+Delay = sum(bucket 0..>3)" ไม่ถูกการันตีเสมอไป** ถ้า `o.EndTime` เป็น NULL ได้ (ดูข้อ 3.2 — High risk ใหม่)                                                                                                                                                                                                                                                                                              | ท้าทาย ba1 บางส่วน — ba1 (1.4, AC-6) เขียนว่า sum 5 bucket ต้องเท่ากับ Delivered "พอดี" โดยไม่ได้เช็คเงื่อนไข NULL ของ EndTime                                            |
| 7   | Ontime/Delay ที่ SLA 1 ชม.                                    | บรรทัด 24, 211–214                                                                 | ✅ ตรง (ปิดคำถามแล้วตาม PO) — เพิ่มเติม: ใช้ `<=` ที่ boundary พอดี (`LateMinutes <= @SlaMinutes` = Ontime) สอดคล้องกับ requirement "≤ End Time + 1 ชม. = Ontime" เป๊ะ ไม่มี off-by-one                                                                                                                                                                                                                                                                                         | เห็นตรงกับ ba1 (1.4)                                                                                                                                                      |
| 8   | Lead time bucket 0/1/2/3/>3 Day                               | บรรทัด 216–220                                                                     | ✅ ตรง boundary ตามนิยาม (0/1440/2880/4320 นาที = 0/24/48/72 ชม.)                                                                                                                                                                                                                                                                                                                                                                                                               | เห็นตรงกับ ba1 (1.4)                                                                                                                                                      |
| 9   | Avg Order Leadtime by Hr. = Total Lead Time / Order Delivered | `AVG(LeadMinutes)/60` บรรทัด 222–224                                               | ⚠️ **ตรงตามสูตร SQL แต่ไม่ตรงตามคำอธิบาย requirement แบบตัวอักษร** — `AVG()` จะหารด้วยจำนวนแถวที่ `LeadMinutes IS NOT NULL` เท่านั้น (SQL AVG ทิ้ง NULL อัตโนมัติ) ถ้ามี order ที่ Delivered แต่ `OrderDate` เป็น NULL ตัวหารจริงจะ**น้อยกว่า** "Order Delivered" ที่ตัวรายงานโชว์ — ดูข้อ 3.6                                                                                                                                                                                 | ท้าทาย ba1 (1.4) — ba1 บันทึกว่า OrderDate nullable ไว้ในหัวข้อ 1.4 แต่ไม่ได้เชื่อมโยงว่ากระทบตัวหารของค่าเฉลี่ยให้ต่างจากคำว่า "Order Delivered" ตามตัวอักษร requirement |
| 10  | Backlog = ไม่ Delivered/Fail/Cancel                           | บรรทัด 139–150                                                                     | ✅ ตรงตามหลักการ + **ยืนยันเพิ่มเติมว่า partition ครบ**: 4 bucket age (`<=1`,`=2`,`=3`,`>3`) ครอบคลุมทุกค่าจำนวนเต็มไม่มีช่องว่าง ผลรวม 4 bucket = TotalBacklog แน่นอนทางคณิตศาสตร์ (ไม่ขึ้นกับข้อมูล)                                                                                                                                                                                                                                                                          | เห็นตรงกับ ba1 (1.5) แต่ยืนยันเพิ่มเติมด้วยการพิสูจน์ completeness ของ partition                                                                                          |
| 11  | Backlog age เทียบ "วันที่ดึงข้อมูล Report"                    | `@BacklogAsOf = @DateTo` บรรทัด 27, 152                                            | 🔶 **วิเคราะห์เชิงปริมาณเพิ่มเติมจาก ba1** — ดูข้อ 3.1 (คำตอบตรงคำถามที่ PO ถามเรื่อง "ย้อนหลังกี่วันถึงเริ่มเพี้ยน")                                                                                                                                                                                                                                                                                                                                                          | ต่อยอดจาก ba1 (1.5/#6) ที่ตั้งเป็นคำถามเปิดไว้เฉยๆ — เอกสารนี้ให้คำตอบเชิงปริมาณที่ใช้ตัดสินใจได้                                                                         |
| 12  | ไม่มี bucket "0 Day" ฝั่ง Backlog                             | บรรทัด 228 (`<=1` เริ่มที่ Day1)                                                   | ✅ ตรง                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | เห็นตรงกับ ba1 (1.5)                                                                                                                                                      |
| 13  | Value by Backlog                                              | บรรทัด 236–240                                                                     | ✅ ตรง (partition สมบูรณ์เหมือนข้อ 10)                                                                                                                                                                                                                                                                                                                                                                                                                                          | เห็นตรงกับ ba1 (1.5)                                                                                                                                                      |
| 14  | Value by During Delivery                                      | บรรทัด 153–159, 242–245                                                            | ⚠️ ตรงตาม mapping ที่ PO ยืนยัน (`15110-15113`→ONROUTE, `15120,15180`→ATCUST) — **แก้ไขความเข้าใจของ ba1**: ba1 ระบุว่าช่วง "15180-17080" *ทั้งช่วง* ยังไม่ฟันธง แต่จริงๆ **`15180` ถูก map ไปที่ ATCUST แล้วอย่างชัดเจนในโค้ด** (บรรทัด 157) ส่วนที่ยังไม่ map จริงๆ คือ **เฉพาะ 16xxx–17080** (สถานะระหว่าง QC/Finance) ซึ่งยังนับใน `IsBacklog=1`/Total Backlog ถูกต้อง แต่จะไม่ปรากฏใน During Delivery ทั้ง 2 ช่อง (ตกหล่นจาก breakdown แต่ไม่ตกหล่นจาก Total) — ดูข้อ 3.7 | ท้าทาย/แก้ไข ba1 (1.5, TBC #4) — ขอบเขตของสถานะที่ "ยังไม่ resolve" แคบกว่าที่ ba1 เขียนไว้                                                                               |

### 2.2 ฝั่ง Detail (`RPT_OrderLeadtimeBacklogDetail`)

| # | จุดตรวจ | SQL อ้างอิง | ตรวจเอง (technical) | เทียบกับ ba1 |
|---|---|---|---|---|
| 1 | ขั้น #ord/#statuslog/#calc เหมือน List "ทุกตัวอักษร" | Detail บรรทัด 69–133 เทียบ List บรรทัด 61–163 | ✅ **ตรวจ diff แบบ character-by-character เองแล้ว ยืนยันว่าเหมือนกันจริง** ยกเว้น Detail เพิ่มคอลัมน์ `s.DeliveredTime` เข้า `#calc` (บรรทัด 129) ซึ่งไม่กระทบ logic การคำนวณใดๆ (ใช้แสดงผล QA เท่านั้น) | ยืนยัน (verify) คำกล่าวอ้างของ ba1 ที่บอกว่า "เหมือนกันทุกตัวอักษร" — **ba1 พูดถูก** ตรวจซ้ำแล้วไม่พบความต่าง |
| 2 | Threshold ตัวเลข bucket ใน `#pick` เทียบกับ `SUM(CASE)` ของ List | Detail บรรทัด 150–184 เทียบ List บรรทัด 216–233 | ✅ ตรวจเองแล้วว่า**เท่ากันทางคณิตศาสตร์**: List ใช้ range check อิสระ (`>0 AND <=1440` ฯลฯ) ส่วน Detail ใช้ cascading `CASE WHEN...ELSE` (first-match-wins) — รูปแบบโค้ดต่างกันแต่ boundary (0, 1440, 2880, 4320 นาที / 1, 2, 3 วัน) **เหมือนกันทุกค่า** ไม่พบ off-by-one ระหว่าง 2 proc | ยืนยัน ba1 (2.2) ด้วยการ derive ทางคณิตศาสตร์เอง ไม่ใช่แค่เชื่อ comment ในโค้ด |
| 3 | Mapping `@OrderType` → คอลัมน์ List | บรรทัด 206–222 | ✅ ตรงตามตาราง 2.2 ของ ba1 ทุกค่า — ตรวจซ้ำ whitelist บรรทัด 24–27 เทียบกับเงื่อนไข DELETE บรรทัด 208–222 ครบทุกค่า ไม่มีค่าใน whitelist ที่ไม่มีเงื่อนไขรองรับ และไม่มีเงื่อนไขที่อ้างถึงค่านอก whitelist | เห็นตรงกับ ba1 (2.2) |
| 4 | Column list 13 คอลัมน์ | บรรทัด 258–289 | ✅ ครบ 13 คอลัมน์ — **แต่พบความเสี่ยงใหม่ที่ ba1 ไม่ได้ตรวจ**: `LEFT JOIN M_Status ms ON ms.StatusCode = o.StatusCode` (บรรทัด 292) ไม่มีการยืนยันว่า `M_Status.StatusCode` เป็น unique/PK — ถ้าไม่ unique จะทำให้แถว Detail **fan-out** (เพิ่มจำนวนแถวเกินจริง) กระทบ invariant หลักของทั้งฟีเจอร์ (Detail count ต้อง = List bucket count) | **High risk ใหม่ที่ ba1 ไม่ได้กล่าวถึงเลย** — ดูข้อ 3.3 |
| 5 | JobNumber/OrderNumber สลับความหมาย | บรรทัด 261–262 | ✅ ตรวจ mapping กับตัวอย่าง Excel ซ้ำแล้ว ยืนยันตรงกับที่ ba1 สรุป (`JobNumber`←`D_Order.OrderNumber`, `OrderNumber`←`RefWebOrder`) — ไม่ใช่บั๊ก | เห็นตรงกับ ba1 (2.4) |
| 6 | Address data quality | บรรทัด 268–280 | ✅ ตรวจ NULL-handling ของสูตร concat เองแล้ว (ทีละ `ISNULL(... NULLIF(LTRIM(RTRIM(...)),N'')...)`) — **สูตรนี้เขียนถูกต้องและปลอดภัยกว่าที่คิด**: field ว่าง/NULL จะถูกตัดออกจาก Address ทั้งท่อนโดยไม่เหลือช่องว่างเกิน ไม่ใช่จุดอ่อนทางเทคนิค ปัญหาที่ ba1 พบ (ชื่อบริษัทปนใน HouseNumber) เป็นปัญหาคุณภาพข้อมูลต้นทาง (OMS) ล้วนๆ ตามที่ SQL comment ยอมรับเอง ไม่ใช่บั๊ก logic ของ proc นี้ | เห็นตรงกับ ba1 (2.5) — ยืนยันเพิ่มเติมว่า NULL-handling ของสูตรนี้ "ถูกต้องดี" ไม่ใช่แค่ "ยอมรับความเสี่ยง" |

---

## 3. จุดที่ต้อง Recheck เป็นพิเศษ

### 3.1 [HIGH] `@BacklogAsOf = @DateTo` vs concept "วันที่รันรายงานจริง" — วิเคราะห์เชิงปริมาณ

**คำถามที่ PO ถามตรงๆ**: "ย้อนหลังกี่วันถึงจะเริ่มเห็นตัวเลขคลาดเคลื่อน"

**คำตอบจากการไล่สูตร**: `BacklogAgeDays = DATEDIFF(DAY, SlotDate, @BacklogAsOf)` โดย `@BacklogAsOf = @DateTo` (ค่าพารามิเตอร์ ไม่ใช่ `GETDATE()`) — เนื่องจาก `SlotDate <= @DateTo` เสมอ (เพราะ `#ord` กรอง `StartTime < @DateToExclusive`) ค่า `BacklogAgeDays` จึง **>= 0 เสมอ** ภายใต้ implementation ปัจจุบัน

- ถ้า `@DateTo = วันนี้จริง` (การใช้งานปกติของ ops รายวัน) → `@BacklogAsOf` เท่ากับ concept ของ PO พอดี ไม่มีความคลาดเคลื่อน
- ถ้า `@DateTo < วันนี้` (ผู้ใช้ดึงรายงานย้อนหลัง เช่น สรุปสิ้นเดือน/สิ้นสัปดาห์) → **เริ่มคลาดเคลื่อนทันทีตั้งแต่ gap = 1 วัน** เพราะสูตรอิงพารามิเตอร์ที่เลือก ไม่ใช่วันจริง ตัวเลข Backlog age ที่ได้จะ**น้อยกว่าความเป็นจริงเสมอ** (ไม่มีทางมากเกินจริง เพราะ `@DateTo <= GETDATE()` ในการใช้งานปกติ)
- ผลกระทบต่อ **bucket ที่มองเห็นได้ (เปลี่ยนคอลัมน์)**: order ที่มี `SlotDate` ใกล้ `@DateTo` (เช่น `SlotDate = @DateTo`, age=0→bucket "1 Day") จะย้าย bucket ทันทีที่ gap ระหว่างวันที่รันจริงกับ `@DateTo` >= 1 วัน (จะกลายเป็น "2 Days" ถ้ารันช้าไป 2 วันจาก `@DateTo` ที่เลือก เป็นต้น)
- ผลกระทบ**รุนแรงสุด**: เมื่อ gap (`GETDATE() - @DateTo`) **> 3 วัน** — backlog order ทุกใบในรายงานย้อนหลังนั้นจะแสดง age ที่ต่ำกว่าความเป็นจริงอย่างมีนัยสำคัญ (order ที่จริงเป็น backlog ค้างนาน อาจโชว์แค่ "1 Day" หรือ "2 Days" ในรายงานย้อนหลัง)
- Value by Backlog / Value by During Delivery ก็คลาดเคลื่อนตามไปด้วย (ผูกกับ bucket เดียวกัน) แต่ **Total Backlog (จำนวน order รวม)** และ **BacklogValueTotal (ยอดรวม)** **ไม่คลาดเคลื่อน** เพราะไม่ขึ้นกับ `@BacklogAsOf` เลย (แค่เช็ค `StatusCode`) — คลาดเคลื่อนเฉพาะ**การแบ่ง bucket อายุ**เท่านั้น

**ข้อเสนอสำหรับตัดสินใจ defect vs accept**:
- ถ้า flow การใช้งานจริงบังคับ/ค่า default ให้ `@DateTo = วันนี้เสมอ` (เช่น หน้าจอ default เป็น "วันนี้" และผู้ใช้ operation ดูแค่วันนี้) → ผลกระทบในทางปฏิบัติ = 0 ยอมรับ implementation ปัจจุบันได้ แต่ควรมี **comment/เอกสารกำกับชัดเจน** ว่า "Backlog age อิงกับ @DateTo ไม่ใช่วันจริง"
- ถ้าผู้ใช้สามารถ (และมีแนวโน้มจะ) เลือกช่วงย้อนหลังเพื่อดู trend/สรุป → ควรแก้เป็น `@BacklogAsOf = CAST(GETDATE() AS DATE)` และเปิดคำถามใหม่ (ดูข้อ 4 ด้านล่าง — negative BacklogAgeDays)

**Verify query (ร่าง ยังไม่ execute)**:
```sql
-- เทียบจำนวน order ต่อ bucket ระหว่าง @BacklogAsOf=@DateTo (ปัจจุบัน) กับ @BacklogAsOf=GETDATE() (concept)
-- รันสำหรับ @DateTo ที่ต่างจากวันนี้หลายระดับ (gap = 1, 2, 3, 7 วัน) เพื่อดูว่า bucket เปลี่ยนกี่ order
SELECT
    o.OrderNumber,
    CAST(o.StartTime AS DATE) AS SlotDate,
    DATEDIFF(DAY, CAST(o.StartTime AS DATE), @DateTo)              AS AgeVsDateTo,
    DATEDIFF(DAY, CAST(o.StartTime AS DATE), CAST(GETDATE() AS DATE)) AS AgeVsToday
FROM D_Order o
WHERE o.IsActive = 1 AND o.BUCode = 'CFW'
  AND o.StatusCode NOT IN ('18000','18001','13004','17002',
                            '13090','13091','19000','19001','19002','19040',
                            '19050','19051','19100','19101','19180')
  AND o.StartTime >= @DateFrom AND o.StartTime < DATEADD(DAY,1,@DateTo);
-- นับจำนวนแถวที่ AgeVsDateTo กับ AgeVsToday ตกคนละ bucket (1/2/3/>3) — จำนวนนี้ = ขนาดผลกระทบจริง
```

### 3.2 [HIGH] `D_Order.EndTime` เป็น NULL ได้หรือไม่ — กระทบ invariant "sum(bucket) = Order Delivered" โดยตรง

ba1 เขียน AC-6 ว่า "ผลรวมทั้ง 5 bucket ต้องเท่ากับ Order Delivered พอดี" เป็นข้อเท็จจริงที่ยืนยันได้แน่นอน — **ตรวจสอบแล้วพบว่าไม่จริงเสมอไป** ถ้า `D_Order.EndTime` เป็น NULL ได้สำหรับบาง order ที่ `IsDelivered=1`:

- `LateMinutes = DATEDIFF(MINUTE, t.SlotEndTime, s.DeliveredTime)` — ถ้า `SlotEndTime` (มาจาก `o.EndTime`) เป็น NULL → `LateMinutes = NULL`
- ทุก comparison ที่ใช้ `LateMinutes` (`OntimeCount`, `DelayCount`, `LeadDay0..LeadDayOver3` ทั้ง 5 bucket) จะประเมินเป็น UNKNOWN และไม่ถูกนับใน**ทั้ง 5 bucket และทั้ง Ontime/Delay** แม้ว่า order นั้นจะถูกนับใน `OrderDelivered` (`SUM(c.IsDelivered)`) อยู่ดี เพราะ `IsDelivered` ไม่ได้ขึ้นกับ `LateMinutes`
- ผลคือ order "หาย" จากทั้ง bucket และ Ontime/Delay แต่ยังถูกนับใน `OrderDelivered` — **`OrderDelivered ≠ OntimeCount+DelayCount` และ `OrderDelivered ≠ LeadDay0+...+LeadDayOver3`** ได้ในทางทฤษฎี

โค้ดไม่มีการ `ISNULL(o.EndTime, ...)` ป้องกันไว้เลย (ต่างจาก `OrderValue` ที่มี `ISNULL(o.TotalNet,0)` ชัดเจน) — เป็นจุดที่ต้อง verify กับ DBA ว่า column นี้ nullable จริงหรือไม่ (มี constraint `NOT NULL` ในระดับ DB หรือไม่)

**Verify query**:
```sql
-- นับ order ที่มี StartTime (เข้าเกณฑ์ #ord) แต่ EndTime เป็น NULL ในช่วงที่จะทดสอบ
SELECT COUNT(*) AS OrdersWithNullEndTime
FROM D_Order o
WHERE o.IsActive = 1 AND o.BUCode = 'CFW'
  AND o.StartTime >= @DateFrom AND o.StartTime < DATEADD(DAY,1,@DateTo)
  AND o.EndTime IS NULL;
-- ถ้า > 0 ให้เช็คต่อว่ามีใบไหนที่ StatusCode='18000' ด้วย (จะเป็นเคสที่ทำให้ invariant พัง)
```

### 3.3 [HIGH] `M_Status` join ใน Detail proc เสี่ยง fan-out — กระทบ core invariant ของทั้งฟีเจอร์ (ba1 ไม่ได้กล่าวถึง)

Detail proc บรรทัด 292: `LEFT JOIN M_Status ms ON ms.StatusCode = o.StatusCode` — เป็น join เดียวในทั้ง 2 proc ที่**ไม่มีการยืนยัน/บังคับ uniqueness ของ join key** (ต่างจาก `#ord`, `#statuslog`, `#store` ที่ทุกตัวถูกบังคับ `CREATE UNIQUE CLUSTERED INDEX` หรือ `GROUP BY` เพื่อการันตี 1:1 ก่อน join)

ถ้า `M_Status.StatusCode` **ไม่ใช่ primary key / ไม่ unique** (เช่น มีหลายแถวต่อ `StatusCode` แยกตามภาษา, BUCode, หรือ version) การ join นี้จะทำให้**แถวผลลัพธ์ของ order นั้น "ทวีคูณ"** — เช่น order 1 ใบ กลายเป็น 2 แถวใน Detail เพราะ match กับ `M_Status` 2 แถว — ผลกระทบโดยตรงคือ **`COUNT(*)` ของ Detail (`@OrderType=...`) จะไม่เท่ากับตัวเลขใน List** ซึ่งเป็น **invariant หลักที่สุดของทั้งฟีเจอร์** (AC-12 ของ ba1 พูดถึงเรื่องนี้ตรงๆ) — นี่คือความเสี่ยงที่กระทบ requirement ข้อสำคัญที่สุดของ Detail proc ทั้งหมด แต่ ba1 ไม่ได้ตรวจ join นี้เลยในเอกสารเดิม

**Verify query**:
```sql
-- เช็คว่า M_Status.StatusCode ซ้ำหรือไม่ (ถ้า COUNT(*) > COUNT(DISTINCT StatusCode) แปลว่ามีความเสี่ยง fan-out จริง)
SELECT StatusCode, COUNT(*) AS Cnt
FROM M_Status
GROUP BY StatusCode
HAVING COUNT(*) > 1;
-- ถ้ามีผลลัพธ์ ให้ตรวจต่อว่า Detail proc ควรเพิ่มเงื่อนไข join (เช่น BUCode, IsActive, LanguageCode) หรือใช้ TOP 1 / MAX
```

### 3.4 [HIGH] `D_Order.OrderNumber` ซ้ำได้หรือไม่ภายใน BU เดียวกัน — ต่อยอด TBC #9 ของ ba1 ให้ลึกกว่าเดิม

ba1 (TBC #3/#9 เดิม) ตั้งคำถามไว้ว่า `D_StatusLog` ไม่มี `BUCode` และ `OrderNumber` อาจ "ซ้ำข้าม BU" — ตรวจ comment ในตัว SQL เพิ่มเติมพบหลักฐานที่บ่งชี้ความเสี่ยง**ภายใน BU เดียวกัน**ด้วย ไม่ใช่แค่ข้าม BU:

- Comment บรรทัด 144 ของ List proc: `19030 ขอเลื่อน (สร้างรายการใหม่)` — ระบุตรงๆ ว่าการเลื่อนนัดจะ**สร้างเรคคอร์ดใหม่** ถ้าเรคคอร์ดใหม่นี้ใช้ `OrderNumber` **เดิมซ้ำกับเรคคอร์ดเก่า** (คนละ `dOrderID`/`ID`) จะเกิดปัญหา: การ join `#statuslog` (บรรทัด 106–108, `JOIN D_StatusLog l ON l.OrderNumber = t.OrderNumber AND l.StatusCode='18000'`) ใช้ **`OrderNumber` เป็น join key เพียงอย่างเดียว ไม่ใช่ `dOrderID`** — ถ้า `#ord` มี 2 แถว (`dOrderID` A=เก่า/ถูกเลื่อน, B=ใหม่) ที่ใช้ `OrderNumber` เดียวกัน และทั้งคู่มี `StartTime` อยู่ในช่วงค้นหา (เป็นไปได้ถ้าเลื่อนนัดข้ามวันแต่ทั้งคู่ยังอยู่ในกรอบรายงาน) log การส่งสำเร็จของใบใดใบหนึ่งจะถูก join เข้าไปที่**ทั้งสอง `dOrderID`** พร้อมกัน (เพราะ join บน `OrderNumber` ไม่เจาะจง `dOrderID`) ทำให้ทั้งใบเก่าที่ถูกยกเลิก/เลื่อนไปแล้ว และใบใหม่ ถูกนับเป็น "Delivered" พร้อมกันทั้งคู่ (double count) หรือใบที่ผิดถูกนับแทนใบที่ถูก

นี่เป็นความเสี่ยง**High** เพราะไม่ใช่แค่กระทบ cross-BU (ที่ ba1 บอกว่ามีการกรอง BUCode ที่ `#ord` มาก่อนแล้วช่วยลดความเสี่ยงบางส่วน) แต่อาจเกิด**ภายใน BU เดียวกัน**ตรงๆ ตามที่ comment ของ SQL เองบอกใบ้ไว้

**Verify query**:
```sql
-- เช็ค OrderNumber ซ้ำภายใน BU เดียวกันช่วงที่จะทดสอบ (สำคัญกว่าการเช็คข้าม BU)
SELECT OrderNumber, COUNT(*) AS Cnt, MIN(ID) AS MinID, MAX(ID) AS MaxID
FROM D_Order
WHERE IsActive = 1 AND BUCode = 'CFW'
GROUP BY OrderNumber
HAVING COUNT(*) > 1;
-- ถ้ามีผลลัพธ์ ให้ query ต่อว่าคู่ที่ซ้ำนี้มี StatusCode ต่างกันแบบ "ใบเก่าถูกเลื่อน (19030) + ใบใหม่" หรือไม่
-- แล้วตรวจว่า D_StatusLog log 18000 ผูกกับ dOrderID ไหนจริง (ถ้า D_StatusLog มีคอลัมน์อ้างอิง Order.ID ให้ join ด้วย ID แทน OrderNumber จะปลอดภัยกว่า)
```

### 3.5 [MEDIUM] `MAX()` แยกคอลัมน์ใน `M_Place` lookup เสี่ยง "Frankenstein row"

บรรทัด 39–40:
```sql
SELECT @BranchName = MAX(pl.NameLocal),
       @StoreName  = MAX(pl.BranchName)
FROM M_Place pl
WHERE pl.PlaceCode = @BranchCode AND pl.BUCode = @BUCode AND pl.IsActive = 1;
```
`MAX()` การันตีแค่ว่าแต่ละคอลัมน์ได้ค่ามากสุดของตัวเอง **ไม่การันตีว่าทั้งสองค่ามาจากแถวเดียวกัน** — ถ้า `M_Place` มีมากกว่า 1 แถว active ต่อ `(PlaceCode, BUCode)` จริง (ตามที่ comment บรรทัด 167 ของ SQL เองบอกว่า unique key จริงคือ `(ProviderCode, BUCode, PlaceCode)`) ค่า `@BranchName` (ใช้ทำ H2) และ `@StoreName` (ใช้ทำคอลัมน์ Store) อาจมาจากคนละ `ProviderCode` กัน ทำให้หัวรายงานกับคอลัมน์ Store แสดงชื่อสาขาไม่ตรงกันแบบเงียบๆ (ไม่ error แต่ผิด)

**Verify query**:
```sql
SELECT PlaceCode, BUCode, COUNT(*) AS Cnt,
       COUNT(DISTINCT NameLocal) AS DistinctNameLocal,
       COUNT(DISTINCT BranchName) AS DistinctBranchName
FROM M_Place
WHERE IsActive = 1
GROUP BY PlaceCode, BUCode
HAVING COUNT(*) > 1;
-- ถ้า DistinctNameLocal > 1 หรือ DistinctBranchName > 1 แปลว่ามีความเสี่ยง Frankenstein row จริง ต้องเพิ่มเงื่อนไข ProviderCode ในการ lookup
```

### 3.6 [MEDIUM] NULL `OrderDate` ทำให้ตัวหารของ Average Leadtime "ไม่เท่ากับ" Order Delivered ตามตัวอักษร requirement

ดูหัวข้อ 2.1 ข้อ 9 — เพิ่มเติมผลกระทบต่อฝั่ง Detail: `@OrderType='AVGORDERHR'` คืนแถวทั้งหมดที่ `SectionCode='LEADTIME'` (คือ order Delivered ทั้งหมด ไม่กรอง `LeadMinutes IS NOT NULL`) ดังนั้นถ้าผู้ใช้กดดูรายละเอียดของค่าเฉลี่ย จะเห็นจำนวนแถว **มากกว่า** จำนวนที่แท้จริงที่ใช้เป็นตัวหารใน `AVG()` ของ List (ซึ่งตัด NULL ออกไปแล้วเงียบๆ) — ความไม่ตรงกันนี้เป็นคนละแบบกับ invariant อื่นๆ (ไม่ใช่บั๊ก แต่เป็นความคาดหวังของผู้ใช้ที่อาจสับสนว่า "ทำไมนับแถว Detail ได้มากกว่าตัวหารจริง")

### 3.7 [MEDIUM] สถานะ 16xxx–17080 (ไม่รวม 15180) ยังไม่ปรากฏใน "Value by During Delivery" แต่ยังนับใน Total Backlog

ต่อยอดข้อ 2.1 ข้อ 14 — ต้องยืนยันกับ PO ว่าการที่กลุ่มสถานะนี้ (รอ QC/รอบันทึกค่าขนส่งหลังส่งแล้ว) หายไปจาก breakdown "During Delivery" ทั้ง 2 ช่อง (ONROUTE/ATCUST) เป็นพฤติกรรมที่ตั้งใจหรือไม่ — เพราะจะทำให้ `DuringDeliveryValueTotal < BacklogValueTotal` เสมอถ้ามี order อยู่ในช่วงนี้ (เป็น subset ที่ไม่ครบ ไม่ใช่บั๊กเชิง SQL แต่เป็นช่องว่างเชิง business ที่ต้องยืนยัน)

### 3.8 [MEDIUM] Race condition ระหว่างขั้นตอนคำนวณ (ไม่มี snapshot isolation)

ทั้ง 4 ขั้นตอน (`#ord` → `#statuslog` → `#calc` → SELECT สรุป) เป็น statement แยกกันภายใน proc เดียว รันภายใต้ isolation level ปกติ (ไม่มีการประกาศ `SET TRANSACTION ISOLATION LEVEL SNAPSHOT` หรือ wrap ด้วย explicit transaction ในโค้ดที่อ่านได้) — ถ้าระบบต้นทาง (`D_Order`, `D_StatusLog`) ถูกเขียนแบบ real-time ระหว่างที่ proc กำลังรัน (เช่น order เปลี่ยนสถานะเป็น Delivered ระหว่างขั้นที่ 1 กับขั้นที่ 2) จะเกิดกรณี: `#ord` capture `StatusCode` เก่า (ยังไม่ Delivered) แต่ `#statuslog` (query แยกทีหลัง) ดันเจอ log `18000` ที่เพิ่ง insert เข้ามาใหม่ ผลคือ `IsDelivered=0` (เพราะเช็ค `t.StatusCode='18000'` จาก snapshot เก่า) แต่ `IsBacklog=1` (จาก `StatusCode` เก่าเช่นกัน ซึ่งยังไม่ใช่ 18000) — order ใบนี้จะถูกนับเป็น **Backlog ทั้งที่จริงถูกส่งสำเร็จไปแล้วในขณะที่รายงานกำลังสร้าง** เป็นความเสี่ยงระดับ Medium (ไม่ใช่ High เพราะเป็น edge case ที่ต้องเกิด race พอดีในช่วงเวลาสั้นๆ ที่ proc รัน และเป็นเรื่องปกติของ operational report ที่ไม่ต้อง 100% real-time consistency) — แนะนำให้บันทึกเป็น known limitation ที่ยอมรับได้ ไม่ต้องแก้ เว้นแต่ QA พบว่าตัวเลขไม่นิ่งขณะเทียบผลจริง

### 3.9 [MEDIUM] Performance: ไม่มี date filter บน `D_StatusLog` ตอน join

Join กับ `D_StatusLog` (บรรทัด 106–108 List / 100–102 Detail) กรองด้วย `OrderNumber` + `StatusCode='18000'` เท่านั้น ไม่มีเงื่อนไขช่วงวันที่ (เช่น `l.CreateDate`) เลย — ถ้า `D_StatusLog` เป็นตารางประวัติ log ขนาดใหญ่ (สะสมทุก order ทุก status ทุก BU ตลอดประวัติศาสตร์ระบบ) และไม่มี index ที่ครอบคลุม `(OrderNumber, StatusCode)` พร้อม `INCLUDE(CreateDate)` การ join นี้อาจกลายเป็น scan ขนาดใหญ่ ยิ่งช่วงวันที่ที่เลือกกว้าง (`#ord` มีหลายพันแถว) ยิ่งกระทบ — ต้องให้ DBA เช็ค execution plan จริงและ index ที่มีอยู่

### 3.10 [LOW] Multiple `18000` log events ต่อ order (redelivery) — MAX(CreateDate) เลือกอันล่าสุดเสมอ

Comment บรรทัด 143 พูดถึง `19050/19051 Redelivery หลังส่งสำเร็จ` ซึ่งแปลว่า order ที่เคย Delivered (มี log `18000`) อาจถูก redeliver ใหม่อีกครั้งในภายหลัง หากกระบวนการ redeliver มีการ insert log `18000` ใหม่อีกครั้ง `MAX(CreateDate)` (บรรทัด 103) จะดึงเวลาของ**ครั้งล่าสุด**เสมอ ซึ่งอาจไม่ใช่เวลาที่ต้องการวัด SLA ครั้งแรก (ต้องยืนยัน business ว่าควรวัด SLA จากการส่งครั้งแรกหรือครั้งสุดท้ายที่ปิดจริง) — จัดเป็น Low เพราะ scope ของ requirement เดิมพูดถึง "จัดส่งสำเร็จ" แบบทั่วไป ยังไม่มีสัญญาณว่าเป็นเคสที่พบบ่อย

---

## 4. Acceptance Criteria ฉบับเทคนิค (Given/When/Then)

> ต่อยอดจาก AC-1 ถึง AC-12 ของ ba1 (ไม่เขียนซ้ำข้อที่ ba1 ครอบคลุมแล้วในระดับ business) — ชุดนี้เจาะเฉพาะ edge case ทางเทคนิคที่พบในหัวข้อ 3 เพื่อให้ QA ทดสอบได้ตรงจุด

**AC-T1 EndTime เป็น NULL (เชื่อม 3.2)**
- Given มี order ที่ `IsActive=1`, อยู่ในช่วงค้นหา, มี log `18000` และ `D_Order.StatusCode='18000'` (เข้าเกณฑ์ Delivered) แต่ `D_Order.EndTime IS NULL`
- When รันรายงาน List
- Then ต้องนิยามให้ชัดว่า order นี้ควรถูกนับใน bucket ไหน (ปัจจุบันจะ "หาย" จากทั้ง Ontime/Delay และทั้ง 5 lead-time bucket แต่ยังถูกนับใน `OrderDelivered`) — QA ต้องตรวจว่า `OrderDelivered = OntimeCount + DelayCount` และ `OrderDelivered = LeadDay0+LeadDay1+LeadDay2+LeadDay3+LeadDayOver3` เท่ากันเป๊ะทุกครั้งที่รันจริง ถ้าไม่เท่ากันให้สืบว่าเกิดจาก NULL EndTime หรือไม่

**AC-T2 OrderNumber ซ้ำภายใน BU เดียวกัน (เชื่อม 3.4)**
- Given มี order 2 ใบขึ้นไปใน BU เดียวกันที่ใช้ `OrderNumber` เดียวกัน (เช่นกรณีเลื่อนนัด 19030) และทั้งคู่มี `StartTime` อยู่ในช่วงค้นหาเดียวกัน
- When รันรายงาน List
- Then จำนวน order ที่นับเป็น Delivered ต้องนับตาม `dOrderID`/`D_Order.ID` แต่ละใบแยกกันอย่างถูกต้อง ไม่เกิด double-count หรือ cross-attribution ของ `DeliveredTime` ข้ามใบ — QA ต้องยืนยันด้วยการเทียบ `COUNT(DISTINCT dOrderID)` กับ `COUNT(*)` ใน `#statuslog`/`#calc` ว่าไม่มีการขยายแถวเกิน 1:1

**AC-T3 M_Status join fan-out ใน Detail (เชื่อม 3.3)**
- Given ผู้ใช้คลิกดู Detail ของ bucket ใดๆ (เช่น `BACKLOG2DAY`)
- When proc `RPT_OrderLeadtimeBacklogDetail` join กับ `M_Status`
- Then จำนวนแถวผลลัพธ์ต้อง**เท่ากับ**จำนวน order ที่เข้าเกณฑ์ bucket นั้นเป๊ะ (นับจาก `#pick` ก่อน join `M_Status`) — ถ้า `M_Status.StatusCode` มีมากกว่า 1 แถวต่อค่า จะทำให้จำนวนแถวเกินจำนวนที่ควรจะเป็น และไม่ตรงกับตัวเลขในหน้า List (ผิด AC-12 ของ ba1) — QA ต้องเทียบ `COUNT(*)` จาก Detail กับ `COUNT(*)` ของ `#pick` ก่อน join M_Status (ถ้าต่างกัน = defect ยืนยันได้ทันที)

**AC-T4 @BacklogAsOf กับรายงานย้อนหลัง (เชื่อม 3.1)**
- Given ผู้ใช้เลือก `@DateTo` เป็นวันที่ในอดีต (ไม่ใช่วันนี้) ที่มี order เป็น Backlog อยู่
- When รันรายงาน แล้วเทียบกับผลที่ควรได้ถ้าคำนวณอายุด้วย `GETDATE()` จริง (ตาม concept ของ PO)
- Then ทีม dev/PO ต้องตัดสินใจและบันทึกไว้ชัดเจนว่า Backlog age ที่แสดงคือ "อายุ ณ วันที่เลือกดู (`@DateTo`)" หรือ "อายุ ณ วันนี้จริง" — ถ้าเลือกอย่างหลัง ต้องแก้ `@BacklogAsOf` เป็น `GETDATE()` และเพิ่มการทดสอบ AC-T5 ต่อทันที (negative age)

**AC-T5 Negative BacklogAgeDays ถ้าเปลี่ยนเป็น GETDATE() (เชื่อม 3.1)**
- Given (สมมติแก้ `@BacklogAsOf = CAST(GETDATE() AS DATE)` ตาม concept ของ PO) มี order ที่ `SlotDate` เป็น**วันในอนาคต**เทียบกับวันนี้ (เช่น ผู้ใช้เลือก `@DateTo` เป็นวันพรุ่งนี้/มะรืนเพื่อดูงานที่จะถึง) และยังไม่ Delivered
- When คำนวณ `BacklogAgeDays = DATEDIFF(DAY, SlotDate, @BacklogAsOf)`
- Then ค่าที่ได้จะติดลบ และตาม logic ปัจจุบัน (`<=1` ครอบคลุมค่าติดลบด้วย) จะถูกจัดเข้า bucket "1 Day" ทั้งที่ยังไม่ถึงกำหนดส่งจริง — ต้องตัดสินใจว่าจะกันเคสนี้ออกจาก Backlog ทั้งหมด (order ที่ยังไม่ถึงกำหนด ไม่ควรนับเป็น Backlog เลย) หรือยอมรับ

**AC-T6 Average Leadtime denominator vs AVGORDERHR row count (เชื่อม 3.6)**
- Given มี order ที่ Delivered แต่ `OrderDate` เป็น NULL อยู่ในช่วงค้นหา
- When เทียบจำนวนแถวที่ได้จาก Detail `@OrderType='AVGORDERHR'` กับตัวหารจริงที่ใช้คำนวณ `AvgLeadtimeHr` ใน List
- Then ทีมต้องยืนยันว่าความต่างนี้ (จำนวนแถว Detail > ตัวหารจริงของค่าเฉลี่ย) เป็นพฤติกรรมที่ยอมรับได้และสื่อสารกับผู้ใช้อย่างไร (เช่น เพิ่ม note ในรายงานว่า order ที่ไม่มี `OrderDate` ไม่ถูกรวมในค่าเฉลี่ย)

**AC-T7 M_Place duplicate ProviderCode (เชื่อม 3.5)**
- Given `M_Place` มีมากกว่า 1 แถว active สำหรับ `(PlaceCode, BUCode)` เดียวกัน (ต่าง `ProviderCode`) โดยมี `NameLocal`/`BranchName` ไม่เหมือนกัน
- When ดูหัวรายงาน (H2) และคอลัมน์ Store ของสาขานั้น
- Then ต้องแสดงชื่อสาขาชุดเดียวกันสอดคล้องกันเสมอ (ไม่ใช่ H2 มาจาก provider A แต่ Store มาจาก provider B) — QA ต้องตรวจสอบว่าค่าที่ได้จริงตรงกับแถวใดแถวหนึ่งใน `M_Place` แบบสมบูรณ์ ไม่ใช่ค่าผสมข้ามแถว

**AC-T8 During Delivery ไม่ครอบคลุมสถานะ 16xxx–17080 (เชื่อม 3.7)**
- Given มี order ที่อยู่ในสถานะช่วง 16xxx–17080 (ไม่รวม 15180) และยังเป็น Backlog
- When ดูคอลัมน์ Value by During Delivery (ONROUTE/ATCUST) เทียบกับ Total Backlog
- Then ต้องยืนยันกับ PO ว่ายอมรับให้ `DuringDeliveryValueTotal < BacklogValueTotal` ในกรณีนี้ หรือควรมี category เพิ่มเติมสำหรับสถานะกลุ่มนี้

---

## 5. เทียบกับข้อสรุปของ ba1

### เห็นด้วย (ยืนยันซ้ำด้วยการตรวจอิสระ)
- List↔Detail ใช้ logic ขั้นที่ 1–3 เหมือนกันจริง (ตรวจ diff เองแล้ว ไม่ใช่แค่เชื่อ comment)
- Threshold ตัวเลข bucket ระหว่าง 2 proc ตรงกันทางคณิตศาสตร์ (derive เองแล้ว ไม่ใช่แค่เทียบตัวเลขผิวเผิน)
- Store format (underscore), TotalNet vs basket amount, JobNumber/OrderNumber สลับชื่อ, Address data quality — ตรวจซ้ำแล้วยืนยันตรงตามที่ ba1 สรุป
- Address concat formula ปลอดภัยเรื่อง NULL-handling ดีอยู่แล้ว (เป็นการยืนยันเชิงบวกเพิ่มเติมจาก ba1)

### ท้าทาย / แก้ไข
1. **AC-6 ของ ba1** ("ผลรวม 5 bucket ต้องเท่ากับ Order Delivered พอดี") **ไม่การันตี 100%** ถ้า `EndTime` เป็น NULL ได้ — ควรเพิ่มเงื่อนไข verify ก่อนปิด AC นี้ (ดู 3.2/AC-T1)
2. **TBC #4 ของ ba1** (สถานะ 15180–17080 "จัดกลุ่มไหน") **กว้างเกินจริง** — โค้ดจริง map `15180` เข้า ATCUST ชัดเจนแล้ว ส่วนที่ยังไม่ resolve จริงๆ คือแค่ 16xxx–17080 (ดู 3.7)
3. **ข้อ #6 ของ ba1** (`@BacklogAsOf`) ba1 ตั้งเป็นคำถามเปิดลอยๆ — เอกสารนี้ให้**คำตอบเชิงปริมาณ**ที่ใช้ตัดสินใจ defect vs accept ได้ทันที (gap 1 วันเริ่มเพี้ยน, gap >3 วันกระทบรุนแรง) (ดู 3.1/AC-T4/AC-T5)
4. **TBC #9/#3 ของ ba1** (D_StatusLog ไม่มี BUCode) ba1 พูดถึงเฉพาะความเสี่ยงข้าม BU — เอกสารนี้เจาะลึกเพิ่มว่าเสี่ยง**ภายใน BU เดียวกัน**ได้ด้วยจาก comment เรื่อง 19030 สร้างเรคคอร์ดใหม่ (ดู 3.4/AC-T2)
5. **จุดที่ ba1 ไม่ได้ตรวจเลย**: M_Status join fan-out risk ใน Detail proc (High, ดู 3.3/AC-T3), M_Place MAX() cross-column risk (ดู 3.5/AC-T7), race condition ข้ามขั้นตอน (ดู 3.8), performance ของ D_StatusLog join ที่ไม่มี date filter (ดู 3.9), NULL OrderDate กระทบตัวหารเฉลี่ย vs AVGORDERHR row count (ดู 3.6/AC-T6)

---

## 6. คำถามเพิ่มเติมที่ต้องยืนยันกับ PO/dev/DBA (นอกเหนือจาก 13 ข้อเดิมของ ba1)

14. 🆕 **[High]** `M_Status.StatusCode` เป็น unique/primary key จริงหรือไม่ — ถ้าไม่ใช่ ต้องแก้ join ใน `RPT_OrderLeadtimeBacklogDetail` (เพิ่มเงื่อนไข หรือ dedup ก่อน join) ก่อนปล่อยใช้งาน เพราะกระทบ invariant หลักของ AC-12
15. 🆕 **[High]** `D_Order.OrderNumber` รับประกันไม่ซ้ำภายใน BU เดียวกันหรือไม่ (โดยเฉพาะกรณี 19030 เลื่อนนัด/สร้างเรคคอร์ดใหม่) — ถ้าซ้ำได้ ต้องเปลี่ยน join key ของ `#statuslog` จาก `OrderNumber` เป็นตัวระบุที่ unique กว่า (เช่น join ผ่าน `D_Order.ID` ถ้า `D_StatusLog` มีคอลัมน์อ้างอิงถึงได้)
16. 🆕 **[High]** `D_Order.EndTime` เป็น NULL ได้หรือไม่ (มี constraint NOT NULL ระดับ DB หรือไม่) — ถ้าได้ ต้องตัดสินใจว่า order เหล่านี้ควรตกอยู่ bucket ไหน แทนที่จะ "หาย" จากทั้ง Ontime/Delay และ Lead-time bucket
17. 🆕 **[Medium]** `M_Place` มีมากกว่า 1 แถว active ต่อ `(PlaceCode, BUCode)` จริงหรือไม่ (ต่าง `ProviderCode`) — ถ้ามี ต้องเพิ่มเงื่อนไข join ให้ H2/Store ไม่ผสมข้ามแถว
18. 🆕 **[Medium]** ควรวัด SLA/Lead time ของ order ที่ถูก redeliver (19050/19051) จากเวลา delivered **ครั้งแรก** หรือ**ครั้งล่าสุดที่ปิดจริง**
19. 🆕 **[Low]** ยืนยัน index ที่มีอยู่จริงบน `D_StatusLog` (คอลัมน์ `OrderNumber`, `StatusCode`, `CreateDate`) เพื่อประเมิน performance ก่อนขึ้น production จริง
20. 🆕 **[Low]** `@BUCode` default เป็น `'CFW'` แบบ hardcode (บรรทัด 15 ของทั้ง 2 proc) — ยืนยันว่าแอปฝั่งเรียกใช้จะ pass `@BUCode` explicit เสมอ ไม่พึ่งพา default นี้ในทางปฏิบัติ (ป้องกันกรณีถูกใช้กับ BU อื่นในอนาคตแล้วได้ข้อมูล CFW ผิดสาขาธุรกิจแบบเงียบๆ)

---

## 7. สรุปก่อนส่งต่อ

เอกสารนี้ตรวจจากการอ่าน SQL text (ทั้ง 2 proc ครบทุกบรรทัด) + เทียบ requirement + เทียบเอกสาร ba1 เท่านั้น **ยังไม่ได้ execute query ใดๆ จริง** (ไม่มี DB connection) — ทุก query ในหัวข้อ 3 เป็นร่างให้ DBA/ทีมที่มีสิทธิ์รันต่อ

**ผลตรวจสรุป**: logic การคำนวณหลักของทั้ง 2 proc ถูกต้องตาม requirement และสอดคล้องกับที่ ba1 สรุปไว้เป็นส่วนใหญ่ (9/16 ข้อตรงสนิท) แต่มี **High risk ใหม่ 3 จุด** (M_Status join fan-out, OrderNumber duplicate ภายใน BU, EndTime nullable) ที่**ยังไม่เคย verify กับข้อมูลจริง** และกระทบ invariant สำคัญของฟีเจอร์โดยตรง (จำนวนแถว Detail ต้องตรงกับ List, ผลรวม bucket ต้องตรงกับ Order Delivered) — เป็นความเสี่ยงที่ควรปิดให้ได้**ก่อน**เข้ารอบ UAT ไม่ใช่หลัง

**ขั้นตอนถัดไปที่แนะนำ**:
1. ส่ง query ในหัวข้อ 3.1–3.4 (4 ข้อ High risk) ให้ DBA รันตรวจก่อนเป็นอันดับแรก — ผลจะบอกได้ทันทีว่าความเสี่ยงเป็นเรื่องจริงหรือแค่ทฤษฎี
2. รวมคำถามข้อ 14–16 (High) เข้ากับ backlog คำถามเดิมของ ba1 ส่งให้ PO/dev ตอบพร้อมกัน
3. หลังยืนยันครบ ส่งต่อให้ `ux-designer` ออกแบบ User Flow/Wireframe ของหน้า List และ Detail ต่อได้เลยสำหรับส่วนที่ไม่กระทบ data correctness (H1-H3, ตาราง, filter panel) ส่วน column/label ที่ผูกกับคำถามยังเปิด (Store format, Value label, During Delivery breakdown) ให้ wireframe เป็น placeholder ไว้ก่อนจนกว่าจะปิดคำถามได้
