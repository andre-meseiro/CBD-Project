USE WWIGlobal;

DROP VIEW IF EXISTS Sales.vCityStates;
GO
CREATE VIEW Sales.vCityStates
AS
	SELECT c.Name City, s.Name State
	FROM WWIGlobal.Sales.City c
		join WWIGlobal.Sales.State s on s.Code=c.State
GO

DROP VIEW IF EXISTS Sales.vStateSalesTerritory
GO
CREATE VIEW Sales.vStateSalesTerritory
AS
	SELECT s.Name State, st.Name 'Sales Territory'
	FROM WWIGlobal.Sales.State s
		join WWIGlobal.Sales.SalesTerritory st on st.SalesTerritoryID=s.SalesTerritory 
GO

DROP VIEW IF EXISTS vCustomer
GO
CREATE VIEW vCustomer
AS
	select og.Name 'Group', COALESCE(ct.Name,'Head') 'City', COALESCE(s.Name,'Office')'State', ol.PostalCode 'Postal Code', c.PrimaryContact 'Primary Contact', cat.Name 'Category'
	from WWIGlobal.Sales.Customer c
		left join WWIGlobal.Sales.Office o on o.OfficeID=c.CustomerOffice
		left join WWIGlobal.Sales.OfficeGroup og on og.GroupID=o.OfficeGroup
		left join WWIGlobal.Sales.OfficeLocation ol on ol.LocationID=o.OfficeLocation
		left join WWIGlobal.Sales.City ct on ct.CityID=ol.City
		left join WWIGlobal.Sales.State s on s.Code=ct.State
		left join WWIGlobal.Sales.Category cat on cat.CategoryID=c.Category 
GO

DROP VIEW IF EXISTS Sales.vSalesEmployee
GO
CREATE VIEW Sales.vSalesEmployee
AS
	SELECT e.Name, e.PreferedName
	FROM WWIGlobal.Sales.Employee e
	WHERE e.EmployeeID in (SELECT se.EmployeeID
	FROM WWIGlobal.Sales.SalesEmployee se);
GO

DROP VIEW IF EXISTS Sales.vProducts
GO
CREATE VIEW Sales.vProducts
AS
	select pd.Description 'Description', c.Name 'Color', s.Size, p.Weight 'Weight (Kg)', pk.Name 'Package', p.TaxRate 'Tax Rate', p.UnitPrice 'Unit Price', p.RetailPrice 'Retail Price'
	from WWIGlobal.Sales.Product p
		JOIN WWIGlobal.Sales.ProductDescription pd on pd.DescriptionID = p.ProductDescription
		join WWIGlobal.Sales.Color c on c.ColorID = p.Color
		join WWIGlobal.Sales.Size s on s.SizeID = p.Size
		join WWIGlobal.Sales.Package pk on pk.PackageID = p.SellPackage 
GO

DROP VIEW IF EXISTS Sales.vSalesHeader
GO
CREATE VIEW Sales.vSalesHeader
AS
	SELECT og.Name 'Group', COALESCE(cty.Name,'Head')'City', COALESCE(st.Name,'Office') 'State', OrderDate 'Order Date', DueDate 'Delivery Date', oog.Name 'Bill To', COALESCE(city.Name,'Head')'City To Bill', COALESCE(sta.Name,'Office')'State To Bill', e.Name 'Employee', (SELECT SUM(p.UnitPrice*sd.OrderQty)
		FROM WWIGlobal.Sales.SalesOrderDetail sd
			JOIN WWIGlobal.Sales.Product p on p.ProductID=sd.ProductID
		WHERE sd.SalesOrderID=sh.SalesOrderID)'Sub Total', sh.TaxAmount 'Tax Amount', FORMAT((SELECT SUM(p.UnitPrice*sd.OrderQty)
		FROM WWIGlobal.Sales.SalesOrderDetail sd
			JOIN WWIGlobal.Sales.Product p on p.ProductID=sd.ProductID
		WHERE sd.SalesOrderID=sh.SalesOrderID) + (SELECT SUM(p.UnitPrice*sd.OrderQty)
		FROM WWIGlobal.Sales.SalesOrderDetail sd
			JOIN WWIGlobal.Sales.Product p on p.ProductID=sd.ProductID
		WHERE sd   .SalesOrderID=sh.SalesOrderID) * (sh.TaxAmount/100),'N2')'Total'
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
GO

DROP VIEW IF EXISTS vSalesDetails
GO
CREATE VIEW vSalesDetails
AS
	SELECT sd.SalesOrderID, sd.OrderQty , pd.[Description], s.[Size], c.Name 'Color', p.UnitPrice
	FROM WWIGlobal.Sales.SalesOrderDetail sd
		JOIN WWIGlobal.Sales.Product p on p.ProductID=sd.ProductID
		JOIN WWIGlobal.Sales.ProductDescription pd on pd.DescriptionID = p.ProductDescription
		join WWIGlobal.Sales.Color c on c.ColorID = p.Color
		join WWIGlobal.Sales.Size s on s.SizeID = p.Size
		join WWIGlobal.Sales.Package pk on pk.PackageID = p.SellPackage 
GO
