SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* =============================================================================
   RPT_UtilizationSlotDeliveryPickup
   -----------------------------------------------------------------------------
   Data source สำหรับรายงาน Slot Time Delivery / Slot Time Pick up
     @DeliveryOptionCode = 'DIY'  ->  รายงาน Slot Time Delivery
     @DeliveryOptionCode = 'PIC'  ->  รายงาน Slot Time Pick-up
     @DeliveryOptionCode = NULL / 'ALL' -> รวมทั้งสอง (แยกด้วยคอลัมน์ DeliveryOptionCode)
 
   Report Builder = reports/CFW/RPT_UtilizationSlotDeliveryPickup.rdl
   Task 70494 (SA)  |  QA = task 70600  |  User Story = 70457
   บทวิเคราะห์ = reports/CFW/RPT_UtilizationSlotDeliveryPickup_Analysis.md
 
   READ-ONLY เท่านั้น — ไม่มี INSERT/UPDATE/DELETE ใดๆ
 
   -----------------------------------------------------------------------------
   *** DRAFT — ยังไม่ได้ compile/รันกับ DB จริง (ผู้ใช้ยืนยันว่ารับความเสี่ยงนี้ได้) ***
   ยืนยันแล้วจากผู้ใช้ 2026-09-09:
     - ชื่อคอลัมน์ D_BookingLog ใช้ตาม data-hub (underscore) -> PlaceCodeMerchandise_Send
     - DeliveryOptionCode มีทั้ง 'DIY' และ 'PIC'
   ยังไม่ยืนยัน (เลือกทางที่ปลอดภัยไว้ก่อน):
     - [ยืนยันแล้ว 2026-09-10] proc สร้างบน **TMSSlotBooking** (RDL DataSource ชี้ TMSSlotBooking)
       ไม่ใช่ TMSCustomer แบบ RPT_* ตัวอื่นของ CFW เพราะ Usage มาจาก D_BookingLog ซึ่งอยู่ DB นี้
       -> D_BookingLog เป็น local table (คง 3-part name ไว้ให้อ่านง่าย ยังรันได้ปกติ)
       -> M_Place / M_Pool / M_ChannelOfSell / C_PoolSlotTemplate ยังอ้างข้าม DB ไป TMSMaster
       ⚠ ต้องมั่นใจว่า login ของ SSRS DataSource มีสิทธิ์อ่าน TMSMaster ด้วย ไม่ใช่แค่ TMSSlotBooking
       (precedent cross-DB 3-part = RPT_TruckManifest -> TMSTransport.dbo.D_Shipment)
     - ชื่อนิติบุคคลใน H2 ("บริษัท เซ็นทรัล ฟู้ด โฮลเซลล์ จำกัด") ไม่มีใน M_Place
       -> ตอนนี้ใส่ชื่อสาขาอย่างเดียว ซึ่งตรงกับ export จริงของ STS แล้ว
     - '00001' ในคอลัมน์ Store เป็น MechandiseCode หรือ PlaceCode
       -> ใช้ MechandiseCode (คีย์เดียวกับที่ผูก booking) คืนทั้งสองค่ามาให้ RDL เลือกได้
 
   -----------------------------------------------------------------------------
   ตรวจสอบกับ export จริงของ STS แล้ว (2026-09-09, ช่วง 01–09/09/2026, 2 สาขา)
     downloads/wi70494/ReportSlottimeDelivery 2026-09-09_05-29.xls   (189 แถวข้อมูล)
     downloads/wi70494/ReportSlottimePickup   2026-09-09_05-30.xls   (72 แถวข้อมูล)
   ผลตรวจ 261 แถว ไม่มีข้อยกเว้นเลย:
     1. Set Up  Total = ผลบวก 4 คอลัมน์ channel  ทุกแถว
     2. Usage   Total = ผลบวก 4 คอลัมน์ channel  ทุกแถว
     3. Utilization เก็บเป็น **ratio** (usage/setup) ไม่คูณ 100
        เช่น setup 200 / usage 4 -> Total 0.02, คอลัมน์ XB (setup 100, usage 4) -> 0.04
        คอลัมน์ Total = Usage รวม / Set Up รวม ไม่ใช่ผลบวกของ % ราย channel
     4. ไม่มีแถวไหนที่ Usage > 0 แต่ Set Up = 0
     5. export ปัจจุบัน **ไม่มีคอลัมน์ VIP** -> VIP คือของใหม่ที่ task นี้เพิ่ม
   -> (1) แปลว่าในข้อมูลจริงไม่มี template ที่ ChannelCode เป็น NULL (หรือ STS ไม่ได้เอามารวม)
      proc นี้จึงลง channel เฉพาะ template ที่ระบุ ChannelCode ชัดเจน ส่วนตัว NULL
      แยกเป็น ColumnKey 'SHARED' และนับใน TOTAL -> ผลบวก 4 channel ยังเท่ากับ Total
      เหมือน STS ตราบใดที่ไม่มี template NULL (ถ้ามีจะเห็นเป็นคอลัมน์ SHARED ไม่หายเงียบ)
 
   -----------------------------------------------------------------------------
   นิยาม (อ้างอิงโค้ดที่คุม capacity จริง — ห้ามแก้ให้ต่างโดยไม่แก้โค้ดตาม)
     Set Up  = C_PoolSlotTemplate.Capacity                (TMSMaster)
               BookingService.SearchTimeSlotAvailableAsync ข้อ 3 + FilterSlotTemplates
     Usage   = COUNT(D_BookingLog WHERE IsActive = 1)     (TMSSlotBooking)
               BookingLogService.CountBookingLogsBatch — *ไม่สน IsCreateJob*
               (= รวม booking ที่ hold ไว้ยังไม่ผูก order ตรงกับที่ engine ใช้คุม capacity)
     Utilization = Usage / Set Up  ** คืนเป็น ratio ไม่คูณ 100 ** (ยืนยันจาก export ข้อ 3)
               RDL ฟอร์แมต '0.00%' ถ้าคูณ 100 ที่นี่ด้วยจะได้ 100.00%
 
   -----------------------------------------------------------------------------
   โครงผลลัพธ์ = long format 1 แถวต่อ (Store x SlotDay x SlotTime x ColumnKey)
   คงค่าวัดไว้เป็น 3 field ตามที่ผู้ใช้เลือก: Utilization / SetupQty / UsageQty
   (ไม่ unpivot เป็น MeasureKey) -> RDL ต้องใช้ **adjacent column groups** 3 ชุด
   วางเรียงกันซ้ายไปขวา ทุกชุด group ด้วย ColumnKey + sort ด้วย ColumnSeq เหมือนกัน
   แล้วผูกช่องค่าไปคนละ field:
     ชุดที่ 1 หัว 'Utilization' (พื้นแดง)  -> Utilization  format '0.00%'
     ชุดที่ 2 หัว 'Set Up'      (พื้นเขียว) -> SetupQty     format '#,##0'
     ชุดที่ 3 หัว 'Usage'       (พื้นน้ำเงิน)-> UsageQty     format '#,##0'
   ในแต่ละชุดซ้อน 2 ชั้น: GroupKey (แถบ Normal / VIP) -> ColumnKey (หัวคอลัมน์จริง)
 
   ColumnKey / ColumnSeq
     'TOTAL'     ColumnSeq 0    -> Total Delivery Up / Total Pick Up   (GroupKey = '')
     <ShortName> ColumnSeq 10,20,...  -> STS / WA / XB / XC (เรียงตาม ShortName = ลำดับใน STS)
     'SHARED'    ColumnSeq 940  -> template ที่ ChannelCode = NULL (ปกติไม่มี — RDL ซ่อนได้)
     'VIP'       ColumnSeq 900  -> คอลัมน์ VIP (ของใหม่ task นี้)
     <อื่น>      ColumnSeq 950  -> SaleSource ที่ไม่มีใน M_ChannelOfSell (ข้อมูลเพี้ยน ให้เห็น)
 
   GroupKey / GroupSeq (แถบหัวคอลัมน์ชั้นบน — ให้ 'Normal' กินความกว้างเท่าจำนวน channel เอง)
     ''       GroupSeq 0 -> เหนือคอลัมน์ Total เป็นช่องว่างตามภาพตัวอย่าง
     'Normal' GroupSeq 1 -> ครอบ channel ทั้งหมด + SHARED + SaleSource แปลกปลอม
     'VIP'    GroupSeq 2 -> ครอบคอลัมน์ VIP
   เรียงคอลัมน์ = GroupSeq แล้วค่อย ColumnSeq
 
   Usage map เข้าคอลัมน์ได้ตรงๆ เพราะ D_BookingLog.SaleSource เก็บ M_ChannelOfSell.ShortName
   (BookingService.CreateBookingAsync: saleSource = channelOfSell.ShortName)
 
   ⚠ D_BookingLog.SlotType เก็บค่าที่ "ลูกค้าขอ" ไม่ใช่ค่าของ template ที่ได้ไป
     (slotType = SlotTypeEnums.Normalize(request.SlotType))
     -> booking VIP ที่ fallback ไปกิน slot ทั่วไป (BR011) ยังบันทึกเป็น SlotType='VIP'
     -> จะเห็นเป็น "VIP มี Usage แต่ Set Up = 0" (IsMissingSetup = 1) ซึ่งสะท้อนพฤติกรรมจริง
        ของระบบ ไม่ใช่บั๊กของ proc — engine เองก็นับ VIP แยก bucket โดยไม่หักจาก capacity
        ของ slot ทั่วไปที่ถูกกินไป
 
   -----------------------------------------------------------------------------
   ข้อสมมติที่ยังรอ BA ยืนยัน (ดู RPT_UtilizationSlotDeliveryPickup_Analysis.md §6) — เปลี่ยนที่นี่ได้ทันที
     A. Grain = Store, Set Up ระดับ pool ซ้ำทุกสาขาใน pool เดียวกัน
        คืน StoreCountInPool มาด้วย ถ้า > 1 แปลว่าแถวนั้นแชร์โควตากับสาขาอื่น
     B. Usage นับ IsCreateJob ทั้ง 0 และ 1 (ตรง engine) — ถ้าอยากได้เฉพาะที่เป็น order จริง
        ให้เปิดบรรทัด AND bl.IsCreateJob = 1 ที่ #booking
     C. [ตัดสินใจแล้ว 2026-09-10] Total **รวม VIP** -> Total = ผลรวมของทุกคอลัมน์ที่เห็น
        เดิมเคยทำเป็น parameter @IncludeVipInTotal ไว้ ตอนนี้ถอดออกแล้ว เหตุผลที่เลือกรวม:
          1. STS ปัจจุบันไม่รู้จัก SlotType เลย Total ของมันนับ booking ทุกใบอยู่แล้ว
             -> ถ้าเราตัด VIP ออก Total เราจะ "ต่ำกว่า" STS ไม่ใช่ตรงกับ STS
          2. D_BookingLog.SlotType เก็บค่าที่ลูกค้าขอ ไม่ใช่ของ template ที่ได้ไป
             booking VIP ที่ fallback ไปกิน slot ทั่วไป (BR011) ยังเป็น SlotType='VIP'
             ถ้าตัด VIP ออกจาก Total -> capacity ที่ถูกกินอยู่ใน Total Set Up แต่ booking
             ที่กินมันไปไม่อยู่ใน Total Usage -> Total Utilization ต่ำกว่าจริงแบบเงียบๆ
             (วันนี้ยังไม่มี template VIP ตั้งไว้ ลูกค้า VIP ทุกใบจึง fallback หมด ผลกระทบยิ่งเยอะ)
          3. คนอ่านรายงานคาดหวังว่า Total = ผลรวมของคอลัมน์ที่เห็นบนหน้าจอ
        ⚠ แจ้ง QA: คอลัมน์ราย channel (STS/WA/XB/XC) จะ **ไม่ตรงกับ STS** ตรงที่มี booking VIP
          เพราะเราย้าย booking พวกนั้นออกจากคอลัมน์ sale source ไปอยู่คอลัมน์ VIP ตามที่ BA สั่ง
          -- เป็นความตั้งใจของ task นี้ ไม่ใช่ bug ส่วน Total ต้องตรงกับ STS
     D. Set Up = 0 -> proc คืน Utilization = NULL (NULL = คำนวณไม่ได้ ไม่ใช่ 0)
        แต่ **ฝั่ง RDL แสดงผลต่างจากนี้** ตามที่ผู้ใช้กำหนด 2026-09-10 และตรงกับ mock:
          Utilization ไม่มีค่า -> แสดง 0.00%
          Usage       ไม่มีค่า -> แสดง 0
          Set Up      ไม่มีค่า / เป็น 0 -> แสดงช่องว่าง
        กฎการแสดงผลอยู่ใน expression ของช่องใน RPT_UtilizationSlotDeliveryPickup.rdl ไม่ได้แก้ที่ proc
        เพื่อให้ dataset ยังแยกออกว่า "ไม่มี template" (NULL) กับ "มี template แต่ capacity 0" ได้
     E. ไม่ตัดวันหยุดสาขา / cutoff ออก — รายงานเป็น capacity vs usage ล้วน
     F. แถวที่มี Usage แต่ไม่มี Set Up แสดงด้วย (FULL OUTER) + flag IsMissingSetup = 1
        (export จริงไม่มีเคสนี้เลย แต่เคส VIP fallback ข้างบนจะสร้างขึ้นมาได้)
   ============================================================================= */
ALTER   PROCEDURE [dbo].[RPT_UtilizationSlotDeliveryPickup]
    @BUCode             VARCHAR(20)  = NULL,   -- M_Place.BUCode (เว้นว่าง = ทุก BU)
    @ProviderCode       VARCHAR(20)  = NULL,   -- default 'CFW'
    @BranchCode         VARCHAR(20)  = NULL,   -- M_Place.PlaceCode หรือ MechandiseCode (NULL = ทุกสาขา)
    -- รับเป็นข้อความ 'yyyy-MM-dd' (RDL ส่ง textbox มาตรงๆ) แล้วแปลงเป็น DATE ในนี้
    @DateFrom           VARCHAR(20)  = NULL,
    @DateTo             VARCHAR(20)  = NULL,
    @DeliveryOptionCode VARCHAR(10)  = NULL    -- 'DIY' | 'PIC' | NULL/'ALL'
AS
BEGIN
    SET NOCOUNT ON;
 
    -- BUCode มีอยู่บน M_Place ตารางเดียว (C_PoolSlotTemplate / D_BookingLog / M_ChannelOfSell
    -- ไม่มีคอลัมน์นี้) จึงกรองที่ชั้นสาขา แล้วผลจะไหลต่อไปยัง template (ผ่าน pool)
    -- และ booking (ผ่าน MechandiseCode) เองโดยอัตโนมัติ
    SET @BUCode             = NULLIF(LTRIM(RTRIM(@BUCode)), '');
    SET @ProviderCode       = NULLIF(LTRIM(RTRIM(@ProviderCode)), '');
    IF @ProviderCode IS NULL SET @ProviderCode = 'CFW';
    SET @BranchCode         = NULLIF(LTRIM(RTRIM(@BranchCode)), '');
    SET @DeliveryOptionCode = NULLIF(LTRIM(RTRIM(@DeliveryOptionCode)), '');
    IF @DeliveryOptionCode = 'ALL' SET @DeliveryOptionCode = NULL;
 
    ---------------------------------------------------- แปลงวันที่จากข้อความ
    -- รูปแบบที่รับ: 'yyyy-MM-dd' (style 23) เช่น '2026-06-01'
    -- เว้นว่าง/NULL -> วันนี้; กรอกมาแต่แปลงไม่ได้ -> error ทันที
    -- (ไม่ fallback เงียบๆ เพราะพิมพ์ผิดแล้วได้รายงานผิดวันโดยไม่รู้ตัวอันตรายกว่า)
    DECLARE @DateFromText VARCHAR(20) = NULLIF(LTRIM(RTRIM(@DateFrom)), '');
    DECLARE @DateToText   VARCHAR(20) = NULLIF(LTRIM(RTRIM(@DateTo)),   '');
    DECLARE @DtFrom DATE = TRY_CONVERT(DATE, @DateFromText, 23);
    DECLARE @DtTo   DATE = TRY_CONVERT(DATE, @DateToText,   23);
 
    IF @DateFromText IS NOT NULL AND @DtFrom IS NULL
        THROW 50001, N'DateFrom ไม่ถูกต้อง ต้องอยู่ในรูปแบบ yyyy-MM-dd เช่น 2026-06-01', 1;
    IF @DateToText IS NOT NULL AND @DtTo IS NULL
        THROW 50002, N'DateTo ไม่ถูกต้อง ต้องอยู่ในรูปแบบ yyyy-MM-dd เช่น 2026-06-01', 1;
 
    IF @DtFrom IS NULL SET @DtFrom = CAST(GETDATE() AS DATE);
    IF @DtTo   IS NULL SET @DtTo   = @DtFrom;
    IF @DtTo   < @DtFrom SET @DtTo = @DtFrom;
 
    ------------------------------------------------------------------ หัวรายงาน
    -- ข้อความทั้ง 3 บรรทัดลอกจาก export จริงของ STS แบบตรงตัว
    DECLARE @H1 NVARCHAR(200), @H2 NVARCHAR(300), @H3 NVARCHAR(200);
 
    -- ชื่อสาขาสำหรับ H2 (MAX กันกรณีมี code ซ้ำ — pattern เดียวกับ RPT_DeliveryOrder)
    -- ใช้ NameLocal ก่อน เพราะ export โชว์ "สาขา ศรีนครินทร์ 1" (มีคำว่า "สาขา" นำ)
    DECLARE @BranchName NVARCHAR(200);
    IF @BranchCode IS NOT NULL
        SELECT @BranchName = MAX(ISNULL(pl.NameLocal, pl.BranchName))
        FROM M_Place pl
        WHERE (pl.PlaceCode = @BranchCode OR pl.MechandiseCode = @BranchCode)
          AND pl.ProviderCode = @ProviderCode
          AND (@BUCode IS NULL OR pl.BUCode = @BUCode)
          AND pl.IsActive = 1;
 
    SET @H1 = CASE @DeliveryOptionCode
                WHEN 'PIC' THEN N'รายงาน Slot Time Pick-up'
                WHEN 'DIY' THEN N'รายงาน Slot Time Delivery'
                ELSE            N'รายงาน Slot Time Delivery / Pick-up'
              END;
    SET @H2 = N'สาขา : ' + CASE
                WHEN @BranchCode IS NULL THEN N'แสดงทุกสาขา'   -- ตรง export STS
                WHEN @BranchName IS NULL THEN @BranchCode
                ELSE @BranchName
              END;
    -- export STS ใช้รูปช่วงวันที่เสมอ (ไม่มีรูป "ณ วันที่" แบบ RPT_DeliveryOrder)
    SET @H3 = N'ระหว่างวันที่ ' + FORMAT(@DtFrom, 'dd/MM/yyyy')
            + N' ถึง ' + FORMAT(@DtTo, 'dd/MM/yyyy');
 
    ------------------------------------------------------- ขั้นที่ 1: ช่วงวันที่
    DROP TABLE IF EXISTS #dates;
 
    SELECT TOP (DATEDIFF(DAY, @DtFrom, @DtTo) + 1)
           DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1, @DtFrom) AS SlotDay
    INTO #dates
    FROM sys.all_objects;   -- tally (pattern เดียวกับ RPT_TruckManifest)
 
    ------------------------------------------------ ขั้นที่ 2: สาขาในขอบเขต + pool
    -- StoreCountInPool = จำนวนสาขาที่แชร์โควตา pool เดียวกัน (ดูข้อสมมติ A)
    DROP TABLE IF EXISTS #store;
 
    SELECT
        pl.Id                                AS MPlaceId,
        pl.PlaceCode                         AS StoreCode,
        pl.Code2Digit                        AS StoreCode2Digit,
        pl.MechandiseCode                    AS StoreMerchandiseCode,
        ISNULL(pl.NameLocal, pl.BranchName)  AS StoreName,
        po.PoolCode,
        po.Id                                AS MPoolId,
        CONVERT(INT, 0)                      AS StoreCountInPool
    INTO #store
    FROM M_Place pl
    JOIN M_Pool  po ON po.Id = pl.MPoolId
                                 AND po.IsActive = 1
    WHERE pl.ProviderCode = @ProviderCode
      AND (@BUCode IS NULL OR pl.BUCode = @BUCode)
      AND pl.IsActive = 1
      AND pl.MechandiseCode IS NOT NULL
      AND (@BranchCode IS NULL OR pl.PlaceCode = @BranchCode OR pl.MechandiseCode = @BranchCode);
 
    -- นับจากสาขาทั้งหมดใน pool ไม่ใช่เฉพาะที่อยู่ในขอบเขต filter (เงื่อนไขเดียวกับ
    -- PlaceRepository.GetMerchandiseCodesByPool ที่ engine ใช้ตอนนับ booking)
    UPDATE s
    SET StoreCountInPool = x.Cnt
    FROM #store s
    CROSS APPLY (
        SELECT COUNT(*) AS Cnt
        FROM M_Place p2
        WHERE p2.MPoolId = s.MPoolId
          AND p2.IsActive = 1
          AND p2.MechandiseCode IS NOT NULL
    ) x;
 
    -------------------------------------------------- ขั้นที่ 3: channel ที่ใช้ได้
    -- เรียงตาม ShortName ได้ STS, WA, XB, XC ตรงลำดับใน export STS
    -- (ถ้า BA อยากได้ลำดับอื่นต้องเพิ่มคอลัมน์ลำดับใน M_ChannelOfSell)
    DROP TABLE IF EXISTS #channel;
 
    SELECT
        ch.ChannelCode,
        ch.ShortName,
        CONVERT(INT, ROW_NUMBER() OVER (ORDER BY ch.ShortName) * 10) AS ColumnSeq
    INTO #channel
    FROM (
        SELECT DISTINCT ChannelCode, ShortName
        FROM M_ChannelOfSell
        WHERE ProviderCode = @ProviderCode
          AND IsActive = 1
          AND ShortName IS NOT NULL
    ) ch;
 
    ------------------------------------------------------ ขั้นที่ 4: template ดิบ
    -- SlotTypeNorm ตาม SlotTypeEnums.Normalize:
    --   'VIP' (trim/ไม่สนตัวพิมพ์) -> VIP, ที่เหลือรวม NULL -> 'ทั่วไป'
    --   *ห้ามเขียน WHERE SlotType = N'ทั่วไป' ตรงๆ* แถว NULL จะหายเงียบ
    DROP TABLE IF EXISTS #tmpl;
 
    SELECT
        t.Id                AS CPoolSlotTemplateId,
        t.PoolCode,
        t.DeliveryOptionCode,
        t.ChannelCode,
        t.StartTime,
        t.EndTime,
        CONVERT(NVARCHAR(20), CASE WHEN UPPER(LTRIM(RTRIM(ISNULL(t.SlotType, '')))) = 'VIP'
                                   THEN N'VIP' ELSE N'ทั่วไป' END) AS SlotTypeNorm,
        ISNULL(t.Capacity, 0) AS Capacity
    INTO #tmpl
    FROM C_PoolSlotTemplate t
    WHERE t.ProviderCode = @ProviderCode
      AND t.StartTime IS NOT NULL
      AND t.EndTime   IS NOT NULL
      AND (@DeliveryOptionCode IS NULL OR t.DeliveryOptionCode = @DeliveryOptionCode)
      AND EXISTS (SELECT 1 FROM #store s WHERE s.PoolCode = t.PoolCode);
 
    CREATE INDEX IX_tmpl ON #tmpl (PoolCode, DeliveryOptionCode, StartTime, EndTime, SlotTypeNorm);
 
    -------------------------------- ขั้นที่ 5: Set Up ต่อคอลัมน์ (ก่อนกระจายรายวัน)
    -- 5.1 คอลัมน์ TOTAL — นับ template ใบละครั้ง (ไม่ double count) รวม VIP ด้วย
    DROP TABLE IF EXISTS #setup_col;
 
    SELECT
        t.PoolCode,
        t.DeliveryOptionCode,
        t.StartTime,
        t.EndTime,
        CONVERT(NVARCHAR(30), 'TOTAL') AS ColumnKey,
        CONVERT(INT, 0)                AS ColumnSeq,
        SUM(t.Capacity)                AS SetupQty
    INTO #setup_col
    FROM #tmpl t
    GROUP BY t.PoolCode, t.DeliveryOptionCode, t.StartTime, t.EndTime;
 
    -- 5.2 คอลัมน์ราย channel (กลุ่ม Normal) — เฉพาะ template ที่ระบุ ChannelCode
    --     ทำให้ผลบวก 4 คอลัมน์ = Total เหมือน export STS (ตรวจแล้ว 261/261 แถว)
    INSERT INTO #setup_col (PoolCode, DeliveryOptionCode, StartTime, EndTime, ColumnKey, ColumnSeq, SetupQty)
    SELECT t.PoolCode, t.DeliveryOptionCode, t.StartTime, t.EndTime,
           c.ShortName, c.ColumnSeq, SUM(t.Capacity)
    FROM #tmpl t
    JOIN #channel c ON c.ChannelCode = t.ChannelCode
    WHERE t.SlotTypeNorm = N'ทั่วไป'
    GROUP BY t.PoolCode, t.DeliveryOptionCode, t.StartTime, t.EndTime, c.ShortName, c.ColumnSeq;
 
    -- 5.3 คอลัมน์ SHARED — template ที่ ChannelCode เป็น NULL = ใช้ได้ทุก channel
    --     ข้อมูลจริงไม่มีเคสนี้ แต่ถ้ามีจะได้ไม่หายเงียบ (RDL ซ่อนคอลัมน์นี้ได้)
    --     ⚠ ถ้าเจอเคสนี้ต้องคุยกับ BA ว่าจะกระจายลง channel ยังไง เพราะ FilterSlotTemplates
    --       มองว่าทุก channel เห็น template นี้ (และถูก template เจาะจง channel บังตาม
    --       dedupe (StartTime, EndTime, SlotType) ที่เลือกตัว ChannelCode ไม่ NULL ก่อน)
    INSERT INTO #setup_col (PoolCode, DeliveryOptionCode, StartTime, EndTime, ColumnKey, ColumnSeq, SetupQty)
    SELECT t.PoolCode, t.DeliveryOptionCode, t.StartTime, t.EndTime, 'SHARED', 940, SUM(t.Capacity)
    FROM #tmpl t
    WHERE t.SlotTypeNorm = N'ทั่วไป'
      AND t.ChannelCode IS NULL
    GROUP BY t.PoolCode, t.DeliveryOptionCode, t.StartTime, t.EndTime;
 
    -- 5.4 คอลัมน์ VIP — VIP ไม่แตกราย channel ตามที่ BA ระบุ และตรงกับของจริงที่
    --     template VIP มัก set ChannelCode = NULL
    INSERT INTO #setup_col (PoolCode, DeliveryOptionCode, StartTime, EndTime, ColumnKey, ColumnSeq, SetupQty)
    SELECT t.PoolCode, t.DeliveryOptionCode, t.StartTime, t.EndTime, 'VIP', 900, SUM(t.Capacity)
    FROM #tmpl t
    WHERE t.SlotTypeNorm = N'VIP'
    GROUP BY t.PoolCode, t.DeliveryOptionCode, t.StartTime, t.EndTime;
 
    ------------------------------------------ ขั้นที่ 6: Usage ต่อ (สาขา, วัน, slot, คอลัมน์)
    -- คีย์เวลาสร้างแบบเดียวกับที่ engine สร้างตอนจอง:
    --   StartDate = วันของ slot + Template.StartTime, EndDate = วันของ slot + Template.EndTime
    --   (BookingService.CreateBookingAsync: startDate = bookingDate.Add(startTime))
    -- ผูก booking กับสาขาผ่าน PlaceCodeMerchandise_Send = M_Place.MechandiseCode
    DROP TABLE IF EXISTS #booking;
 
    SELECT
        bl.PlaceCodeMerchandise_Send AS StoreMerchandiseCode,
        bl.DeliveryOptionCode,
        CAST(bl.StartDate AS DATE)   AS SlotDay,
        CAST(bl.StartDate AS TIME)   AS StartTime,
        CAST(bl.EndDate   AS TIME)   AS EndTime,
        CONVERT(NVARCHAR(30),
            CASE WHEN UPPER(LTRIM(RTRIM(ISNULL(bl.SlotType, '')))) = 'VIP'
                 THEN 'VIP'
                 ELSE ISNULL(NULLIF(LTRIM(RTRIM(bl.SaleSource)), ''), N'(ไม่ระบุ)')
            END) AS ColumnKey,
        COUNT(*) AS UsageQty
    INTO #booking
    FROM TMSSlotBooking.dbo.D_BookingLog bl
    WHERE bl.ProviderCode = @ProviderCode
      AND bl.IsActive = 1
      -- ข้อสมมติ B: engine ไม่สน IsCreateJob -> รายงานก็ไม่สน
      -- AND bl.IsCreateJob = 1        -- <- เปิดบรรทัดนี้ถ้า BA อยากได้เฉพาะที่เป็น order จริง
      AND bl.StartDate >= CAST(@DtFrom AS DATETIME)
      AND bl.StartDate <  DATEADD(DAY, 1, CAST(@DtTo AS DATETIME))
      AND (@DeliveryOptionCode IS NULL OR bl.DeliveryOptionCode = @DeliveryOptionCode)
      AND EXISTS (SELECT 1 FROM #store s WHERE s.StoreMerchandiseCode = bl.PlaceCodeMerchandise_Send)
    GROUP BY
        bl.PlaceCodeMerchandise_Send,
        bl.DeliveryOptionCode,
        CAST(bl.StartDate AS DATE),
        CAST(bl.StartDate AS TIME),
        CAST(bl.EndDate   AS TIME),
        CASE WHEN UPPER(LTRIM(RTRIM(ISNULL(bl.SlotType, '')))) = 'VIP'
             THEN 'VIP'
             ELSE ISNULL(NULLIF(LTRIM(RTRIM(bl.SaleSource)), ''), N'(ไม่ระบุ)')
        END;
 
    -- แตกเป็น 2 ส่วน: คอลัมน์ TOTAL (รวมทุก ColumnKey ของ slot) + คอลัมน์ราย key
    DROP TABLE IF EXISTS #usage;
 
    SELECT StoreMerchandiseCode, DeliveryOptionCode, SlotDay, StartTime, EndTime,
           CONVERT(NVARCHAR(30), 'TOTAL') AS ColumnKey,
           SUM(UsageQty) AS UsageQty
    INTO #usage
    FROM #booking
    GROUP BY StoreMerchandiseCode, DeliveryOptionCode, SlotDay, StartTime, EndTime;
 
    INSERT INTO #usage (StoreMerchandiseCode, DeliveryOptionCode, SlotDay, StartTime, EndTime, ColumnKey, UsageQty)
    SELECT StoreMerchandiseCode, DeliveryOptionCode, SlotDay, StartTime, EndTime, ColumnKey, UsageQty
    FROM #booking;
 
    ----------------------------- ขั้นที่ 7: กาง Set Up รายวัน แล้วรวมกับ Usage
    -- FULL OUTER: แถวที่มี Set Up แต่ไม่มี Usage = ปกติ (export เต็มไปด้วย 0)
    --             แถวที่มี Usage แต่ไม่มี Set Up -> IsMissingSetup = 1 (ข้อสมมติ F)
    DROP TABLE IF EXISTS #setup;
 
    SELECT
        s.StoreMerchandiseCode,
        sc.DeliveryOptionCode,
        d.SlotDay,
        sc.StartTime,
        sc.EndTime,
        sc.ColumnKey,
        sc.ColumnSeq,
        sc.SetupQty
    INTO #setup
    FROM #setup_col sc
    JOIN #store s ON s.PoolCode = sc.PoolCode
    CROSS JOIN #dates d;
 
    SELECT
        -- หัวรายงาน
        @H1 AS H1,
        @H2 AS H2,
        @H3 AS H3,
 
        -- แกนแถว
        st.StoreCode,                                             -- M_Place.PlaceCode
        st.StoreMerchandiseCode,                                  -- คีย์ที่ผูกกับ booking
        st.StoreName,
        st.StoreMerchandiseCode + N' - ' + ISNULL(st.StoreName, N'') AS StoreLabel,
        st.PoolCode,
        st.StoreCountInPool,                                      -- > 1 = แชร์โควตากับสาขาอื่น
        k.DeliveryOptionCode,
        k.SlotDay,
        CONVERT(CHAR(10), k.SlotDay, 23)                          AS SlotDayText,  -- yyyy-MM-dd ตาม export
        -- export มี slot '00:00-24:00' และ '12:00-24:00' -> เวลาจบที่ <= เวลาเริ่ม
        -- แปลว่าเที่ยงคืนของวันถัดไป (ชนิด time เก็บ 24:00 ไม่ได้) แสดงเป็น '24:00'
        CONVERT(CHAR(5), k.StartTime, 108) + '-'
            + CASE WHEN k.EndTime <= k.StartTime
                   THEN '24:00'
                   ELSE CONVERT(CHAR(5), k.EndTime, 108) END      AS SlotTime,
        k.StartTime                                               AS SlotStartTime,
        k.EndTime                                                 AS SlotEndTime,
 
        -- แกนคอลัมน์
        k.ColumnKey,
        MAX(k.ColumnSeq)                                          AS ColumnSeq,
        -- แถบหัวคอลัมน์ชั้นบน: Total ไม่มีแถบ (ช่องว่าง) ตามภาพตัวอย่าง
        CASE WHEN k.ColumnKey = 'TOTAL' THEN N''
             WHEN k.ColumnKey = 'VIP'   THEN N'VIP'
             ELSE N'Normal' END                                   AS GroupKey,
        CASE WHEN k.ColumnKey = 'TOTAL' THEN 0
             WHEN k.ColumnKey = 'VIP'   THEN 2
             ELSE 1 END                                           AS GroupSeq,
 
        -- ค่า
        SUM(ISNULL(k.SetupQty, 0))                                AS SetupQty,
        SUM(ISNULL(k.UsageQty, 0))                                AS UsageQty,
        -- ratio ไม่คูณ 100 — RDL ฟอร์แมต '0.00%' (ยืนยันจาก export STS)
        CASE WHEN SUM(ISNULL(k.SetupQty, 0)) > 0
             THEN CONVERT(DECIMAL(18,6), SUM(ISNULL(k.UsageQty, 0)))
                  / CONVERT(DECIMAL(18,6), SUM(k.SetupQty))
             ELSE NULL   -- ข้อสมมติ D: Set Up = 0 -> ช่องว่าง ไม่ใช่ 0.00%
        END                                                       AS Utilization,
        CASE WHEN SUM(ISNULL(k.SetupQty, 0)) = 0 AND SUM(ISNULL(k.UsageQty, 0)) > 0
             THEN 1 ELSE 0 END                                    AS IsMissingSetup
    FROM (
        SELECT
            ISNULL(su.StoreMerchandiseCode, us.StoreMerchandiseCode) AS StoreMerchandiseCode,
            ISNULL(su.DeliveryOptionCode,   us.DeliveryOptionCode)   AS DeliveryOptionCode,
            ISNULL(su.SlotDay,   us.SlotDay)                         AS SlotDay,
            ISNULL(su.StartTime, us.StartTime)                       AS StartTime,
            ISNULL(su.EndTime,   us.EndTime)                         AS EndTime,
            ISNULL(su.ColumnKey, us.ColumnKey)                       AS ColumnKey,
            -- คอลัมน์ที่โผล่มาจากฝั่ง usage อย่างเดียว: VIP=900, sale source แปลกปลอม=950
            ISNULL(su.ColumnSeq,
                   CASE WHEN us.ColumnKey = 'TOTAL' THEN 0
                        WHEN us.ColumnKey = 'VIP'   THEN 900
                        ELSE ISNULL((SELECT c.ColumnSeq FROM #channel c WHERE c.ShortName = us.ColumnKey), 950)
                   END)                                              AS ColumnSeq,
            su.SetupQty,
            us.UsageQty
        FROM #setup su
        FULL OUTER JOIN #usage us
               ON  us.StoreMerchandiseCode = su.StoreMerchandiseCode
               AND us.DeliveryOptionCode   = su.DeliveryOptionCode
               AND us.SlotDay              = su.SlotDay
               AND us.StartTime            = su.StartTime
               AND us.EndTime              = su.EndTime
               AND us.ColumnKey            = su.ColumnKey
    ) k
    JOIN #store st ON st.StoreMerchandiseCode = k.StoreMerchandiseCode
    GROUP BY
        st.StoreCode, st.StoreMerchandiseCode, st.StoreName, st.PoolCode, st.StoreCountInPool,
        k.DeliveryOptionCode, k.SlotDay, k.StartTime, k.EndTime, k.ColumnKey
    ORDER BY
        st.StoreMerchandiseCode,
        k.DeliveryOptionCode,
        k.SlotDay,
        k.StartTime,
        k.EndTime,
        CASE WHEN k.ColumnKey = 'TOTAL' THEN 0
             WHEN k.ColumnKey = 'VIP'   THEN 2
             ELSE 1 END,
        MAX(k.ColumnSeq);
 
    DROP TABLE IF EXISTS #dates;
    DROP TABLE IF EXISTS #store;
    DROP TABLE IF EXISTS #channel;
    DROP TABLE IF EXISTS #tmpl;
    DROP TABLE IF EXISTS #setup_col;
    DROP TABLE IF EXISTS #booking;
    DROP TABLE IF EXISTS #usage;
    DROP TABLE IF EXISTS #setup;
END
GO