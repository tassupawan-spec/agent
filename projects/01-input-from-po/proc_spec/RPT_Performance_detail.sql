SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[RPT_OrderLeadtimeBacklogDetail]
    @BUCode       VARCHAR(20)   = NULL,
    @BranchCode   VARCHAR(20)   = NULL,
    @DateFrom     DATE          = NULL,
    @DateTo       DATE          = NULL,
    @OrderType    VARCHAR(30)   = 'ALL'     -- ช่องที่คลิกมาจาก List (ชื่อค่าตาม STS เช่น OrderLead2Day) - ALL = ทั้ง 2 section
AS
BEGIN
    SET NOCOUNT ON;
 
    SET @BUCode      = NULLIF(LTRIM(RTRIM(@BUCode)), '');
    IF @BUCode IS NULL SET @BUCode = 'CFW';
    SET @BranchCode  = NULLIF(LTRIM(RTRIM(@BranchCode)), '');
 
    -- ช่องที่คลิก: ค่าที่รับ (ไม่สนตัวพิมพ์เล็กใหญ่) - STS ใช้ OrderLead2Day ค่าอื่นตั้งชื่อตาม pattern เดียวกัน
    --   OrderOntime, OrderDelay, OrderLead0Day, OrderLead1Day, OrderLead2Day, OrderLead3Day, OrderLeadOver3Day,
    --   AvgOrderHr (ช่อง Average Order Leadtime by Hr. = order ที่ส่งสำเร็จทั้งหมด ซึ่งเป็นตัวหารของค่าเฉลี่ย),
    --   BacklogTotal, Backlog1Day, Backlog2Day, Backlog3Day, BacklogOver3Day, ALL
    SET @OrderType = UPPER(ISNULL(NULLIF(LTRIM(RTRIM(@OrderType)), ''), 'ALL'));
    IF @OrderType NOT IN ('ALL',
                          'ORDERONTIME', 'ORDERDELAY', 'AVGORDERHR',
                          'ORDERLEAD0DAY', 'ORDERLEAD1DAY', 'ORDERLEAD2DAY', 'ORDERLEAD3DAY', 'ORDERLEADOVER3DAY',
                          'BACKLOGTOTAL', 'BACKLOG1DAY', 'BACKLOG2DAY', 'BACKLOG3DAY', 'BACKLOGOVER3DAY')
        THROW 50001, 'RPT_OrderLeadtimeBacklogDetail: invalid @OrderType', 1;
 
    IF @DateFrom IS NULL SET @DateFrom = CAST(DATEADD(DD, -1, GETDATE()) AS DATE);
    IF @DateTo   IS NULL SET @DateTo   = @DateFrom;
 
    DECLARE @DateToExclusive DATE = DATEADD(DAY, 1, @DateTo);
    -- ค่าคงที่ - ต้องเท่ากับ List เสมอ (07/09 ตัด @SlaHours/@BacklogAsOf ออกจาก parameter)
    DECLARE @SlaHours    INT  = 1;
    DECLARE @SlaMinutes  INT  = @SlaHours * 60;
    DECLARE @BacklogAsOf DATE = @DateTo;
 
    -- หัวรายงาน (H1-H3 เหมือน List ต่างแค่คำว่า Detail)
    DECLARE @H1 NVARCHAR(200) = N'Order Lead-Time & Backlog Report Detail';
    DECLARE @H2 NVARCHAR(500), @H3 NVARCHAR(200);
 
    -- ชื่อสาขาจาก master ของสาขาที่เลือกเข้ามาดึง (BA เคาะ 07/09: H2 และ Store ยึดตาม @BranchCode)
    -- map H2 -> NameLocal, Store -> BranchName เหมือน List (ยืนยันคอลัมน์ด้วย perfcheck C1)
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
    IF @BranchCode IS NOT NULL AND @StoreName IS NULL SET @StoreName = @BranchCode;
 
    SET @H3 = N'รายงานประจำวันที่ ' + FORMAT(@DateFrom, 'dd/MM/yyyy')
            + N' ถึง ' + FORMAT(@DateTo, 'dd/MM/yyyy');
 
    -- ============================================================================
    -- ขั้นที่ 1-3: คัดลอกจาก RPT_OrderLeadtimeBacklog ห้ามแก้ให้ต่างกัน
    -- ============================================================================
 
    -- ขั้นที่ 1: ชุด order ตั้งต้น = order ที่ slot (StartTime) อยู่ในช่วงที่ค้นหา
    DROP TABLE IF EXISTS #ord;
 
    SELECT
        o.ID                       AS dOrderID,
        o.OrderNumber              AS OrderNumber,
        o.PlaceCode_Sell           AS BranchCode,
        o.StatusCode               AS StatusCode,
        CAST(o.StartTime AS DATE)  AS SlotDate,
        o.EndTime                  AS SlotEndTime,
        o.OrderDate                AS OrderCreatedTime,   -- "Order Created Time" = OrderDate (เคาะ 07/09 - เดิม CreateDate)
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
    CREATE NONCLUSTERED INDEX IX_ord_OrderNumber ON #ord (OrderNumber) INCLUDE (dOrderID);
 
    -- ขั้นที่ 2: เวลาเปลี่ยนสถานะระดับ order (pivot จาก D_StatusLog รอบเดียว)
    DROP TABLE IF EXISTS #statuslog;
 
    SELECT
        t.dOrderID,
        MAX(CASE WHEN l.StatusCode = '18000' THEN l.CreateDate END) AS DeliveredTime
    INTO #statuslog
    FROM #ord t
    JOIN D_StatusLog l
          ON l.OrderNumber = t.OrderNumber
         AND l.StatusCode = '18000'
    GROUP BY t.dOrderID
    OPTION (RECOMPILE);
 
    CREATE UNIQUE CLUSTERED INDEX IX_statuslog_dOrderID ON #statuslog (dOrderID);
 
    -- ขั้นที่ 3: จัด bucket ต่อ order (ทั้ง lead time และ backlog)
    DROP TABLE IF EXISTS #calc;
 
    SELECT
        t.dOrderID,
        t.BranchCode,
        t.OrderValue,
        CASE WHEN s.DeliveredTime IS NOT NULL
              AND t.StatusCode = '18000' THEN 1 ELSE 0 END AS IsDelivered,
        DATEDIFF(MINUTE, t.SlotEndTime, s.DeliveredTime)      AS LateMinutes,
        DATEDIFF(MINUTE, t.OrderCreatedTime, s.DeliveredTime) AS LeadMinutes,
        -- รายการ code และเหตุผลอยู่ใน comment ของ List (ขั้นที่ 3) - ต้องเหมือนกันเป๊ะ
        CASE WHEN t.StatusCode NOT IN ('18000', '18001',
                                       '13004', '17002',
                                       '13090', '13091', '19000', '19001', '19002', '19040', '19050', '19051',
                                       '19100', '19101', '19180')
             THEN 1 ELSE 0 END AS IsBacklog,
        DATEDIFF(DAY, t.SlotDate, @BacklogAsOf) AS BacklogAgeDays,
        CASE WHEN t.StatusCode IN ('15120', '15180')                   THEN 'ATCUST'
             WHEN t.StatusCode IN ('15110', '15111', '15112', '15113') THEN 'ONROUTE'
             ELSE NULL END AS DuringDeliveryStage,
        s.DeliveredTime
    INTO #calc
    FROM #ord t
    LEFT JOIN #statuslog s ON s.dOrderID = t.dOrderID
    OPTION (RECOMPILE);
 
    -- ============================================================================
    -- จบส่วนที่คัดลอกจาก List
    -- ============================================================================
 
    -- ขั้นที่ 4: ติดป้าย Section/Bucket ต่อ order
    -- เงื่อนไขแต่ละ bucket ต้องเป็นสูตรเดียวกับ SUM(CASE ...) ใน SELECT สุดท้ายของ List
    -- order 1 ใบตกได้ section เดียว (IsDelivered กับ IsBacklog ไม่ทับกันเพราะเช็ค StatusCode คนละชุด)
    DROP TABLE IF EXISTS #pick;
 
    SELECT
        c.dOrderID, c.BranchCode, c.OrderValue, c.DeliveredTime, c.LateMinutes, c.BacklogAgeDays,
        CASE WHEN c.IsDelivered = 1 THEN 1 ELSE 2 END                                   AS SectionOrder,
        CASE WHEN c.IsDelivered = 1 THEN 'LEADTIME' ELSE 'BACKLOG' END                  AS SectionCode,
        CASE WHEN c.IsDelivered = 1 THEN N'Order Lead time' ELSE N'Backlog' END          AS SectionName,
        -- bucket: ฝั่ง lead time นับจาก End Time slot / ฝั่ง backlog นับอายุจาก Slot Date ถึง @BacklogAsOf
        CASE WHEN c.IsDelivered = 1 THEN
                 CASE WHEN c.LateMinutes <=    0 THEN 0
                      WHEN c.LateMinutes <= 1440 THEN 1
                      WHEN c.LateMinutes <= 2880 THEN 2
                      WHEN c.LateMinutes <= 4320 THEN 3
                      ELSE 4 END
             ELSE
                 CASE WHEN c.BacklogAgeDays <= 1 THEN 1
                      WHEN c.BacklogAgeDays  = 2 THEN 2
                      WHEN c.BacklogAgeDays  = 3 THEN 3
                      ELSE 4 END
        END                                                                             AS BucketOrder,
        CASE WHEN c.IsDelivered = 1 THEN
                 CASE WHEN c.LateMinutes <=    0 THEN 'DAY0'
                      WHEN c.LateMinutes <= 1440 THEN 'DAY1'
                      WHEN c.LateMinutes <= 2880 THEN 'DAY2'
                      WHEN c.LateMinutes <= 4320 THEN 'DAY3'
                      ELSE 'OVER3' END
             ELSE
                 CASE WHEN c.BacklogAgeDays <= 1 THEN 'DAY1'
                      WHEN c.BacklogAgeDays  = 2 THEN 'DAY2'
                      WHEN c.BacklogAgeDays  = 3 THEN 'DAY3'
                      ELSE 'OVER3' END
        END                                                                             AS BucketCode,
        CASE WHEN c.IsDelivered = 1 THEN
                 CASE WHEN c.LateMinutes <=    0 THEN N'0 Day'
                      WHEN c.LateMinutes <= 1440 THEN N'1 Day'
                      WHEN c.LateMinutes <= 2880 THEN N'2 Days'
                      WHEN c.LateMinutes <= 4320 THEN N'3 Days'
                      ELSE N'> 3 Days' END
             ELSE
                 CASE WHEN c.BacklogAgeDays <= 1 THEN N'1 Day'
                      WHEN c.BacklogAgeDays  = 2 THEN N'2 Days'
                      WHEN c.BacklogAgeDays  = 3 THEN N'3 Days'
                      ELSE N'> 3 Days' END
        END                                                                             AS BucketName,
        -- ฝั่ง lead time: Ontime/Delay ตาม SLA (ช่อง #Ontime / #Delay ใน List)
        CASE WHEN c.IsDelivered = 1 THEN
                 CASE WHEN c.LateMinutes <= @SlaMinutes THEN N'Ontime' ELSE N'Delay' END
             ELSE NULL END                                                              AS OntimeStatus,
        -- ฝั่ง backlog: ขั้นตอนระหว่างจัดส่ง (ช่อง Value by During delivery ใน List)
        CASE WHEN c.IsDelivered = 0 THEN c.DuringDeliveryStage ELSE NULL END           AS DuringDeliveryCode,
        CASE WHEN c.IsDelivered = 0 THEN
                 CASE c.DuringDeliveryStage
                      WHEN 'ONROUTE' THEN N'อยู่ระหว่างการจัดส่ง/บริการ'
                      WHEN 'ATCUST'  THEN N'ถึงบ้านลูกค้ากำลังจัดส่ง'
                      ELSE NULL END
             ELSE NULL END                                                              AS DuringDeliveryName
    INTO #pick
    FROM #calc c
    WHERE c.IsDelivered = 1 OR c.IsBacklog = 1;
 
    CREATE UNIQUE CLUSTERED INDEX IX_pick_dOrderID ON #pick (dOrderID);
 
    -- ขั้นที่ 4.1: กรองตามช่องที่คลิกจาก List (ใช้ code ที่คำนวณไว้แล้ว ไม่เขียนเงื่อนไขซ้ำ -> ตรงกับ List เสมอ)
    -- เปิดตรงด้วย ALL จะข้ามขั้นนี้และได้ทั้ง 2 section
    IF @OrderType <> 'ALL'
        DELETE FROM #pick
        WHERE NOT (
               (@OrderType = 'AVGORDERHR'        AND SectionCode = 'LEADTIME')
            OR (@OrderType = 'ORDERONTIME'       AND SectionCode = 'LEADTIME' AND OntimeStatus = N'Ontime')
            OR (@OrderType = 'ORDERDELAY'        AND SectionCode = 'LEADTIME' AND OntimeStatus = N'Delay')
            OR (@OrderType = 'ORDERLEAD0DAY'     AND SectionCode = 'LEADTIME' AND BucketCode = 'DAY0')
            OR (@OrderType = 'ORDERLEAD1DAY'     AND SectionCode = 'LEADTIME' AND BucketCode = 'DAY1')
            OR (@OrderType = 'ORDERLEAD2DAY'     AND SectionCode = 'LEADTIME' AND BucketCode = 'DAY2')
            OR (@OrderType = 'ORDERLEAD3DAY'     AND SectionCode = 'LEADTIME' AND BucketCode = 'DAY3')
            OR (@OrderType = 'ORDERLEADOVER3DAY' AND SectionCode = 'LEADTIME' AND BucketCode = 'OVER3')
            OR (@OrderType = 'BACKLOGTOTAL'      AND SectionCode = 'BACKLOG')
            OR (@OrderType = 'BACKLOG1DAY'       AND SectionCode = 'BACKLOG'  AND BucketCode = 'DAY1')
            OR (@OrderType = 'BACKLOG2DAY'       AND SectionCode = 'BACKLOG'  AND BucketCode = 'DAY2')
            OR (@OrderType = 'BACKLOG3DAY'       AND SectionCode = 'BACKLOG'  AND BucketCode = 'DAY3')
            OR (@OrderType = 'BACKLOGOVER3DAY'   AND SectionCode = 'BACKLOG'  AND BucketCode = 'OVER3')
        );
 
    -- ขั้นที่ 4.5: ชื่อสาขาต่อ order (ใช้เฉพาะกรณี @BranchCode = NULL ดึงทุกสาขา) - เหมือน List
    DROP TABLE IF EXISTS #store;
 
    SELECT
        c.BranchCode,
        MAX(pl.BranchName) AS StoreName
    INTO #store
    FROM (SELECT DISTINCT BranchCode FROM #pick) c
    LEFT JOIN M_Place pl ON pl.PlaceCode = c.BranchCode
                        AND pl.BUCode    = @BUCode
                        AND pl.IsActive  = 1
    GROUP BY c.BranchCode;
 
    CREATE UNIQUE CLUSTERED INDEX IX_store_BranchCode ON #store (BranchCode);
 
    -- ขั้นที่ 5: ดึงรายละเอียด order 13 คอลัมน์ตาม requirement + คอลัมน์จัดกลุ่ม
    -- เรียง: Section (Lead time ก่อน Backlog) > Bucket (0 Day -> > 3 Days) > Slot Date > เลขที่ใบงาน
    -- STS ไม่มีแถว Summary ในหน้า Detail - ถ้าต้องการยอดรวมต่อ section/bucket ให้ RDL ทำ group footer
    SELECT
        ROW_NUMBER() OVER (ORDER BY p.SectionOrder, p.BucketOrder, o.StartTime, o.OrderNumber) AS RowNum,
        @H1                                                           AS H1,
        @H2                                                           AS H2,
        @H3                                                           AS H3,
        -- คอลัมน์จัดกลุ่มสำหรับ RDL (group ชั้น 1 = Section, ชั้น 2 = Bucket)
        p.SectionOrder                                                AS SectionOrder,
        p.SectionCode                                                 AS SectionCode,
        p.SectionName                                                 AS SectionName,
        p.BucketOrder                                                 AS BucketOrder,
        p.BucketCode                                                  AS BucketCode,
        p.BucketName                                                  AS BucketName,
        p.OntimeStatus                                                AS OntimeStatus,        -- เฉพาะ Lead time
        p.DuringDeliveryCode                                          AS DuringDeliveryCode,  -- เฉพาะ Backlog
        p.DuringDeliveryName                                          AS DuringDeliveryName,  -- เฉพาะ Backlog
        -- 13 คอลัมน์ตาม requirement
        -- Store = ชื่อจาก master ตรงๆ (BA เคาะ 07/09) - เลือกสาขาเดียวใช้ชื่อของ @BranchCode
        CASE WHEN @BranchCode IS NOT NULL THEN @StoreName
             ELSE ISNULL(st.StoreName, p.BranchCode) END              AS Store,
        o.OrderNumber                                                 AS JobNumber,        -- เลขที่ใบงาน (SNRJ...)
        o.RefWebOrder                                                 AS OrderNumber,      -- เลขที่ Order (WP.../XB.../XC.../TT...)
        o.OrderDate                                                   AS OrderDate,        -- เคาะ 07/09 ใช้ OrderDate; RDL format dd/MM/yyyy HH:mm:ss
        CAST(o.StartTime AS DATE)                                     AS SlotDate,         -- RDL format dd/MM/yyyy
        CONVERT(CHAR(5), o.StartTime, 108) + ' - '
            + CONVERT(CHAR(5), o.EndTime, 108)                        AS SlotTime,         -- "12:00 - 12:00" ตาม STS
        ISNULL(ms.StatusDisplayLocal, o.StatusCode)                   AS OrderStatus,
        -- Address: ต่อจากส่วนย่อยของ D_Order (ไม่มีคอลัมน์ที่อยู่เต็ม) - STS ขึ้นต้นด้วย "เลขที่ " แล้วตามด้วยส่วนที่เหลือ
        -- TBC ข้อ D1: STS บางแถวมีชื่อบริษัทอยู่ในเลขที่บ้าน แสดงว่า OMS ยัดข้อความมาใน HouseNumber - เราโชว์ตามที่เก็บ
        LTRIM(RTRIM(
              ISNULL(N'เลขที่ ' + NULLIF(LTRIM(RTRIM(o.HouseNumber)), N'') + N' ', N'')
            + ISNULL(N'หมู่ '   + NULLIF(LTRIM(RTRIM(o.Moo)),         N'') + N' ', N'')
            + ISNULL(            NULLIF(LTRIM(RTRIM(o.Village)),     N'') + N' ', N'')
            + ISNULL(N'ซอย '   + NULLIF(LTRIM(RTRIM(o.Soi)),         N'') + N' ', N'')
            + ISNULL(N'ถนน '   + NULLIF(LTRIM(RTRIM(o.Road)),        N'') + N' ', N'')
            + ISNULL(            NULLIF(LTRIM(RTRIM(o.SubDistrictName)), N'') + N' ', N'')
            + ISNULL(            NULLIF(LTRIM(RTRIM(o.DistrictName)),    N'') + N' ', N'')
            + ISNULL(            NULLIF(LTRIM(RTRIM(o.ProvinceName)),    N'') + N' ', N'')
            + ISNULL(            NULLIF(LTRIM(RTRIM(o.Zipcode)),         N''),        N'')
        ))                                                            AS Address,
        o.SubDistrictName                                             AS SubDistrict,
        o.DistrictName                                                AS District,
        o.ProvinceName                                                AS Province,
        o.Zipcode                                                     AS Postcode,
        CAST(p.OrderValue AS DECIMAL(18, 2))                          AS Value,            -- ยอดเดียวกับ List (TotalNet)
        -- คอลัมน์ช่วย QA (ไม่ต้องโชว์ใน RDL): ใช้ไล่ว่า order ตก bucket นี้เพราะอะไร
        p.DeliveredTime                                               AS DeliveredTime,
        p.LateMinutes                                                 AS LateMinutes,
        p.BacklogAgeDays                                              AS BacklogAgeDays
    FROM #pick p
    JOIN D_Order o          ON o.ID = p.dOrderID
    LEFT JOIN M_Status ms   ON ms.StatusCode = o.StatusCode
    LEFT JOIN #store st     ON st.BranchCode = p.BranchCode
    ORDER BY RowNum
    OPTION (RECOMPILE);
 
    DROP TABLE IF EXISTS #store;
    DROP TABLE IF EXISTS #pick;
    DROP TABLE IF EXISTS #calc;
    DROP TABLE IF EXISTS #statuslog;
    DROP TABLE IF EXISTS #ord;
END
GO