# Business Requirement Review: Order Lead-Time & Backlog Report (Task #70681)

> เอกสารนี้จัดทำโดย BA (Business Analyst) เพื่อรีวิว PROC ที่พัฒนาไว้แล้ว เทียบกับ Requirement เชิงธุรกิจของ Task #70681 ก่อนส่งต่อให้ BA เทคนิค (ba2-tech-analyst) แตกเป็น API/Backend logic และ Frontend requirement ต่อไป
> ความละเอียด: เขียนในระดับ **Business (~50%)** — เน้นให้ PO/QA ที่ไม่ใช่สาย technical อ่านแล้วตัดสินใจได้ ไม่ลงลึกทุก join/index/edge-case ทางเทคนิค
> **[อัปเดต 2026-09-16]**: PO ยืนยันคำตอบกลับมาสำหรับคำถามเปิดหลายข้อ และไฟล์ `RPT_Performance_detail.sql` ถูกแทนที่ด้วย proc ของหน้า Detail จริงแล้ว — รายละเอียดการอัปเดตอยู่ในหัวข้อ 0, 1.1, 1.4, 1.5, 1.6, 2 (เขียนใหม่ทั้งหมด), 4.7–4.8, 5 (AC-2/5/10/12), 6, 7

---

## 0. สรุปภาพรวม

### ไฟล์ที่ตรวจและวิธีอ่าน

| ไฟล์ | วิธีอ่าน | อ่านได้ |
|---|---|---|
| `RPT_OrderLeadtimeBacklog.sql` | Read tool (อ่านครบทั้งไฟล์ 1–256 รวม comment ทุกบรรทัด) | ✅ ครบ |
| `RPT_Performance_detail.sql` (เนื้อหาไฟล์ถูกแทนที่แล้ว — ปัจจุบันเป็น `ALTER PROCEDURE [dbo].[RPT_OrderLeadtimeBacklogDetail]` ไม่ใช่ Daily Performance Report ของ CFR อีกต่อไป) | Read tool (อ่านซ้ำทั้งไฟล์ 1–303 หลัง PO แจ้งว่าเนื้อหาเปลี่ยน) | ✅ ครบ |
| `Example ReportOrderLeadtimeSummary 2026-08-26_03-55.xlsx` | ไม่มี Python/openpyxl ในเครื่อง (ตรวจแล้ว ไม่ได้ติดตั้งเพิ่ม) จึงอ่านผ่าน **Excel COM Automation** (PowerShell + `Excel.Application`, read-only) | ✅ อ่านครบทั้ง 4 sheet |
| Azure DevOps Task #70681 | **เข้าไม่ได้ในเซสชันนี้** (redirect ไป login) | ผู้ใช้ paste ข้อความ requirement มาให้แทน — ใช้เป็นแหล่งอ้างอิงหลักของเอกสารนี้ |
| DB จริง (TMS) | **ไม่มี DB connection ในเซสชันนี้** | ไม่ได้ query จริง — ทุก query ในเอกสารนี้เป็น "ร่างให้ DBA/ทีมที่มีสิทธิ์รันต่อ" เท่านั้น |

### ไฟล์ Excel ตัวอย่าง มี 4 sheet
| Sheet | เนื้อหา |
|---|---|
| `29 07 2026 ถึง 26 08 2026` | รายงาน List/Summary ตัวอย่าง 1 สาขา (SNR_001) ช่วง 29/07–26/08/2026 |
| `2907-2608 - Backlog` | รายงาน **Detail** ของ Backlog จริง 88 แถว (ตรงกับ #Total Backlog=88 ในหน้า Summary พอดี) — คอลัมน์ตรงกับที่ requirement ระบุทุกตัว |
| `01 04 2026 ถึง 26 08 2026` | รายงาน List/Summary ตัวอย่างอีกช่วงวันที่ (ยาวกว่า) สาขาเดียวกัน |
| `Sheet1` | ตาราง cross-check สูตร/นิยามของ PO เอง (ยกตัวเลขจาก 2 sheet แรกมาแปะคู่กับสูตรที่เขียนไว้ในคอลัมน์ขวา) |

### หัวข้อพบสำคัญ (headline)
1. **PROC ฝั่ง List/Summary (`RPT_OrderLeadtimeBacklog.sql`) implement ตรงกับ requirement และตรงกับ layout ของไฟล์ Excel ตัวอย่างเป็นส่วนใหญ่** แต่ตัว SQL เองมี comment "TBC" (To Be Confirmed) ที่ผู้เขียนติดไว้เองหลายข้อ — บางข้อ PO ยืนยันปิดแล้วในรอบนี้ ดูหัวข้อ 1 และ 6
2. **[อัปเดต 2026-09-16] PROC สำหรับหน้า Detail ถูกสร้างขึ้นแล้ว** — ไฟล์ `RPT_Performance_detail.sql` ถูกแทนที่เนื้อหาด้วย proc ตัวจริง `RPT_OrderLeadtimeBacklogDetail` implement ตาม concept ของหน้า Detail ครบ (คัดลอก logic ขั้นที่ 1–3 จาก List proc มาเป๊ะเพื่อการันตีว่าตัวเลขตรงกัน, มี `@OrderType` รับค่าว่าคลิกมาจากช่องไหนใน List, มี 13 คอลัมน์ตาม requirement ครบ) — รีวิวแล้วในหัวข้อ 2 พบว่าโครงสร้างถูกต้องดี มีจุดที่ต้องระวัง 2 จุด (การตั้งชื่อฟิลด์ JobNumber/OrderNumber สลับกับที่คาดจากชื่อคอลัมน์ SQL, และ data quality ของ Address ที่ SQL เองก็ comment เตือนไว้)
3. **[อัปเดต 2026-09-16]** PO ยืนยันกลับมาแล้วว่า (ก) การเลือกได้มากกว่า 1 สาขาพร้อมกัน เป็น **nice-to-have ไม่ใช่ requirement บังคับ** ("ทำได้ก็ดีแล้ว") — ปรับสถานะจาก Gap เป็น **Known limitation ที่ PO รับทราบแล้ว** (ทั้ง List และ Detail proc ยังรองรับได้แค่ 1 สาขา/ทุกสาขาเหมือนเดิม); (ข) concept ของ "วันที่ดึงข้อมูล Report" สำหรับคำนวณอายุ Backlog ก็ได้รับการยืนยันแล้วว่าต้องเทียบกับ **วันที่รันรายงานจริง** แต่ **ตัว SQL ปัจจุบัน (ทั้ง List และ Detail) ยัง hardcode ใช้ `@BacklogAsOf = @DateTo`** ซึ่งยังไม่ถูก verify ว่าตรงกับ concept นี้เสมอไป — ยังเป็นจุดที่ implementation ต้องตรวจสอบเพิ่ม (ดูหัวข้อ 1.5/6)
4. **ข้อจำกัดสำคัญของรอบตรวจนี้**: ไม่มีไฟล์ export จาก CFW ให้เทียบแบบ cell-to-cell (ต่างจากงาน RPT_UtilizationSlotDeliveryPickup ก่อนหน้า) มีเพียงไฟล์ Excel ตัวอย่างที่ PO เตรียมเอง ซึ่งใช้ตรวจ "โครงสร้าง/สูตรคำนวณ" ได้ แต่ใช้ยืนยัน "ตัวเลขถูกต้องตรงกับข้อมูลจริงใน DB" ไม่ได้ — ต้องอาศัยการ query DB ต้นทางโดยตรงเป็นเกณฑ์หลักแทน (ดูหัวข้อ 4)
5. **สถานะคำถามเปิดหลังจาก PO ยืนยันรอบนี้ (ดูหัวข้อ 6 เต็ม)**: ปิดแล้ว 3 ข้อ (SLA 1 ชม., During Delivery mapping, Detail proc มีแล้ว), คลี่คลายเป็นส่วนใหญ่ 1 ข้อ (ตัวอย่างข้อมูล Detail ฝั่ง Lead time), ยังเปิดอยู่ 7 ข้อเดิม (18001, D_StatusLog ไม่มี BUCode, สถานะ 15180-17080, multi-branch เป็น known-limimation, backlog-age concept-vs-implementation, Store format, Value=TotalNet) และพบคำถามใหม่ 2 ข้อจากการรีวิว Detail proc (Address data quality, การตั้งชื่อฟิลด์ JobNumber/OrderNumber) — รวมยังเปิดอยู่ **9 ข้อ จากทั้งหมด 13 ข้อ**

---

## 1. รีวิว PROC เทียบ Requirement (ส่วน List/Summary)

> อ้างอิงบรรทัดจาก `RPT_OrderLeadtimeBacklog.sql`

### 1.1 Condition การค้นหา

| Business Rule | สิ่งที่ PROC ทำ | สถานะ |
|---|---|---|
| ใช้กรอบเวลาดึงข้อมูล = Start Time | `WHERE o.StartTime >= @DateFrom AND o.StartTime < @DateToExclusive` (บรรทัด 81–82); comment บรรทัด 58 ยืนยันเอง "วันที่จัดส่ง" map จาก `D_Order.StartTime` | ✅ **ตรง** |
| เลือกสาขาได้มากกว่า 1 สาขา | `@BranchCode VARCHAR(20) = NULL` เป็นค่าเดี่ยว comment บรรทัด 7 ระบุเอง "**ดึงทีละสาขา** (NULL = ทุกสาขา)" — proc รองรับได้แค่ **"1 สาขา"** หรือ **"ทุกสาขา"** เท่านั้น (ทั้ง List และ Detail proc เป็นแบบเดียวกัน) | ⚠️ **Known limitation — ไม่ blocking** — [อัปเดต 2026-09-16] PO ตอบกลับว่า "ทำได้ก็ดีแล้ว" ตีความว่าเป็นลักษณะ nice-to-have ไม่ใช่เงื่อนไขที่ต้องแก้ก่อนปล่อยใช้งานรอบนี้ แต่ยังคงเป็นข้อจำกัดจริงของ PROC ปัจจุบัน บันทึกไว้ให้ ba2/dev พิจารณาทำเพิ่มในอนาคตได้ถ้าต้องการ |

### 1.2 Report Header

| Business Rule | สิ่งที่ PROC ทำ | สถานะ |
|---|---|---|
| H1 = "Order Lead-Time & Backlog Report" | `@H1 = N'Order Lead-Time & Backlog Report'` (บรรทัด 30) — ตรงกับ Excel ตัวอย่าง cell [1,1] เป๊ะ | ✅ **ตรง** |
| H2 = "สาขา : ชื่อสาขา" | บรรทัด 38–50 ดึงจาก `M_Place.NameLocal` — ตรงกับ Excel ตัวอย่าง [2,1] เป๊ะ ("สาขา : บริษัท เซ็นทรัล ฟู้ด โฮลเซลล์ จำกัด (สาขา ศรีนครินทร์ 1)") | ✅ **ตรง** (กรณีเลือก 1 สาขา หรือทุกสาขา) — ⚠️ ยังไม่มี case สำหรับ "เลือกหลายสาขาเจาะจง" เพราะเป็น known limitation ตามข้อ 1.1 |
| H3 = "รายงานประจำวันที่ ... ถึง ..." | บรรทัด 54–55 `FORMAT(@DateFrom,'dd/MM/yyyy')` — ตรงกับ Excel [3,1] เป๊ะ | ✅ **ตรง** |

### 1.3 รูปแบบคอลัมน์ Store

| Business Rule | สิ่งที่ PROC ทำ | สถานะ |
|---|---|---|
| Store แสดง = Store Code (เว้นวรรค 1 วรรค) Store Name | PROC **ไม่ได้ประกอบสตริงเอง** แต่ดึงค่า `M_Place.BranchName` ตรงๆ (บรรทัด 40, 179, 198–202) โดย comment เองบอกว่ายังไม่ยืนยันว่าคอลัมน์ไหนเก็บค่าแบบไหน ("ต้องยืนยันด้วย perfcheck C1", บรรทัด 35) | ⚠️ **ต้องยืนยัน** — Excel ตัวอย่างแสดงค่าจริงเป็น `SNR_001_ศรีนครินทร์ 1` (คั่นด้วย **underscore `_`** ไม่ใช่ "เว้นวรรค") ถ้า master data (`M_Place.BranchName`) เก็บมาเป็น underscore จริง แปลว่า requirement เขียนคำว่า "เว้นวรรค" ไว้ไม่ตรงกับข้อมูลจริง ต้องยืนยันกับ PO ว่ายอมรับรูปแบบตาม master (underscore) หรือให้ proc ประกอบสตริงเองด้วยเว้นวรรคจริงๆ |

### 1.4 Order Inbound

| Business Rule | สิ่งที่ PROC ทำ | สถานะ |
|---|---|---|
| Order Inbound = COUNT(Order ID อ้างอิง Date ตาม Date Slot) | `COUNT(*)` จาก `#ord` ที่กรองด้วย `StartTime` (บรรทัด 63–84, 209) | ✅ **ตรง** |
| Order Delivered = COUNT(Order ที่สถานะจัดส่งสำเร็จในช่วงที่ค้นหา) | `SUM(c.IsDelivered)` (บรรทัด 210) โดย `IsDelivered` เช็ค **2 ชั้น**: มี log `18000` และ `D_Order.StatusCode = 18000` ทั้งใบ (บรรทัด 126–131) | ✅ **ตรงตามที่ implement** — ⚠️ แต่มี TBC เปิดอยู่ว่าควรนับสถานะ `18001` (ส่งบางส่วน) เป็น Delivered ด้วยหรือไม่ (comment บรรทัด 98–100) — ดูหัวข้อ 6 |
| Ontime/Delay: นับเฉพาะ Order ที่ Delivered, SLA ที่ End Time ของ Slot | `LateMinutes = DATEDIFF(MINUTE, SlotEndTime, DeliveredTime)` เทียบกับ `@SlaMinutes` (ตั้งค่าคงที่ 1 ชม., บรรทัด 24, 211–214) | ✅ **ตรง — ยืนยันปิดแล้ว** — [อัปเดต 2026-09-16] PO ยืนยันชัดเจนว่า "1 ชั่วโมงถือว่า Delay" คือคำตอบสุดท้าย ไม่ต้องใช้ Service Time ต่อ order/สาขา เกณฑ์ SLA คงที่ 1 ชม. ตามที่ PROC implement ไว้ถูกต้องแล้ว |
| Lead time bucket 0/1/2/3/>3 Day (นับจาก End Time Slot จนถึง Delivery Date) | `LeadDay0..LeadDayOver3` ใช้ฐาน `LateMinutes` เดียวกับ Ontime/Delay (บรรทัด 216–220) ช่วงตรงตามนิยาม 0=ภายในเวลา, 1=≤24ชม., 2=≤48ชม., 3=≤72ชม., >3=อื่นๆ | ✅ **ตรง** |
| Average Order Leadtime by Hr. = Total Lead Time / Order Delivered | `AVG(LeadMinutes)/60` โดย `LeadMinutes = DATEDIFF(MINUTE, OrderCreatedTime, DeliveredTime)` (บรรทัด 136, 222–224) | ✅ **ตรงตามสูตร** — ⚠️ หมายเหตุ: `OrderCreatedTime` ผูกกับ `D_Order.OrderDate` ไม่ใช่ `CreateDate` ตามที่ comment ระบุว่า "BA เคาะ 07/09" (บรรทัด 70–72) เป็นการตัดสินใจที่ปิดไปแล้ว แต่ยังไม่เคยเทียบกับข้อมูลจริงว่า `OrderDate` แทน "เวลาสร้างคำสั่งซื้อ" ได้ถูกต้อง 100% — แนะนำให้ยืนยันอีกครั้งตอน UAT |

### 1.5 Total Backlog

| Business Rule                                                                           | สิ่งที่ PROC ทำ                                                                                                                                                                                                                                                          | สถานะ                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| --------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Backlog = ยังไม่ Delivered / ไม่ใช่ Fail Delivery / ไม่ Cancel                          | `IsBacklog` คำนวณจาก `StatusCode NOT IN (...)` โดยแยกกลุ่ม completed/fail-delivery/cancel ไว้ชัดเจน (บรรทัด 139–150)                                                                                                                                                     | ✅ **ตรงตามหลักการ** — ⚠️ มีช่วงสถานะ `15180–17080` (งานที่ส่งแล้วแต่ยังไม่ปิดงาน QC/Finance) ที่ SQL เองยังไม่ฟันธงว่าควรอยู่กลุ่มไหน (TBC ข้อ 17, บรรทัด 145, 156)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| Backlog Day1/2/3/>3 เทียบ Slot Date กับ "วันที่ดึงข้อมูล Report"                        | `BacklogAgeDays = DATEDIFF(DAY, SlotDate, @BacklogAsOf)` โดย `@BacklogAsOf = @DateTo` (**ไม่ใช่ `GETDATE()`**, บรรทัด 26–27, 152) — Detail proc ใช้ค่าเดียวกันนี้ด้วย (บรรทัด 37)                                                                                        | 🔶 **Concept ปิดแล้ว แต่ implementation ยังไม่ verify ว่าตรงกัน** — [อัปเดต 2026-09-16] PO ยืนยัน concept แล้ว: "นับตาม Slot Date นะ ตาม Concept คือ ลูกค้านัดวันไหนก็ต้องควรวันนั้น" หมายความว่าอายุ Backlog ต้องเทียบกับ **วันที่รันรายงานจริง (วันนี้)** ไม่ใช่แค่ขอบเขตช่วงวันที่ค้นหา แต่ **SQL ปัจจุบัน (ทั้ง List และ Detail) ยัง hardcode ใช้ `@BacklogAsOf = @DateTo`** ซึ่งเป็นค่าพารามิเตอร์ที่ผู้ใช้เลือกเอง ไม่ใช่ `GETDATE()` — ถ้าการใช้งานจริงผู้ใช้เลือก `@DateTo` = วันนี้เสมอ (ไม่เคยดึงรายงานย้อนหลัง) พฤติกรรมปัจจุบันจะเทียบเท่ากับ concept ของ PO ในทางปฏิบัติ แต่ถ้ามีการดึงรายงานย้อนหลังจริง ตัวเลขจะเพี้ยนจาก concept — ยังไม่ปิดได้ 100% ต้องแจ้ง dev ตรวจสอบเพิ่ม (ดูคำถามข้อ 6 ในหัวข้อ 6) |
| ไม่มีช่อง "0 Day" ฝั่ง Backlog                                                          | Bucket เริ่มที่ `BacklogAgeDays <= 1` เป็น "1 Day" แรกสุด ไม่มี bucket 0 (บรรทัด 228–233)                                                                                                                                                                                | ✅ **ตรง** — ยืนยันด้วยไฟล์ Excel ตัวอย่างที่ไม่มีคอลัมน์ "0 Day" ในส่วน Backlog เช่นกัน                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| Value by backlog (1/2/3/>3 Day + Total)                                                 | `BacklogValueDay1..DayOver3, BacklogValueTotal` (บรรทัด 236–240) ผลรวม 4 ช่วง = Total เป๊ะ ตรวจกับ Excel ตัวอย่างแล้วสอดคล้อง (4,089+0+30,138.44+421,740.56 = 455,968.00)                                                                                                | ✅ **ตรง**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| Value by During delivery (อยู่ระหว่างการจัดส่ง/บริการ, ถึงบ้านลูกค้อกำลังจัดส่ง, Total) | `DuringDeliveryValueOnRoute/AtCustomer/Total` (บรรทัด 242–245) map จาก **สถานะปัจจุบัน** ของ order: `15110–15113`→ONROUTE, `15120,15180`→ATCUST (บรรทัด 153–159) — label ตรงคำเป๊ะกับ Excel ตัวอย่าง [5,26]/[5,27] และ Detail proc ใช้ mapping เดียวกัน (บรรทัด 192–197) | ✅ **ตรง — ยืนยันปิดแล้ว** — [อัปเดต 2026-09-16] PO ยืนยันชัดเจนว่า "อยู่ระหว่างการจัดส่ง/บริการ" = **Out for delivery** และ "ถึงบ้านลูกค้อกำลังจัดส่ง" = **Check-in Customer** ตรงกับที่ SQL map ไว้แล้ว — ความละเอียดเสริมที่ยังแนะนำ: ยังไม่เคย verify ว่า status code `15110-15113`/`15120,15180` ตรงกับชื่อสถานะ "Out for delivery"/"Check-in Customer" ใน `M_Status` จริงหรือไม่ (แนะนำให้ query `M_Status` ยืนยันชื่อ status code เหล่านี้เป็นความละเอียดเสริม ไม่ใช่คำถามเปิดหลักอีกต่อไป)                                                                                                                                                                                                                        |

### 1.6 ภาพรวมความครอบคลุมของ PROC List/Summary
โดยสรุป ฝั่ง List/Summary **implement ครบทุกฟิลด์ที่ requirement ขอ** และ **สอดคล้องกับ layout/ตัวเลขของไฟล์ Excel ตัวอย่างในเชิงโครงสร้างและสูตร** (ตรวจ cross-check ผลรวมย่อยกับผลรวมใหญ่แล้วลงตัวทุกจุดที่ตรวจได้จากไฟล์ตัวอย่าง) [อัปเดต 2026-09-16] หลัง PO ยืนยันคำถามกลับมา เหลือ**จุดที่ยังเปิดอยู่จริง 4 จุด** (Store format, 18001, D_StatusLog ไม่มี BUCode, สถานะ 15180-17080) และ **1 จุด concept ปิดแล้วแต่ implementation ยังไม่ verify** (นิยาม "วันที่ดึงข้อมูล Report" สำหรับอายุ Backlog) ส่วนเรื่องเลือกได้มากกว่า 1 สาขา ปรับจาก Gap เป็น **Known limitation ที่ไม่ blocking** แล้ว และเรื่อง SLA 1 ชม. + During Delivery mapping **ปิดคำถามได้แล้ว** — ดูรายละเอียดคำถามทั้งหมดในหัวข้อ 6

---

## 2. รีวิว PROC สำหรับหน้า Detail (RPT_OrderLeadtimeBacklogDetail) เทียบกับ Requirement

> **[อัปเดต 2026-09-16]**: ไฟล์ `RPT_Performance_detail.sql` ที่เคยระบุว่าเป็นรายงานคนละตัว (Daily Performance Report ของ CFR) **ถูกแทนที่เนื้อหาด้วย proc ตัวจริงของหน้า Detail แล้ว** — อ่านไฟล์ใหม่ทั้งไฟล์ (บรรทัด 1–303) พบว่าเป็น `ALTER PROCEDURE [dbo].[RPT_OrderLeadtimeBacklogDetail]` หัวข้อนี้จึงเปลี่ยนจาก "ฟันธงว่ายังไม่มี proc" เป็น **รีวิว proc จริงเทียบกับ requirement** ในรูปแบบเดียวกับหัวข้อ 1

### 2.1 โครงสร้าง Parameter และความสอดคล้องกับ List

| จุดที่ตรวจ | สิ่งที่พบ | สถานะ |
|---|---|---|
| Parameter หลัก (`@BUCode`, `@BranchCode`, `@DateFrom`, `@DateTo`) | เหมือน List proc ทุกตัว รวมถึง default value เดียวกัน (บรรทัด 6–9, 15–17, 30–31) | ✅ ตรง |
| Parameter ใหม่ `@OrderType VARCHAR(30) = 'ALL'` | รับค่าระบุว่าคลิกมาจากช่องไหนของหน้า List เช่น `ORDERLEAD2DAY`, `BACKLOG1DAY` มี whitelist ตรวจค่าที่รับ (บรรทัด 19–28) ครอบคลุมทุกช่องที่ต้อง click-through ตาม requirement | ✅ ครบ |
| ขั้นที่ 1–3 (`#ord`, `#statuslog`, `#calc`) | comment ในไฟล์ระบุเอง (บรรทัด 64–66, 135–137) ว่า "คัดลอกจาก RPT_OrderLeadtimeBacklog ห้ามแก้ให้ต่างกัน" — ตรวจเทียบทีละบรรทัดกับ List proc แล้ว **เหมือนกันทุกตัวอักษร** (WHERE, JOIN, DATEDIFF, status code list ทั้งหมด) | ✅ **ตรง 100%** — เป็นจุดออกแบบที่ดี การันตีว่าตัวเลข Detail จะไม่มีวัน "คำนวณคนละสูตร" กับ List |
| `@BranchCode` เลือกได้ทีละสาขา | เหมือน List ทุกประการ (บรรทัด 7) — ยังไม่รองรับ multi-branch เช่นเดียวกัน | ⚠️ Known limitation เดียวกับ List — PO ระบุแล้วว่าไม่ blocking (ดูหัวข้อ 1.1) |
| `@BacklogAsOf = @DateTo` | เหมือน List เป๊ะ (บรรทัด 37) comment ยืนยันเอง "ต้องเท่ากับ List เสมอ" (บรรทัด 34) | ✅ สอดคล้องกับ List แต่ยังมีคำถามเปิดเดียวกันเรื่อง concept ของ PO (ดูหัวข้อ 1.5/6) |

### 2.2 Logic การกรองตาม @OrderType เทียบกับ bucket ของ List

จุดสำคัญที่สุดของ Detail proc คือ**ต้องกรอง order ให้ตรงกับตัวเลขในแต่ละ bucket ของ List เป๊ะ** (invariant ที่ AC-12 พูดถึง) — proc นี้ออกแบบโดยคำนวณ `SectionCode`/`BucketCode`/`OntimeStatus` ไว้ในตาราง `#pick` ก่อน (บรรทัด 144–197) โดยใช้เกณฑ์ตัวเลข **เดียวกันเป๊ะ** กับ `SUM(CASE ...)` ของ List (เทียบ threshold `LateMinutes`/`BacklogAgeDays` บรรทัด 150–184 ของ Detail กับบรรทัด 211–220, 230–233 ของ List) แล้วค่อยกรองด้วย `@OrderType` จากค่าที่คำนวณไว้แล้วนั้น (บรรทัด 206–222) — เป็นวิธีที่ดีเพราะ**ไม่ได้เขียนเงื่อนไขตัวเลขซ้ำอีกชุด** จึงไม่มีช่องให้ logic สองฝั่งเพี้ยนไปจากกันโดยไม่รู้ตัว

ตรวจ mapping `@OrderType` ทีละค่าเทียบกับคอลัมน์ของ List:

| `@OrderType`                        | เงื่อนไขใน Detail (`#pick`)                                                     | คอลัมน์ที่ควรตรงกันใน List                            | ตรวจแล้ว                                        |
| ----------------------------------- | ------------------------------------------------------------------------------- | ----------------------------------------------------- | ----------------------------------------------- |
| `ORDERONTIME`                       | `SectionCode='LEADTIME' AND OntimeStatus='Ontime'` (`LateMinutes<=@SlaMinutes`) | `OntimeCount`                                         | ✅ ตรง                                           |
| `ORDERDELAY`                        | `SectionCode='LEADTIME' AND OntimeStatus='Delay'`                               | `DelayCount`                                          | ✅ ตรง                                           |
| `ORDERLEAD0DAY`…`ORDERLEADOVER3DAY` | `SectionCode='LEADTIME' AND BucketCode='DAY0'…'OVER3'`                          | `LeadDay0`…`LeadDayOver3`                             | ✅ ตรง                                           |
| `AVGORDERHR`                        | `SectionCode='LEADTIME'` (ไม่กรอง bucket)                                       | ตัวหารของ `AvgLeadtimeHr` (= Order Delivered ทั้งหมด) | ✅ ตรง — เป็นชุดเดียวกับ Order Delivered ทั้งหมด |
| `BACKLOGTOTAL`                      | `SectionCode='BACKLOG'` (ไม่กรอง bucket)                                        | `TotalBacklog`                                        | ✅ ตรง                                           |
| `BACKLOG1DAY`…`BACKLOGOVER3DAY`     | `SectionCode='BACKLOG' AND BucketCode='DAY1'…'OVER3'`                           | `BacklogDay1`…`BacklogDayOver3`                       | ✅ ตรง                                           |

**สรุป**: จากการอ่าน SQL logic เพียงอย่างเดียว (ยังไม่ได้รัน query จริง) mapping ทั้งหมดตรงกับคอลัมน์ของ List **100%** — แต่ยังต้อง verify ด้วยการรันจริงเทียบตัวเลขก่อนปิดได้สมบูรณ์ (ดูชุด query ใหม่ในหัวข้อ 4.7–4.8)

**ข้อสังเกตเพิ่มเติม (ไม่ใช่ gap)**: ไม่มีค่า `@OrderType` สำหรับคลิกที่ตัวเลข **"Order Inbound"** หรือ **"Order Delivered"** แบบดิบ (ไม่แยก bucket) โดยตรง — แต่ requirement เขียนไว้แค่ "Order Lead time > Click ได้ตามเวลา, Backlog > Click ได้ตามเวลา" จึงไม่ใช่ gap ตาม scope ที่ขอ (ค่า `AVGORDERHR` ให้ชุดข้อมูลเดียวกับ Order Delivered ทั้งหมดอยู่แล้วหากต้องการใช้)

### 2.3 Column list เทียบกับ requirement (13 คอลัมน์)

| Requirement  | คอลัมน์ output ของ PROC | Mapping                                                                                                                                      | สถานะ                                                                   |
| ------------ | ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| Store        | `Store`                 | ชื่อจาก `M_Place.BranchName` (เหมือน List)                                                                                                   | ✅ ตรง (มีคำถามเรื่อง underscore เดียวกับ List ข้อ 7)                    |
| เลขที่ใบงาน  | `JobNumber`             | **`o.OrderNumber`** (บรรทัด 261)                                                                                                             | ⚠️ ดูหัวข้อ 2.4 — สลับกับที่คาดจากชื่อคอลัมน์ SQL                       |
| เลขที่ Order | `OrderNumber`           | **`o.RefWebOrder`** (บรรทัด 262)                                                                                                             | ⚠️ ดูหัวข้อ 2.4                                                         |
| Order Date   | `OrderDate`             | `o.OrderDate` (เหมือน List ใช้ตัวเดียวกับ "Order Created Time")                                                                              | ✅ ตรง                                                                   |
| Slot Date    | `SlotDate`              | `CAST(o.StartTime AS DATE)`                                                                                                                  | ✅ ตรง                                                                   |
| Slot Time    | `SlotTime`              | `"HH:mm - HH:mm"` จาก StartTime/EndTime (บรรทัด 265–266) ตรงกับ format ในไฟล์ Excel ตัวอย่าง (`"12:00 - 12:00"`)                             | ✅ ตรง                                                                   |
| Order Status | `OrderStatus`           | `M_Status.StatusDisplayLocal` (fallback เป็น StatusCode ถ้าไม่พบ) ตรงกับ label ภาษาไทยในไฟล์ Excel ตัวอย่าง (เช่น "รายการใหม่/รอเบิกสินค้า") | ✅ ตรง                                                                   |
| Address      | `Address`               | ประกอบจาก HouseNumber/Moo/Village/Soi/Road/SubDistrict/District/Province/Zipcode ของ `D_Order` (บรรทัด 270–280)                              | ⚠️ ดูหัวข้อ 2.5 (TBC ข้อ D1 — data quality)                             |
| Sub district | `SubDistrict`           | `o.SubDistrictName`                                                                                                                          | ✅ ตรง                                                                   |
| District     | `District`              | `o.DistrictName`                                                                                                                             | ✅ ตรง                                                                   |
| Province     | `Province`              | `o.ProvinceName`                                                                                                                             | ✅ ตรง                                                                   |
| Postcode     | `Postcode`              | `o.Zipcode`                                                                                                                                  | ✅ ตรง                                                                   |
| Value        | `Value`                 | `p.OrderValue` (ยอดเดียวกับ List คือ `TotalNet`)                                                                                             | ✅ ตรง (ผูกกับคำถามเดียวกับ List ข้อ 8 เรื่อง TotalNet vs basket amount) |

**สรุป: ครบทั้ง 13 คอลัมน์ตามที่ requirement ระบุ** พร้อมคอลัมน์เสริมสำหรับ RDL (SectionOrder/Code/Name, BucketOrder/Code/Name, OntimeStatus, DuringDeliveryCode/Name) และคอลัมน์ช่วย QA ที่ไม่ต้องแสดงผล (DeliveredTime, LateMinutes, BacklogAgeDays) ซึ่งมีประโยชน์มากสำหรับ QA ตอนไล่ debug ว่าทำไม order หนึ่งตกอยู่ bucket นั้น

### 2.4 จุดที่ต้องระวัง: การตั้งชื่อฟิลด์ JobNumber / OrderNumber สลับกับชื่อคอลัมน์ SQL

พบว่า:
- คอลัมน์ผลลัพธ์ `JobNumber` (label ธุรกิจ = "เลขที่ใบงาน") ดึงมาจาก **`D_Order.OrderNumber`**
- คอลัมน์ผลลัพธ์ `OrderNumber` (label ธุรกิจ = "เลขที่ Order") ดึงมาจาก **`D_Order.RefWebOrder`**

กล่าวคือ ชื่อคอลัมน์ SQL `OrderNumber` ใน `D_Order` **ไม่ได้แปลว่า "เลขที่ Order" ตามที่ชื่อคอลัมน์บอก** แต่หมายถึง "เลขที่ใบงาน" ในทางธุรกิจ ส่วนสิ่งที่ธุรกิจเรียกว่า "เลขที่ Order" จริงๆ กลับมาจากคอลัมน์ `RefWebOrder` แทน — ตรวจสอบแล้วว่า**สอดคล้องกับข้อมูลตัวอย่างจริงในไฟล์ Excel** (`2907-2608 - Backlog`): คอลัมน์ "เลขที่ใบงาน" มีรูปแบบ `SNRJ26080012245` (ขึ้นต้นด้วยรหัสสาขา+J) ส่วนคอลัมน์ "เลขที่ Order" มีรูปแบบ `WP26080010000144` / `XB26080010000174` (ขึ้นต้นด้วยรหัส channel) ตรงกับ pattern ที่ proc ดึงมา — **ไม่ใช่บั๊ก ข้อมูลถูกต้อง**

อย่างไรก็ตาม **นี่คือจุดเสี่ยงสับสนสูงสำหรับ dev/QA รุ่นถัดไป** เพราะชื่อคอลัมน์ SQL (`D_Order.OrderNumber`) กับชื่อ business field (เลขที่ Order) เป็นคนละความหมายกัน — ถ้า ba2-tech-analyst/dev อ้างอิงชื่อคอลัมน์ SQL ตรงๆ ตอนออกแบบ API field name หรือช่อง filter/search จะทำให้ผู้ใช้งานสับสนหรือ map ผิดได้ง่าย ต้องสื่อสารให้ชัดเจนกับทีม dev/QA ว่า **"เลขที่ Order" ที่ผู้ใช้เห็นบนจอ = `RefWebOrder` ไม่ใช่ `OrderNumber`** — ดูคำถามข้อ 13 ในหัวข้อ 6 (ขอให้ dev ยืนยันว่าตั้งใจแบบนี้และคง naming นี้ต่อไปในทุกจุดที่เกี่ยวข้อง)

### 2.5 จุดที่ต้องระวัง: Address มีข้อมูลปนเปื้อน (TBC ข้อ D1 ในตัว SQL เอง)

SQL comment บรรทัด 269 เขียนไว้เองว่า: **"TBC ข้อ D1: STS บางแถวมีชื่อบริษัทอยู่ในเลขที่บ้าน แสดงว่า OMS ยัดข้อความมาใน HouseNumber - เราโชว์ตามที่เก็บ"** — proc เลือกที่จะ**แสดงข้อมูลตามที่เก็บจริงใน `D_Order.HouseNumber` โดยไม่ทำความสะอาด (clean) ข้อมูล** ตรวจสอบกับไฟล์ Excel ตัวอย่างพบเคสนี้จริง (แถว 10–11 ของ sheet `2907-2608 - Backlog`: `"เลขที่ บริษัท เซ็นทรัล ฟู้ด โฮลเซลล์ จำกัด (สาขา ศรีนครินทร์ 1) 5 กรุงเทพมหานคร 10270"` — มีชื่อบริษัทแทรกอยู่กลาง Address) — เป็น**ปัญหาคุณภาพข้อมูลต้นทาง (ฝั่ง OMS)** ไม่ใช่บั๊กของ proc นี้ แต่กระทบหน้าตารายงานที่ผู้ใช้เห็นโดยตรง ต้องยืนยันกับ PO ว่ายอมรับให้แสดงตามข้อมูลดิบแบบนี้ต่อไปหรือควรมี logic กรอง/ตัดข้อความแปลกปลอมออกในชั้น proc/RDL — ดูคำถามข้อ 12 ในหัวข้อ 6

### 2.6 อื่นๆ ที่สังเกตเห็น
- Detail proc **ไม่มีแถว Summary/ผลรวม** (comment บรรทัด 241 ยืนยันเอง "STS ไม่มีแถว Summary ในหน้า Detail") — ถ้าต้องการยอดรวมต่อ section/bucket ให้ RDL ทำ group footer เอง เป็น design decision ที่สมเหตุสมผล ไม่ใช่ gap
- การเรียงลำดับ (`ORDER BY SectionOrder, BucketOrder, StartTime, OrderNumber`, บรรทัด 243) เรียง Lead time ก่อน Backlog และเรียง bucket จากน้อยไปมาก ตรงกับ layout ของ List ที่วาง "Order Lead time" ไว้ก่อน "Backlog" — สอดคล้องกันดี
- ไฟล์ Excel ตัวอย่างที่เคยพบว่า sheet List/Summary มีหัวข้อ "Order Lead Time รายการ > 3 Days"/"> 0 Day" ว่างเปล่าไม่มีข้อมูลตัวอย่างด้านล่าง (เคยตั้งเป็นคำถามเปิดข้อ 10 เดิม) — ตอนนี้**คลี่คลายเป็นส่วนใหญ่แล้ว** เพราะ Detail proc ออกแบบให้รองรับทั้ง section "LEADTIME" และ "BACKLOG" ด้วย logic และ column set เดียวกันอยู่แล้ว (ดูหัวข้อ 2.1–2.3) เหลือเพียงไม่มีตัวอย่างข้อมูลจริงฝั่ง Lead time ให้ดูเทียบเท่านั้น ไม่ใช่ gap ทางออกแบบ — แนะนำให้ QA รัน `@OrderType='ORDERLEAD1DAY'` เป็นต้น เพื่อดูตัวอย่างจริงตอน UAT (ดูหัวข้อ 6 ข้อ 10)

---

## 3. ข้อจำกัดของการตรวจสอบรอบนี้

- **"ไม่สามารถ Recheck data กับ Sort จาก CFW ได้"** หมายถึง: รอบตรวจนี้**ไม่มีไฟล์ export จากระบบ CFW จริง** (เช่นไฟล์ `Result_...xlsx` ที่ generate จากระบบ CFW ที่ใช้เทียบแบบ cell-to-cell ในงาน RPT_UtilizationSlotDeliveryPickup ก่อนหน้า) มีเพียงไฟล์ Excel ที่ PO เตรียมขึ้นเองเป็น "ตัวอย่าง/mockup รูปแบบรายงาน" (`Example ReportOrderLeadtimeSummary...xlsx`) ซึ่งใช้ตรวจสอบ **โครงสร้างรายงานและความสอดคล้องของสูตรคำนวณ** ได้ (และได้ใช้ตรวจในหัวข้อ 1–2 แล้ว) แต่ **ใช้เป็นเกณฑ์ยืนยันว่าตัวเลขที่ PROC คำนวณตรงกับข้อมูลจริงใน DB หรือไม่ไม่ได้** เพราะไม่รู้ว่าตัวเลขในไฟล์ตัวอย่างนี้มาจาก environment/เวลาไหน สร้างด้วยวิธีใด
- **ไม่มี DB connection ในเซสชันนี้** — ไม่สามารถรัน query จริงเพื่อยืนยันตัวเลขได้ ทุก query ในหัวข้อ 4 เป็น **ร่างให้ DBA/ทีมที่มีสิทธิ์เข้าถึง DB นำไปรันต่อเท่านั้น ยังไม่ได้ execute**
- ดังนั้นแนวทางการตรวจสอบความถูกต้องของข้อมูลสำหรับงานนี้ **จึงอิง "query DB ต้นทางโดยตรงเทียบกับผลลัพธ์ของ PROC" เป็นเกณฑ์หลักเพียงทางเดียว** ไม่ใช่การเทียบไฟล์ export ของ CFW แบบงานก่อนหน้า

---

## 4. วิธีการเช็ค Data: Database SQL เทียบกับ Data ที่ PROC Generate ออกมา

> หลักการ: รัน query ที่ดึงข้อมูลตรงจากตารางต้นทาง (`D_Order`, `D_StatusLog`, `M_Place`) แบบ**ไม่ผ่าน PROC** แล้วเทียบตัวเลขกับผลลัพธ์ที่ได้จากการ `EXEC RPT_OrderLeadtimeBacklog` ด้วยพารามิเตอร์ชุดเดียวกัน (สาขา/ช่วงวันที่เดียวกัน) — ถ้าตัวเลขไม่ตรง แปลว่ามี logic ใน PROC ที่ต้องตรวจเพิ่ม
>
> **หมายเหตุ**: query ด้านล่างทั้งหมดยังไม่ได้ execute จริง (ไม่มี DB connection ในเซสชันนี้) เป็นร่างให้ DBA/QA นำไปรันเทียบผลกับ `EXEC RPT_OrderLeadtimeBacklog @BUCode='CFW', @BranchCode='<รหัสสาขาที่ทดสอบ>', @DateFrom='<วันที่>', @DateTo='<วันที่>'`

### 4.1 เช็ค Order Inbound
```sql
-- นับ Order Inbound ตรงจาก D_Order เทียบกับคอลัมน์ OrderInbound ของ PROC
SELECT COUNT(*) AS OrderInbound_FromDB
FROM D_Order o
WHERE o.IsActive = 1
  AND o.BUCode = 'CFW'
  AND o.PlaceCode_Sell = @BranchCode
  AND o.StartTime >= @DateFrom
  AND o.StartTime <  DATEADD(DAY, 1, @DateTo);
```

### 4.2 เช็ค Order Delivered + Ontime/Delay
```sql
-- ดึง order ที่มี log สถานะ 18000 (Delivered) พร้อมเวลา แล้วเทียบ SLA กับ End Time ของ slot เอง
SELECT
    o.ID, o.OrderNumber, o.EndTime AS SlotEndTime,
    dl.DeliveredTime,
    DATEDIFF(MINUTE, o.EndTime, dl.DeliveredTime) AS LateMinutes,
    CASE WHEN DATEDIFF(MINUTE, o.EndTime, dl.DeliveredTime) <= 60 THEN 'Ontime' ELSE 'Delay' END AS OntimeDelayFlag
FROM D_Order o
JOIN (
    SELECT l.OrderNumber, MAX(l.CreateDate) AS DeliveredTime
    FROM D_StatusLog l
    WHERE l.StatusCode = '18000'
    GROUP BY l.OrderNumber
) dl ON dl.OrderNumber = o.OrderNumber
WHERE o.IsActive = 1 AND o.BUCode = 'CFW' AND o.StatusCode = '18000'
  AND o.PlaceCode_Sell = @BranchCode
  AND o.StartTime >= @DateFrom AND o.StartTime < DATEADD(DAY, 1, @DateTo);
-- เทียบ COUNT(*) กับ OrderDelivered, เทียบ COUNT ของแต่ละ flag กับ OntimeCount/DelayCount ของ PROC
```

### 4.3 เช็ค Lead Time bucket (0/1/2/3/>3 Day)
```sql
-- ต่อยอดจาก query 4.2 ใส่ CASE จัด bucket แล้ว GROUP BY เทียบกับ LeadDay0..LeadDayOver3 ของ PROC
SELECT
    CASE
        WHEN LateMinutes <= 0                     THEN '0 Day'
        WHEN LateMinutes > 0    AND LateMinutes <= 1440 THEN '1 Day'
        WHEN LateMinutes > 1440 AND LateMinutes <= 2880 THEN '2 Days'
        WHEN LateMinutes > 2880 AND LateMinutes <= 4320 THEN '3 Days'
        ELSE '> 3 Days'
    END AS LeadBucket,
    COUNT(*) AS Cnt
FROM ( /* subquery เดียวกับ 4.2 */ ) x
GROUP BY CASE
        WHEN LateMinutes <= 0                     THEN '0 Day'
        WHEN LateMinutes > 0    AND LateMinutes <= 1440 THEN '1 Day'
        WHEN LateMinutes > 1440 AND LateMinutes <= 2880 THEN '2 Days'
        WHEN LateMinutes > 2880 AND LateMinutes <= 4320 THEN '3 Days'
        ELSE '> 3 Days'
    END;
```

### 4.4 เช็ค Average Order Leadtime by Hr.
```sql
SELECT
    CAST(AVG(DATEDIFF(MINUTE, o.OrderDate, dl.DeliveredTime) * 1.0 / 60) AS DECIMAL(10,2)) AS AvgLeadtimeHr_FromDB
FROM D_Order o
JOIN ( SELECT l.OrderNumber, MAX(l.CreateDate) AS DeliveredTime
       FROM D_StatusLog l WHERE l.StatusCode = '18000' GROUP BY l.OrderNumber ) dl
    ON dl.OrderNumber = o.OrderNumber
WHERE o.IsActive = 1 AND o.BUCode = 'CFW' AND o.StatusCode = '18000'
  AND o.PlaceCode_Sell = @BranchCode
  AND o.StartTime >= @DateFrom AND o.StartTime < DATEADD(DAY, 1, @DateTo);
```

### 4.5 เช็ค Total Backlog + อายุ Backlog
```sql
-- นับ Backlog ตรงจาก D_Order ด้วย logic exclude status เดียวกับที่ PROC ใช้ (บรรทัด 146-150)
SELECT
    o.OrderNumber,
    CAST(o.StartTime AS DATE) AS SlotDate,
    DATEDIFF(DAY, CAST(o.StartTime AS DATE), @BacklogAsOf) AS BacklogAgeDays
FROM D_Order o
WHERE o.IsActive = 1 AND o.BUCode = 'CFW'
  AND o.PlaceCode_Sell = @BranchCode
  AND o.StartTime >= @DateFrom AND o.StartTime < DATEADD(DAY, 1, @DateTo)
  AND o.StatusCode NOT IN ('18000','18001','13004','17002',
                            '13090','13091','19000','19001','19002','19040',
                            '19050','19051','19100','19101','19180');
-- เทียบ COUNT(*) กับ TotalBacklog, เทียบ GROUP BY BacklogAgeDays bucket กับ BacklogDay1..DayOver3
-- **สำคัญ**: ทดสอบทั้งกรณี @BacklogAsOf = @DateTo (ตามที่ PROC ใช้จริง) และกรณี @BacklogAsOf = GETDATE()
--            (ตามที่ concept ของ PO ยืนยันไว้ล่าสุด) แล้วดูว่าตัวเลขต่างกันหรือไม่ในเคสที่ @DateTo ≠ วันนี้จริง (ดูหัวข้อ 1.5/6)
```

### 4.6 เช็ค Value by Backlog / During Delivery
```sql
-- ต่อยอดจาก query 4.5 เพิ่มคอลัมน์ TotalNet และสถานะปัจจุบันของ order
SELECT
    o.OrderNumber, ISNULL(o.TotalNet, 0) AS OrderValue, o.StatusCode,
    CASE WHEN o.StatusCode IN ('15120','15180') THEN 'ATCUST'
         WHEN o.StatusCode IN ('15110','15111','15112','15113') THEN 'ONROUTE'
         ELSE NULL END AS DuringDeliveryStage
FROM D_Order o
WHERE /* เงื่อนไข backlog เดียวกับ 4.5 */ 1=1;
-- SUM(OrderValue) แยกตาม BacklogAgeDays bucket เทียบกับ BacklogValueDay1..Total
-- SUM(OrderValue) แยกตาม DuringDeliveryStage เทียบกับ DuringDeliveryValueOnRoute/AtCustomer/Total
```

### 4.7 เช็คจำนวนแถว Detail เทียบกับตัวเลข Summary (ผ่าน `@OrderType`)
```sql
-- รันคู่กันแล้วเทียบ COUNT(*) ของ Detail กับค่าคอลัมน์ของ List สำหรับสาขา/ช่วงวันที่เดียวกัน
-- ตัวอย่าง: เช็คว่า BACKLOGTOTAL ตรงกับ TotalBacklog
EXEC RPT_OrderLeadtimeBacklog          @BUCode='CFW', @BranchCode=@BranchCode, @DateFrom=@DateFrom, @DateTo=@DateTo;
EXEC RPT_OrderLeadtimeBacklogDetail    @BUCode='CFW', @BranchCode=@BranchCode, @DateFrom=@DateFrom, @DateTo=@DateTo, @OrderType='BACKLOGTOTAL';
-- นับจำนวนแถวที่ได้จาก exec ที่สอง (COUNT(*)) เทียบกับค่าคอลัมน์ TotalBacklog ของแถวสาขานั้นจาก exec แรก ต้องเท่ากันพอดี

-- ทำซ้ำแบบเดียวกันไล่ทุกค่า @OrderType เทียบกับคอลัมน์ที่เกี่ยวข้อง (ดูตาราง mapping ในหัวข้อ 2.2):
--   ORDERONTIME <-> OntimeCount, ORDERDELAY <-> DelayCount,
--   ORDERLEAD0DAY..ORDERLEADOVER3DAY <-> LeadDay0..LeadDayOver3,
--   AVGORDERHR <-> OrderDelivered (ตัวหารของ AvgLeadtimeHr),
--   BACKLOG1DAY..BACKLOGOVER3DAY <-> BacklogDay1..BacklogDayOver3
-- ถ้าตัวเลขไม่ตรงแม้แต่คู่เดียว แปลว่ามี logic ใน #pick หรือเงื่อนไข @OrderType ที่คลาดจาก List ต้องเปิด defect ทันที (ดูหัวข้อ 2.2)
```

### 4.8 เช็คมูลค่า (Value) ในหน้า Detail เทียบกับ Summary
```sql
-- เช็คว่า SUM(Value) ของแถว Detail ที่กรองด้วย @OrderType='BACKLOG1DAY' เท่ากับ BacklogValueDay1 ของ List หรือไม่
EXEC RPT_OrderLeadtimeBacklogDetail @BUCode='CFW', @BranchCode=@BranchCode, @DateFrom=@DateFrom, @DateTo=@DateTo, @OrderType='BACKLOG1DAY';
-- SUM(Value) ของผลลัพธ์ที่ได้ ต้อง = BacklogValueDay1 ของแถวสาขานั้นใน List พอดี (ทำซ้ำกับ Day2/Day3/Over3 และ During delivery ผ่าน DuringDeliveryCode)
```

---

## 5. Acceptance Criteria (ระดับ Business — Given/When/Then)

> ครอบคลุม business rule หลักตาม requirement ไม่ลงรายละเอียด edge case ทางเทคนิคทุกจุด (เช่น NULL join, duplicate key) — เขียนให้ QA ใช้ทดสอบ UAT ได้ทันที

**AC-1 กรอบเวลาและสาขาที่ค้นหา**
- Given ผู้ใช้เลือกช่วงวันที่ A–B และเลือก 1 สาขา
- When กดดูรายงาน Order Lead-Time & Backlog
- Then รายงานต้องแสดงเฉพาะ Order ที่ **Slot เริ่มต้น (Start Time)** อยู่ในช่วง A–B ของสาขานั้นเท่านั้น และ H3 ต้องแสดงช่วงวันที่ A–B ตรงกับที่เลือก

**AC-2 การเลือกหลายสาขา (Known limitation — ไม่ blocking)**
- Given ผู้ใช้ต้องการเลือกมากกว่า 1 สาขาพร้อมกัน (ไม่ใช่ทุกสาขา)
- When กดดูรายงาน
- Then **ปัจจุบัน PROC (ทั้ง List และ Detail) ยังไม่รองรับ** — [อัปเดต 2026-09-16] PO ยืนยันแล้วว่าเป็น nice-to-have ("ทำได้ก็ดีแล้ว") ไม่ใช่เงื่อนไขบังคับสำหรับรอบนี้ ให้ QA ทดสอบเฉพาะกรณี "1 สาขา" และ "ทุกสาขา" สำหรับ UAT รอบนี้ ส่วนการรองรับหลายสาขาที่ระบุเจาะจงให้บันทึกเป็น backlog ของทีม dev ไว้พิจารณาต่อ (ดูหัวข้อ 1.1/6)

**AC-3 รูปแบบชื่อสาขา (Store)**
- Given รายงานแสดงแถวของสาขาใดๆ
- When ดูคอลัมน์ Store
- Then ต้องแสดงเป็น "รหัสสาขา + ชื่อสาขา" ตามรูปแบบที่ตกลงกับ PO (ปัจจุบันดึงตรงจาก master data — ต้องยืนยันตัวคั่นให้ตรงกับที่ต้องการ ดูหัวข้อ 1.3/6)

**AC-4 Order Inbound / Delivered**
- Given มี Order ที่ Slot Date อยู่ในช่วงค้นหา N รายการ และในจำนวนนั้นมี M รายการที่สถานะเป็น "จัดส่งสำเร็จ" (18000) ภายในช่วงเดียวกัน
- When ดูรายงาน
- Then Order Inbound ต้องแสดง = N และ Order Delivered ต้องแสดง = M

**AC-5 Ontime / Delay**
- Given Order ที่ Delivered แล้ว มีเวลาส่งสำเร็จ (log 18000) เทียบกับ End Time ของ Slot
- When เวลาส่งสำเร็จ ≤ End Time + 1 ชั่วโมง
- Then Order นั้นต้องถูกนับเป็น **Ontime**; ถ้าเกิน 1 ชั่วโมง ต้องถูกนับเป็น **Delay** (เกณฑ์ 1 ชม. นี้ PO ยืนยันแล้วว่าเป็นคำตอบสุดท้าย — ปิดคำถามแล้ว)

**AC-6 Lead Time Bucket**
- Given Order ที่ Delivered แล้ว
- When คำนวณระยะเวลาจาก End Time ของ Slot ถึงเวลาส่งสำเร็จ
- Then ต้องถูกจัดเข้า bucket ที่ถูกต้องตามนิยาม (0 Day = ภายในเวลา / 1 Day = ภายใน 24 ชม. / 2 Days = ภายใน 48 ชม. / 3 Days = ภายใน 72 ชม. / >3 Days = เกินกว่านั้น) และผลรวมทั้ง 5 bucket ต้อง **เท่ากับ Order Delivered พอดี**

**AC-7 Average Order Leadtime by Hr.**
- Given Order ที่ Delivered แล้วทุกรายการในช่วงค้นหา
- When คำนวณ Lead Time เฉลี่ย
- Then ค่าที่แสดงต้อง = ผลรวม (เวลาส่งสำเร็จ − เวลาสร้าง order) ของทุก Order Delivered หารด้วยจำนวน Order Delivered แสดงผลเป็นชั่วโมง ทศนิยม 2 ตำแหน่ง

**AC-8 Total Backlog**
- Given Order ที่สถานะยังไม่ใช่ "จัดส่งสำเร็จ", "ส่งไม่สำเร็จ" หรือ "ยกเลิก"
- When ดูรายงาน
- Then Order เหล่านั้นต้องถูกนับรวมใน Total Backlog ทั้งหมด และต้องถูกจัดกลุ่มอายุ (1/2/3/>3 Day) ตามส่วนต่างระหว่าง Slot Date กับวันที่ใช้อ้างอิง (**concept ยืนยันแล้วว่าคือวันที่รันรายงานจริง แต่ implementation ปัจจุบันยังไม่ verify ว่าตรงกัน — ดูหัวข้อ 1.5/6**) โดยไม่มี bucket "0 Day" ในส่วนนี้

**AC-9 Value by Backlog**
- Given รายการ Backlog ที่ถูกจัดกลุ่มอายุแล้วตาม AC-8
- When ดูคอลัมน์ Value by backlog
- Then มูลค่ารวมของแต่ละช่วงอายุต้องรวมกันได้เท่ากับ Total Value พอดี และมูลค่าที่แสดงต้องตรงกับยอด Order (ต้องยืนยันว่าเป็น "ยอด basket" หรือ "amount สุทธิ" — ดูหัวข้อ 6)

**AC-10 Value by During Delivery**
- Given รายการ Backlog ที่สถานะปัจจุบันอยู่ระหว่างการจัดส่ง (Out for delivery / Check-in Customer)
- When ดูคอลัมน์ Value by During delivery
- Then มูลค่าต้องถูกแยกเป็น 2 กลุ่มตามสถานะปัจจุบัน (อยู่ระหว่างการจัดส่ง/บริการ = Out for delivery, ถึงบ้านลูกค้ากำลังจัดส่ง = Check-in Customer — PO ยืนยัน mapping นี้แล้ว) ไม่ทับซ้อนกัน และ Total ของสองกลุ่มนี้ต้อง **≤ Total Value ของ Backlog ทั้งหมด** (เพราะเป็น subset)

**AC-11 แถว Summary**
- Given เลือก 1 สาขา หรือทุกสาขา
- When ดูแถวสุดท้ายของรายงาน (Summary)
- Then กรณีเลือก 1 สาขา ตัวเลขในแถว Summary ต้องเท่ากับแถวของสาขานั้นทุกคอลัมน์เป๊ะ; กรณีเลือกทุกสาขา แถว Summary ต้องเท่ากับผลรวมของทุกสาขาที่แสดง

**AC-12 Detail — คลิกดูรายละเอียด**
- Given ผู้ใช้คลิกที่ตัวเลขในคอลัมน์ Order Lead time bucket ใดๆ หรือคอลัมน์ Backlog bucket ใดๆ
- When ระบบเรียก `RPT_OrderLeadtimeBacklogDetail` โดยส่งค่า `@OrderType` ตรงกับคอลัมน์ที่คลิก (เช่นคลิก "2 Days" ฝั่ง Backlog → `@OrderType='BACKLOG2DAY'`)
- Then ต้องแสดงรายการ Order ที่ตรงกับเงื่อนไข bucket ที่คลิกเท่านั้น ด้วยคอลัมน์ Store, เลขที่ใบงาน (JobNumber), เลขที่ Order (OrderNumber — มาจาก RefWebOrder ไม่ใช่ D_Order.OrderNumber, ดูหัวข้อ 2.4), Order Date, Slot Date, Slot Time, Order Status, Address, Sub district, District, Province, Postcode, Value และจำนวนแถวทั้งหมดต้อง**เท่ากับตัวเลขที่แสดงในหน้า Summary ของ bucket นั้นพอดี** — [อัปเดต 2026-09-16] proc ถูกสร้างแล้ว (`RPT_OrderLeadtimeBacklogDetail`) และจากการอ่าน logic พบว่า mapping `@OrderType` ตรงกับ bucket ของ List ทุกค่า (ดูหัวข้อ 2.2) แต่ **ยังไม่ได้ verify ด้วยการรันจริง** — ต้องรัน query เทียบในหัวข้อ 4.7 ก่อนปิด AC นี้ได้สมบูรณ์

---

## 6. ❓ คำถามที่ต้องยืนยันกับ PO / CFW / DBA

> รวมทั้งคำถามที่ SQL เขียนไว้เองในรูป comment "TBC" และคำถามที่พบเพิ่มเติมจากการรีวิวรอบนี้ (ไม่มีข้อไหนที่ BA เดาคำตอบเอง) — [อัปเดต 2026-09-16] คงเลขข้อเดิมไว้เพื่อ traceability พร้อม tag สถานะ: ✅ ปิดแล้ว / 🔶 คลี่คลายเป็นส่วนใหญ่ / ⚠️ ยังเปิดอยู่ / 🆕 คำถามใหม่

1. ⚠️ **[จาก SQL TBC ข้อ 1, บรรทัด 98–100]** สถานะ `18001` (จัดส่งสำเร็จบางส่วน) ควรนับเป็น "Order Delivered" ด้วยหรือไม่ — ปัจจุบัน PROC นับเฉพาะ `18000`
2. ✅ **[ปิดแล้ว — จาก SQL TBC ข้อ 2, บรรทัด 23]** เกณฑ์ SLA สำหรับ Ontime/Delay — PO ยืนยันแล้ว (2026-09-16): "1 ชั่วโมงถือว่า Delay" คือคำตอบสุดท้าย ตรงกับที่ PROC implement ไว้ (`@SlaHours = 1`) ไม่ต้องใช้ Service Time ต่อ order/สาขา
3. ⚠️ **[จาก SQL TBC ข้อ 9, บรรทัด 109–111]** `D_StatusLog` ไม่มีคอลัมน์ BUCode — ถ้า `OrderNumber` อาจซ้ำข้าม BU ได้จริง ต้องเพิ่มเงื่อนไข `ProviderCode` ในการ join หรือไม่ (ต้อง verify กับข้อมูลจริง)
4. ⚠️ **[จาก SQL TBC ข้อ 17, บรรทัด 145, 156]** สถานะช่วง `15180–17080` (ส่งแล้วแต่ยังไม่ปิดงาน เช่น รอ QC/รอบันทึกค่าขนส่ง) ควรจัดเป็น Backlog กลุ่มไหน และควรนับเข้า "During Delivery" (ส่วนใดของ 2 ช่อง) หรือไม่นับเลย
5. ⚠️ **[Known limitation — ไม่ blocking, อัปเดต 2026-09-16]** การเลือกสาขาได้ "มากกว่า 1 สาขา" ตามที่ requirement ระบุ — ปัจจุบัน PROC (ทั้ง List และ Detail) รองรับได้แค่ "1 สาขา" หรือ "ทุกสาขา" เท่านั้น PO ยืนยันว่าเป็น nice-to-have ("ทำได้ก็ดีแล้ว") ไม่ blocking สำหรับรอบนี้ — บันทึกไว้เป็น backlog ให้ทีม dev พิจารณาทำเพิ่มในอนาคต ไม่ต้องรอคำตอบก่อนปิดงานรอบนี้
6. 🔶 **[Concept ปิดแล้ว, implementation ยังเปิดอยู่ — อัปเดต 2026-09-16]** อายุ Backlog (Backlog Day1/2/3/>3) — PO ยืนยัน concept แล้วว่าต้องนับตาม Slot Date เทียบกับ **"วันที่ดึงข้อมูล Report" = วันที่รันรายงานจริง** (concept: "ลูกค้านัดวันไหนก็ต้องควรส่งวันนั้น") **แต่ SQL ปัจจุบันทั้ง List และ Detail proc ยัง hardcode ใช้ `@BacklogAsOf = @DateTo`** (ค่าพารามิเตอร์ที่ผู้ใช้เลือก ไม่ใช่ `GETDATE()`) ซึ่งยังไม่ถูก verify ว่าตรงกับ concept นี้เสมอไป — ต้องแจ้ง dev แก้เป็น `GETDATE()` หรือยืนยันอีกครั้งว่ากรณีใช้งานจริงจะ `@DateTo` = วันนี้เสมอ (ไม่เคยดึงรายงานย้อนหลัง) จึงจะถือว่าพฤติกรรมปัจจุบันเทียบเท่ากันในทางปฏิบัติ
7. ⚠️ **[พบใหม่จากการรีวิวนี้]** รูปแบบคอลัมน์ Store ที่ requirement เขียนว่า "รหัสสาขา (เว้นวรรค 1 วรรค) ชื่อสาขา" แต่ข้อมูลจริงใน master (`M_Place.BranchName`) ที่เห็นในไฟล์ตัวอย่างคั่นด้วย underscore (`SNR_001_ศรีนครินทร์ 1`) — ยอมรับตามข้อมูล master หรือให้ PROC ประกอบสตริงใหม่ด้วยเว้นวรรค
8. ⚠️ **[requirement เขียนเปิดไว้เอง]** Value ที่ใช้ในทุกคอลัมน์ (Value by backlog / During delivery / Detail) ควรเป็น "ยอดออเดอร์ basket" หรือ "amount" — ปัจจุบัน PROC ใช้ `D_Order.TotalNet` (ยอดสุทธิระดับ order) โดยเจตนาไม่ใช้ `C_OrderPayment.Amount` เพราะอาจนับซ้ำเมื่อ 1 order มีหลาย payment (comment บรรทัด 73–76) — ต้องยืนยันว่า `TotalNet` ถูกต้องตามที่ธุรกิจต้องการ
9. ✅ **[ปิดแล้ว — requirement เขียนเปิดไว้เอง]** "อยู่ระหว่างการจัดส่ง/บริการ" และ "ถึงบ้านลูกค้ากำลังจัดส่ง" — PO ยืนยันแล้ว (2026-09-16): "อยู่ระหว่างการจัดส่ง/บริการ" = **Out for delivery**, "ถึงบ้านลูกค้ากำลังจัดส่ง" = **Check-in Customer** ตรงกับ mapping ที่ PROC ทำไว้แล้ว (`15110-15113`→ONROUTE, `15120,15180`→ATCUST) — ความละเอียดเสริมที่ยังแนะนำ (ไม่ blocking): ยืนยัน status code เหล่านี้กับชื่อใน `M_Status` อีกชั้นตอน UAT
10. 🔶 **[คลี่คลายเป็นส่วนใหญ่ — อัปเดต 2026-09-16]** เดิมสงสัยว่า Detail ฝั่ง "Order Lead time" ต้องการ column set เดียวกับฝั่ง Backlog หรือไม่ (เพราะไฟล์ Excel ตัวอย่างไม่มีข้อมูลตัวอย่างส่วนนี้) — ตอนนี้ตอบได้แล้วจากการอ่าน Detail proc: **ใช้ column set และ logic เดียวกันทั้ง 2 section** (ดูหัวข้อ 2.1–2.3) เหลือเพียงไม่มีตัวอย่างข้อมูลจริงให้ดูเทียบเท่านั้น — แนะนำให้ QA รัน `@OrderType='ORDERLEAD1DAY'` (หรือ bucket อื่น) ดูตัวอย่างจริงตอน UAT เพื่อปิดข้อนี้ให้สมบูรณ์
11. ✅ **[ปิดแล้ว — อัปเดต 2026-09-16]** เดิมถามว่า PROC สำหรับหน้า Detail จะพัฒนาใหม่ทั้งหมดหรือไม่ — **ตอบแล้ว: proc ถูกสร้างขึ้นจริงแล้ว** (`RPT_OrderLeadtimeBacklogDetail`) รีวิวละเอียดในหัวข้อ 2 พบว่า implement ตรงตาม concept ดี มีจุดที่ต้องระวัง 2 จุดถูกยกเป็นคำถามใหม่ข้อ 12–13 ด้านล่าง
12. 🆕 **[พบใหม่จากการรีวิว Detail proc — TBC ข้อ D1 ที่ SQL เขียนไว้เอง บรรทัด 269]** คอลัมน์ Address มีบางแถวที่ข้อมูลปนเปื้อน (ชื่อบริษัทถูกยัดอยู่ในฟิลด์ `HouseNumber` จากฝั่ง OMS ต้นทาง — ยืนยันพบจริงในไฟล์ Excel ตัวอย่าง) ปัจจุบัน proc แสดงข้อมูลตามที่เก็บจริงโดยไม่ clean — ต้องยืนยันกับ PO ว่ายอมรับให้แสดงตามข้อมูลดิบต่อไป หรือควรมี logic กรอง/ตัดข้อความแปลกปลอมออกก่อนแสดงผล
13. 🆕 **[พบใหม่จากการรีวิว Detail proc]** คอลัมน์ output `JobNumber` (เลขที่ใบงาน) ดึงจาก `D_Order.OrderNumber` ส่วนคอลัมน์ `OrderNumber` (เลขที่ Order) ดึงจาก `D_Order.RefWebOrder` — ชื่อคอลัมน์ SQL กับความหมายทางธุรกิจสลับกับที่คาดไว้ (ตรวจแล้วว่าสอดคล้องกับข้อมูลตัวอย่างจริง ไม่ใช่บั๊ก) แต่เป็นจุดเสี่ยงสับสนสูงเวลาออกแบบ API/field name — ขอให้ dev ยืนยันว่าตั้งใจแบบนี้และจะคง naming convention นี้สม่ำเสมอในทุกจุดที่เกี่ยวข้อง (API, เอกสารส่งมอบ ฯลฯ) เพื่อกันความสับสนของทีมถัดไป

---

## 7. สรุปก่อนส่งต่อ

**[อัปเดต 2026-09-16]** เอกสารนี้ตรวจจาก **การอ่าน SQL text + ไฟล์ Excel ตัวอย่างเท่านั้น** ยังไม่ได้ query DB จริงเพื่อยืนยันตัวเลข (ไม่มี DB connection ในเซสชันนี้) และไม่มีไฟล์ export จาก CFW ให้เทียบแบบ cell-to-cell (ข้อจำกัดที่ผู้ใช้ระบุไว้ตั้งแต่ต้น) — สถานะปัจจุบันหลัง PO ยืนยันคำตอบรอบนี้:

- ฝั่ง **List/Summary**: implement ครบตามโครงสร้าง requirement และสอดคล้องกับไฟล์ตัวอย่าง — เหลือ **4 คำถามเปิดจริง** (#1, #3, #4, #7) และ **1 จุด concept ปิดแล้วแต่ implementation ยังไม่ verify** (#6 เรื่อง `@BacklogAsOf`) ส่วนเรื่อง multi-branch (#5) เป็น known limitation ที่ไม่ blocking แล้ว
- ฝั่ง **Detail**: **ตอนนี้มี PROC แล้ว** (`RPT_OrderLeadtimeBacklogDetail`) รีวิวพบว่า logic การกรองตาม `@OrderType` ตรงกับ bucket ของ List ทุกค่า (ยืนยันจากการอ่านโค้ด ยังไม่ได้รันจริง) column list ครบ 13 คอลัมน์ตาม requirement — เหลือ 2 คำถามใหม่ที่ต้องยืนยัน (#12 Address data quality, #13 การตั้งชื่อฟิลด์ JobNumber/OrderNumber)
- รวมคำถามที่ยังเปิดอยู่จริงทั้งเอกสาร: **9 ข้อ จากทั้งหมด 13 ข้อ** (ปิดแล้ว #2, #9, #11; คลี่คลายเป็นส่วนใหญ่ #10; ที่เหลือ #1, #3, #4, #5, #6, #7, #8, #12, #13 ยังเปิดอยู่)

**ขั้นตอนถัดไปที่แนะนำ**: รอ PO ยืนยันคำถามที่เหลือในหัวข้อ 6 (โดยเฉพาะข้อ 1, 6 ที่กระทบตัวเลขโดยตรง และข้อ 13 ที่กระทบการออกแบบ API ฝั่ง ba2-tech-analyst) ก่อนส่งต่อให้ **ba2-tech-analyst** แตกเป็น Frontend/API requirement และ Acceptance Criteria เชิงเทคนิคต่อไป — ข้อมูลครบตามนี้หรือไม่ ต้องการแก้ไขจุดไหนก่อนส่งต่อ BA เทคนิคไหมครับ/คะ?
