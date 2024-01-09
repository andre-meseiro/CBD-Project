USE WWIGlobal

-- Role of Administrator
CREATE ROLE Administrador
GRANT INSERT TO Administrador
GRANT ALTER TO Administrador
GRANT DELETE TO Administrador
GRANT SELECT TO Administrador
GO

CREATE USER AdminWWIGlobal
WITHOUT LOGIN
GO

EXEC sp_addrolemember 'Administrador' ,'AdminWWIGlobal'
GO

EXECUTE AS USER = 'AdminWWIGlobal'
	SELECT * FROM Sales.Category
REVERT
GO

-- Role of EmployeeSalesPerson
CREATE ROLE EmployeeSalesPerson
GRANT INSERT ON Sales.SalesOrderDetail TO EmployeeSalesPerson
GRANT UPDATE ON Sales.SalesOrderDetail TO EmployeeSalesPerson
GRANT DELETE ON Sales.SalesOrderDetail TO EmployeeSalesPerson
GRANT INSERT ON Sales.SalesOrderHeader TO EmployeeSalesPerson
GRANT UPDATE ON Sales.SalesOrderHeader TO EmployeeSalesPerson
GRANT DELETE ON Sales.SalesOrderHeader TO EmployeeSalesPerson
GRANT SELECT ON SCHEMA::Sales TO EmployeeSalesPerson
GO

CREATE USER EmployeeSales
WITHOUT LOGIN
GO

EXEC sp_addrolemember 'EmployeeSalesPerson' ,'EmployeeSales'
GO

EXECUTE AS USER = 'EmployeeSales'
	SELECT * FROM Sales.Category
REVERT
GO

EXECUTE AS USER = 'EmployeeSales'
	INSERT INTO Sales.SalesOrderHeader (OrderDate,DueDate,CustomerID,BillToID,EmployeeID,TaxAmount) VALUES (GETDATE(),GETDATE(),1,1,1,0)	
REVERT
GO

EXECUTE AS USER = 'EmployeeSales'
	UPDATE Sales.SalesOrderHeader 
	SET TaxAmount = 13
	WHERE SalesOrderID=(SELECT TOP(1) SalesOrderID FROM Sales.SalesOrderHeader ORDER BY SalesOrderID DESC)
REVERT
GO

SELECT * 
FROM Sales.SalesOrderHeader 
ORDER BY 2 DESC

EXECUTE AS USER = 'EmployeeSales'
	DELETE Sales.SalesOrderHeader
	WHERE SalesOrderID=(SELECT TOP(1) SalesOrderID FROM Sales.SalesOrderHeader ORDER BY SalesOrderID DESC)
REVERT
GO


-- Role of SalesTerritory
DROP VIEW IF EXISTS Sales.vSalesHeader
GO
CREATE VIEW Sales.vSalesHeader
AS
	SELECT sh.SalesOrderID ID, og.Name 'Group', COALESCE(cty.Name,'Head')'City', COALESCE(st.Name,'Office') 'State', OrderDate 'Order Date', DueDate 'Delivery Date', oog.Name 'Bill To', COALESCE(city.Name,'Head')'City To Bill', COALESCE(sta.Name,'Office')'State To Bill', e.Name 'Employee'
	FROM WWIGlobal.Sales.SalesOrderHeader sh
		JOIN WWIGlobal.Sales.Employee e on e.EmployeeID=sh.EmployeeID
		JOIN WWIGlobal.Sales.Customer c on c.CustomerID=sh.CustomerID
		JOIN WWIGlobal.Sales.Office o on o.OfficeID=c.CustomerOffice
		JOIN WWIGlobal.Sales.OfficeGroup og on og.GroupID=o.OfficeGroup
		LEFT JOIN WWIGlobal.Sales.OfficeLocation ol on ol.LocationID=o.OfficeLocation
		LEFT JOIN WWIGlobal.Sales.City cty on cty.CityID=ol.City
		LEFT JOIN WWIGlobal.Sales.[State] st on st.Code=cty.[State]
		JOIN WWIGlobal.Sales.Customer cc on cc.CustomerID=sh.BillToID
		JOIN WWIGlobal.Sales.Office oo on oo.OfficeID=cc.CustomerOffice
		JOIN WWIGlobal.Sales.OfficeGroup oog on oog.GroupID=oo.OfficeGroup
		LEFT JOIN WWIGlobal.Sales.OfficeLocation ool on ool.LocationID=oo.OfficeLocation
		LEFT JOIN WWIGlobal.Sales.City city on city.CityID=ool.City
		LEFT JOIN WWIGlobal.Sales.[State] sta on sta.Code=city.[State]
		JOIN WWIGlobal.Sales.SalesTerritory salest on st.SalesTerritory=salest.SalesTerritoryID
		WHERE salest.Name='Rocky Mountain'
GO

DROP VIEW IF EXISTS Sales.vRockyMountainSalesHeader
GO
CREATE VIEW Sales.vRockyMountainSalesHeader
AS
	SELECT * FROM Sales.vSalesHeader
GO

DROP VIEW IF EXISTS Sales.vSalesDetails
GO
CREATE view Sales.vSalesDetails
AS
	SELECT sd.SalesOrderID 'Sale ID',sd.OrderQty,pd.Description,c.Name'Color',s.Size,p.Weight,p.LeadTimeDays,p.TaxRate,CONVERT(varchar(40),DECRYPTBYKEY(p.RetailPriceEncrypted))'Retail Price',CONVERT(varchar(40),DECRYPTBYKEY(p.UnitPriceEncrypted))'Unit Price'
	FROM WWIGlobal.Sales.SalesOrderDetail sd
	JOIN Sales.Product p on sd.ProductID=p.ProductID
	JOIN Sales.ProductDescription pd on pd.DescriptionID=p.ProductDescription
	JOIN Sales.Color c on c.ColorID=p.Color
	JOIN Sales.Size s on s.SizeID=p.Size
GO

DROP VIEW IF EXISTS Sales.vRockyMountainSalesDetails
GO
CREATE VIEW Sales.vRockyMountainSalesDetails
AS
	SELECT * FROM Sales.vSalesDetails
GO

CREATE ROLE SalesTerritory
GRANT SELECT ON Sales.vRockyMountainSalesDetails TO SalesTerritory
GRANT SELECT ON Sales.vRockyMountainSalesHeader TO SalesTerritory

CREATE USER SalesTerritoryUser
WITHOUT LOGIN
GO

EXEC sp_addrolemember 'SalesTerritory' ,'SalesTerritoryUser'
GO

EXECUTE AS USER = 'SalesTerritoryUser'
	SELECT * FROM Sales.vRockyMountainSalesDetails
REVERT
GO

EXECUTE AS USER = 'SalesTerritoryUser'
	SELECT * FROM Sales.vRockyMountainSalesHeader
REVERT
GO