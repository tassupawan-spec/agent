SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[RPT_OrderLeadtimeBacklog]
    @BUCode       VARCHAR(20)   = NULL,
    @BranchCode   VARCHAR(20)   = NULL,  -- ดึงทีละสาขา (NULL = ทุกสาขา)
    @DateFrom     DATE          = NULL,
    @DateTo       DATE          = NULL
AS
BEGIN
    SET NOCOUNT ON;
 
    SET @BUCode      = NULLIF(LTRIM(RTRIM(@BUCode)), '');
    IF @BUCode IS NULL SET @BUCode = 'CFW';
    SET @BranchCode  = NULLIF(LTRIM(RTRIM(@BranchCode)), '');
 
    IF @DateFrom IS NULL SET @DateFrom = CAST(DATEADD(DD, -1, GETDATE()) AS DATE);
    IF @DateTo   IS NULL SET @DateTo   = @DateFrom;
 
    DECLARE @DateToExclusive DATE = DATEADD(DAY, 1, @DateTo);
    -- ค่าคงที่ (07/09 ตัด @SlaHours/@BacklogAsOf ออกจาก parameter ตามที่เคาะ)
    -- SLA หลัง End Time slot ที่ยังถือว่า Ontime = 1 ชม. ตาม REQ CFW (TBC ข้อ 2 ยังเปิด - ถ้าเปลี่ยนแก้ตัวเลขนี้ทั้ง 2 proc)
    DECLARE @SlaHours    INT  = 1;
    DECLARE @SlaMinutes  INT  = @SlaHours * 60;
    -- วันอ้างอิงอายุ backlog = วันสุดท้ายของช่วงที่ค้นหา (เลือกช่วงถึงวันนี้ = วันที่รัน ตรงกับ STS)
    DECLARE @BacklogAsOf DATE = @DateTo;
 
    -- หัวรายงาน (ตาม Report Header ใน work item)
    DECLARE @H1 NVARCHAR(200) = N'Order Lead-Time & Backlog Report';
    DECLARE @H2 NVARCHAR(500), @H3 NVARCHAR(200);
 
    -- ชื่อสาขาจาก master ของสาขาที่เลือกเข้ามาดึง (BA เคาะ 07/09: ทั้ง H2 และคอลัมน์ Store ยึดตาม @BranchCode)
    -- STS ใช้ 2 ชื่อคนละคอลัมน์: H2 = ชื่อเต็มบริษัท+สาขา, Store = "SNR_001_ศรีนครินทร์ 1"
    -- map H2 -> NameLocal, Store -> BranchName (ต้องยืนยันด้วย perfcheck C1 ว่าคอลัมน์ไหนเก็บค่าแบบไหน)
    -- MAX กันกรณี M_Place มี PlaceCode ซ้ำ - pattern เดียวกับ RPT_DeliveryOrder
    DECLARE @BranchName NVARCHAR(200), @StoreName NVARCHAR(200);
    IF @BranchCode IS NOT NULL
        SELECT @BranchName = MAX(pl.NameLocal),
               @StoreName  = MAX(pl.BranchName)
        FROM M_Place pl
        WHERE pl.PlaceCode = @BranchCode
          AND pl.BUCode    = @BUCode
          AND pl.IsActive  = 1;
 
    SET @H2 = N'สาขา : ' + CASE
                WHEN @BranchCode IS NULL THEN N'ทุกสาขา'
                WHEN @BranchName IS NULL THEN @BranchCode
                ELSE @BranchName
              END;
    -- ถ้า master ไม่มีชื่อ โชว์รหัสดิบให้ QA เห็นว่า mapping เพี้ยน (ไม่ให้ว่างเงียบๆ)
    IF @BranchCode IS NOT NULL AND @StoreName IS NULL SET @StoreName = @BranchCode;
 
    SET @H3 = N'รายงานประจำวันที่ ' + FORMAT(@DateFrom, 'dd/MM/yyyy')
            + N' ถึง ' + FORMAT(@DateTo, 'dd/MM/yyyy');
 
    -- ขั้นที่ 1: ชุด order ตั้งต้น = order ที่ slot (StartTime) อยู่ในช่วงที่ค้นหา
    -- #70681: comment ใน work item ยืนยันว่า "วันที่จัดส่ง" map จาก D_Order.StartTime
    -- order ที่ StartTime IS NULL ไม่ต้องดึง (ยืนยันกับ BA แล้ว) - การเทียบช่วงวันที่
    -- ตัด NULL ออกให้อยู่แล้ว จึงไม่ต้องมีเงื่อนไข IS NOT NULL เพิ่ม
    DROP TABLE IF EXISTS #ord;
 
    SELECT
        o.ID                       AS dOrderID,
        o.OrderNumber              AS OrderNumber,
        o.PlaceCode_Sell           AS BranchCode,
        o.StatusCode               AS StatusCode,
        CAST(o.StartTime AS DATE)  AS SlotDate,
        o.EndTime                  AS SlotEndTime,
        -- "Order Created Time" = D_Order.OrderDate (เคาะ 07/09 - เดิมใช้ CreateDate)
        -- OrderDate เป็น nullable: order ที่ไม่มีค่าจะได้ LeadMinutes = NULL และถูกตัดออกจาก AVG (ไม่ทำให้ค่าเฉลี่ยเพี้ยน)
        o.OrderDate                AS OrderCreatedTime,
        -- TBC: Value = "ยอดออเดอร์ basket หรือ amount" - ตอนนี้ใช้ยอดสุทธิระดับ order
        -- จงใจไม่ใช้ C_OrderPayment.Amount เพราะ 1 order มีได้หลาย payment แล้วยอดจะเบิ้ล
        -- (บั๊กแบบเดียวกับที่เจอใน RPT_DeliveryOrderDetail)
        ISNULL(o.TotalNet, 0)      AS OrderValue
    INTO #ord
    FROM D_Order o
    WHERE o.IsActive = 1
      AND o.BUCode   = @BUCode
      AND o.StartTime >= @DateFrom
      AND o.StartTime <  @DateToExclusive
      AND (@BranchCode IS NULL OR o.PlaceCode_Sell = @BranchCode)
    OPTION (RECOMPILE);
 
    CREATE UNIQUE CLUSTERED INDEX IX_ord_dOrderID ON #ord (dOrderID);
    -- index สำหรับ join กับ D_StatusLog ในขั้นที่ 2 (clustered ด้านบนเป็น dOrderID ช่วยตรงนี้ไม่ได้)
    CREATE NONCLUSTERED INDEX IX_ord_OrderNumber ON #ord (OrderNumber) INCLUDE (dOrderID);
 
    -- ขั้นที่ 2: เวลาเปลี่ยนสถานะระดับ order (pivot จาก D_StatusLog รอบเดียว ใช้ทั้ง 2 บล็อก)
    -- ยืม pattern จาก RPT_Performance_detail (CFR)
    -- ข้อควรระวัง: D_StatusLog ไม่มีคอลัมน์ BUCode และ 1 order มีหลาย log (ราย product/ราย shipment)
    --   -> join ผ่าน OrderNumber ของ #ord ที่กรอง BU มาแล้ว และ MAX() ยุบให้เหลือ order ละแถว
    DROP TABLE IF EXISTS #statuslog;
 
    SELECT
        t.dOrderID,
        -- TBC ข้อ 1: CFR รวม 18000/18001/13004 เป็น "order_complete" ก้อนเดียว
        --            รายงานนี้ Delivered ต้องไม่รวม 13004 (ส่งไม่สำเร็จ) แน่ๆ
        --            เหลือถามแค่ 18001 (ส่งบางส่วน) นับเป็น Delivered ด้วยไหม
        -- เวลาส่งสำเร็จ = log 18000 (Completed) ตาม req ที่ระบุ "Delivered (18000)" - ดู TBC ข้อ 16
        -- (07/09 ตัด log 15110/15120 ออก: ช่อง During delivery เปลี่ยนไปดูสถานะปัจจุบันแทน)
        MAX(CASE WHEN l.StatusCode = '18000' THEN l.CreateDate END) AS DeliveredTime
    INTO #statuslog
    FROM #ord t
    JOIN D_StatusLog l
          ON l.OrderNumber = t.OrderNumber
         AND l.StatusCode = '18000'
         -- TBC ข้อ 9: D_StatusLog ไม่มี BUCode และ RPT_Performance_detail (CFR) join D_Order
         -- ด้วย BUCode + OrderNumber แปลว่า OrderNumber อาจซ้ำข้าม BU ได้
         -- ถ้าซ้ำจริงต้องเติมเงื่อนไข l.ProviderCode ด้วย - ต้อง verify กับข้อมูลจริงก่อน
    GROUP BY t.dOrderID
    OPTION (RECOMPILE);
 
    CREATE UNIQUE CLUSTERED INDEX IX_statuslog_dOrderID ON #statuslog (dOrderID);
 
    -- ขั้นที่ 3: จัด bucket ต่อ order (ทั้ง lead time และ backlog)
    DROP TABLE IF EXISTS #calc;
 
    SELECT
        t.dOrderID,
        t.BranchCode,
        t.OrderValue,
 
        -- ---------- ฝั่ง Order Inbound ----------
        -- ต้องเช็ค 2 ชั้น: มี log 18000 (ได้เวลาส่ง) + D_Order.StatusCode = 18000 (ทั้งใบส่งครบจริง)
        -- เช็คชั้นเดียวไม่พอ เพราะ 1 order มีได้หลาย shipment - ถ้าเช็คแค่ log
        -- order ที่ส่งครบแค่ shipment เดียวจะถูกนับเป็น Delivered ทั้งที่ทั้งใบยังไม่จบ
        -- (D_Order.StatusCode = MIN ของ child ตาม CONTEXT.md)
        CASE WHEN s.DeliveredTime IS NOT NULL
              AND t.StatusCode = '18000' THEN 1 ELSE 0 END AS IsDelivered,
        -- ส่วนต่างจาก End Time ของ slot (นาที) ใช้ทั้ง Ontime/Delay และ bucket lead time
        -- ค่าติดลบ = ส่งก่อนหมด slot (CFR เรียก 'Early') รายงานนี้มีแค่ Ontime/Delay จึงนับรวมเป็น Ontime
        DATEDIFF(MINUTE, t.SlotEndTime, s.DeliveredTime)  AS LateMinutes,
        -- lead time สำหรับค่าเฉลี่ย นับจากเวลาสร้าง order (คนละฐานกับ bucket - ตามสเปค)
        DATEDIFF(MINUTE, t.OrderCreatedTime, s.DeliveredTime) AS LeadMinutes,
 
        -- ---------- ฝั่ง Order Backlog ----------
        -- Backlog = ยังไม่ delivered / ไม่ใช่ fail delivery / ไม่ cancel (รายการ code เทียบกับ M_Status 07/09)
        --   completed     : 18000 เสร็จสิ้น, 18001 จัดส่งสำเร็จบางส่วน
        --   fail delivery : 13004 จัดส่งไม่สำเร็จ (รอติดต่อ), 17002 ส่งไม่สำเร็จ รอบันทึกค่าขนส่ง
        --   cancel        : 13090/13091 Cancel Following, 19000/19001/19002 Cancelled, 19040 เปลี่ยนเป็นรับที่สาขา,
        --                   19050/19051 Redelivery หลังส่งสำเร็จ, 19100/19101/19180 Return to Sender
        --   ยังเป็น backlog: 19030 ขอเลื่อน (สร้างรายการใหม่), 19060 เลื่อนข้ามวัน, 13002/13003 จัดรถ/โหลดไม่สำเร็จ,
        --                   14004 Failed pickup, 15180-17080 ส่งแล้วแต่ยังไม่ปิดงาน (QC/Finance) - ดู TBC ข้อ 17
        CASE WHEN t.StatusCode NOT IN ('18000', '18001',
                                       '13004', '17002',
                                       '13090', '13091', '19000', '19001', '19002', '19040', '19050', '19051',
                                       '19100', '19101', '19180')
             THEN 1 ELSE 0 END AS IsBacklog,
        -- อายุ backlog = เทียบ Slot Date กับวันที่อ้างอิง (@BacklogAsOf)
        DATEDIFF(DAY, t.SlotDate, @BacklogAsOf) AS BacklogAgeDays,
        -- ขั้นตอนระหว่างจัดส่ง ดูจาก "สถานะปัจจุบัน" ของ order (07/09 เปลี่ยนจากเช็ค log - กัน order ที่ออกรถแล้วถูกเลื่อนกลับมา)
        --   ONROUTE = 15110 อยู่ระหว่างเดินทางจัดส่ง + 15111 ส่ง SMS แจ้ง + 15112/15113 เดินทางล่าช้า = "อยู่ระหว่างการจัดส่ง/บริการ"
        --   ATCUST  = 15120 ถึงที่หมายจัดส่ง + 15180 จัดส่งสินค้าแล้ว (ยังไม่ปิด 18000)          = "ถึงบ้านลูกค้ากำลังจัดส่ง"
        --   16xxx/17xxx (รอ QC / รอบันทึกค่าขนส่งหลังส่งแล้ว) ยังไม่เข้าช่องไหน - TBC ข้อ 17
        CASE WHEN t.StatusCode IN ('15120', '15180')                   THEN 'ATCUST'
             WHEN t.StatusCode IN ('15110', '15111', '15112', '15113') THEN 'ONROUTE'
             ELSE NULL END AS DuringDeliveryStage
    INTO #calc
    FROM #ord t
    LEFT JOIN #statuslog s ON s.dOrderID = t.dOrderID
    OPTION (RECOMPILE);
 
    -- ขั้นที่ 3.5: ชื่อสาขาต่อ order (ใช้เฉพาะกรณี @BranchCode = NULL ดึงทุกสาขา)
    -- กรณีเลือกสาขาเดียว Store ใช้ @StoreName ที่หาจาก @BranchCode ไว้แล้วด้านบน (BA เคาะ 07/09)
    -- ยุบให้เหลือสาขาละแถวก่อน join: M_Place unique ที่ (ProviderCode, BUCode, PlaceCode) ไม่ใช่ PlaceCode เดี่ยวๆ
    -- ถ้า join ตรงเข้า #calc แล้วมีแถวซ้ำ COUNT(*) = Order Inbound จะบานตามจำนวนแถวที่ซ้ำ
    -- (RPT_DeliveryOrder ก็ใช้ MAX(NameLocal) กันเคสนี้เหมือนกัน)
    --
    -- รหัสสาขา: ยึดตาม master M_Place ที่ maintain อยู่ (ยืนยันกับ BA แล้ว)
    -- ทั้ง @BranchCode ที่หน้าจอส่งมา และ D_Order.PlaceCode_Sell ต้องเป็น M_Place.PlaceCode ตัวเดียวกัน
    -- ถ้า StoreName ออกมาเป็น NULL แปลว่ารหัสไม่ตรงกับ master (เช่นหน้าจอส่ง 'SNR' แต่ master เป็น
    -- 'SNR_001') - รายงานจะโชว์รหัสดิบแทนชื่อสาขา ใช้เป็นสัญญาณให้ QA จับได้ว่า mapping เพี้ยน
    DROP TABLE IF EXISTS #store;
 
    SELECT
        c.BranchCode,
        MAX(pl.BranchName) AS StoreName   -- คอลัมน์เดียวกับ @StoreName ให้ 2 กรณีโชว์รูปแบบเดียวกัน
    INTO #store
    FROM (SELECT DISTINCT BranchCode FROM #calc) c
    LEFT JOIN M_Place pl ON pl.PlaceCode = c.BranchCode
                        AND pl.BUCode    = @BUCode
                        AND pl.IsActive  = 1
    GROUP BY c.BranchCode;
 
    CREATE UNIQUE CLUSTERED INDEX IX_store_BranchCode ON #store (BranchCode);
 
    -- ขั้นที่ 4: สรุปต่อสาขา + แถว Summary (WITH ROLLUP)
    -- ดึงทีละสาขา -> แถว Summary จะมีตัวเลขเท่ากับแถวสาขาเดียวนั้น
    -- ตรงกับภาพตัวอย่างใน work item ที่แถว SNR_001 กับ Summary เท่ากันทุกช่อง
    SELECT
        @H1 AS H1,
        @H2 AS H2,
        @H3 AS H3,
        CASE WHEN GROUPING(c.BranchCode) = 1
             THEN N'Summary'
             -- Store = ชื่อจาก master ตรงๆ ไม่ประกอบ Code + Name เอง (BA เคาะ 07/09 ยึดตาม master)
             -- เลือกสาขาเดียว -> ชื่อของ @BranchCode ที่หาไว้ / ทุกสาขา -> ชื่อของแต่ละ PlaceCode_Sell
             WHEN @BranchCode IS NOT NULL THEN @StoreName
             ELSE MAX(ISNULL(st.StoreName, c.BranchCode))
        END AS Store,
        GROUPING(c.BranchCode) AS IsSummaryRow,
        -- รหัสสาขาของแถว (NULL ที่แถว Summary) - RDL ใช้ส่งไปกรอง Detail ตอนคลิกตัวเลข
        -- ต้องเป็นค่าเดียวกับ D_Order.PlaceCode_Sell ที่ proc Detail ใช้กรอง
        c.BranchCode                                                  AS BranchCode,
 
        -- ================= Order Inbound =================
        COUNT(*)                                                      AS OrderInbound,
        SUM(c.IsDelivered)                                            AS OrderDelivered,
        SUM(CASE WHEN c.IsDelivered = 1
                  AND c.LateMinutes <= @SlaMinutes THEN 1 ELSE 0 END) AS OntimeCount,
        SUM(CASE WHEN c.IsDelivered = 1
                  AND c.LateMinutes >  @SlaMinutes THEN 1 ELSE 0 END) AS DelayCount,
 
        SUM(CASE WHEN c.IsDelivered = 1 AND c.LateMinutes <=    0                            THEN 1 ELSE 0 END) AS LeadDay0,
        SUM(CASE WHEN c.IsDelivered = 1 AND c.LateMinutes >     0 AND c.LateMinutes <= 1440  THEN 1 ELSE 0 END) AS LeadDay1,
        SUM(CASE WHEN c.IsDelivered = 1 AND c.LateMinutes >  1440 AND c.LateMinutes <= 2880  THEN 1 ELSE 0 END) AS LeadDay2,
        SUM(CASE WHEN c.IsDelivered = 1 AND c.LateMinutes >  2880 AND c.LateMinutes <= 4320  THEN 1 ELSE 0 END) AS LeadDay3,
        SUM(CASE WHEN c.IsDelivered = 1 AND c.LateMinutes >  4320                            THEN 1 ELSE 0 END) AS LeadDayOver3,
 
        -- Average Order Leadtime by Hr. = Total Lead Time / Order Delivered
        CAST(ISNULL(AVG(CASE WHEN c.IsDelivered = 1
                             THEN c.LeadMinutes * 1.0 / 60 END), 0) AS DECIMAL(10, 2)) AS AvgLeadtimeHr,
 
        -- ================= Order Backlog =================
        SUM(c.IsBacklog)                                                                     AS TotalBacklog,
        -- bucket 1 Day กินตั้งแต่ age <= 1 (รวม slot วันเดียวกัน) เพื่อไม่ให้มี order ตกหล่นนอก bucket
        -- รายงานไม่มีช่อง "0 Day" ฝั่ง backlog - TBC ข้อ 5
        SUM(CASE WHEN c.IsBacklog = 1 AND c.BacklogAgeDays <= 1                     THEN 1 ELSE 0 END) AS BacklogDay1,
        SUM(CASE WHEN c.IsBacklog = 1 AND c.BacklogAgeDays  = 2                     THEN 1 ELSE 0 END) AS BacklogDay2,
        SUM(CASE WHEN c.IsBacklog = 1 AND c.BacklogAgeDays  = 3                     THEN 1 ELSE 0 END) AS BacklogDay3,
        SUM(CASE WHEN c.IsBacklog = 1 AND c.BacklogAgeDays  > 3                     THEN 1 ELSE 0 END) AS BacklogDayOver3,
 
        -- Value by backlog: ยอดรวมตาม Order ในแต่ละช่วงเวลาของ Backlog
        CAST(SUM(CASE WHEN c.IsBacklog = 1 AND c.BacklogAgeDays <= 1 THEN c.OrderValue ELSE 0 END) AS DECIMAL(18, 2)) AS BacklogValueDay1,
        CAST(SUM(CASE WHEN c.IsBacklog = 1 AND c.BacklogAgeDays  = 2 THEN c.OrderValue ELSE 0 END) AS DECIMAL(18, 2)) AS BacklogValueDay2,
        CAST(SUM(CASE WHEN c.IsBacklog = 1 AND c.BacklogAgeDays  = 3 THEN c.OrderValue ELSE 0 END) AS DECIMAL(18, 2)) AS BacklogValueDay3,
        CAST(SUM(CASE WHEN c.IsBacklog = 1 AND c.BacklogAgeDays  > 3 THEN c.OrderValue ELSE 0 END) AS DECIMAL(18, 2)) AS BacklogValueDayOver3,
        CAST(SUM(CASE WHEN c.IsBacklog = 1                           THEN c.OrderValue ELSE 0 END) AS DECIMAL(18, 2)) AS BacklogValueTotal,
 
        -- Value by During delivery: subset ของ Backlog ที่ออกรถไปแล้ว (2 ช่องไม่ทับกัน)
        CAST(SUM(CASE WHEN c.IsBacklog = 1 AND c.DuringDeliveryStage = 'ONROUTE' THEN c.OrderValue ELSE 0 END) AS DECIMAL(18, 2)) AS DuringDeliveryValueOnRoute,
        CAST(SUM(CASE WHEN c.IsBacklog = 1 AND c.DuringDeliveryStage = 'ATCUST'  THEN c.OrderValue ELSE 0 END) AS DECIMAL(18, 2)) AS DuringDeliveryValueAtCustomer,
        CAST(SUM(CASE WHEN c.IsBacklog = 1 AND c.DuringDeliveryStage IS NOT NULL THEN c.OrderValue ELSE 0 END) AS DECIMAL(18, 2)) AS DuringDeliveryValueTotal
    FROM #calc c
    LEFT JOIN #store st ON st.BranchCode = c.BranchCode
    GROUP BY c.BranchCode WITH ROLLUP
    ORDER BY IsSummaryRow, Store
    OPTION (RECOMPILE);
 
    DROP TABLE IF EXISTS #store;
    DROP TABLE IF EXISTS #calc;
    DROP TABLE IF EXISTS #statuslog;
    DROP TABLE IF EXISTS #ord;
END
GO