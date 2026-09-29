## Technical Condition Review: RPT_UtilizationSlotDeliveryPickup PROC

> ขอบเขต: ตรวจ **condition ทางเทคนิค** ในตัว `PROC_RPT_UtilizationSlotDeliveryPickup.sql` (บรรทัด 1–499) เท่านั้น — ทุก WHERE / JOIN / CASE / EXISTS / date boundary
> อ้างอิงประกอบ: เอกสารของ ba1 `RPT_UtilizationSlotDeliveryPickup_DataConsistency_Checklist.md` โดยเฉพาะข้อ 3.7, 3.9, 3.12–3.15, 3.18, 3.20–3.21
> **ไม่ได้รัน SQL จริง** (ไม่มี DB connection) — วิเคราะห์จาก syntax/logic ของ SQL text ล้วนๆ ทุกข้อผ่านการอ่านโค้ดจริง ไม่มีข้อใดเดา ถ้าไม่มั่นใจย้ายไปหมวด 7 เป็นคำถามแทน

---

### 1. สรุปภาพรวม

- ตรวจ condition ทั้งหมด **15 จุด** ในหมวด 2 (ครอบคลุมทุก temp table, ทุก JOIN/EXISTS, ทุก CASE ที่กำหนดคอลัมน์, และ FULL OUTER JOIN หลัก)
- พบ **High 6 จุด, Medium 3 จุด, Low 3 จุด, ยืนยัน/ปิดประเด็นของ ba1 (Confirmed) 3 จุด**
- ประเด็นใหม่ที่สำคัญที่สุด (ยังไม่เคยถูกพูดถึงในเอกสาร ba1): **ไม่มี NULL-safe join บน `DeliveryOptionCode`** ใน FULL OUTER JOIN หลัก (บรรทัด 466–474), **ไม่มีการ guard ความไม่ซ้ำของ key** ที่ใช้ JOIN ทั้งฝั่ง `M_ChannelOfSell.ChannelCode` (บรรทัด 245–256, 306) และฝั่ง `M_Place.MechandiseCode` (บรรทัด 475) และ **template ที่ ChannelCode ไม่ตรงกับ #channel เลย (ไม่ใช่ NULL) จะหายไปจากทุกคอลัมน์ราย channel แบบเงียบๆ** (บรรทัด 306) ซึ่งขัดกับ invariant "ผลบวก 4 channel = Total" ที่ ba1 ใช้ยืนยันความถูกต้อง
- ข้อของ ba1 ที่ตรวจแล้ว **ยืนยันตรงกับผลอ่าน SQL 100%**: 3.13 (ไม่มี join สถานะงาน), 3.14 (IsCreateJob ไม่ถูกกรอง), และครึ่งฝั่ง code ของ 3.7 (ไม่มี condition ใดกัน SD/VIP ออกจาก Pickup โดยเฉพาะ)
- ข้อของ ba1 ที่ควร **ปรับระดับความเสี่ยงขึ้น** จากผลตรวจนี้: 3.15 (SHARED) — เดิมให้ Low เพราะเช็คเฉพาะกรณี `ChannelCode IS NULL` แต่กรณี `ChannelCode` ที่ไม่ NULL แต่ไม่ match กับ #channel เลย (channel ปิดใช้งาน/ลบ/พิมพ์โค้ดผิด) เป็นอีกเคสที่ SQL ไม่มี condition ป้องกันเลย และไม่มีคอลัมน์ fallback มารองรับเหมือนฝั่ง Usage — ดูข้อ 2.7 และหมวด 4

---

### 2. Condition-by-Condition Review

| #    | ตำแหน่ง (บรรทัด SQL)                          | Condition ที่ตรวจ                                                                                                          | สิ่งที่พบ / ความเห็นเชิงเทคนิค                                                                                                                                                                                                                                                                                                                                                                                      | เชื่อมกับข้อของ ba1                | ความเสี่ยง |
| ---- | ---------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------- | ---------- |
| 2.1  | 174–180                                        | `@BranchName` = `MAX(...)` WHERE `pl.PlaceCode = @BranchCode OR pl.MechandiseCode = @BranchCode`                              | เงื่อนไข OR ข้าม 2 natural key คนละ domain (PlaceCode กับ MechandiseCode) โดยไม่ disambiguate — ถ้าค่าใน 2 domain นี้ชนกัน (เช่น PlaceCode ของสาขา A บังเอิญเท่ากับ MechandiseCode ของสาขา B) จะได้ `MAX()` ของชื่อสาขาที่อาจไม่ใช่สาขาที่ผู้ใช้ตั้งใจกรอง H2 จะผิดแบบเงียบๆ ไม่ error                                                                                                                              | —                                    | Medium     |
| 2.2  | 217, 225                                       | `#store` WHERE เดียวกัน: `(@BranchCode IS NULL OR pl.PlaceCode = @BranchCode OR pl.MechandiseCode = @BranchCode)`             | ปัญหาเดียวกับ 2.1 แต่กระทบ **ข้อมูลจริงของรายงาน** ไม่ใช่แค่ header — ถ้าเกิด collision จะดึงสาขาที่ไม่ตั้งใจเข้ามาทั้งแถว (ไม่ใช่แค่ผิดชื่อ)                                                                                                                                                                                                                                                                       | —                                    | Medium     |
| 2.3  | 197–202                                        | `#dates` สร้างจาก `TOP (DATEDIFF(...)+1)` บน `sys.all_objects` (ไม่มี WHERE, ไม่มีการเช็คว่าพอ)                              | ไม่มี guard ว่า `sys.all_objects` มีแถวพอสำหรับช่วงวันที่ที่ยาวมาก (หลายปี) — ถ้าจำนวนวันที่ขอเกินจำนวนแถวใน catalog view ของ DB นั้น (เกิดได้ถ้า DB ใหม่/ถูก restore มา metadata น้อย) `TOP` จะคืนแถวน้อยกว่าที่ขอ **แบบเงียบๆ ไม่ error** ทำให้ #dates ขาดบางวันไปโดยไม่มีใครรู้                                                                                                                                | —                                    | Low        |
| 2.4  | 218–220, 223                                   | `#store` ใช้ **INNER JOIN** `M_Pool po ON po.Id = pl.MPoolId AND po.IsActive = 1`                                             | สาขา (`M_Place`) ที่ `MPoolId IS NULL` (ยังไม่ถูก assign pool) หรือ pool ของสาขานั้นถูกปิดใช้งาน (`po.IsActive=0`) จะ**หายไปจาก `#store` ทั้งแถวทันที** และหายต่อเนื่องจากทุก temp table ที่ตามมา (#tmpl ผ่าน EXISTS, #booking ผ่าน EXISTS, #setup) — รายงานจะไม่มีแถวของสาขานั้นเลยแม้จะมี booking จริงอยู่ใน `D_BookingLog` และไม่มี flag/warning ใดบอกว่า "สาขานี้ถูกตัดออกเพราะไม่มี pool"                     | เกี่ยวเนื่อง 3.12 (ba1)              | **High**   |
| 2.5  | 229–238                                        | `StoreCountInPool` UPDATE ผ่าน CROSS APPLY: `COUNT(*) FROM M_Place p2 WHERE p2.MPoolId = s.MPoolId AND p2.IsActive=1 AND p2.MechandiseCode IS NOT NULL` | Subquery นี้**ไม่มี** `p2.ProviderCode = @ProviderCode` เทียบกับที่ `#store` เองกรอง ProviderCode ทุกจุด — ถ้า `MPoolId` (ค่า Id ของ `M_Pool`) ไม่ได้ scope เฉพาะ provider เดียว (เช่นเป็น global surrogate key ที่ provider อื่นมี pool คนละอันแต่ Id เผอิญชนกันไม่ได้เพราะเป็น PK, แต่ถ้า design จริงคือ M_Place ของ 2 providers ชี้ MPoolId เดียวกันได้) ตัวเลขนี้จะรวมสาขาข้าม provider เข้ามาด้วย — ต้องยืนยัน schema (ดูหมวด 7) | ท้าทาย 3.12 (ba1)                    | **High**   |
| 2.6  | 245–256                                        | `#channel`: `SELECT DISTINCT ChannelCode, ShortName FROM M_ChannelOfSell WHERE ProviderCode=@ProviderCode AND IsActive=1 AND ShortName IS NOT NULL` | `DISTINCT` ทำงานบนคู่ `(ChannelCode, ShortName)` ไม่ใช่บน `ChannelCode` เดี่ยวๆ — ถ้า `ChannelCode` เดียวกันมีมากกว่า 1 `ShortName` (data เก่า/ถูกเปลี่ยนชื่อ) `#channel` จะมี **2 แถวของ ChannelCode เดียวกัน** ไม่มี unique constraint ใดกันไว้ในตัว SQL นี้เลย                                                                                                                                                     | —                                    | **High**   |
| 2.7  | 306 (JOIN), 308 (GROUP BY)                     | `#tmpl t JOIN #channel c ON c.ChannelCode = t.ChannelCode` (5.2 คอลัมน์ราย channel)                                          | ผลจากข้อ 2.6: ถ้า `#channel` มี 2 แถวของ `ChannelCode` เดียวกัน (ShortName ต่างกัน) การ JOIN ตรงนี้จะ **fan-out** — Capacity ของ template ใบเดียวถูกนับซ้ำเข้า 2 คอลัมน์ (หรือ SUM ซ้ำ) โดยไม่มี error ใดๆ และตัว GROUP BY ปลายทาง (บรรทัด 476–478 ใช้ `SUM(ISNULL(k.SetupQty,0))`) จะ**ดูดกลืนผลคูณซ้ำนี้เข้าไปในตัวเลขสุดท้ายเงียบๆ** ทำให้ SetupQty ของ channel นั้นสูงเกินจริงโดยไม่มีสัญญาณเตือน — เป็น JOIN ที่ทำให้ข้อมูลซ้ำตามที่ scope งานนี้ขอให้หา | ต่อเนื่องจาก 2.6                     | **High**   |
| 2.8  | 306–308 (มุมกลับ)                              | เทมเพลตที่ `ChannelCode` **ไม่ใช่ NULL แต่ไม่ match** กับแถวใดใน `#channel` เลย (channel ปิดใช้งาน/ลบ/พิมพ์โค้ดผิด/ProviderCode ไม่ตรง) | ผล INNER JOIN คือ template แถวนั้น**หายไปจากทุกคอลัมน์ราย channel (5.2) แบบเงียบๆ** — แต่ Capacity ของมันยังถูกนับรวมใน TOTAL อยู่ (5.1 บรรทัด 288–298 ไม่ join #channel เลย) ผลคือ **ผลบวกคอลัมน์ที่เห็น (SD+WA+XB+XC+SHARED+VIP) < Total** ซึ่งขัดกับ invariant ที่ ba1 ใช้ยืนยันความถูกต้องใน 261 แถวที่ตรวจ (ข้อมูลจริง ณ วันที่ตรวจไม่มีเคสนี้ แต่ SQL ไม่มี condition ป้องกันไปข้างหน้าเลย) — เทียบกับฝั่ง Usage ที่**มี** fallback bucket (ColumnSeq 950, บรรทัด 458–463) รองรับ SaleSource ที่ไม่ match #channel แต่ฝั่ง **Setup ไม่มี fallback แบบเดียวกัน** | ท้าทาย 3.15 (ba1)                    | **High**   |
| 2.9  | 310–320 (SHARED, 5.3)                          | คอมเมนต์บรรทัด 312–314 อ้างว่ามี "dedupe (StartTime, EndTime, SlotType) ที่เลือก ChannelCode ไม่ NULL ก่อน" ทำที่ฝั่ง booking engine | ตัว PROC **ไม่มี logic dedupe ใดๆ** รองรับ/ตรวจสอบ assumption นี้เลย — ถ้าข้อมูลจริงมีทั้งแถว `ChannelCode IS NULL` (SHARED) และแถว channel เจาะจงพร้อมกันในสล็อตเดียวกัน (เวลา+ประเภทเดียวกัน) `#setup_col` (5.1) จะ SUM Capacity ของทั้งสองเข้า TOTAL รวมกัน ซึ่งอาจไม่ตรงกับ capacity ที่ engine ให้จองได้จริง (ยังไม่รู้ว่า engine มองเป็น capacity แยกกันหรือ capacity เดียวกันที่มีได้หลายทางเข้าถึง)                     | ท้าทาย 3.15 (ba1)                    | Medium     |
| 2.10 | 337–368 (#booking), 466–474 (FULL OUTER JOIN)  | `us.DeliveryOptionCode = su.DeliveryOptionCode` เป็นหนึ่งใน key ของ FULL OUTER JOIN                                          | **`DeliveryOptionCode` เป็นคอลัมน์เดียวใน key ทั้งหมดของ FULL OUTER JOIN ที่ไม่ถูกบังคับ NOT NULL ที่ไหนเลย** ทั้งใน `#tmpl` (WHERE บรรทัด 276–280 ไม่เช็ค DeliveryOptionCode NULL) และ `#booking` (WHERE บรรทัด 351–358 เช่นกัน) — และ parameter filter (`@DeliveryOptionCode IS NULL OR ... = @DeliveryOptionCode`, บรรทัด 279, 357) **อนุญาตให้ NULL ผ่านได้ทั้งสองฝั่ง** เมื่อเรียกแบบ "ALL" — ตาม SQL semantics มาตรฐาน `NULL = NULL` ประเมินเป็น UNKNOWN (ไม่ match) ดังนั้นถ้า template หนึ่งกับ booking หนึ่งมี `DeliveryOptionCode IS NULL` ตรงกันจริง (เป็นไปได้ถ้า master data ไม่บังคับ NOT NULL) แถวทั้งสองจะ **ไม่ถูก merge เป็นแถวเดียวโดย FULL OUTER JOIN** แต่จะแยกเป็น 2 แถว (Setup-only กับ Usage-only) — ฝั่ง Usage-only จะโชว์ `IsMissingSetup=1` ทั้งที่จริงมี Setup รออยู่ (แค่ join ไม่ติด) | ใหม่ — ไม่มีใน checklist ba1         | **High**   |
| 2.11 | 475                                             | Final SELECT: `JOIN #store st ON st.StoreMerchandiseCode = k.StoreMerchandiseCode`                                            | Join ปลายทางใช้ **natural/business key** (`MechandiseCode`) ไม่ใช่ surrogate key (`MPlaceId` ที่ `#store` มีอยู่แล้วตั้งแต่บรรทัด 209) — ถ้า `M_Place` มีมากกว่า 1 แถว active ที่ `MechandiseCode` ซ้ำกัน (data quality issue ที่ SQL นี้ไม่ตรวจ/ไม่ dedupe ที่ไหนเลย) ทุก measure ของสาขานั้น (`SetupQty`, `UsageQty`) จะถูก **fan-out คูณตามจำนวนแถวซ้ำ** เพราะ JOIN นี้อยู่ *หลัง* การ SUM ของ derived table `k` แล้วยัง JOIN ต่อกับ #store ที่อาจมีมากกว่า 1 แถว — เป็นไปได้ว่าเป็นสาเหตุทางเลือกของ 3.3 (จำนวนแถวต่างกัน 20 แถว) นอกเหนือจากสมมติฐาน template count ที่ ba1 ตั้งไว้ | ท้าทาย 3.3, 3.12 (ba1)                | **High**   |
| 2.12 | 128–147 (โดยเฉพาะ 144)                         | `@ProviderCode` ถ้า NULL/ว่าง จะถูก set เป็น `'CFW'` เสมอ (`IF @ProviderCode IS NULL SET @ProviderCode = 'CFW'`)             | ต่างจาก `@BUCode`/`@BranchCode`/`@DeliveryOptionCode` ที่ NULL แปลว่า "ทุกค่า" — `@ProviderCode` **ไม่มีโหมด "ทุก provider"** เลย เพราะถูก default บังคับเป็น CFW เสมอ ถ้าในอนาคตมีความต้องการรายงานข้าม provider จะต้องแก้ signature ของ proc — ไม่ใช่บั๊ก แต่เป็น design constraint ที่ไม่ได้ระบุเป็น business rule ไว้ชัดเจนที่ไหน                                                                                    | —                                    | Low        |
| 2.13 | 351–358                                         | `#booking` WHERE — เทียบกับ 3.13 ของ ba1 ("ไม่กรองสถานะงานขนส่ง")                                                             | ตรวจ WHERE ทั้งหมด (บรรทัด 351–358) มีแค่ `ProviderCode`, `IsActive=1`, ช่วงวันที่ (`StartDate`), `DeliveryOptionCode`, และ `EXISTS` กับ `#store` — **ยืนยันตรงกับ ba1 100%**: ไม่มี JOIN หรือ subquery ใดเชื่อมไปยังตาราง job/shipment/status เลยสักจุด                                                                                                                                                              | ยืนยัน 3.13 (ba1)                    | Confirmed  |
| 2.14 | 353–354                                         | `AND bl.IsCreateJob = 1` ถูก comment ปิดไว้ — เทียบกับ 3.14 ของ ba1                                                            | ยืนยันตรงกับ ba1: บรรทัดถูก comment ปิดจริง เป็น toggle เดียว ไม่มี logic อื่นแอบกรอง `IsCreateJob` ซ่อนอยู่ที่จุดอื่นของ proc (ตรวจทั้งไฟล์แล้วไม่มี reference คำว่า `IsCreateJob` ที่อื่นอีก)                                                                                                                                                                                                                       | ยืนยัน 3.14 (ba1)                    | Confirmed  |
| 2.15 | 182–186, 279, 357                               | เทียบกับ 3.7 ของ ba1 ("Delivery vs Pickup แยกคอลัมน์ยังไง — มี WHERE/JOIN ไหนกรอง SD/VIP ออกจาก Pickup จริงหรือไม่")           | ตรวจทั้งไฟล์แล้ว: **จุดเดียว** ที่ proc แยก Delivery/Pickup คือ filter `@DeliveryOptionCode` ที่ #tmpl (บรรทัด 279) และ #booking (บรรทัด 357) ซึ่งเป็น filter เดียวกันไม่สนใจ ChannelCode/SlotType เลย — **ไม่มี condition ใดในโค้ด SQL นี้ที่กัน SD channel หรือ VIP SlotType ออกจากฝั่ง PIC โดยเฉพาะ** สรุปเชิงเทคนิคได้ว่า สาเหตุที่ CFW Pickup export ไม่มีคอลัมน์ SD/VIP ต้องเป็นเรื่อง **ข้อมูลจริงใน `C_PoolSlotTemplate`** (ไม่มี template PIC ของ SD/VIP) ไม่ใช่ logic ของ proc — ตอบครึ่ง "code" ของคำถาม 3.7 ให้ ba1 ได้ทันที ส่วนครึ่ง "data" ยังต้อง query DB ตาม AC เดิมของ ba1 | ยืนยัน/ปิดครึ่งหนึ่งของ 3.7 (ba1)     | Confirmed  |

---

### 3. Condition ที่ขาดหายไป (Missing Condition) ที่ควรมีแต่ไม่มี

1. **ไม่มี NULL-safe join บน `DeliveryOptionCode`** ใน FULL OUTER JOIN หลัก (บรรทัด 466–474) — ควรเป็น `ISNULL(us.DeliveryOptionCode,'') = ISNULL(su.DeliveryOptionCode,'')` หรือเทียบเท่า โดยเฉพาะเมื่อ proc รองรับโหมด `@DeliveryOptionCode = NULL/'ALL'` ที่ปล่อยให้ NULL ไหลผ่านมาถึงจุดนี้ได้จริง (ข้อ 2.10)
2. **ไม่มี dedup/uniqueness guard บน `M_ChannelOfSell.ChannelCode`** ก่อนใช้เป็น join key ที่บรรทัด 245–256 และ 306 — ควรมี `GROUP BY ChannelCode` (เลือก ShortName ตัวเดียวต่อ ChannelCode ด้วยกติกาที่ตกลงกัน) แทน `SELECT DISTINCT` แบบคู่คอลัมน์ (ข้อ 2.6–2.7)
3. **ไม่มี fallback bucket ฝั่ง Setup** สำหรับ `ChannelCode` ที่ไม่ NULL แต่ไม่ match กับ `#channel` — ฝั่ง Usage มี (ColumnSeq 950, บรรทัด 458–463) แต่ฝั่ง Setup (5.2, บรรทัด 300–308) ไม่มี ทำให้เกิดการหายแบบไม่สมมาตรระหว่างสองฝั่ง (ข้อ 2.8)
4. **ไม่มี dedup/uniqueness guard บน `M_Place.MechandiseCode`** ก่อนใช้เป็น join key ปลายทาง (บรรทัด 475) — ทั้งที่ `#store` มี surrogate key (`MPlaceId`) อยู่แล้วตั้งแต่ต้น (บรรทัด 209) แต่ปลายทางกลับไม่ใช้ (ข้อ 2.11)
5. **ไม่มี `ProviderCode` filter** ใน subquery คำนวณ `StoreCountInPool` (บรรทัด 229–238) ทั้งที่ทุก temp table อื่นกรอง ProviderCode อย่างเข้มงวด (ข้อ 2.5)
6. **ไม่มี TRIM/normalize** บน text key ที่ใช้ JOIN/EXISTS ระหว่างตาราง (`PoolCode` บรรทัด 280, `ChannelCode` บรรทัด 306, `StoreMerchandiseCode` บรรทัด 358, 475) ทั้งที่ proc เองมี pattern TRIM ให้เห็นชัดเจนในจุดอื่น (parameter ต่างๆ บรรทัด 142–146, `SlotType`/`SaleSource` บรรทัด 271, 344–346, 365–367) — เป็นความไม่สม่ำเสมอในการป้องกันข้อมูลเปื้อน
7. **ไม่มี guard สำหรับกรณี `#dates` ได้แถวไม่ครบ** ตามที่ `TOP` ขอ เมื่อ `sys.all_objects` มีแถวไม่พอ (ข้อ 2.3) — ความเสี่ยงต่ำในทางปฏิบัติ แต่ไม่มี error ใดแจ้งเตือนถ้าเกิดขึ้นจริง
8. **ไม่มีเงื่อนไขใดกันสาขาที่ไม่มี pool ที่ active หายไปแบบเงียบๆ** (ข้อ 2.4) — ควรพิจารณา LEFT JOIN + flag แทน INNER JOIN ถ้าธุรกิจต้องการเห็นสาขาที่ตั้งค่าไม่ครบด้วย

---

### 4. Condition ที่ Challenge ข้อสรุปเดิมของ ba1

- **ท้าทาย 3.15 (SHARED — เดิมให้ความเสี่ยง Low)**: ba1 ตรวจเฉพาะกรณี `ChannelCode IS NULL` และสรุปว่าปัจจุบันไม่มีเคสนี้ในข้อมูลจริง จึง Low แต่จากการอ่าน SQL พบว่ามี **อีกเคสหนึ่งที่ต่างออกไปและน่าจะเกิดได้ง่ายกว่า** คือ `ChannelCode` ที่ไม่ NULL แต่ไม่ match กับ `#channel` (channel ถูกปิดใช้งาน/ลบ/พิมพ์โค้ดผิด) ซึ่ง SQL **ไม่มี fallback ป้องกันเลย** (ข้อ 2.8, หมวด 3 ข้อ 3) แนะนำให้ปรับความเสี่ยงของ "channel ไม่ match" เป็น **High** แยกจาก 3.15 เดิม (ซึ่งยังคง Low ได้สำหรับกรณี NULL เท่านั้น)
- **ท้าทาย 3.12 (Pool sharing — StoreCountInPool)**: ba1 อ้างอิงคอมเมนต์ในโค้ด (บรรทัด 227–228) ว่า subquery นี้ตรงกับ logic ของ `PlaceRepository.GetMerchandiseCodesByPool` ฝั่ง engine แต่จากการอ่าน SQL เพียงอย่างเดียว **ยืนยันไม่ได้ว่าตรงจริง** เพราะ subquery ที่บรรทัด 232–238 ขาด `ProviderCode` filter (ข้อ 2.5) — ถ้า engine ฝั่งนั้นกรอง ProviderCode ด้วย ตัวเลข `StoreCountInPool` ของ proc นี้อาจสูงกว่าที่ engine ใช้จริง ต้องขอดูโค้ด `PlaceRepository.GetMerchandiseCodesByPool` มายืนยัน ไม่ใช่เชื่อจาก comment อย่างเดียว
- **ท้าทาย 3.3 (จำนวนแถวต่างกัน 20 แถว)**: ba1 ตั้งสมมติฐานเดียวว่าสาเหตุคือจำนวน `C_PoolSlotTemplate` record ต่างกันระหว่าง environment และเขียน AC ให้ query นับ record เทียบ — แนะนำให้ **เพิ่มการตรวจอีกทาง** คือเช็คว่า `M_Place` ของสาขา 00006 (และ pool เดียวกัน) มีแถว active ที่ `MechandiseCode` ซ้ำกันหรือไม่ (ข้อ 2.11) เพราะถ้ามี จะทำให้แถวรายงานเพิ่มขึ้นแบบคูณ (fan-out) ได้เช่นกัน โดยไม่เกี่ยวกับจำนวน template เลย — ควร query ทั้งสองแบบคู่กันก่อนสรุป root cause ไม่ใช่เช็คแค่ template count
- **ปิดครึ่ง "code" ของ 3.7 ให้ ba1**: ยืนยันจาก SQL ว่าไม่มี condition ใดในตัว proc ที่แยก SD/VIP ออกจาก Pickup โดยเฉพาะ (ข้อ 2.15) — คำถามที่เหลือของ 3.7 เป็นเรื่อง data (`C_PoolSlotTemplate` มี record PIC ของ SD/VIP จริงหรือไม่) ล้วนๆ ตรงกับที่ AC เดิมของ ba1 ในหมวด 8 ออกแบบไว้อยู่แล้ว ไม่ต้องแก้ AC
- **ยืนยัน 3.13, 3.14 ตรงกับ ba1 100%** ไม่มีข้อโต้แย้งเพิ่มเติม (ข้อ 2.13–2.14)

---

### 5. Acceptance Criteria เพิ่มเติม (เฉพาะจุดใหม่ ความเสี่ยงสูง)

> ครอบคลุมเฉพาะข้อใหม่ที่ประเมิน **High** ในหมวด 2 ที่ยังไม่มีใน AC เดิมของ ba1 (หมวด 8 ของเอกสาร ba1)
>
> **หลักการตรวจ (ปรับตาม PO 2026-09-15)**: ทุก AC เทียบกับ **ฐานข้อมูลต้นทางโดยตรง** (`C_PoolSlotTemplate`, `D_BookingLog`, `M_Place`, `M_ChannelOfSell`, `M_Pool`) เท่านั้น — **ไม่ใช้ไฟล์ export ของ CFW เป็นเกณฑ์เทียบหลัก** (ใช้เป็นข้อมูลอ้างอิงประกอบได้เท่านั้น) โฟกัสที่ "PROC ดึง/ประมวลผลข้อมูลจาก DB ถูกต้องไหม มีเคสไหนหลุด/ขาด/ซ้ำจากที่ควรดึงมาบ้าง" ทุกข้อบังคับให้มี **2 เคสเสมอ**:
> - **Happy Case**: สถานการณ์ข้อมูลปกติ (ไม่มี NULL/collision/duplicate ตาม condition ที่ข้อนั้นพูดถึง) → PROC ต้องให้ผลตรงกับ query DB ต้นทางตรงๆ 100%
> - **Unhappy Case**: edge case ตาม condition ที่ข้อนั้นพบจริง → ต้องนับได้เป็นตัวเลข ทั้ง "เคสแบบนี้มีอยู่ใน DB กี่แถว" และ "PROC output จับ/หลุด/ซ้ำกี่แถว" พร้อมแยกว่า **"หลุดตามที่ออกแบบไว้ (by design)"** หรือ **"หลุดเพราะบั๊ก (defect)"**
>
> query ทั้งหมดด้านล่างต่อยอดจาก query 2 ชุดในหมวด 7 (ข้อ 1–2) และเพิ่มชุดใหม่ตามที่แต่ละ AC ต้องใช้ — **ยังไม่ได้ execute จริงในรอบนี้**

**AC-T1 — สาขาไม่มี pool ที่ active หายจากรายงานแบบเงียบ (ข้อ 2.4)**
- **Given (Happy)**: query นับสาขาที่มี pool ถูกต้องครบ:
  ```sql
  SELECT COUNT(*) AS ValidStoreCnt
  FROM M_Place pl
  JOIN M_Pool po ON po.Id = pl.MPoolId AND po.IsActive = 1
  WHERE pl.ProviderCode='CFW' AND pl.IsActive=1 AND pl.MechandiseCode IS NOT NULL;
  ```
- **Given (Unhappy)**: query หาสาขาที่ไม่มี pool active (เข้าเงื่อนไขที่ INNER JOIN ที่ #store ตัดทิ้ง):
  ```sql
  SELECT pl.MechandiseCode, pl.PlaceCode
  FROM M_Place pl
  WHERE pl.ProviderCode='CFW' AND pl.IsActive=1 AND pl.MechandiseCode IS NOT NULL
    AND (pl.MPoolId IS NULL
         OR NOT EXISTS (SELECT 1 FROM M_Pool po WHERE po.Id = pl.MPoolId AND po.IsActive = 1));
  ```
  แล้วนับ booking ที่มีอยู่จริงของสาขากลุ่มนี้ในช่วงวันที่ทดสอบ:
  ```sql
  SELECT COUNT(*) AS OrphanUsageCnt
  FROM TMSSlotBooking.dbo.D_BookingLog bl
  WHERE bl.IsActive = 1
    AND bl.StartDate >= @DtFrom AND bl.StartDate < DATEADD(DAY,1,@DtTo)
    AND bl.PlaceCodeMerchandise_Send IN (/* MechandiseCode จาก query ข้างบน */);
  ```
- **When**: รันรายงานโดยไม่ระบุ `@BranchCode` (all branches) ครอบคลุมช่วงวันที่เดียวกับที่ query ด้านบนใช้
- **Then (Happy)**: `COUNT(DISTINCT StoreMerchandiseCode)` ที่ปรากฏใน proc output (สำหรับสาขาในกลุ่ม ValidStoreCnt) ต้อง **= ValidStoreCnt พอดี** ไม่ขาดไม่เกิน
- **Then (Unhappy)**: ถ้า `OrphanUsageCnt > 0` (มี booking จริงของสาขาที่ไม่มี pool active) ตรวจว่าสาขานั้นปรากฏใน proc output กี่แถว — **Pass (by design)**: ปรากฏ **0 แถว** เท่ากับพฤติกรรมปัจจุบันของ INNER JOIN บรรทัด 219–220 (ถือว่า "หลุดตามที่ออกแบบ" แต่ต้องให้ PO เซ็นรับทราบเป็นลายลักษณ์อักษรว่ายอมรับ ไม่ใช่ปิดอัตโนมัติ) — **Fail (defect)**: ปรากฏบางส่วน/ไม่ครบ (เช่น 1 ใน 2 แถวของสาขานั้นโผล่มา) เพราะนั่นแปลว่ามี logic อื่นนอกเหนือจาก INNER JOIN ที่ทำให้พฤติกรรมไม่สม่ำเสมอ ต้องเปิด defect ทันที
- **Pass criteria**: ValidStoreCnt ตรง 100% (Happy) และ OrphanUsageCnt ทุกแถวหายไปแบบ all-or-nothing ไม่ใช่บางส่วน (Unhappy)

**AC-T2 — ChannelCode ซ้ำใน M_ChannelOfSell ทำให้ Setup ถูกนับซ้ำ (ข้อ 2.6–2.7)**
- **Given (Happy)**: query ยืนยันไม่มี ChannelCode ซ้ำ:
  ```sql
  SELECT ChannelCode, COUNT(DISTINCT ShortName) AS DistinctShortName
  FROM M_ChannelOfSell
  WHERE ProviderCode='CFW' AND IsActive=1 AND ShortName IS NOT NULL
  GROUP BY ChannelCode
  HAVING COUNT(DISTINCT ShortName) > 1;
  ```
  (คาดหวัง 0 แถว)
- **Given (Unhappy)**: ถ้า query ข้างบนคืนมา N แถว (N ChannelCode ที่มี ShortName ซ้ำ) ให้ query capacity จริงของแต่ละ ChannelCode นั้นตรงจากต้นทาง (ไม่ผ่าน proc):
  ```sql
  SELECT t.PoolCode, t.ChannelCode, t.StartTime, t.EndTime, SUM(t.Capacity) AS RawCapacity
  FROM C_PoolSlotTemplate t
  WHERE t.ProviderCode='CFW' AND t.ChannelCode = @DuplicatedChannelCode
    AND UPPER(LTRIM(RTRIM(ISNULL(t.SlotType,'')))) <> 'VIP'
  GROUP BY t.PoolCode, t.ChannelCode, t.StartTime, t.EndTime;
  ```
- **When**: รัน proc สำหรับ pool/ช่วงเวลาเดียวกัน แล้วอ่านค่า `SetupQty` ของคอลัมน์ที่ตรงกับ ChannelCode นั้น (อาจปรากฏเป็น 2 คอลัมน์ถ้า ShortName ต่างกัน)
- **Then (Happy)**: ถ้า N=0 → `SetupQty` ในคอลัมน์ channel นั้นของ proc output ต้อง **= RawCapacity พอดี** (ratio 1:1) ทุกแถวที่สุ่มตรวจ
- **Then (Unhappy)**: ถ้า N>0 → เช็ค `SUM(SetupQty ของทุกคอลัมน์ที่มาจาก ChannelCode เดียวกันนั้น)` เทียบกับ `RawCapacity` — **Fail (defect เสมอ ไม่มี by-design)**: ถ้า SUM(SetupQty หลายคอลัมน์) = RawCapacity × (จำนวน ShortName ที่ซ้ำ) แปลว่ายืนยัน fan-out bug ตามที่วิเคราะห์ 100% (ไม่มี comment ใดใน SQL บอกว่าเจตนาให้นับซ้ำ) — **Pass ไม่ได้เลยถ้า N>0 และ ratio ≠ 1** ต้องเปิด defect เสมอ ไม่มีเงื่อนไข "by design" ให้ข้อนี้
- **Pass criteria**: N=0 (Happy, ปิดข้อได้) หรือถ้า N>0 ต้อง ratio SUM(SetupQty)/RawCapacity = 1 พอดี (ไม่ใช่ N) จึงจะถือว่า proc ป้องกัน fan-out ไว้แล้วโดยบังเอิญ — ถ้า ratio > 1 คือ fail แน่นอน

**AC-T3 — Template ที่ ChannelCode ไม่ match #channel หายจากคอลัมน์ราย channel (ข้อ 2.8)**
- **Given (Happy)**: query ยืนยันไม่มี orphaned ChannelCode:
  ```sql
  SELECT COUNT(*) AS OrphanTemplateCnt
  FROM C_PoolSlotTemplate t
  WHERE t.ProviderCode='CFW' AND t.ChannelCode IS NOT NULL
    AND UPPER(LTRIM(RTRIM(ISNULL(t.SlotType,'')))) <> 'VIP'
    AND NOT EXISTS (
        SELECT 1 FROM M_ChannelOfSell c
        WHERE c.ProviderCode='CFW' AND c.IsActive=1 AND c.ShortName IS NOT NULL
          AND c.ChannelCode = t.ChannelCode);
  ```
  (คาดหวัง 0 แถว)
- **Given (Unhappy)**: ถ้า `OrphanTemplateCnt = M > 0` ให้ query ผลรวม Capacity ของ M แถวนั้น แยกตาม (PoolCode, StartTime, EndTime): `SUM(t.Capacity) AS OrphanCapacity ... GROUP BY t.PoolCode, t.StartTime, t.EndTime`
- **When**: รัน proc สำหรับ pool/สโลตที่มี orphan template อยู่ อ่านค่า `SetupQty` ของคอลัมน์ `TOTAL` เทียบกับผลบวก `SetupQty` ของคอลัมน์ SD+WA+XB+XC+SHARED+VIP ในแถวเดียวกัน
- **Then (Happy)**: ถ้า M=0 → `TOTAL = SUM(คอลัมน์ที่เห็นทั้งหมด)` ต้องตรง 100% ทุกแถวที่สุ่มตรวจ (invariant คงอยู่)
- **Then (Unhappy)**: ถ้า M>0 → `TOTAL - SUM(คอลัมน์ที่เห็นทั้งหมด)` ของแถวนั้นต้อง **= OrphanCapacity พอดี** — **Fail (defect เสมอ)**: ถ้าตัวเลขตรงตามนี้ ยืนยัน bug ตามที่วิเคราะห์ (ไม่มี design ใดตั้งใจให้ template หายจากคอลัมน์ราย channel โดยไม่มี fallback) ต้องเพิ่ม fallback bucket ฝั่ง Setup — ไม่มีเคส "by design" สำหรับข้อนี้เช่นกัน
- **Pass criteria**: M=0 (Happy, ปิดข้อได้) หรือถ้า M>0 ส่วนต่าง TOTAL−SUM(columns) ต้อง = 0 (ไม่ใช่ OrphanCapacity) จึงจะถือว่า proc มี logic อื่นชดเชยไว้แล้วโดยไม่รู้ตัว — ถ้าส่วนต่าง > 0 คือ fail แน่นอน

**AC-T4 — NULL DeliveryOptionCode ทำให้ FULL OUTER JOIN ไม่ merge (ข้อ 2.10)**
- **Given (Happy)**: query ยืนยันไม่มี NULL:
  ```sql
  SELECT
    (SELECT COUNT(*) FROM C_PoolSlotTemplate WHERE ProviderCode='CFW' AND DeliveryOptionCode IS NULL) AS TmplNullCnt,
    (SELECT COUNT(*) FROM TMSSlotBooking.dbo.D_BookingLog WHERE ProviderCode='CFW' AND IsActive=1 AND DeliveryOptionCode IS NULL) AS BookingNullCnt;
  ```
  (คาดหวังทั้งคู่ = 0)
- **Given (Unhappy)**: ถ้าทั้งสองค่า > 0 ให้หาคู่ที่ควร merge กัน — key อื่นตรงกันหมด (PoolCode/StoreMerchandiseCode, StartTime, EndTime, ChannelCode/SlotType) ยกเว้น DeliveryOptionCode ที่เป็น NULL ทั้งคู่ นับจำนวนคู่นี้เป็น `K`
- **When**: รันรายงานด้วย `@DeliveryOptionCode = NULL` (โหมด ALL) ครอบคลุม pool/สาขาที่มี K คู่นี้อยู่
- **Then (Happy)**: ถ้า TmplNullCnt=0 และ BookingNullCnt=0 → ปิดข้อนี้ (ทฤษฎีล้วนๆ ในข้อมูลปัจจุบัน) แต่ยังคงคำแนะนำแก้ join เป็น hardening ไว้เหมือนเดิม
- **Then (Unhappy)**: ถ้า K>0 → ตรวจแต่ละคู่ใน proc output ว่าปรากฏเป็น **1 แถว** (SetupQty และ UsageQty มีค่าทั้งคู่, `IsMissingSetup=0`) หรือ **2 แถวแยกกัน** (แถวหนึ่ง SetupQty มีค่า/UsageQty=0, อีกแถว UsageQty มีค่า/SetupQty=NULL, `IsMissingSetup=1`) — **Fail (defect เสมอ)**: พบว่าแยกเป็น 2 แถวแม้แต่ 1 คู่ ยืนยัน bug ตามที่วิเคราะห์ทันที (ไม่มี design ใดตั้งใจให้ NULL=NULL ไม่ merge) ต้องแก้ FULL OUTER JOIN ให้ NULL-safe
- **Pass criteria**: TmplNullCnt=BookingNullCnt=0 (Happy) หรือถ้า K>0 จำนวนคู่ที่แยกเป็น 2 แถวต้อง **= 0** จาก K คู่ทั้งหมด จึงจะผ่าน — พบ 1 คู่ที่แยกก็ถือว่า fail

**AC-T5 — MechandiseCode ซ้ำใน M_Place ทำให้ตัวเลขถูกคูณ (ข้อ 2.11)**
- **Given (Happy)**: query ยืนยันไม่มี MechandiseCode ซ้ำ:
  ```sql
  SELECT MechandiseCode, COUNT(*) AS Cnt
  FROM M_Place
  WHERE ProviderCode='CFW' AND IsActive=1 AND MechandiseCode IS NOT NULL
  GROUP BY MechandiseCode
  HAVING COUNT(*) > 1;
  ```
  (คาดหวัง 0 แถว — รันรวมทุกสาขา โดยเฉพาะสาขา 00006 ที่ ba1 พบความผิดปกติในข้อ 3.1/3.3)
- **Given (Unhappy)**: ถ้าพบสาขาใดมี `Cnt = K > 1` (เช่นสาขา 00006) ให้ query ค่าฐานตรงจากต้นทางโดยไม่ผ่าน proc สำหรับสาขานั้น (ยึด `PoolCode` จาก M_Place 1 แถวใดก็ได้ใน K แถวนั้น): `SUM(C_PoolSlotTemplate.Capacity)` ต่อ (StartTime, EndTime) และ `COUNT(D_BookingLog)` ที่ `PlaceCodeMerchandise_Send` เท่ากับ MechandiseCode นั้น ต่อ (SlotDay, StartTime, EndTime, ColumnKey) — เรียกค่านี้ว่า `RawSetup` และ `RawUsage`
- **When**: รัน proc กรอง `@BranchCode` = MechandiseCode ของสาขานั้น อ่านค่า `SetupQty`/`UsageQty` ที่ proc คืนมา
- **Then (Happy)**: ถ้าทุกสาขา Cnt=1 → `SetupQty`/`UsageQty` จาก proc ต้อง **= RawSetup/RawUsage พอดี** (ratio 1:1) ทุกแถวที่สุ่มตรวจ
- **Then (Unhappy)**: ถ้าสาขานั้น K>1 → เช็ค `SetupQty`/`UsageQty` จาก proc **= RawSetup × K / RawUsage × K** หรือไม่ — **ถ้าตรงตามอัตรา K พอดี**: ยืนยัน fan-out bug ตามที่วิเคราะห์ 100% และให้ระบุว่าค่า K ของสาขา 00006 อธิบายผลต่าง 20 แถว/ตัวเลขที่ ba1 พบในข้อ 3.1, 3.3 ได้ลงตัวหรือไม่ (เทียบ `จำนวนแถวจริง − จำนวนแถวคาดหวัง` กับ `(K−1) × จำนวน SlotDay×SlotTime×ColumnKey ของสาขานั้น`) — ไม่มีเคส "by design" สำหรับข้อนี้เช่นกัน (ไม่มีเหตุผลทางธุรกิจใดรองรับ MechandiseCode ซ้ำ)
- **Pass criteria**: Cnt=0 ทุกสาขา (Happy, ปิดข้อได้) หรือถ้าพบ K>1 ที่สาขาใด ต้องได้ ratio = 1 (ไม่ใช่ K) จึงจะถือว่า proc ป้องกันการคูณซ้ำไว้แล้ว — ถ้า ratio = K คือ fail และกลายเป็น root cause หลักที่ต้องแก้ (ใช้ `MPlaceId` แทน `MechandiseCode` ในการ join ปลายทาง หรือ dedupe `#store` ก่อน)

**AC-T6 — StoreCountInPool อาจรวมข้าม Provider (ข้อ 2.5)**
- **Given (Happy)**: query ยืนยันไม่มี MPoolId ใช้ข้าม provider:
  ```sql
  SELECT MPoolId, COUNT(DISTINCT ProviderCode) AS ProviderCnt
  FROM M_Place
  WHERE IsActive=1 AND MechandiseCode IS NOT NULL AND MPoolId IS NOT NULL
  GROUP BY MPoolId
  HAVING COUNT(DISTINCT ProviderCode) > 1;
  ```
  (คาดหวัง 0 แถว) — ควบคู่กับคำยืนยัน schema จากทีม dev/DBA ว่า `M_Pool.Id` ถูกออกแบบให้ scope เฉพาะ 1 provider เสมอหรือไม่ (คำถามข้อ 3 ในหมวด 7)
- **Given (Unhappy)**: ถ้าพบ P pools ที่ ProviderCnt>1 ให้เตรียม 2 ค่าต่อ pool: `RawCountUnfiltered` (นับทุกสาขาในพูลไม่กรอง Provider — ตรงกับที่โค้ดปัจจุบันบรรทัด 232–238 ทำ) และ `RawCountFiltered` (นับเฉพาะสาขาที่ `ProviderCode='CFW'` ในพูลเดียวกัน)
- **When**: รัน proc สำหรับสาขาที่อยู่ใน pool กลุ่ม P อ่านค่า `StoreCountInPool` ที่ proc คำนวณจริง (แม้ไม่ได้ expose ในรายงาน แต่ query ตรง column นี้จาก dataset ได้)
- **Then (Happy)**: ถ้า P=0 (ไม่มี pool ข้าม provider) → `StoreCountInPool` ที่ proc คำนวณ (ไม่มี filter) ต้อง **= RawCountFiltered พอดี** ทุก pool ที่สุ่มตรวจ เพราะไม่มีสาขาจาก provider อื่นให้ปนอยู่แล้ว (safe by data แม้โค้ดไม่มี filter)
- **Then (Unhappy)**: ถ้า P>0 → เช็คว่า `StoreCountInPool` จาก proc **= RawCountUnfiltered** (ไม่ใช่ RawCountFiltered) — **ถ้าตรงกับ RawCountUnfiltered และ RawCountUnfiltered ≠ RawCountFiltered**: ยืนยัน bug ตามที่วิเคราะห์ (นับรวมสาขาข้าม provider จริง) ต้องแก้ subquery เพิ่ม `p2.ProviderCode = @ProviderCode` — ไม่มีเคส "by design" รองรับการนับข้าม provider (ไม่มี comment ใดใน SQL ระบุเจตนานี้)
- **Pass criteria**: P=0 (Happy, ปิดข้อได้ทั้งจาก data และยังคงแนะนำเพิ่ม filter เป็น defensive coding) หรือถ้า P>0 ต้องได้ `StoreCountInPool = RawCountFiltered` (ไม่ใช่ RawCountUnfiltered) จึงจะผ่าน — ถ้า = RawCountUnfiltered คือ fail ชัดเจน

---

### 6. 📌 จุดที่ UX Designer ต้องรู้

- **"IsMissingSetup=1" อาจไม่ได้แปลว่า VIP fallback เสมอไปอย่างที่ ba1 สรุปไว้** — จากข้อ 2.10 (AC-T4) แถวที่ `IsMissingSetup=1` อาจเกิดจาก join ไม่ติดเพราะ `DeliveryOptionCode` เป็น NULL ทั้งสองฝั่ง (ปัญหาระบบ ไม่ใช่พฤติกรรมจริงของธุรกิจ) ถ้า QA ยืนยันเคสนี้เกิดขึ้นจริง UX ต้องออกแบบให้แยกความแตกต่างระหว่าง "VIP fallback ตั้งใจ" กับ "ข้อมูลผิดปกติจาก join" ไม่ใช่ใช้ label เดียวกันหมด
- **Total อาจไม่เท่ากับผลบวกคอลัมน์ที่เห็นเสมอไป** (จากข้อ 2.8/2.9) — ถ้า data ในอนาคตมี channel ที่ถูกปิดใช้งานหรือ template ที่มี ChannelCode ไม่ match ระบบ UI/รายงานควรมีกลไกเผื่อไว้ (เช่น checksum เตือน หรืออย่างน้อยไม่ต้อง hard-code ความคาดหวังว่า Total = SUM เสมอ) ไม่ใช่ปล่อยให้ผู้ใช้สังเกตความคลาดเคลื่อนเอง
- **สาขาที่ไม่มี pool ตั้งค่าไว้จะหายจากรายงานทั้งแถวโดยไม่มี error/indicator ใดๆ** (ข้อ 2.4) — ถ้าผู้ใช้ (operations staff) คาดหวังจะเห็นทุกสาขา อาจต้องมีหน้าจอ/ช่องทางแยกสำหรับแจ้งว่า "สาขานี้ยังไม่ถูกตั้งค่า pool" แทนที่จะให้ผู้ใช้สงสัยว่าทำไมสาขาหายไปเฉยๆ (ยังไม่ใช่ scope ของ report นี้โดยตรง แต่ควรรู้ไว้ตอนออกแบบ empty/error state)
- Utilization ที่เกิน 100% (ตามที่ ba1 ระบุแล้วในข้อ 3.5) ยังคงต้องออกแบบรองรับตามเดิม — ไม่มีข้อมูลใหม่จากรอบตรวจนี้ที่เปลี่ยนข้อสรุปนั้น

---

### 7. ❓ คำถามที่ต้องยืนยันกับ CFW / PO / DBA

1. **[ใหม่]** ขอ DBA รัน query ตรวจว่า `M_ChannelOfSell.ChannelCode` (scope `ProviderCode='CFW' AND IsActive=1`) มี `ChannelCode` ใดที่มีมากกว่า 1 `ShortName` หรือไม่:
   ```sql
   SELECT ChannelCode, COUNT(DISTINCT ShortName) AS DistinctShortName
   FROM M_ChannelOfSell
   WHERE ProviderCode = 'CFW' AND IsActive = 1 AND ShortName IS NOT NULL
   GROUP BY ChannelCode
   HAVING COUNT(DISTINCT ShortName) > 1;
   ```
   (เชื่อมกับ AC-T2, ข้อ 2.6–2.7)

2. **[ใหม่]** ขอ DBA รัน query ตรวจว่า `M_Place.MechandiseCode` (scope `ProviderCode='CFW' AND IsActive=1`) มีค่าใดซ้ำกันมากกว่า 1 แถวหรือไม่ โดยเฉพาะสาขา 00006 ที่ ba1 พบความผิดปกติ:
   ```sql
   SELECT MechandiseCode, COUNT(*) AS Cnt
   FROM M_Place
   WHERE ProviderCode = 'CFW' AND IsActive = 1 AND MechandiseCode IS NOT NULL
   GROUP BY MechandiseCode
   HAVING COUNT(*) > 1;
   ```
   (เชื่อมกับ AC-T5, ข้อ 2.11 — เป็นสมมติฐานสาเหตุทางเลือกของ 3.1/3.3 ที่ ba1 ยังไม่ได้เช็ค)

3. **[ใหม่]** ขอทีม dev ยืนยัน schema: `M_Pool.Id` (ที่ `M_Place.MPoolId` ชี้ไป) ถูก scope เฉพาะ 1 `ProviderCode` เสมอหรือไม่ — ถ้าไม่แน่ใจ ขอดู DDL/FK constraint ของ `M_Pool`/`M_Place` (เชื่อมกับ AC-T6, ข้อ 2.5)

4. **[ใหม่]** ขอ DBA เช็คว่า `C_PoolSlotTemplate.DeliveryOptionCode` หรือ `D_BookingLog.DeliveryOptionCode` มีค่า NULL อยู่จริงในข้อมูลปัจจุบันหรือไม่ (แค่ `COUNT(*) WHERE DeliveryOptionCode IS NULL` ของทั้งสองตาราง) — ถ้ามี ต้องแก้ FULL OUTER JOIN ให้ NULL-safe ก่อน deploy (เชื่อมกับ AC-T4, ข้อ 2.10)

5. **[ใหม่]** ยืนยันกับ dev/PO ว่า `@ProviderCode` ที่ default บังคับเป็น `'CFW'` เสมอ (ไม่มีโหมด "ทุก provider") เป็นข้อจำกัดที่ตั้งใจถาวร หรือควรเปิดช่องให้ NULL = ทุก provider เหมือนพารามิเตอร์ตัวอื่น (ข้อ 2.12) — ไม่เร่งด่วน แต่ควรบันทึกเป็น design decision ให้ชัด

6. **[ใหม่]** ขอทีม backend ยืนยัน logic ของ `PlaceRepository.GetMerchandiseCodesByPool` (โค้ดฝั่ง engine ที่คอมเมนต์ในบรรทัด 227–228 อ้างถึง) ว่ากรอง `ProviderCode` ด้วยหรือไม่ — เพื่อตัดสินว่า subquery `StoreCountInPool` ในบรรทัด 229–238 ต้องเพิ่ม filter ให้ตรงกันหรือไม่ (เชื่อมกับ AC-T6)

7. สืบเนื่องจากข้อ 2.9 (dedupe assumption ของ SHARED template): ขอดู logic จริงของ `BookingService.SearchTimeSlotAvailableAsync` / `FilterSlotTemplates` (โค้ด backend ที่คอมเมนต์บรรทัด 55–56, 312–314 อ้างถึง) ว่าเมื่อสล็อตเวลาเดียวกันมีทั้ง template `ChannelCode NULL` และ template เจาะจง channel พร้อมกัน engine มองเป็น capacity แยกกันหรือ capacity เดียวกันที่เข้าถึงได้หลายทาง — เพื่อยืนยันว่าการ SUM รวมของ proc (5.1) ถูกต้องตามธุรกิจหรือไม่

8. ยืนยันกับ PO/CFW ว่าพฤติกรรม "สาขาที่ไม่มี pool ที่ active จะหายไปจากรายงานทั้งแถวโดยไม่มี error/indicator" (ข้อ 2.4, AC-T1) เป็นพฤติกรรมที่ยอมรับได้ หรือควรมีแถว/สัญญาณแจ้งเตือนแทน

---

**สรุปก่อนส่งต่อ**: เอกสารนี้ตรวจเฉพาะ condition ในตัว SQL PROC เท่านั้น ยังไม่ได้ query DB จริงเช่นเดียวกับข้อจำกัดของ ba1 (ข้อ 3.20) — คำถามและ AC ใหม่ทั้งหมดในหมวด 5–7 ต้องรอผล query จาก DBA ก่อนจึงจะปิดได้ 100% รอ **PO ตรวจสอบและยืนยัน** ก่อนว่าจะให้ดำเนินการอย่างไรต่อ (เช่น ส่ง query ในหมวด 7 ให้ DBA รันจริง, หรือส่งต่อให้ ux-designer ทำ screen flow โดยถือว่าประเด็นเหล่านี้เป็น known-risk ที่ยังไม่ปิด) — ยังไม่ส่งต่อ ux-designer จนกว่า PO จะยืนยัน
