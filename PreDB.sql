ALTER DATABASE "F:\vs-workspace\DIMS\Database.mdf" SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

GO

ALTER DATABASE "F:\vs-workspace\DIMS\Database.mdf" COLLATE Chinese_PRC_CI_AS;

GO

ALTER DATABASE "F:\vs-workspace\DIMS\Database.mdf" SET MULTI_USER;

GO

CREATE TABLE Staffs( -- 职员表
	StaffId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT (NEWID()) NOT NULL, -- 标识
	StaffNo VARCHAR(32) UNIQUE NOT NULL, -- 编号
	StaffName NVARCHAR(32) NOT NULL, -- 姓名
	StaffPwd VARCHAR(32) DEFAULT ('00000000') NOT NULL -- 登陆密码
);

CREATE TABLE Departments( -- 部门表
	DepartmentId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT (NEWID()) NOT NULL, -- 标识
	DepartmentName NVARCHAR(32) UNIQUE NOT NULL -- 名称
);

CREATE TABLE StaffsInDepartments( -- 职员-所属部门关系表
	StaffId UNIQUEIDENTIFIER NOT NULL, -- 职员标识
	DepartmentId UNIQUEIDENTIFIER NOT NULL, -- 所属部门标识
	PRIMARY KEY (StaffId, DepartmentId)
);

CREATE TABLE Suppliers( -- 供应商表
	SupplierId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT (NEWID()) NOT NULL, -- 标识
	SupplierName NVARCHAR(32) UNIQUE NOT NULL, -- 名称
	SupplierAddress NVARCHAR(64) NOT NULL, -- 地址
	SupplierPhone VARCHAR(32) NOT NULL -- 电话
);

CREATE TABLE Drugs( -- 药品表
	DrugId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT (NEWID()) NOT NULL, -- 标识
	DrugName NVARCHAR(32) UNIQUE NOT NULL, -- 名称
	DrugLife SMALLINT CHECK (DrugLife > 0) NOT NULL -- 保质期 (天数)
);

CREATE TABLE InDrugs( -- 库存药品表
	DrugId UNIQUEIDENTIFIER NOT NULL, -- 药品标识
	DrugBatch DATETIME NOT NULL, -- 药品批次
	SupplierId UNIQUEIDENTIFIER NOT NULL, -- 供应商标识
	StaffId_In UNIQUEIDENTIFIER NOT NULL, -- 入库职员标识
	DrugInTime DATETIME DEFAULT GETDATE() NOT NULL, -- 入库时间
	DrugNum SMALLINT CHECK (DrugNum > 0) NOT NULL, -- 药品数量
	PRIMARY KEY(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime),
	FOREIGN KEY (DrugId) REFERENCES Drugs(DrugId),
	FOREIGN KEY (SupplierId) REFERENCES Suppliers(SupplierId),
	FOREIGN KEY (StaffId_In) REFERENCES Staffs(StaffId),
	CHECK (DATEDIFF(SS, DrugBatch, DrugInTime) >= 0)
);

CREATE TABLE OutDrugs( -- 已出库药品表
	DrugId UNIQUEIDENTIFIER NOT NULL, -- 药品标识
	DrugBatch DATETIME NOT NULL, -- 药品批次
	SupplierId UNIQUEIDENTIFIER NOT NULL, -- 供应商标识
	StaffId_In UNIQUEIDENTIFIER NOT NULL, -- 入库职员标识
	DrugInTime DATETIME DEFAULT GETDATE() NOT NULL, -- 入库时间
	StaffId_Out UNIQUEIDENTIFIER NOT NULL, -- 出库职员标识
	DrugOutTime DATETIME DEFAULT GETDATE() NOT NULL, -- 出库时间
	StaffId_Handover UNIQUEIDENTIFIER NOT NULL, -- 交接职员标识
	DrugNum SMALLINT CHECK (DrugNum > 0) NOT NULL, -- 药品数量
	PRIMARY KEY(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover),
	FOREIGN KEY (DrugId) REFERENCES Drugs(DrugId),
	FOREIGN KEY (SupplierId) REFERENCES Suppliers(SupplierId),
	FOREIGN KEY (StaffId_In) REFERENCES Staffs(StaffId),
	FOREIGN KEY (StaffId_Out) REFERENCES Staffs(StaffId),
	FOREIGN KEY (StaffId_Handover) REFERENCES Staffs(StaffId),
	CHECK (DATEDIFF(SS, DrugBatch, DrugInTime) >= 0),
	CHECK (DATEDIFF(SS, DrugInTime, DrugOutTime) >= 0)
);

CREATE TABLE DestroyedDrugs( -- 已销毁药品表
	DrugId UNIQUEIDENTIFIER NOT NULL, -- 药品标识
	DrugBatch DATETIME NOT NULL, -- 药品批次
	SupplierId UNIQUEIDENTIFIER NOT NULL, -- 供应商标识
	StaffId_In UNIQUEIDENTIFIER NOT NULL, -- 入库职员标识
	DrugInTime DATETIME DEFAULT GETDATE() NOT NULL, -- 入库时间
	StaffId_Destroy UNIQUEIDENTIFIER NOT NULL, -- 销毁职员标识
	DrugDestroyTime DATETIME DEFAULT GETDATE() NOT NULL, -- 销毁时间
	DrugNum SMALLINT CHECK (DrugNum > 0) NOT NULL, -- 药品数量
	PRIMARY KEY(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime),
	FOREIGN KEY (DrugId) REFERENCES Drugs(DrugId),
	FOREIGN KEY (SupplierId) REFERENCES Suppliers(SupplierId),
	FOREIGN KEY (StaffId_In) REFERENCES Staffs(StaffId),
	FOREIGN KEY (StaffId_Destroy) REFERENCES Staffs(StaffId),
	CHECK (DATEDIFF(SS, DrugBatch, DrugInTime) >= 0),
	CHECK (DATEDIFF(SS, DrugInTime, DrugDestroyTime) >= 0)
);

-- = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

GO

CREATE VIEW View_StaffsDetails -- 职员细节视图
AS
SELECT s.StaffId, s.StaffNo, s.StaffName, s.StaffPwd, d.DepartmentId, d.DepartmentName
FROM Staffs s, StaffsInDepartments sd, Departments d
WHERE s.StaffId = sd.StaffId AND sd.DepartmentId = d.DepartmentId;

GO

CREATE VIEW View_StaffsInWarehouseDetails -- 药库职员细节视图
AS
SELECT *, (s.StaffNo + ' ' + s.StaffName) AS FullTitle
FROM View_StaffsDetails s
WHERE s.DepartmentName = '药库';

GO

CREATE VIEW View_NonStaffsInWarehouseDetails -- 非药库职员细节视图
AS
SELECT *, (s.DepartmentName + ' ' + s.StaffNo + ' ' + s.StaffName) AS FullTitle
FROM View_StaffsDetails s
WHERE s.DepartmentName != '药库';

GO

CREATE VIEW View_InDrugsSummary -- 库存药品汇总视图
AS
SELECT d.DrugId, d.DrugName, d.DrugLife, COALESCE(SUM(i.DrugNum), 0) AS DrugNum
FROM Drugs d LEFT OUTER JOIN InDrugs i ON d.DrugId = i.DrugId
GROUP BY d.DrugId, d.DrugName, d.DrugLife;

GO

CREATE VIEW View_InDrugsSummary_LowInventory -- 低库存量库存药品汇总视图
AS
SELECT *
FROM View_InDrugsSummary
WHERE DrugNum < 50;

GO

CREATE VIEW View_InDrugsDetails -- 库存药品细节视图
AS
SELECT d.DrugId, d.DrugName, d.DrugLife, i.DrugBatch, i.SupplierId, s1.SupplierName, i.StaffId_In, s2.StaffName AS StaffName_In, i.DrugInTime, i.DrugNum, (d.DrugLife - DATEDIFF(DAY, i.DrugBatch, GETDATE())) AS RemainingLife
FROM Drugs d, InDrugs i, Suppliers s1, View_StaffsDetails s2
WHERE d.DrugId = i.DrugId AND i.SupplierId = s1.SupplierId AND i.StaffId_In = s2.StaffId;

GO

CREATE VIEW View_InDrugsDetails_Close2Expiry -- 临期库存药品细节视图
AS
SELECT *
FROM View_InDrugsDetails
WHERE RemainingLife < (DrugLife / 10);

GO

CREATE VIEW View_OutDrugsDetails -- 已出库药品细节视图
AS
SELECT d.DrugId, d.DrugName, d.DrugLife, o.DrugBatch, o.SupplierId, s1.SupplierName, o.StaffId_In, s2.StaffName AS StaffName_In, o.DrugInTime, o.StaffId_Out, s3.StaffName AS StaffName_Out, o.DrugOutTime, o.StaffId_Handover, s4.StaffName AS StaffName_Handover, s4.DepartmentId AS DepartmentId_Handover, s4.DepartmentName AS DepartmentName_Handover, o.DrugNum
FROM Drugs d, OutDrugs o, Suppliers s1, View_StaffsDetails s2, View_StaffsDetails s3, View_StaffsDetails s4
WHERE d.DrugId = o.DrugId AND o.SupplierId = s1.SupplierId AND o.StaffId_In = s2.StaffId AND o.StaffId_Out = s3.StaffId AND o.StaffId_Handover = s4.StaffId;

GO

CREATE VIEW View_DestroyedDrugsDetails -- 已销毁药品细节视图
AS
SELECT d.DrugId, d.DrugName, d.DrugLife, dd.DrugBatch, dd.SupplierId, s1.SupplierName, dd.StaffId_In, s2.StaffName AS StaffName_In, dd.DrugInTime, dd.StaffId_Destroy, s3.StaffName AS StaffName_Destroy, dd.DrugDestroyTime, dd.DrugNum
FROM Drugs d, DestroyedDrugs dd, Suppliers s1, View_StaffsDetails s2, View_StaffsDetails s3
WHERE d.DrugId = dd.DrugId AND dd.SupplierId = s1.SupplierId AND dd.StaffId_In = s2.StaffId AND dd.StaffId_Destroy = s3.StaffId;

GO

CREATE VIEW View_AllRecordedDrugsDetails -- 所有药品细节视图
AS
SELECT DrugId, DrugName, DrugLife, DrugBatch, SupplierId, SupplierName, StaffId_In, StaffName_In, DrugInTime, DrugNum, RemainingLife, NULL AS StaffId_Out, NULL AS StaffName_Out, NULL AS DrugOutTime, NULL AS StaffId_Handover, NULL AS StaffName_Handover, NULL AS DepartmentId_Handover, NULL AS DepartmentName_Handover, NULL AS StaffId_Destroy, NULL AS StaffName_Destroy, NULL AS DrugDestroyTime
FROM View_InDrugsDetails
UNION
SELECT DrugId, DrugName, DrugLife, DrugBatch, SupplierId, SupplierName, StaffId_In, StaffName_In, DrugInTime, DrugNum, NULL AS RemainingLife, StaffId_Out, StaffName_Out, DrugOutTime, StaffId_Handover, StaffName_Handover, DepartmentId_Handover, DepartmentName_Handover, NULL AS StaffId_Destroy, NULL AS StaffName_Destroy, NULL AS DrugDestroyTime
FROM View_OutDrugsDetails
UNION
SELECT DrugId, DrugName, DrugLife, DrugBatch, SupplierId, SupplierName, StaffId_In, StaffName_In, DrugInTime, DrugNum, NULL AS RemainingLife, NULL AS StaffId_Out, NULL AS StaffName_Out, NULL AS DrugOutTime, NULL AS StaffId_Handover, NULL AS StaffName_Handover, NULL AS DepartmentId_Handover, NULL AS DepartmentName_Handover, StaffId_Destroy, StaffName_Destroy, DrugDestroyTime
FROM View_DestroyedDrugsDetails;

GO

-- = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

GO

-- 将库存药品出库
CREATE PROCEDURE sp_OutInDrugs @DrugId UNIQUEIDENTIFIER, @DrugNumSum INT, @StaffId_Out UNIQUEIDENTIFIER, @DrugOutTime DATETIME, @StaffId_Handover UNIQUEIDENTIFIER, @returnValue SMALLINT OUTPUT
AS
SET XACT_ABORT ON
BEGIN TRAN
DECLARE @DrugBatch DATETIME;
DECLARE @SupplierId UNIQUEIDENTIFIER;
DECLARE @StaffId_In UNIQUEIDENTIFIER;
DECLARE @DrugInTime DATETIME;
DECLARE @DrugNum SMALLINT;
SET @returnValue = 0;
DECLARE DrugBatches CURSOR FOR SELECT DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum
								FROM InDrugs
								WHERE DrugId = @DrugId
								ORDER BY DrugBatch ASC;
OPEN DrugBatches;
FETCH NEXT FROM DrugBatches INTO @DrugBatch, @SupplierId, @StaffId_In, @DrugInTime, @DrugNum;
WHILE @@FETCH_STATUS = 0 AND @DrugNumSum > 0
BEGIN
	IF @DrugNum >= @DrugNumSum
	BEGIN
		IF @DrugNum > @DrugNumSum
		BEGIN
			UPDATE InDrugs
			SET DrugNum = (DrugNum - @DrugNumSum)
			WHERE DrugId = @DrugId AND DrugBatch = @DrugBatch AND SupplierId = @SupplierId AND StaffId_In = @StaffId_In AND DrugInTime = @DrugInTime;
			SET @returnValue = @returnValue + @@error;
		END
		ELSE
		BEGIN
			DELETE FROM InDrugs
			WHERE DrugId = @DrugId AND DrugBatch = @DrugBatch AND SupplierId = @SupplierId AND StaffId_In = @StaffId_In AND DrugInTime = @DrugInTime;
			SET @returnValue = @returnValue + @@error;
		END
		INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
			VALUES(@DrugId, @DrugBatch, @SupplierId, @StaffId_In, @DrugInTime, @StaffId_Out, @DrugOutTime, @StaffId_Handover, @DrugNumSum);
		SET @returnValue = @returnValue + @@error;
		SET @DrugNumSum = 0;
	END
	ELSE
	BEGIN
		SET @DrugNumSum = @DrugNumSum - @DrugNum;
		DELETE FROM InDrugs
		WHERE DrugId = @DrugId AND DrugBatch = @DrugBatch AND SupplierId = @SupplierId AND StaffId_In = @StaffId_In AND DrugInTime = @DrugInTime;
		INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
			VALUES(@DrugId, @DrugBatch, @SupplierId, @StaffId_In, @DrugInTime, @StaffId_Out, @DrugOutTime, @StaffId_Handover, @DrugNum);
		SET @returnValue = @returnValue + @@error;
	END
	FETCH NEXT FROM DrugBatches INTO @DrugBatch, @SupplierId, @StaffId_In, @DrugInTime, @DrugNum;
END
CLOSE DrugBatches;
DEALLOCATE DrugBatches;
SET @returnValue = @returnValue + @@error;
COMMIT TRAN

GO

-- 将库存药品销毁
CREATE PROCEDURE sp_DestroyInDrugs @DrugId UNIQUEIDENTIFIER, @DrugBatch DATETIME, @SupplierId UNIQUEIDENTIFIER, @StaffId_In UNIQUEIDENTIFIER, @DrugInTime DATETIME, @StaffId_Destroy UNIQUEIDENTIFIER, @DrugDestroyTime DATETIME, @returnValue SMALLINT OUTPUT
AS
SET XACT_ABORT ON
BEGIN TRAN
DECLARE @DrugNum SMALLINT;
SET @returnValue = 0;
SELECT @DrugNum = DrugNum
FROM InDrugs
WHERE DrugId = @DrugId AND DrugBatch = @DrugBatch AND SupplierId = @SupplierId AND StaffId_In = @StaffId_In AND DrugInTime = @DrugInTime;
SET @returnValue = @returnValue + @@error;
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, @DrugBatch, @SupplierId, @StaffId_In, @DrugInTime, @StaffId_Destroy, @DrugDestroyTime, @DrugNum);
SET @returnValue = @returnValue + @@error;
DELETE FROM InDrugs
WHERE DrugId = @DrugId AND DrugBatch = @DrugBatch AND SupplierId = @SupplierId AND StaffId_In = @StaffId_In AND DrugInTime = @DrugInTime;
SET @returnValue = @returnValue + @@error;
COMMIT TRAN

GO

-- = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

INSERT INTO Staffs(StaffNo, StaffName, StaffPwd) VALUES('S2017051601', '李勇', 'S2017051601');
INSERT INTO Staffs(StaffNo, StaffName, StaffPwd) VALUES('S2017051602', '刘晨', 'S2017051602');
INSERT INTO Staffs(StaffNo, StaffName, StaffPwd) VALUES('S2017051603', '王敏', 'S2017051603');
INSERT INTO Staffs(StaffNo, StaffName, StaffPwd) VALUES('S2017051604', '张立', 'S2017051604');
INSERT INTO Staffs(StaffNo, StaffName, StaffPwd) VALUES('S2017051605', '张三', 'S2017051605');
INSERT INTO Staffs(StaffNo, StaffName, StaffPwd) VALUES('S2017051606', '李四', 'S2017051606');
INSERT INTO Staffs(StaffNo, StaffName, StaffPwd) VALUES('S2017051607', '王红', 'S2017051607');
INSERT INTO Staffs(StaffNo, StaffName, StaffPwd) VALUES('S2017051608', '何琳', 'S2017051608');
INSERT INTO Staffs(StaffNo, StaffName, StaffPwd) VALUES('S2017051609', '黎敏', 'S2017051609');
INSERT INTO Staffs(StaffNo, StaffName, StaffPwd) VALUES('S2017051610', '张飞', 'S2017051610');

-- = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

INSERT INTO Staffs(StaffNo, StaffName, StaffPwd) VALUES('C2020052501', '李敏', 'C2020052501');
INSERT INTO Staffs(StaffNo, StaffName, StaffPwd) VALUES('C2020052502', '张辉', 'C2020052502');
INSERT INTO Staffs(StaffNo, StaffName, StaffPwd) VALUES('C2020052503', '白磊', 'C2020052503');

INSERT INTO Staffs(StaffNo, StaffName, StaffPwd) VALUES('W2020052504', '杜鹃', 'W2020052504');
INSERT INTO Staffs(StaffNo, StaffName, StaffPwd) VALUES('W2020052505', '李强', 'W2020052505');
INSERT INTO Staffs(StaffNo, StaffName, StaffPwd) VALUES('W2020052506', '赵栋', 'W2020052506');

INSERT INTO Staffs(StaffNo, StaffName, StaffPwd) VALUES('H2020052507', '黄鑫', 'H2020052507');
INSERT INTO Staffs(StaffNo, StaffName, StaffPwd) VALUES('H2020052508', '郝文', 'H2020052508');
INSERT INTO Staffs(StaffNo, StaffName, StaffPwd) VALUES('H2020052509', '彭晓', 'H2020052509');

-- = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

INSERT INTO Departments(DepartmentName) Values('药库');
INSERT INTO Departments(DepartmentName) Values('门诊中药房');
INSERT INTO Departments(DepartmentName) Values('门诊西药房');
INSERT INTO Departments(DepartmentName) Values('住院药房');

-- = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

DECLARE @DepartmentId UNIQUEIDENTIFIER;
DECLARE @StaffId UNIQUEIDENTIFIER;

SELECT @DepartmentId = DepartmentId FROM Departments WHERE DepartmentName = '药库';
DECLARE SStaffs CURSOR FOR SELECT StaffId FROM Staffs WHERE StaffNo LIKE 'S%';
OPEN SStaffs;
FETCH NEXT FROM SStaffs INTO @StaffId;
WHILE @@FETCH_STATUS = 0
BEGIN
	INSERT INTO StaffsInDepartments(StaffId, DepartmentId) VALUES(@StaffId, @DepartmentId);
	FETCH NEXT FROM SStaffs INTO @StaffId;
END
CLOSE SStaffs;
DEALLOCATE SStaffs;

SELECT @DepartmentId = DepartmentId FROM Departments WHERE DepartmentName = '门诊中药房';
DECLARE CStaffs CURSOR FOR SELECT StaffId FROM Staffs WHERE StaffNo LIKE 'C%';
OPEN CStaffs;
FETCH NEXT FROM CStaffs INTO @StaffId;
WHILE @@FETCH_STATUS = 0
BEGIN
	INSERT INTO StaffsInDepartments(StaffId, DepartmentId) VALUES(@StaffId, @DepartmentId);
	FETCH NEXT FROM CStaffs INTO @StaffId;
END
CLOSE CStaffs;
DEALLOCATE CStaffs;

SELECT @DepartmentId = DepartmentId FROM Departments WHERE DepartmentName = '门诊西药房';
DECLARE WStaffs CURSOR FOR SELECT StaffId FROM Staffs WHERE StaffNo LIKE 'W%';
OPEN WStaffs;
FETCH NEXT FROM WStaffs INTO @StaffId;
WHILE @@FETCH_STATUS = 0
BEGIN
	INSERT INTO StaffsInDepartments(StaffId, DepartmentId) VALUES(@StaffId, @DepartmentId);
	FETCH NEXT FROM WStaffs INTO @StaffId;
END
CLOSE WStaffs;
DEALLOCATE WStaffs;

SELECT @DepartmentId = DepartmentId FROM Departments WHERE DepartmentName = '住院药房';
DECLARE HStaffs CURSOR FOR SELECT StaffId FROM Staffs WHERE StaffNo LIKE 'H%';
OPEN HStaffs;
FETCH NEXT FROM HStaffs INTO @StaffId;
WHILE @@FETCH_STATUS = 0
BEGIN
	INSERT INTO StaffsInDepartments(StaffId, DepartmentId) VALUES(@StaffId, @DepartmentId);
	FETCH NEXT FROM HStaffs INTO @StaffId;
END
CLOSE HStaffs;
DEALLOCATE HStaffs;

-- = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

INSERT INTO Suppliers(SupplierName, SupplierAddress, SupplierPhone)
	VALUES('遵义市意通医药有限责任公司', '遵义市沙河小区华南C2栋', '17811941621');
INSERT INTO Suppliers(SupplierName, SupplierAddress, SupplierPhone)
	VALUES('贵州鼎圣药业有限公司', '遵义市红花岗区沙河路B号楼2楼', '17822557252');
INSERT INTO Suppliers(SupplierName, SupplierAddress, SupplierPhone)
	VALUES('贵州国泰医药有限公司', '贵阳市富源北路35号', '17833553673');
INSERT INTO Suppliers(SupplierName, SupplierAddress, SupplierPhone)
	VALUES('铜仁梵天药业有限公司', '铜仁市梵净山大道绿福宫小区', '17845457475');
INSERT INTO Suppliers(SupplierName, SupplierAddress, SupplierPhone)
	VALUES('贵州科渝奇鼎医药有限公司', '贵阳市园林路1号', '17855257965');
INSERT INTO Suppliers(SupplierName, SupplierAddress, SupplierPhone)
	VALUES('贵州振兴医药有限公司贵阳分公司', '贵阳市舒家寨富源中路261号', '17867568686');
INSERT INTO Suppliers(SupplierName, SupplierAddress, SupplierPhone)
	VALUES('国药控股贵州有限公司', '贵阳国家高新技术产业开发区金阳科技产业园', '17837785477');
INSERT INTO Suppliers(SupplierName, SupplierAddress, SupplierPhone)
	VALUES('铜仁新中太药业有限公司', '铜仁市文笔路25号', '17880257080');
INSERT INTO Suppliers(SupplierName, SupplierAddress, SupplierPhone)
	VALUES('贵州省药材公司', '贵阳市富源北路22号A区', '17859030598');
INSERT INTO Suppliers(SupplierName, SupplierAddress, SupplierPhone)
	VALUES('江阴天江药业有限公司', '江阴市经济开发区秦望山路8号', '17829486254');
INSERT INTO Suppliers(SupplierName, SupplierAddress, SupplierPhone)
	VALUES('石阡县天佑中西药有限公司', '石阡县汤山镇河西农贸市场', '17815309574');
INSERT INTO Suppliers(SupplierName, SupplierAddress, SupplierPhone)
	VALUES('贵州弘一医药有限责任公司', '贵阳市青年路70号', '17816037460');

-- = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

INSERT INTO Drugs(DrugName, DrugLife) VALUES('阿莫西林胶囊', 180);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('氨苄西林钠', 120);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('青霉素钠', 90);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('磷霉素钠', 360);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('利伐沙班片', 270);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('头孢拉定胶囊', 120);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('头孢曲松钠', 90);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('头孢吡肟', 180);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('头孢噻肟钠', 480);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('骨筋丸胶囊', 180);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('复方穿心莲片', 360);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('四季感冒片', 360);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('午时茶颗粒', 360);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('十三味马钱子丸', 720);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('氯芬黄敏片', 540);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('痫愈胶囊', 360);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('地高辛', 180);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('替米沙坦片', 360);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('噻奈普汀片', 180);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('复方樟薄软膏', 720);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('利血平', 180);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('克拉霉素片', 360);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('复方消化酶片', 180);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('愈创罂粟待因片', 180);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('伏格列波糖', 180);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('氧氟沙星眼膏', 360);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('莫匹罗星软膏', 360);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('草木犀流浸液片', 360);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('复合维生素片', 180);
INSERT INTO Drugs(DrugName, DrugLife) VALUES('舍雷肽酶肠溶片', 360);

-- = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

DECLARE @StaffInWarehouseId01 UNIQUEIDENTIFIER;
SELECT @StaffInWarehouseId01 = StaffId FROM Staffs WHERE StaffNo = 'S2017051601';
DECLARE @StaffInWarehouseId02 UNIQUEIDENTIFIER;
SELECT @StaffInWarehouseId02 = StaffId FROM Staffs WHERE StaffNo = 'S2017051602';
DECLARE @StaffInWarehouseId03 UNIQUEIDENTIFIER;
SELECT @StaffInWarehouseId03 = StaffId FROM Staffs WHERE StaffNo = 'S2017051603';
DECLARE @StaffInWarehouseId04 UNIQUEIDENTIFIER;
SELECT @StaffInWarehouseId04 = StaffId FROM Staffs WHERE StaffNo = 'S2017051604';
DECLARE @StaffInWarehouseId05 UNIQUEIDENTIFIER;
SELECT @StaffInWarehouseId05 = StaffId FROM Staffs WHERE StaffNo = 'S2017051605';
DECLARE @StaffInWarehouseId06 UNIQUEIDENTIFIER;
SELECT @StaffInWarehouseId06 = StaffId FROM Staffs WHERE StaffNo = 'S2017051606';
DECLARE @StaffInWarehouseId07 UNIQUEIDENTIFIER;
SELECT @StaffInWarehouseId07 = StaffId FROM Staffs WHERE StaffNo = 'S2017051607';
DECLARE @StaffInWarehouseId08 UNIQUEIDENTIFIER;
SELECT @StaffInWarehouseId08 = StaffId FROM Staffs WHERE StaffNo = 'S2017051608';
DECLARE @StaffInWarehouseId09 UNIQUEIDENTIFIER;
SELECT @StaffInWarehouseId09 = StaffId FROM Staffs WHERE StaffNo = 'S2017051609';
DECLARE @StaffInWarehouseId10 UNIQUEIDENTIFIER;
SELECT @StaffInWarehouseId10 = StaffId FROM Staffs WHERE StaffNo = 'S2017051610';

DECLARE @NonStaffInWarehouseId01 UNIQUEIDENTIFIER;
SELECT @NonStaffInWarehouseId01 = StaffId FROM Staffs WHERE StaffNo = 'C2020052501';
DECLARE @NonStaffInWarehouseId02 UNIQUEIDENTIFIER;
SELECT @NonStaffInWarehouseId02 = StaffId FROM Staffs WHERE StaffNo = 'C2020052502';
DECLARE @NonStaffInWarehouseId03 UNIQUEIDENTIFIER;
SELECT @NonStaffInWarehouseId03 = StaffId FROM Staffs WHERE StaffNo = 'C2020052503';
DECLARE @NonStaffInWarehouseId04 UNIQUEIDENTIFIER;
SELECT @NonStaffInWarehouseId04 = StaffId FROM Staffs WHERE StaffNo = 'W2020052504';
DECLARE @NonStaffInWarehouseId05 UNIQUEIDENTIFIER;
SELECT @NonStaffInWarehouseId05 = StaffId FROM Staffs WHERE StaffNo = 'W2020052505';
DECLARE @NonStaffInWarehouseId06 UNIQUEIDENTIFIER;
SELECT @NonStaffInWarehouseId06 = StaffId FROM Staffs WHERE StaffNo = 'W2020052506';
DECLARE @NonStaffInWarehouseId07 UNIQUEIDENTIFIER;
SELECT @NonStaffInWarehouseId07 = StaffId FROM Staffs WHERE StaffNo = 'H2020052507';
DECLARE @NonStaffInWarehouseId08 UNIQUEIDENTIFIER;
SELECT @NonStaffInWarehouseId08 = StaffId FROM Staffs WHERE StaffNo = 'H2020052508';
DECLARE @NonStaffInWarehouseId09 UNIQUEIDENTIFIER;
SELECT @NonStaffInWarehouseId09 = StaffId FROM Staffs WHERE StaffNo = 'H2020052509';

DECLARE @SupplierId01 UNIQUEIDENTIFIER;
SELECT @SupplierId01 = SupplierId FROM Suppliers WHERE SupplierName = '遵义市意通医药有限责任公司';
DECLARE @SupplierId02 UNIQUEIDENTIFIER;
SELECT @SupplierId02 = SupplierId FROM Suppliers WHERE SupplierName = '贵州鼎圣药业有限公司';
DECLARE @SupplierId03 UNIQUEIDENTIFIER;
SELECT @SupplierId03 = SupplierId FROM Suppliers WHERE SupplierName = '贵州国泰医药有限公司';
DECLARE @SupplierId04 UNIQUEIDENTIFIER;
SELECT @SupplierId04 = SupplierId FROM Suppliers WHERE SupplierName = '铜仁梵天药业有限公司';
DECLARE @SupplierId05 UNIQUEIDENTIFIER;
SELECT @SupplierId05 = SupplierId FROM Suppliers WHERE SupplierName = '贵州科渝奇鼎医药有限公司';
DECLARE @SupplierId06 UNIQUEIDENTIFIER;
SELECT @SupplierId06 = SupplierId FROM Suppliers WHERE SupplierName = '贵州振兴医药有限公司贵阳分公司';
DECLARE @SupplierId07 UNIQUEIDENTIFIER;
SELECT @SupplierId07 = SupplierId FROM Suppliers WHERE SupplierName = '国药控股贵州有限公司';
DECLARE @SupplierId08 UNIQUEIDENTIFIER;
SELECT @SupplierId08 = SupplierId FROM Suppliers WHERE SupplierName = '铜仁新中太药业有限公司';
DECLARE @SupplierId09 UNIQUEIDENTIFIER;
SELECT @SupplierId09 = SupplierId FROM Suppliers WHERE SupplierName = '贵州省药材公司';
DECLARE @SupplierId10 UNIQUEIDENTIFIER;
SELECT @SupplierId10 = SupplierId FROM Suppliers WHERE SupplierName = '江阴天江药业有限公司';
DECLARE @SupplierId11 UNIQUEIDENTIFIER;
SELECT @SupplierId11 = SupplierId FROM Suppliers WHERE SupplierName = '石阡县天佑中西药有限公司';
DECLARE @SupplierId12 UNIQUEIDENTIFIER;
SELECT @SupplierId12 = SupplierId FROM Suppliers WHERE SupplierName = '贵州弘一医药有限责任公司';

DECLARE @DrugId UNIQUEIDENTIFIER;
SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '阿莫西林胶囊';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-01-20 11:53:45', @SupplierId02, @StaffInWarehouseId09, '2020-01-23 10:13:34', 15);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-05-25 13:15:23', @SupplierId05, @StaffInWarehouseId07, '2020-05-27 13:59:53', 273);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-05-21 10:28:23', @SupplierId10, @StaffInWarehouseId06, '2019-05-25 11:53:45', @StaffInWarehouseId06, '2019-06-09 10:25:14', @NonStaffInWarehouseId09, 350);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-05-21 10:28:23', @SupplierId10, @StaffInWarehouseId06, '2019-05-25 11:53:45', @StaffInWarehouseId06, '2019-06-19 08:40:25', @NonStaffInWarehouseId06, 100);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-10-17 13:59:53', @SupplierId10, @StaffInWarehouseId03, '2019-10-19 13:15:23', @StaffInWarehouseId06, '2019-10-28 15:47:34', @NonStaffInWarehouseId08, 220);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-10-17 13:59:53', @SupplierId10, @StaffInWarehouseId03, '2019-10-19 13:15:23', @StaffInWarehouseId09, '2019-11-03 18:36:02', @NonStaffInWarehouseId06, 240);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-01-20 11:53:45', @SupplierId02, @StaffInWarehouseId09, '2020-01-23 10:13:34', @StaffInWarehouseId09, '2020-01-31 13:35:42', @NonStaffInWarehouseId03, 100);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-01-20 11:53:45', @SupplierId02, @StaffInWarehouseId09, '2020-01-23 10:13:34', @StaffInWarehouseId09, '2020-02-15 11:06:02', @NonStaffInWarehouseId05, 120);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-05-21 10:28:23', @SupplierId10, @StaffInWarehouseId06, '2019-05-25 11:53:45', @StaffInWarehouseId02, '2019-11-05 15:15:29', 17);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-10-17 13:59:53', @SupplierId10, @StaffInWarehouseId03, '2019-10-19 13:15:23', @StaffInWarehouseId05, '2020-03-29 10:53:14', 13);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '氨苄西林钠';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-03-18 14:29:16', @SupplierId02, @StaffInWarehouseId07, '2020-03-21 10:28:23', 32);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-05-27 13:15:23', @SupplierId04, @StaffInWarehouseId03, '2020-05-30 15:25:22', 524);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-05-05 10:36:55', @SupplierId02, @StaffInWarehouseId08, '2019-05-09 14:29:16', @StaffInWarehouseId07, '2019-06-06 13:45:24', @NonStaffInWarehouseId02, 450);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-08-03 12:03:05', @SupplierId02, @StaffInWarehouseId04, '2019-08-05 09:16:44', @StaffInWarehouseId09, '2019-11-03 19:06:52', @NonStaffInWarehouseId03, 100);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-11-07 10:28:23', @SupplierId02, @StaffInWarehouseId01, '2019-11-11 15:13:29', @StaffInWarehouseId04, '2019-11-23 14:32:08', @NonStaffInWarehouseId09, 260);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-05-05 10:36:55', @SupplierId02, @StaffInWarehouseId08, '2019-05-09 14:29:16', @StaffInWarehouseId03, '2019-08-23 10:59:05', 26);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-08-03 12:03:05', @SupplierId02, @StaffInWarehouseId04, '2019-08-05 09:16:44', @StaffInWarehouseId01, '2019-11-17 14:52:17', 17);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-11-07 10:28:23', @SupplierId02, @StaffInWarehouseId01, '2019-11-11 15:13:29', @StaffInWarehouseId05, '2020-02-23 17:09:22', 16);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '青霉素钠';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-04-17 16:45:39', @SupplierId04, @StaffInWarehouseId03, '2020-04-19 16:45:21', 9);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-05-23 17:06:57', @SupplierId05, @StaffInWarehouseId02, '2020-05-27 10:34:26', 27);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2018-07-08 17:06:57', @SupplierId03, @StaffInWarehouseId06, '2018-07-11 10:36:55', @StaffInWarehouseId08, '2018-07-26 13:45:24', @NonStaffInWarehouseId06, 300);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2018-09-28 10:36:55', @SupplierId03, @StaffInWarehouseId09, '2018-09-30 12:03:05', @StaffInWarehouseId06, '2018-10-09 19:06:52', @NonStaffInWarehouseId08, 420);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2018-11-30 16:45:39', @SupplierId07, @StaffInWarehouseId03, '2018-12-03 17:06:57', @StaffInWarehouseId10, '2018-12-24 14:32:08', @NonStaffInWarehouseId03, 500);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-02-09 10:30:22', @SupplierId08, @StaffInWarehouseId04, '2019-02-12 16:21:05', @StaffInWarehouseId10, '2019-02-15 13:45:24', @NonStaffInWarehouseId01, 100);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-04-28 16:45:39', @SupplierId07, @StaffInWarehouseId02, '2019-04-30 10:29:50', @StaffInWarehouseId09, '2019-05-17 19:06:52', @NonStaffInWarehouseId02, 150);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-07-07 12:03:05', @SupplierId04, @StaffInWarehouseId08, '2019-07-11 13:36:56', @StaffInWarehouseId10, '2019-07-29 14:32:08', @NonStaffInWarehouseId02, 180);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2018-07-08 17:06:57', @SupplierId03, @StaffInWarehouseId06, '2018-07-11 10:36:55', @StaffInWarehouseId05, '2018-10-01 12:05:53', 25);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2018-09-28 10:36:55', @SupplierId03, @StaffInWarehouseId09, '2018-09-30 12:03:05', @StaffInWarehouseId05, '2018-12-19 15:53:01', 17);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2018-11-30 16:45:39', @SupplierId07, @StaffInWarehouseId03, '2018-12-03 17:06:57', @StaffInWarehouseId01, '2019-02-22 13:07:35', 8);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-02-09 10:30:22', @SupplierId08, @StaffInWarehouseId04, '2019-02-12 16:21:05', @StaffInWarehouseId04, '2019-05-01 12:36:19', 5);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-04-28 16:45:39', @SupplierId07, @StaffInWarehouseId02, '2019-04-30 10:29:50', @StaffInWarehouseId03, '2019-07-19 13:54:56', 25);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-07-07 12:03:05', @SupplierId04, @StaffInWarehouseId08, '2019-07-11 13:36:56', @StaffInWarehouseId05, '2019-09-27 12:13:15', 19);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '磷霉素钠';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2019-12-01 16:05:38', @SupplierId04, @StaffInWarehouseId02, '2019-12-03 16:45:39', 89);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-04-15 16:21:05', @SupplierId05, @StaffInWarehouseId01, '2020-04-17 09:51:13', 371);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2018-12-01 09:16:30', @SupplierId04, @StaffInWarehouseId04, '2018-12-10 10:30:22', @StaffInWarehouseId08, '2018-12-17 16:45:24', @NonStaffInWarehouseId06, 300);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-05-13 16:13:10', @SupplierId10, @StaffInWarehouseId10, '2019-05-16 10:16:03', @StaffInWarehouseId06, '2019-06-04 10:06:52', @NonStaffInWarehouseId07, 220);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2018-12-01 09:16:30', @SupplierId04, @StaffInWarehouseId04, '2018-12-10 10:30:22', @StaffInWarehouseId02, '2019-11-10 16:17:05', 3);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-05-13 16:13:10', @SupplierId10, @StaffInWarehouseId10, '2019-05-16 10:16:03', @StaffInWarehouseId02, '2020-04-15 14:27:35', 51);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '利伐沙班片';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2019-10-06 10:30:30', @SupplierId10, @StaffInWarehouseId05, '2019-10-08 16:05:38', 16);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2019-12-29 16:06:37', @SupplierId05, @StaffInWarehouseId01, '2020-01-03 15:41:37', 305);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2018-09-15 11:20:54', @SupplierId05, @StaffInWarehouseId03, '2018-09-25 09:16:30', @StaffInWarehouseId08, '2018-09-26 13:49:24', @NonStaffInWarehouseId05, 250);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-07-07 16:45:39', @SupplierId02, @StaffInWarehouseId03, '2019-07-13 11:37:43', @StaffInWarehouseId06, '2019-07-29 16:06:32', @NonStaffInWarehouseId06, 180);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-09-09 10:29:50', @SupplierId05, @StaffInWarehouseId03, '2019-09-15 16:13:10', @StaffInWarehouseId10, '2019-10-08 15:30:08', @NonStaffInWarehouseId03, 460);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2018-09-15 11:20:54', @SupplierId05, @StaffInWarehouseId03, '2018-09-25 09:16:30', @StaffInWarehouseId04, '2019-06-05 11:05:06', 15);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-07-07 16:45:39', @SupplierId02, @StaffInWarehouseId03, '2019-07-13 11:37:43', @StaffInWarehouseId05, '2020-03-28 13:47:09', 39);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-09-09 10:29:50', @SupplierId05, @StaffInWarehouseId03, '2019-09-15 16:13:10', @StaffInWarehouseId05, '2020-05-21 15:08:15', 27);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '头孢拉定胶囊';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-03-07 11:39:43', @SupplierId06, @StaffInWarehouseId08, '2020-03-10 10:30:30', 27);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-03-27 14:09:17', @SupplierId11, @StaffInWarehouseId09, '2020-03-29 11:43:54', 412);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-06-07 09:22:55', @SupplierId04, @StaffInWarehouseId07, '2020-06-09 11:20:54', 357);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2018-12-01 16:06:37', @SupplierId03, @StaffInWarehouseId04, '2018-12-10 16:45:39', @StaffInWarehouseId08, '2019-01-06 11:43:04', @NonStaffInWarehouseId08, 280);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-03-11 10:53:26', @SupplierId03, @StaffInWarehouseId10, '2019-03-13 10:03:19', @StaffInWarehouseId06, '2019-04-03 15:46:42', @NonStaffInWarehouseId05, 110);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-06-23 15:05:26', @SupplierId02, @StaffInWarehouseId05, '2019-06-27 15:34:09', @StaffInWarehouseId10, '2019-06-28 18:37:08', @NonStaffInWarehouseId06, 350);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-10-05 10:53:26', @SupplierId01, @StaffInWarehouseId01, '2019-10-08 16:06:37', @StaffInWarehouseId10, '2019-10-17 13:05:27', @NonStaffInWarehouseId09, 100);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-03-07 11:39:43', @SupplierId06, @StaffInWarehouseId08, '2020-03-10 10:30:30', @StaffInWarehouseId10, '2020-04-02 09:05:07', @NonStaffInWarehouseId06, 270);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-03-07 11:39:43', @SupplierId06, @StaffInWarehouseId08, '2020-03-10 10:30:30', @StaffInWarehouseId10, '2020-04-12 13:25:25', @NonStaffInWarehouseId02, 140);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-03-07 11:39:43', @SupplierId06, @StaffInWarehouseId08, '2020-03-10 10:30:30', @StaffInWarehouseId10, '2020-04-15 18:07:24', @NonStaffInWarehouseId03, 130);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2018-12-01 16:06:37', @SupplierId03, @StaffInWarehouseId04, '2018-12-10 16:45:39', @StaffInWarehouseId04, '2019-03-24 13:59:15', 9);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-03-11 10:53:26', @SupplierId03, @StaffInWarehouseId10, '2019-03-13 10:03:19', @StaffInWarehouseId03, '2019-06-30 09:29:53', 16);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-06-23 15:05:26', @SupplierId02, @StaffInWarehouseId05, '2019-06-27 15:34:09', @StaffInWarehouseId01, '2019-10-14 13:36:05', 21);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-10-05 10:53:26', @SupplierId01, @StaffInWarehouseId01, '2019-10-08 16:06:37', @StaffInWarehouseId05, '2020-03-29 10:35:37', 3);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '头孢曲松钠';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-04-05 09:22:55', @SupplierId07, @StaffInWarehouseId04, '2020-04-06 10:36:55', 36);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-06-16 10:53:26', @SupplierId11, @StaffInWarehouseId05, '2020-06-17 09:35:19', 205);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-03-30 15:26:30', @SupplierId07, @StaffInWarehouseId04, '2019-04-10 15:05:26', @StaffInWarehouseId08, '2019-04-22 11:33:04', @NonStaffInWarehouseId07, 220);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-06-13 14:09:17', @SupplierId03, @StaffInWarehouseId06, '2019-06-15 15:26:30', @StaffInWarehouseId06, '2019-06-23 17:40:42', @NonStaffInWarehouseId08, 420);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-11-22 11:43:54', @SupplierId05, @StaffInWarehouseId02, '2019-11-24 16:04:06', @StaffInWarehouseId10, '2019-11-28 17:07:28', @NonStaffInWarehouseId09, 360);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-03-23 11:43:54', @SupplierId05, @StaffInWarehouseId08, '2020-03-26 10:53:26', @StaffInWarehouseId10, '2020-04-17 10:05:27', @NonStaffInWarehouseId08, 470);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-03-30 15:26:30', @SupplierId07, @StaffInWarehouseId04, '2019-04-10 15:05:26', @StaffInWarehouseId01, '2019-06-24 09:16:55', 8);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-06-13 14:09:17', @SupplierId03, @StaffInWarehouseId06, '2019-06-15 15:26:30', @StaffInWarehouseId03, '2019-09-03 14:36:05', 63);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-11-22 11:43:54', @SupplierId05, @StaffInWarehouseId02, '2019-11-24 16:04:06', @StaffInWarehouseId03, '2020-02-14 09:56:50', 15);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2020-03-23 11:43:54', @SupplierId05, @StaffInWarehouseId08, '2020-03-26 10:53:26', @StaffInWarehouseId01, '2020-06-17 08:56:08', 29);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '头孢吡肟';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-02-03 09:54:06', @SupplierId08, @StaffInWarehouseId04, '2020-02-05 10:53:26', 3);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-05-05 10:37:30', @SupplierId06, @StaffInWarehouseId09, '2020-05-09 14:09:17', 405);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-02-18 10:30:30', @SupplierId08, @StaffInWarehouseId07, '2019-02-25 10:28:23', @StaffInWarehouseId09, '2019-02-28 17:40:42', @NonStaffInWarehouseId08, 200);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-06-27 15:29:42', @SupplierId05, @StaffInWarehouseId06, '2019-06-28 09:54:06', @StaffInWarehouseId07, '2019-07-10 17:07:28', @NonStaffInWarehouseId09, 130);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-02-18 10:30:30', @SupplierId08, @StaffInWarehouseId07, '2019-02-25 10:28:23', @StaffInWarehouseId02, '2019-08-06 16:13:43', 27);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-06-27 15:29:42', @SupplierId05, @StaffInWarehouseId06, '2019-06-28 09:54:06', @StaffInWarehouseId02, '2019-12-13 15:13:47', 6);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '头孢噻肟钠';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2019-03-22 10:30:30', @SupplierId09, @StaffInWarehouseId04, '2019-03-23 14:06:45', 13);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-05-21 10:53:26', @SupplierId09, @StaffInWarehouseId05, '2020-05-25 11:53:51', 165);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2018-12-10 15:29:42', @SupplierId09, @StaffInWarehouseId08, '2018-12-12 10:37:30', @StaffInWarehouseId09, '2019-01-05 09:47:12', @NonStaffInWarehouseId06, 140);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2018-12-10 15:29:42', @SupplierId09, @StaffInWarehouseId08, '2018-12-12 10:37:30', @StaffInWarehouseId01, '2020-03-23 15:22:16', 5);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '骨筋丸胶囊';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-01-02 10:53:26', @SupplierId04, @StaffInWarehouseId03, '2020-01-03 15:29:42', 5);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-03-21 16:22:10', @SupplierId06, @StaffInWarehouseId06, '2020-03-25 10:53:26', 15);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-05-06 10:53:26', @SupplierId06, @StaffInWarehouseId10, '2020-05-08 14:25:12', 517);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2018-12-13 15:16:29', @SupplierId09, @StaffInWarehouseId09, '2018-12-15 10:49:32', @StaffInWarehouseId07, '2018-12-28 13:04:58', @NonStaffInWarehouseId09, 110);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-06-01 09:54:06', @SupplierId10, @StaffInWarehouseId01, '2019-06-04 16:22:10', @StaffInWarehouseId09, '2019-07-07 16:25:29', @NonStaffInWarehouseId04, 80);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2018-12-13 15:16:29', @SupplierId09, @StaffInWarehouseId09, '2018-12-15 10:49:32', @StaffInWarehouseId03, '2020-06-03 08:53:19', 7);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-06-01 09:54:06', @SupplierId10, @StaffInWarehouseId01, '2019-06-04 16:22:10', @StaffInWarehouseId05, '2019-11-21 10:11:06', 23);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '复方穿心莲片';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2019-07-25 11:53:51', @SupplierId03, @StaffInWarehouseId05, '2019-07-28 08:25:22', 14);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-05-10 15:46:02', @SupplierId04, @StaffInWarehouseId09, '2020-05-15 15:16:29', 306);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2018-09-17 09:11:35', @SupplierId04, @StaffInWarehouseId07, '2018-09-20 11:39:43', @StaffInWarehouseId01, '2018-10-08 09:23:39', @NonStaffInWarehouseId04, 85);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-07-25 11:53:51', @SupplierId03, @StaffInWarehouseId05, '2019-07-28 08:25:22', @StaffInWarehouseId08, '2019-08-08 12:02:19', @NonStaffInWarehouseId02, 130);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-07-25 11:53:51', @SupplierId03, @StaffInWarehouseId05, '2019-07-28 08:25:22', @StaffInWarehouseId09, '2019-08-14 16:23:35', @NonStaffInWarehouseId07, 160);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2018-09-17 09:11:35', @SupplierId04, @StaffInWarehouseId07, '2018-09-20 11:39:43', @StaffInWarehouseId04, '2019-09-02 15:02:14', 39);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '四季感冒片';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-05-25 09:11:35', @SupplierId12, @StaffInWarehouseId01, '2020-05-30 14:35:02', 513);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2018-12-10 16:22:10', @SupplierId03, @StaffInWarehouseId10, '2018-12-11 09:32:46', @StaffInWarehouseId05, '2018-12-23 08:13:05', @NonStaffInWarehouseId05, 230);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2018-12-10 16:22:10', @SupplierId03, @StaffInWarehouseId10, '2018-12-11 09:32:46', @StaffInWarehouseId06, '2018-12-27 16:22:16', @NonStaffInWarehouseId08, 110);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2018-12-10 16:22:10', @SupplierId03, @StaffInWarehouseId10, '2018-12-11 09:32:46', @StaffInWarehouseId08, '2019-01-03 09:11:45', @NonStaffInWarehouseId02, 230);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-06-07 13:02:19', @SupplierId07, @StaffInWarehouseId10, '2019-06-26 17:24:20', @StaffInWarehouseId09, '2019-07-23 13:13:43', @NonStaffInWarehouseId03, 120);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-06-07 13:02:19', @SupplierId07, @StaffInWarehouseId10, '2019-06-26 17:24:20', @StaffInWarehouseId10, '2019-08-02 15:22:32', @NonStaffInWarehouseId05, 100);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-06-07 13:02:19', @SupplierId07, @StaffInWarehouseId10, '2019-06-26 17:24:20', @StaffInWarehouseId05, '2019-08-16 14:22:03', @NonStaffInWarehouseId06, 240);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-05-25 09:11:35', @SupplierId12, @StaffInWarehouseId01, '2020-05-30 14:35:02', @StaffInWarehouseId06, '2020-06-03 12:04:08', @NonStaffInWarehouseId01, 200);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-05-25 09:11:35', @SupplierId12, @StaffInWarehouseId01, '2020-05-30 14:35:02', @StaffInWarehouseId08, '2020-06-08 15:13:05', @NonStaffInWarehouseId08, 100);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-05-25 09:11:35', @SupplierId12, @StaffInWarehouseId01, '2020-05-30 14:35:02', @StaffInWarehouseId09, '2020-06-22 13:13:05', @NonStaffInWarehouseId09, 340);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2018-12-10 16:22:10', @SupplierId03, @StaffInWarehouseId10, '2018-12-11 09:32:46', @StaffInWarehouseId02, '2019-11-24 08:52:36', 8);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-06-07 13:02:19', @SupplierId07, @StaffInWarehouseId10, '2019-06-26 17:24:20', @StaffInWarehouseId02, '2020-05-13 16:07:16', 17);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '午时茶颗粒';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-01-12 16:22:10', @SupplierId07, @StaffInWarehouseId04, '2020-01-13 09:11:35', 4);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-05-25 15:46:02', @SupplierId06, @StaffInWarehouseId03, '2020-06-01 15:46:02', 25);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-02-23 16:37:34', @SupplierId11, @StaffInWarehouseId02, '2019-02-25 15:03:11', @StaffInWarehouseId07, '2019-03-05 20:43:19', @NonStaffInWarehouseId09, 120);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-02-23 16:37:34', @SupplierId11, @StaffInWarehouseId02, '2019-02-25 15:03:11', @StaffInWarehouseId03, '2020-02-03 14:23:38', 32);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '十三味马钱子丸';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2019-09-29 14:16:23', @SupplierId06, @StaffInWarehouseId04, '2019-10-02 16:47:32', 3);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-06-01 09:11:35', @SupplierId10, @StaffInWarehouseId04, '2020-06-04 08:25:32', 224);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2018-05-23 14:16:23', @SupplierId01, @StaffInWarehouseId04, '2018-05-29 14:16:23',  @StaffInWarehouseId08, '2018-07-25 12:03:46', @NonStaffInWarehouseId09, 160);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2018-05-23 14:16:23', @SupplierId01, @StaffInWarehouseId04, '2018-05-29 14:16:23', @StaffInWarehouseId02, '2020-04-24 11:47:13', 24);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '氯芬黄敏片';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2019-11-07 12:09:34', @SupplierId09, @StaffInWarehouseId09, '2019-11-08 09:22:55', 35);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-06-02 10:32:11', @SupplierId03, @StaffInWarehouseId10, '2020-06-05 15:56:22', 313);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2018-05-03 14:16:23', @SupplierId01, @StaffInWarehouseId04, '2018-05-05 11:36:03', @StaffInWarehouseId06, '2018-07-02 11:04:08', @NonStaffInWarehouseId09, 100);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2018-09-13 10:32:11', @SupplierId03, @StaffInWarehouseId05, '2018-09-14 10:32:11', @StaffInWarehouseId10, '2018-09-27 15:20:20', @NonStaffInWarehouseId04, 150);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2018-05-03 14:16:23', @SupplierId01, @StaffInWarehouseId04, '2018-05-05 11:36:03', @StaffInWarehouseId05, '2019-10-04 13:36:18', 6);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2018-09-13 10:32:11', @SupplierId03, @StaffInWarehouseId05, '2018-09-14 10:32:11', @StaffInWarehouseId02, '2020-02-16 13:11:58', 20);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '痫愈胶囊';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2019-11-03 12:09:34', @SupplierId07, @StaffInWarehouseId04, '2019-11-04 15:19:01', 10);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-04-05 16:37:34', @SupplierId10, @StaffInWarehouseId09, '2020-04-09 10:45:06', 109);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-11-03 12:09:34', @SupplierId07, @StaffInWarehouseId04, '2019-11-04 15:19:01', @StaffInWarehouseId10, '2019-11-21 16:07:58', @NonStaffInWarehouseId03, 250);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-11-03 12:09:34', @SupplierId07, @StaffInWarehouseId04, '2019-11-04 15:19:01', @StaffInWarehouseId09, '2019-12-03 09:53:20', @NonStaffInWarehouseId02, 280);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '地高辛';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-02-11 12:09:34', @SupplierId07, @StaffInWarehouseId01, '2020-02-13 11:16:22', 5);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-05-05 10:32:11', @SupplierId10, @StaffInWarehouseId06, '2020-05-06 08:43:04', 279);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-06-05 11:16:22', @SupplierId02, @StaffInWarehouseId10, '2019-06-07 12:09:34', @StaffInWarehouseId10, '2019-07-11 18:27:38', @NonStaffInWarehouseId03, 250);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-11-27 16:37:34', @SupplierId09, @StaffInWarehouseId04, '2019-11-29 15:03:24', @StaffInWarehouseId07, '2019-12-03 08:59:29', @NonStaffInWarehouseId02, 280);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-02-11 12:09:34', @SupplierId07, @StaffInWarehouseId01, '2020-02-13 11:16:22', @StaffInWarehouseId06, '2020-02-21 12:27:08', @NonStaffInWarehouseId04, 220);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-02-11 12:09:34', @SupplierId07, @StaffInWarehouseId01, '2020-02-13 11:16:22', @StaffInWarehouseId09, '2020-02-23 15:50:20', @NonStaffInWarehouseId05, 200);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-06-05 11:16:22', @SupplierId02, @StaffInWarehouseId10, '2019-06-07 12:09:34', @StaffInWarehouseId03, '2019-11-21 10:29:06', 7);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-11-27 16:37:34', @SupplierId09, @StaffInWarehouseId04, '2019-11-29 15:03:24', @StaffInWarehouseId03, '2020-05-13 10:29:06', 27);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '替米沙坦片';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2019-09-05 16:39:18', @SupplierId11, @StaffInWarehouseId04, '2019-09-06 13:56:17', 16);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-03-29 16:37:34', @SupplierId09, @StaffInWarehouseId10, '2020-04-12 15:03:14', 230);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2018-10-11 13:48:35', @SupplierId05, @StaffInWarehouseId01, '2018-10-13 16:37:34', @StaffInWarehouseId09, '2018-11-11 11:17:48', @NonStaffInWarehouseId03, 190);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-02-06 08:43:04', @SupplierId09, @StaffInWarehouseId05, '2019-02-08 15:08:24', @StaffInWarehouseId07, '2019-02-23 15:16:07', @NonStaffInWarehouseId02, 200);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2018-10-11 13:48:35', @SupplierId05, @StaffInWarehouseId01, '2018-10-13 16:37:34', @StaffInWarehouseId03, '2019-09-14 15:20:16', 3);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-02-06 08:43:04', @SupplierId09, @StaffInWarehouseId05, '2019-02-08 15:08:24', @StaffInWarehouseId03, '2020-01-12 09:53:36', 21);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '噻奈普汀片';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-02-16 11:16:22', @SupplierId11, @StaffInWarehouseId03, '2020-02-19 12:36:59', 19);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-06-13 16:39:18', @SupplierId08, @StaffInWarehouseId04, '2020-06-14 09:31:09', 234);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2018-09-17 16:39:18', @SupplierId12, @StaffInWarehouseId05, '2018-09-19 15:03:24', @StaffInWarehouseId07, '2018-10-08 11:43:14', @NonStaffInWarehouseId04, 280);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2018-12-12 12:13:04', @SupplierId02, @StaffInWarehouseId01, '2018-12-16 16:37:34', @StaffInWarehouseId06, '2018-12-25 15:41:42', @NonStaffInWarehouseId05, 180);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-03-26 08:43:04', @SupplierId09, @StaffInWarehouseId05, '2019-03-28 15:08:24', @StaffInWarehouseId06, '2019-04-18 09:33:08', @NonStaffInWarehouseId06, 190);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2018-09-17 16:39:18', @SupplierId12, @StaffInWarehouseId05, '2018-09-19 15:03:24', @StaffInWarehouseId03, '2019-03-08 10:29:06', 7);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2018-12-12 12:13:04', @SupplierId02, @StaffInWarehouseId01, '2018-12-16 16:37:34', @StaffInWarehouseId05, '2019-06-03 15:20:16', 33);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-03-26 08:43:04', @SupplierId09, @StaffInWarehouseId05, '2019-03-28 15:08:24', @StaffInWarehouseId03, '2019-09-10 09:53:36', 25);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '复方樟薄软膏';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2018-08-15 13:48:35', @SupplierId12, @StaffInWarehouseId04, '2018-08-18 11:07:57', 3);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2019-11-03 16:39:18', @SupplierId02, @StaffInWarehouseId06, '2019-11-06 16:39:18', 5);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-05-13 16:39:18', @SupplierId01, @StaffInWarehouseId08, '2020-05-18 15:22:07', 32);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2018-06-30 10:53:38', @SupplierId06, @StaffInWarehouseId10, '2018-07-02 13:59:04', @StaffInWarehouseId06, '2018-08-01 13:13:54', @NonStaffInWarehouseId04, 230);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2018-06-30 10:53:38', @SupplierId06, @StaffInWarehouseId10, '2018-07-02 13:59:04', @StaffInWarehouseId05, '2020-05-25 08:56:16', 45);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '利血平';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-01-15 10:53:38', @SupplierId12, @StaffInWarehouseId02, '2020-01-17 16:03:46', 3);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-06-13 11:16:22', @SupplierId07, @StaffInWarehouseId01, '2020-06-15 15:05:50', 85);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-03-29 12:13:04', @SupplierId08, @StaffInWarehouseId04, '2019-03-30 13:58:28', @StaffInWarehouseId06, '2019-04-03 11:43:04', @NonStaffInWarehouseId01, 280);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-03-29 12:13:04', @SupplierId08, @StaffInWarehouseId04, '2019-03-30 13:58:28', @StaffInWarehouseId07, '2019-04-07 15:36:42', @NonStaffInWarehouseId04, 240);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-03-29 12:13:04', @SupplierId08, @StaffInWarehouseId04, '2019-03-30 13:58:28', @StaffInWarehouseId08, '2019-04-22 17:37:08', @NonStaffInWarehouseId05, 220);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-03-29 12:13:04', @SupplierId08, @StaffInWarehouseId04, '2019-03-30 13:58:28', @StaffInWarehouseId09, '2019-05-02 09:05:27', @NonStaffInWarehouseId02, 100);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-06-13 13:48:35', @SupplierId08, @StaffInWarehouseId10, '2019-06-14 17:09:04', @StaffInWarehouseId10, '2019-06-19 11:03:04', @NonStaffInWarehouseId05, 120);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-06-13 13:48:35', @SupplierId08, @StaffInWarehouseId10, '2019-06-14 17:09:04', @StaffInWarehouseId10, '2019-06-23 15:26:42', @NonStaffInWarehouseId08, 160);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-06-13 13:48:35', @SupplierId08, @StaffInWarehouseId10, '2019-06-14 17:09:04', @StaffInWarehouseId09, '2019-07-08 08:37:08', @NonStaffInWarehouseId03, 150);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-01-15 10:53:38', @SupplierId12, @StaffInWarehouseId02, '2020-01-17 16:03:46', @StaffInWarehouseId08, '2020-01-19 11:05:27', @NonStaffInWarehouseId06, 100);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-01-15 10:53:38', @SupplierId12, @StaffInWarehouseId02, '2020-01-17 16:03:46', @StaffInWarehouseId07, '2020-01-26 11:49:04', @NonStaffInWarehouseId09, 280);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-01-15 10:53:38', @SupplierId12, @StaffInWarehouseId02, '2020-01-17 16:03:46',  @StaffInWarehouseId06, '2020-02-03 15:46:02', @NonStaffInWarehouseId01, 260);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-01-15 10:53:38', @SupplierId12, @StaffInWarehouseId02, '2020-01-17 16:03:46', @StaffInWarehouseId06, '2020-02-08 16:31:08', @NonStaffInWarehouseId05, 360);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-01-15 10:53:38', @SupplierId12, @StaffInWarehouseId02, '2020-01-17 16:03:46', @StaffInWarehouseId07, '2020-02-09 13:05:27', @NonStaffInWarehouseId07, 100);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-03-29 12:13:04', @SupplierId08, @StaffInWarehouseId04, '2019-03-30 13:58:28', @StaffInWarehouseId03, '2019-09-13 09:53:36', 1);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-06-13 13:48:35', @SupplierId08, @StaffInWarehouseId10, '2019-06-14 17:09:04', @StaffInWarehouseId08, '2019-11-26 08:16:18', 22);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '克拉霉素片';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2019-10-05 10:53:38', @SupplierId08, @StaffInWarehouseId03, '2019-10-06 16:11:18', 13);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-04-05 16:39:18', @SupplierId06, @StaffInWarehouseId01, '2020-04-06 09:04:36', 418);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-06-17 13:48:35', @SupplierId06, @StaffInWarehouseId09, '2019-06-18 16:19:54', @StaffInWarehouseId06, '2019-07-09 11:55:57', @NonStaffInWarehouseId07, 120);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-06-17 13:48:35', @SupplierId06, @StaffInWarehouseId09, '2019-06-18 16:19:54', @StaffInWarehouseId04, '2020-05-21 09:53:08', 2);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '复方消化酶片';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-03-13 13:48:35', @SupplierId07, @StaffInWarehouseId02, '2020-03-15 14:55:34', 39);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-02-17 13:48:35', @SupplierId06, @StaffInWarehouseId06, '2019-02-18 17:06:36', @StaffInWarehouseId06, '2019-02-23 11:43:04', @NonStaffInWarehouseId01, 280);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-02-17 13:48:35', @SupplierId06, @StaffInWarehouseId06, '2019-02-18 17:06:36', @StaffInWarehouseId07, '2019-02-27 15:36:42', @NonStaffInWarehouseId04, 240);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-02-17 13:48:35', @SupplierId06, @StaffInWarehouseId06, '2019-02-18 17:06:36', @StaffInWarehouseId08, '2019-03-02 11:37:08', @NonStaffInWarehouseId07, 220);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-02-17 13:48:35', @SupplierId06, @StaffInWarehouseId06, '2019-02-18 17:06:36', @StaffInWarehouseId09, '2019-03-02 15:05:27', @NonStaffInWarehouseId02, 100);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-02-17 13:48:35', @SupplierId06, @StaffInWarehouseId06, '2019-02-18 17:06:36', @StaffInWarehouseId10, '2019-03-09 11:03:04', @NonStaffInWarehouseId05, 120);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-12-03 10:53:38', @SupplierId04, @StaffInWarehouseId08, '2019-12-04 15:09:34', @StaffInWarehouseId10, '2019-12-13 15:26:42', @NonStaffInWarehouseId08, 160);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-12-03 10:53:38', @SupplierId04, @StaffInWarehouseId08, '2019-12-04 15:09:34', @StaffInWarehouseId09, '2019-12-18 08:37:08', @NonStaffInWarehouseId03, 150);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-12-03 10:53:38', @SupplierId04, @StaffInWarehouseId08, '2019-12-04 15:09:34', @StaffInWarehouseId08, '2019-12-19 11:05:27', @NonStaffInWarehouseId06, 100);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-12-03 10:53:38', @SupplierId04, @StaffInWarehouseId08, '2019-12-04 15:09:34', @StaffInWarehouseId07, '2020-01-06 11:49:04', @NonStaffInWarehouseId09, 280);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-12-03 10:53:38', @SupplierId04, @StaffInWarehouseId08, '2019-12-04 15:09:34', @StaffInWarehouseId06, '2020-01-13 15:46:02', @NonStaffInWarehouseId01, 260);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-03-13 13:48:35', @SupplierId07, @StaffInWarehouseId02, '2020-03-15 14:55:34', @StaffInWarehouseId06, '2020-03-28 16:31:08', @NonStaffInWarehouseId04, 360);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-03-13 13:48:35', @SupplierId07, @StaffInWarehouseId02, '2020-03-15 14:55:34', @StaffInWarehouseId07, '2020-04-03 13:05:27', @NonStaffInWarehouseId07, 100);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-02-17 13:48:35', @SupplierId06, @StaffInWarehouseId06, '2019-02-18 17:06:36', @StaffInWarehouseId01, '2019-08-05 13:57:46', 5);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-12-03 10:53:38', @SupplierId04, @StaffInWarehouseId08, '2019-12-04 15:09:34', @StaffInWarehouseId02, '2020-05-21 12:08:53', 38);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '愈创罂粟待因片';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-02-28 14:04:06', @SupplierId11, @StaffInWarehouseId07, '2020-03-03 13:53:12', 76);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-06-05 11:16:22', @SupplierId02, @StaffInWarehouseId04, '2020-06-11 15:03:24', 109);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-12-12 12:13:04', @SupplierId03, @StaffInWarehouseId10, '2019-12-16 13:48:35', @StaffInWarehouseId06, '2020-01-08 16:31:08', @NonStaffInWarehouseId01, 360);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-12-12 12:13:04', @SupplierId03, @StaffInWarehouseId10, '2019-12-16 13:48:35', @StaffInWarehouseId02, '2020-06-02 10:06:13', 82);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '伏格列波糖';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-01-13 16:39:18', @SupplierId05, @StaffInWarehouseId01, '2020-01-14 16:05:06', 5);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-03-16 12:03:29', @SupplierId08, @StaffInWarehouseId02, '2020-03-18 14:04:06', 28);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2018-08-17 10:53:38', @SupplierId12, @StaffInWarehouseId07, '2018-08-21 14:05:26', @StaffInWarehouseId06, '2018-08-23 11:43:04', @NonStaffInWarehouseId01, 280);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2018-08-17 10:53:38', @SupplierId12, @StaffInWarehouseId07, '2018-08-21 14:05:26', @StaffInWarehouseId07, '2018-09-07 15:36:42', @NonStaffInWarehouseId04, 240);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2018-08-17 10:53:38', @SupplierId12, @StaffInWarehouseId07, '2018-08-21 14:05:26', @StaffInWarehouseId08, '2018-09-09 11:37:08', @NonStaffInWarehouseId07, 220);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2018-08-17 10:53:38', @SupplierId12, @StaffInWarehouseId07, '2018-08-21 14:05:26', @StaffInWarehouseId09, '2018-09-12 15:05:27', @NonStaffInWarehouseId02, 100);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2018-08-17 10:53:38', @SupplierId12, @StaffInWarehouseId07, '2018-08-21 14:05:26', @StaffInWarehouseId10, '2018-09-19 11:03:04', @NonStaffInWarehouseId05, 120);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-02-03 08:43:04', @SupplierId01, @StaffInWarehouseId03, '2019-02-10 16:17:03', @StaffInWarehouseId10, '2019-02-13 15:26:42', @NonStaffInWarehouseId08, 160);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-02-03 08:43:04', @SupplierId01, @StaffInWarehouseId03, '2019-02-10 16:17:03', @StaffInWarehouseId09, '2019-02-18 08:37:08', @NonStaffInWarehouseId03, 150);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-02-03 08:43:04', @SupplierId01, @StaffInWarehouseId03, '2019-02-10 16:17:03', @StaffInWarehouseId08, '2019-02-19 11:05:27', @NonStaffInWarehouseId06, 100);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-02-03 08:43:04', @SupplierId01, @StaffInWarehouseId03, '2019-02-10 16:17:03', @StaffInWarehouseId07, '2019-03-03 11:49:04', @NonStaffInWarehouseId09, 280);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-02-03 08:43:04', @SupplierId01, @StaffInWarehouseId03, '2019-02-10 16:17:03', @StaffInWarehouseId06, '2019-03-13 15:46:02', @NonStaffInWarehouseId01, 260);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-06-29 08:42:16', @SupplierId08, @StaffInWarehouseId02, '2019-06-30 12:13:04', @StaffInWarehouseId06, '2019-07-08 16:31:08', @NonStaffInWarehouseId03, 360);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-06-29 08:42:16', @SupplierId08, @StaffInWarehouseId02, '2019-06-30 12:13:04', @StaffInWarehouseId07, '2019-07-13 13:05:27', @NonStaffInWarehouseId07, 100);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-06-29 08:42:16', @SupplierId08, @StaffInWarehouseId02, '2019-06-30 12:13:04', @StaffInWarehouseId06, '2019-07-23 11:43:04', @NonStaffInWarehouseId01, 280);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-11-07 14:04:06', @SupplierId09, @StaffInWarehouseId02, '2019-11-09 12:03:29', @StaffInWarehouseId09, '2019-11-22 15:05:27', @NonStaffInWarehouseId02, 100);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-11-07 14:04:06', @SupplierId09, @StaffInWarehouseId02, '2019-11-09 12:03:29', @StaffInWarehouseId10, '2019-11-29 11:03:04', @NonStaffInWarehouseId05, 120);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-11-07 14:04:06', @SupplierId09, @StaffInWarehouseId02, '2019-11-09 12:03:29', @StaffInWarehouseId10, '2019-12-13 15:26:42', @NonStaffInWarehouseId08, 160);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-11-07 14:04:06', @SupplierId09, @StaffInWarehouseId02, '2019-11-09 12:03:29', @StaffInWarehouseId09, '2019-12-18 08:37:08', @NonStaffInWarehouseId03, 150);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-11-07 14:04:06', @SupplierId09, @StaffInWarehouseId02, '2019-11-09 12:03:29', @StaffInWarehouseId08, '2019-12-19 11:05:27', @NonStaffInWarehouseId06, 100);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-01-13 16:39:18', @SupplierId05, @StaffInWarehouseId01, '2020-01-14 16:05:06', @StaffInWarehouseId07, '2020-01-16 11:49:04', @NonStaffInWarehouseId09, 280);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-01-13 16:39:18', @SupplierId05, @StaffInWarehouseId01, '2020-01-14 16:05:06', @StaffInWarehouseId06, '2020-01-23 15:46:02', @NonStaffInWarehouseId01, 260);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-01-13 16:39:18', @SupplierId05, @StaffInWarehouseId01, '2020-01-14 16:05:06', @StaffInWarehouseId06, '2020-01-28 16:31:08', @NonStaffInWarehouseId04, 360);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-01-13 16:39:18', @SupplierId05, @StaffInWarehouseId01, '2020-01-14 16:05:06', @StaffInWarehouseId07, '2020-02-03 13:05:27', @NonStaffInWarehouseId07, 100);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2018-08-17 10:53:38', @SupplierId12, @StaffInWarehouseId07, '2018-08-21 14:05:26', @StaffInWarehouseId01, '2020-02-02 16:27:06', 35);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-02-03 08:43:04', @SupplierId01, @StaffInWarehouseId03, '2019-02-10 16:17:03', @StaffInWarehouseId02, '2019-07-19 10:48:23', 3);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-06-29 08:42:16', @SupplierId08, @StaffInWarehouseId02, '2019-06-30 12:13:04', @StaffInWarehouseId03, '2019-12-05 13:09:56', 9);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-11-07 14:04:06', @SupplierId09, @StaffInWarehouseId02, '2019-11-09 12:03:29', @StaffInWarehouseId08, '2020-04-22 16:19:26', 51);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '氧氟沙星眼膏';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2019-08-03 12:13:04', @SupplierId06, @StaffInWarehouseId08, '2019-08-04 13:17:36', 23);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-04-13 13:17:36', @SupplierId08, @StaffInWarehouseId07, '2020-04-24 08:06:13', 160);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-01-05 12:03:29', @SupplierId12, @StaffInWarehouseId09, '2019-01-08 10:03:21', @StaffInWarehouseId07, '2019-01-16 11:49:04', @NonStaffInWarehouseId09, 280);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-01-05 12:03:29', @SupplierId12, @StaffInWarehouseId09, '2019-01-08 10:03:21', @StaffInWarehouseId06, '2019-01-23 15:46:02', @NonStaffInWarehouseId01, 260);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-06-24 13:17:36', @SupplierId01, @StaffInWarehouseId05, '2019-06-25 13:53:28', @StaffInWarehouseId06, '2019-06-28 16:31:08', @NonStaffInWarehouseId04, 360);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-08-03 12:13:04', @SupplierId06, @StaffInWarehouseId08, '2019-08-04 13:17:36', @StaffInWarehouseId07, '2019-09-03 13:05:27', @NonStaffInWarehouseId07, 100);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-01-05 12:03:29', @SupplierId12, @StaffInWarehouseId09, '2019-01-08 10:03:21', @StaffInWarehouseId08, '2019-12-18 15:09:25', 5);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-06-24 13:17:36', @SupplierId01, @StaffInWarehouseId05, '2019-06-25 13:53:28', @StaffInWarehouseId02, '2020-06-02 16:19:27', 10);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '莫匹罗星软膏';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2019-09-14 12:03:29', @SupplierId04, @StaffInWarehouseId01, '2019-09-19 13:45:30', 36);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-06-01 14:04:06', @SupplierId12, @StaffInWarehouseId04, '2020-06-03 11:15:36', 109);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-06-15 13:17:36', @SupplierId10, @StaffInWarehouseId03, '2019-06-16 11:03:44', @StaffInWarehouseId01, '2019-06-23 15:46:02', @NonStaffInWarehouseId01, 260);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-06-15 13:17:36', @SupplierId10, @StaffInWarehouseId03, '2019-06-16 11:03:44', @StaffInWarehouseId01, '2019-06-27 16:31:08', @NonStaffInWarehouseId04, 360);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-06-15 13:17:36', @SupplierId10, @StaffInWarehouseId03, '2019-06-16 11:03:44', @StaffInWarehouseId07, '2019-06-28 13:05:27', @NonStaffInWarehouseId07, 100);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-09-14 12:03:29', @SupplierId04, @StaffInWarehouseId01, '2019-09-19 13:45:30', @StaffInWarehouseId08, '2019-09-22 11:37:08', @NonStaffInWarehouseId07, 220);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-09-14 12:03:29', @SupplierId04, @StaffInWarehouseId01, '2019-09-19 13:45:30', @StaffInWarehouseId09, '2019-09-22 15:05:27', @NonStaffInWarehouseId06, 100);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-09-14 12:03:29', @SupplierId04, @StaffInWarehouseId01, '2019-09-19 13:45:30', @StaffInWarehouseId10, '2019-10-09 11:03:04', @NonStaffInWarehouseId05, 120);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-06-15 13:17:36', @SupplierId10, @StaffInWarehouseId03, '2019-06-16 11:03:44', @StaffInWarehouseId02, '2020-05-23 13:49:07', 35);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '草木犀流浸液片';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2019-08-03 11:15:36', @SupplierId02, @StaffInWarehouseId02, '2019-08-05 10:16:45', 6);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-03-16 16:39:18', @SupplierId02, @StaffInWarehouseId01, '2020-03-17 16:51:15', 36);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-05-03 13:53:28', @SupplierId10, @StaffInWarehouseId04, '2019-05-04 10:53:38', @StaffInWarehouseId08, '2019-05-22 11:37:08', @NonStaffInWarehouseId07, 220);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-06-28 11:03:44', @SupplierId09, @StaffInWarehouseId05, '2019-06-29 13:56:24', @StaffInWarehouseId09, '2019-07-13 15:05:27', @NonStaffInWarehouseId02, 100);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-05-03 13:53:28', @SupplierId10, @StaffInWarehouseId04, '2019-05-04 10:53:38', @StaffInWarehouseId02, '2020-04-17 11:18:27', 7);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-06-28 11:03:44', @SupplierId09, @StaffInWarehouseId05, '2019-06-29 13:56:24', @StaffInWarehouseId01, '2020-06-12 16:13:42', 8);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '复合维生素片';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-02-03 13:17:36', @SupplierId11, @StaffInWarehouseId05, '2020-02-07 10:45:56', 49);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-03-05 08:42:16', @SupplierId05, @StaffInWarehouseId01, '2020-03-09 10:03:46', 400);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-06-14 12:03:29', @SupplierId11, @StaffInWarehouseId05, '2020-06-16 16:40:46', 230);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-05-30 13:17:36', @SupplierId01, @StaffInWarehouseId07, '2019-06-01 15:34:20', @StaffInWarehouseId06, '2019-06-23 11:43:04', @NonStaffInWarehouseId01, 280);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-05-30 13:17:36', @SupplierId01, @StaffInWarehouseId07, '2019-06-01 15:34:20', @StaffInWarehouseId07, '2019-06-27 15:36:42', @NonStaffInWarehouseId04, 240);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-05-30 13:17:36', @SupplierId01, @StaffInWarehouseId07, '2019-06-01 15:34:20', @StaffInWarehouseId08, '2019-06-29 11:37:08', @NonStaffInWarehouseId08, 220);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-05-30 13:17:36', @SupplierId01, @StaffInWarehouseId07, '2019-06-01 15:34:20', @StaffInWarehouseId09, '2019-07-02 15:05:27', @NonStaffInWarehouseId02, 100);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-05-30 13:17:36', @SupplierId01, @StaffInWarehouseId07, '2019-06-01 15:34:20', @StaffInWarehouseId03, '2019-07-09 11:03:04', @NonStaffInWarehouseId05, 120);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-05-30 13:17:36', @SupplierId01, @StaffInWarehouseId07, '2019-06-01 15:34:20', @StaffInWarehouseId04, '2019-07-13 15:26:42', @NonStaffInWarehouseId08, 160);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-05-30 13:17:36', @SupplierId01, @StaffInWarehouseId07, '2019-06-01 15:34:20', @StaffInWarehouseId09, '2019-07-18 08:37:08', @NonStaffInWarehouseId03, 150);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-05-30 13:17:36', @SupplierId01, @StaffInWarehouseId07, '2019-06-01 15:34:20', @StaffInWarehouseId08, '2019-07-19 11:05:27', @NonStaffInWarehouseId06, 100);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-02-03 13:17:36', @SupplierId11, @StaffInWarehouseId05, '2020-02-07 10:45:56', @StaffInWarehouseId07, '2020-03-03 11:49:04', @NonStaffInWarehouseId09, 280);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-02-03 13:17:36', @SupplierId11, @StaffInWarehouseId05, '2020-02-07 10:45:56', @StaffInWarehouseId03, '2020-03-13 15:46:02', @NonStaffInWarehouseId01, 260);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-02-03 13:17:36', @SupplierId11, @StaffInWarehouseId05, '2020-02-07 10:45:56', @StaffInWarehouseId04, '2020-03-18 16:31:08', @NonStaffInWarehouseId04, 360);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-02-03 13:17:36', @SupplierId11, @StaffInWarehouseId05, '2020-02-07 10:45:56', @StaffInWarehouseId07, '2020-03-19 13:05:27', @NonStaffInWarehouseId07, 100);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-02-03 13:17:36', @SupplierId11, @StaffInWarehouseId05, '2020-02-07 10:45:56', @StaffInWarehouseId09, '2020-04-03 11:43:04', @NonStaffInWarehouseId01, 280);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-02-03 13:17:36', @SupplierId11, @StaffInWarehouseId05, '2020-02-07 10:45:56', @StaffInWarehouseId07, '2020-04-07 15:36:42', @NonStaffInWarehouseId04, 240);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-02-03 13:17:36', @SupplierId11, @StaffInWarehouseId05, '2020-02-07 10:45:56', @StaffInWarehouseId08, '2020-04-09 11:37:08', @NonStaffInWarehouseId07, 220);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-02-03 13:17:36', @SupplierId11, @StaffInWarehouseId05, '2020-02-07 10:45:56', @StaffInWarehouseId09, '2020-04-12 15:05:27', @NonStaffInWarehouseId02, 100);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-02-03 13:17:36', @SupplierId11, @StaffInWarehouseId05, '2020-02-07 10:45:56', @StaffInWarehouseId09, '2020-04-13 11:03:04', @NonStaffInWarehouseId05, 120);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-02-03 13:17:36', @SupplierId11, @StaffInWarehouseId05, '2020-02-07 10:45:56', @StaffInWarehouseId03, '2020-04-15 15:26:42', @NonStaffInWarehouseId08, 160);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2020-02-03 13:17:36', @SupplierId11, @StaffInWarehouseId05, '2020-02-07 10:45:56', @StaffInWarehouseId09, '2020-04-18 08:37:08', @NonStaffInWarehouseId03, 150);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-05-30 13:17:36', @SupplierId01, @StaffInWarehouseId07, '2019-06-01 15:34:20', @StaffInWarehouseId01, '2019-11-20 17:09:32', 42);

SELECT @DrugId = DrugId FROM Drugs WHERE DrugName = '舍雷肽酶肠溶片';
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2019-07-27 14:04:06', @SupplierId10, @StaffInWarehouseId05, '2019-07-29 13:49:56', 19);
INSERT INTO InDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, DrugNum)
	VALUES(@DrugId, '2020-06-15 08:42:16', @SupplierId10, @StaffInWarehouseId01, '2020-06-19 08:42:16', 210);
INSERT INTO OutDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Out, DrugOutTime, StaffId_Handover, DrugNum)
	VALUES(@DrugId, '2019-06-10 08:42:16', @SupplierId11, @StaffInWarehouseId04, '2019-06-11 15:44:30', @StaffInWarehouseId08, '2019-07-05 15:26:42', @NonStaffInWarehouseId08, 160);
INSERT INTO DestroyedDrugs(DrugId, DrugBatch, SupplierId, StaffId_In, DrugInTime, StaffId_Destroy, DrugDestroyTime, DrugNum)
	VALUES(@DrugId, '2019-06-10 08:42:16', @SupplierId11, @StaffInWarehouseId04, '2019-06-11 15:44:30', @StaffInWarehouseId02, '2020-05-23 10:29:26', 10);
