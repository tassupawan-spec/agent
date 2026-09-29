# Task Breakdown: TMS SPRINT – Setup Config Time Slot (VIP) หน้า "แก้ไขข้อมูล Pool"

อ้างอิงจาก `TMS_PoolTimeSlotVIP_Requirement.md` — ใช้ Role split เป็น **SA / Dev API / Dev Front / QA** (ปรับตามทีมจริงได้หากมี Role ต่างจากนี้ เช่น มี DBA แยก)

สถานะ Ticket ทุกช่องยังไม่มีการเปิดจริง จึงระบุเป็น `ยังไม่เปิด` ทั้งหมด — ทีมสามารถแทนที่ด้วยเลข Ticket จริงเมื่อเปิดงานแล้ว

## 0. Master Tracking Table

| #   | API / Component                                                                                                            | SA         | Dev API    | Dev Front  | QA         |
| --- | -------------------------------------------------------------------------------------------------------------------------- | ---------- | ---------- | ---------- | ---------- |
| 1   | **GET /pools/{id}** (ดึงข้อมูล Pool + สรุป) — § 6.1                                                                        | ยังไม่เปิด | ยังไม่เปิด | N/A        | ยังไม่เปิด |
| 2   | **GET /pools/{id}/time-slots** (รายการรอบเวลาจัดส่ง + pagination) — § 6.1                                                  | ยังไม่เปิด | ยังไม่เปิด | N/A        | ยังไม่เปิด |
| 3   | **Master data lookups** (delivery-channels, sales-channels, slot-types, truck-turns) — § 6.1                               | ยังไม่เปิด | ยังไม่เปิด | N/A        | ยังไม่เปิด |
| 4   | **POST /pools/{id}/time-slots** (เพิ่มรอบเวลาจัดส่ง) — § 6.2                                                               | ยังไม่เปิด | ยังไม่เปิด | N/A        | ยังไม่เปิด |
| 5   | **GET/PUT /pools/{id}/time-slots/{slotId}** (แก้ไขรอบเวลาจัดส่ง) — § 6.3                                                   | ยังไม่เปิด | ยังไม่เปิด | N/A        | ยังไม่เปิด |
| 6   | **PATCH /pools/{id}/time-slots/{slotId}/status** (Toggle สถานะรายรอบ) — § 6.4                                              | ยังไม่เปิด | ยังไม่เปิด | N/A        | ยังไม่เปิด |
| 7   | **DELETE /pools/{id}/time-slots/{slotId}** (ลบรอบเวลาจัดส่ง) — § 6.5                                                       | ยังไม่เปิด | ยังไม่เปิด | N/A        | ยังไม่เปิด |
| 8   | **PUT /pools/{id}** (บันทึกข้อมูล Pool หลัก) — § 6.6                                                                       | ยังไม่เปิด | ยังไม่เปิด | N/A        | ยังไม่เปิด |
| 9   | **UI: ฟอร์มข้อมูล Pool + แผงสรุป** (สถานะ, รหัส, ชื่อ TH/EN, Capacity รวม, ช่องทางการขาย, รอบจัดส่ง, รอบ VIP) — § 3, § 6.1 | N/A        | N/A        | ยังไม่เปิด | ยังไม่เปิด |
| 10  | **UI: ตารางรอบเวลาจัดส่ง** (แสดงผล, Toggle, ไอคอนแก้ไข/ลบ, Pagination) — § 3                                               | N/A        | N/A        | ยังไม่เปิด | ยังไม่เปิด |
| 11  | **UI: Modal เพิ่ม/แก้ไขรอบเวลาจัดส่ง** (ต้องยืนยันดีไซน์ก่อน — § 7 Open Items)                                             | N/A        | N/A        | ยังไม่เปิด | ยังไม่เปิด |
| 12  | **UI: Modal ยืนยันการลบ**                                                                                                  | N/A        | N/A        | ยังไม่เปิด | ยังไม่เปิด |
| 13  | **Validation: Truck Turn ซ้ำ/เวลาทับซ้อน, ผลรวม Capacity** — § 5 (Business Rule 5, 7)                                      | ยังไม่เปิด | ยังไม่เปิด | ยังไม่เปิด | ยังไม่เปิด |

## 1. SA (System Analyst)

| # | Task No. | Task | Requirement ref | Detail |
|---|---|---|---|---|
| SA-1 | ยังไม่เปิด | ยืนยัน scope กับ Business/UX ว่าหน้านี้เป็นของใหม่หรือปรับปรุงจากหน้าจอเดิม | § 1 Scope note | ผลกระทบต่อจำนวนงาน (API ใหม่ทั้งหมด vs. ปรับของเดิม) |
| SA-2 | ยังไม่เปิด | ขอ/ยืนยันดีไซน์ Modal เพิ่ม/แก้ไขรอบเวลาจัดส่ง และ Modal ยืนยันการลบ | § 7 Open Items | บล็อกงาน Dev Front ของ Modal (#11, #12) |
| SA-3 | ยังไม่เปิด | ออกแบบ Data Model ตาราง Time Slot (คอลัมน์ตามหัวข้อตาราง § 3) และความสัมพันธ์กับ Pool | § 3, § 6.1–6.6 | รองรับ Slot Type Normal/VIP, Truck Turn, Cut Off Time |
| SA-4 | ยังไม่เปิด | ยืนยัน Business Rule: เงื่อนไขปิดสถานะ Pool เมื่อมีรอบเปิดอยู่, การแจ้งเตือน unsaved changes | § 5 (ข้อ 3, 10), § 7 | |
| SA-5 | ยังไม่เปิด | ยืนยันว่า Toggle สถานะรายรอบเป็น inline-save หรือรวมกับปุ่ม บันทึก | § 6.4 | มีผลต่อ scope ของ API #6 |
| SA-6 | ยังไม่เปิด | ยืนยัน Permission/สิทธิ์การแก้ไขของแต่ละ Role ต่อหน้านี้ | § 7 Open Items | เชื่อมกับเมนู "ข้อมูลกำหนดสิทธิ์ Pool และโซนจัดส่ง" |
| SA-7 | ยังไม่เปิด | สรุป API Spec ฉบับสมบูรณ์ (Endpoint, Request/Response, Error case) ให้ Dev API | § 6.1–6.6 | ส่งต่อให้ Dev API ก่อนเริ่มพัฒนา |

## 2. Dev API (Backend)

| # | Task No. | Task | Requirement ref | Detail |
|---|---|---|---|---|
| API-1 | ยังไม่เปิด | ตรวจสอบ Backend ปัจจุบันว่า GET Pool detail มีอยู่แล้วหรือไม่ ก่อนสร้างใหม่ | § 6.1 | ลด scope ถ้ามีอยู่แล้ว |
| API-2 | ยังไม่เปิด | พัฒนา `GET /pools/{id}` (Pool detail + สรุป 4 ค่า) | § 6.1 | ต้องคำนวณ `activeSlotCount`, `vipSlotCount`, `activeSalesChannelCount` |
| API-3 | ยังไม่เปิด | พัฒนา `GET /pools/{id}/time-slots` พร้อม pagination (5/10/20/50) | § 6.1 | |
| API-4 | ยังไม่เปิด | พัฒนา Master data lookups (delivery-channels, sales-channels, slot-types, truck-turns) | § 6.1 | อาจ reuse ของหน้าจออื่นถ้ามีอยู่แล้ว |
| API-5 | ยังไม่เปิด | พัฒนา `POST /pools/{id}/time-slots` พร้อม validation (Truck Turn ซ้ำ/เวลาทับซ้อน, Capacity รวม) | § 6.2, § 5 (ข้อ 5, 7) | |
| API-6 | ยังไม่เปิด | พัฒนา `GET` + `PUT /pools/{id}/time-slots/{slotId}` | § 6.3 | ใช้ validation ชุดเดียวกับ API-5 |
| API-7 | ยังไม่เปิด | พัฒนา `PATCH /pools/{id}/time-slots/{slotId}/status` (รอผล SA-5 ก่อนว่าต้องมีหรือรวมกับ PUT Pool) | § 6.4 | |
| API-8 | ยังไม่เปิด | พัฒนา `DELETE /pools/{id}/time-slots/{slotId}` | § 6.5 | |
| API-9 | ยังไม่เปิด | พัฒนา `PUT /pools/{id}` (บันทึกข้อมูล Pool หลัก) | § 6.6 | |
| API-10 | ยังไม่เปิด | Unit test ครอบคลุม validation ทุกกรณี (Truck Turn ซ้ำ, เวลาทับซ้อน, Capacity เกิน, ฟิลด์บังคับ) | § 5, § 13 (Master table) | |

## 3. Dev Front (Frontend)

| # | Task No. | Task | Requirement ref | Detail |
|---|---|---|---|---|
| FE-1 | ยังไม่เปิด | พัฒนา UI ฟอร์มข้อมูล Pool + Toggle สถานะการใช้งาน + แผงสรุป 4 การ์ด | § 3, § 6.1 | bind กับ `GET /pools/{id}` |
| FE-2 | ยังไม่เปิด | พัฒนา UI ตารางรอบเวลาจัดส่ง (11 คอลัมน์) + Pagination + Dropdown จำนวนแถวต่อหน้า | § 3, § 6.1 | bind กับ `GET /pools/{id}/time-slots` |
| FE-3 | ยังไม่เปิด | พัฒนา Modal เพิ่ม/แก้ไขรอบเวลาจัดส่ง (รอผล SA-2 เรื่องดีไซน์) | § 6.2, § 6.3, § 7 | bind กับ POST/PUT slot API |
| FE-4 | ยังไม่เปิด | พัฒนา Modal ยืนยันการลบ | § 6.5, § 7 | bind กับ DELETE slot API |
| FE-5 | ยังไม่เปิด | พัฒนา Toggle สถานะรายรอบในตาราง (inline หรือรวมกับปุ่มบันทึก ตามผล SA-5) | § 6.4 | |
| FE-6 | ยังไม่เปิด | Client-side validation ฟิลด์บังคับ + แสดง error message ตาม UX Copy | § 5 | ประสาน UX สำหรับข้อความ error |
| FE-7 | ยังไม่เปิด | ปุ่ม "บันทึก" / "ย้อนกลับ" + แจ้งเตือน unsaved changes (รอผล SA-4) | § 5 (ข้อ 10), § 6.6 | |

## 4. QA

| # | Task No. | Task | Requirement ref | Detail |
|---|---|---|---|---|
| QA-1 | ยังไม่เปิด | Test plan + test case ครอบคลุม CRUD รอบเวลาจัดส่ง (เพิ่ม/แก้ไข/ลบ/toggle) | § 4.1, § 6.2–6.5 | |
| QA-2 | ยังไม่เปิด | Test validation: Truck Turn ซ้ำ, เวลาทับซ้อน, Capacity เกิน, ฟิลด์บังคับ | § 5 (ข้อ 5, 7) | บล็อกจาก API-10 ผ่านก่อน |
| QA-3 | ยังไม่เปิด | Test การคำนวณค่าแผงสรุป (Capacity รวม, ช่องทางการขาย x/4, รอบจัดส่ง, รอบ VIP) | § 6.1 | |
| QA-4 | ยังไม่เปิด | Test Pagination และ Dropdown จำนวนแถวต่อหน้า (5/10/20/50) | § 6.1 | |
| QA-5 | ยังไม่เปิด | Test สิทธิ์การเข้าถึง/แก้ไขตาม Role | § 7 Open Items | รอผล SA-6 |
| QA-6 | ยังไม่เปิด | SIT: ทดสอบ integration ระหว่างหน้านี้กับระบบจัดเส้นทาง/รับออเดอร์ที่อ้างอิง Time Slot | § 1 | |
| QA-7 | ยังไม่เปิด | UAT ร่วมกับผู้ใช้งานจริง (CFW/Admin) | ทั้งหมด | ทำหลัง SIT ผ่านเท่านั้น |
| QA-8 | ยังไม่เปิด | เตรียมข้อมูล/config เริ่มต้น (master data: sales-channels, delivery-channels, slot-types) ก่อนขึ้นระบบจริง | § 6.1 | Production data setup |

## Suggested Sequence

1. **SA-1, SA-2, SA-3** ต้องเสร็จก่อนเริ่มงานอื่นทั้งหมด (ยืนยัน scope, ดีไซน์ Modal, Data Model)
2. **SA-4, SA-5, SA-6** ทำคู่ขนานกับ SA-3 ได้ (เป็นการยืนยัน Business Rule คนละเรื่อง) แต่ต้องเสร็จก่อน API-7, FE-5, FE-7, QA-5 ตามลำดับ
3. เมื่อ SA-3 + SA-7 เสร็จ → **API-1 ถึง API-9** เริ่มพัฒนาได้ โดย API-2, API-3, API-4 (GET/Lookup) ทำคู่ขนานกันได้ก่อน, ตามด้วย API-5/API-6 (Create/Update ต้องใช้ validation ร่วมกัน ทำพร้อมกันได้), API-7 รอผล SA-5, API-8, API-9 ทำคู่ขนานได้
4. **FE-1, FE-2** เริ่มคู่ขนานกับ Dev API ได้ทันทีที่มี API Spec (SA-7) โดยใช้ mock data ระหว่างรอ API จริง
5. **FE-3, FE-4** ต้องรอผล SA-2 (ดีไซน์ Modal) ก่อนเริ่ม
6. **FE-5** รอผล SA-5, **FE-7** รอผล SA-4
7. **QA-1 ถึง QA-5** เริ่มเขียน test case คู่ขนานได้ทันทีที่ Requirement นิ่ง แต่ **รัน QA ได้จริง** ต้องรอ Dev ของ component นั้น ๆ เสร็จก่อน (เช่น QA-2 รอ API-10 ผ่าน)
8. **QA-6 (SIT)** เริ่มได้เมื่อทุก component ผ่าน unit/component test ของตัวเองแล้ว (ไม่ใช่รอทุกงานเสร็จพร้อมกัน)
9. **QA-7 (UAT)** เริ่มได้เมื่อ SIT ผ่านเท่านั้น ห้ามข้ามไป UAT ก่อน
10. **QA-8** ทำก่อน go-live เท่านั้น (ไม่ block งาน dev)

## Dependencies

- Data Model (SA-3) ต้อง finalize ก่อน API ใด ๆ ที่แตะตาราง Time Slot (API-2, 3, 5, 6, 7, 8) จะเริ่มพัฒนาได้จริง
- ดีไซน์ Modal (SA-2) ต้องเสร็จก่อน FE-3, FE-4 เริ่ม — ไม่เช่นนั้นต้องทำซ้ำหากดีไซน์เปลี่ยนภายหลัง
- Contract ของ API (SA-7 / API spec) ต้องนิ่งก่อน Dev Front จะ integrate จริง (ใช้ mock คู่ขนานได้ระหว่างรอ)
- QA-2 (validation) ขึ้นกับ API-10 (unit test validation) ผ่านก่อน ไม่ใช่ขึ้นกับ "Dev เสร็จทั้งหมด"
- SIT (QA-6) ขึ้นกับผลการทดสอบ component ทดสอบผ่านทีละส่วน ไม่ใช่รอทุกงานเสร็จพร้อมกันทีเดียว
- UAT (QA-7) ขึ้นกับ SIT ผ่านเท่านั้น
