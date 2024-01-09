USE WWIGlobal;
GO

DROP PROCEDURE IF EXISTS Sales.spNumberOfCustomersBothBDs
GO
CREATE Procedure Sales.spNumberOfCustomersBothBDs
AS
BEGIN
    DECLARE @oldNumberOfCustomers INT;
    DECLARE @newNumberOfCustomers INT;
    SET @oldNumberOfCustomers=(SELECT COUNT(*)
    FROM WWI_OldData.dbo.Customer);
    SET @newNumberOfCustomers=(SELECT COUNT(*)
    FROM WWIGlobal.Sales.Customer);
    SELECT @oldNumberOfCustomers 'Nº de Costumers Antigo', @newNumberOfCustomers 'Nº de Costumers Novo'
END;
GO

DROP FUNCTION IF EXISTS Sales.fnGetNumberCustomersPerCategoryOldDataBase
GO
CREATE FUNCTION Sales.fnGetNumberCustomersPerCategoryOldDataBase(
    @Category VARCHAR 
(40))
RETURNS INT
AS
BEGIN
    DECLARE @Sum INT
    SET @Sum = CASE 
                    WHEN @Category ='Gift Shop'
                        THEN  (SELECT COUNT(*)
    FROM WWI_OldData.dbo.Customer c
    WHERE c.Category=@Category COLLATE Latin1_General_CI_AS)+(SELECT COUNT(*)
    FROM WWI_OldData.dbo.Customer c
    WHERE c.Category='GiftShop' COLLATE Latin1_General_CI_AS)
                    WHEN @Category ='Kiosk'
                        THEN (SELECT COUNT(*)
    FROM WWI_OldData.dbo.Customer c
    WHERE c.Category=@Category COLLATE Latin1_General_CI_AS)+(SELECT COUNT(*)
    FROM WWI_OldData.dbo.Customer c
    WHERE c.Category='Quiosk' COLLATE Latin1_General_CI_AS)
                    ELSE (SELECT COUNT(*)
    FROM WWI_OldData.dbo.Customer c
    WHERE c.Category=@Category COLLATE Latin1_General_CI_AS)
END;
    RETURN @Sum
END
GO

DROP FUNCTION IF EXISTS Sales.fnGetTotalSalesPerStockItemOldDataBase
GO
CREATE FUNCTION Sales.fnGetTotalSalesPerStockItemNewDataBase(
    @Description VARCHAR(100)
)
RETURNS MONEY
AS
BEGIN
    SET @Description = (SELECT TOP(1)
        value
    FROM string_split(@Description,'('))
    SET @Description = (SELECT Replace(@Description,'250g',''))
    SET @Description = (SELECT Replace(@Description,'500g',''))
    SET @Description = (SELECT Replace(@Description,'5kg',''))
    SET @Description = (SELECT Replace(@Description,'5mm',''))
    SET @Description = (SELECT Replace(@Description,'9mm',''))
    SET @Description = (SELECT Replace(@Description,'18mm',''))
    SET @Description = (SELECT Replace(@Description,'48mmx75m',''))
    SET @Description = (SELECT Replace(@Description,'48mmx100m',''))
    SET @Description = (SELECT Replace(@Description,'50m',''))
    SET @Description = (SELECT Replace(@Description,'20m',''))
    SET @Description = (SELECT Replace(@Description,'10m',''))

    SET @Description = CASE
			WHEN @Description like '"The Gu"%'
				THEN '"The Gu" T-Shirt'
			WHEN @Description like '10 mm Anti static%'
				THEN '10mm Anti Static Bubble Wrap'
			WHEN @Description like '20 mm Anti static%'
				THEN '20mm Anti Static Bubble Wrap'
			WHEN @Description like '32 mm Anti static%'
				THEN '32mm Anti Static Bubble Wrap'
			WHEN @Description like '10 mm Double sided%'
				THEN '10mm Double Sided Bubble Wrap'
			WHEN @Description like '20 mm Double sided%'
				THEN '20mm Double Sided Bubble Wrap'
			WHEN @Description like '32 mm Double sided%'
				THEN '32mm Double Sided Bubble Wrap'
			WHEN @Description like '3 kg%'
				THEN 'Courier Post Bag'
			WHEN @Description like 'Air cushion m%'
				THEN 'Air Cushion Machine'
			WHEN @Description like 'Air cushion f%'
				THEN 'Air Cushion Film'
			WHEN @Description like 'Alien%'
				THEN 'Alien Officer Hoodie'
			WHEN @Description like 'Animal with%'
				THEN 'Animal with Big Feet Slippers'
			WHEN @Description like 'Black and orange f%'
				THEN 'Fragile Despatch Tape'
			WHEN @Description like 'Black and orange g%'
				THEN 'Glass with Care Despatch Tape'
			WHEN @Description like 'Black and orange h%'
				THEN 'Handle with Care Despatch Tape'
			WHEN @Description like 'Black and orange t%'
				THEN 'This Way Up Despatch Tape'
			WHEN @Description like 'Black and y%'
				THEN 'Heavy Despatch Tape'
			WHEN @Description like 'Shipping carton%'
				THEN 'Shipping Carton'
			WHEN @Description like 'Superhero%'
				THEN 'Superhero Jacket'
			WHEN @Description like 'Void fill%'
				THEN 'Void Fill Bag'
			WHEN @Description like 'White chocolate moon%'
				THEN 'White Chocolate Moon Rocks'
			WHEN @Description like 'White chocolate snow%'
				THEN 'White Chocolate Snow Balls'
			ELSE @Description
		END
    DECLARE @result MONEY
    SET @result = (SELECT SUM(p.UnitPrice*sd.OrderQty)
    FROM WWIGlobal.Sales.SalesOrderDetail sd
        JOIN WWIGlobal.Sales.Product p on p.ProductID=sd.ProductID
        JOIN WWIGlobal.Sales.ProductDescription pd on pd.DescriptionID=p.ProductDescription
    WHERE pd.[Description]=@Description)
    RETURN @result;
END
GO

DROP PROCEDURE IF EXISTS Sales.spTotalValuePerProductBothBDs
GO
CREATE Procedure Sales.spTotalValuePerProductBothBDs
AS
BEGIN
    SELECT si.[Stock Item], sum(s.[Unit Price]*s.Quantity)'Total Sales Old Database ($)', WWIGlobal.Sales.fnGetTotalSalesPerStockItemNewDataBase(si.[Stock Item])'Total Sales New Database ($)'
    FROM WWI_OldData.dbo.Sale s
        JOIN WWI_OldData.dbo.[Stock Item] si ON si.[Stock Item Key]=s.[Stock Item Key]
    GROUP BY [Stock Item]
    ORDER BY 2 DESC
END
GO

DROP PROCEDURE IF EXISTS Sales.spNumberOfCustomersBothBDsPerCategory
GO
CREATE Procedure Sales.spNumberOfCustomersBothBDsPerCategory
AS
BEGIN
    SELECT co.Category , Sales.fnGetNumberCustomersPerCategoryOldDataBase(co.Category) 'Nº da Database Antiga', (select count(*)
        from WWIGlobal.Sales.Customer c
            JOIN WWIGlobal.Sales.Category ct on ct.CategoryID =c.Category
        where co.Category COLLATE Latin1_General_CI_AS =ct.Name
        )'Nº da Database Nova'
    FROM WWI_OldData.dbo.Customer co
    WHERE co.Category COLLATE Latin1_General_CI_AS IN (SELECT cc.Name
    FROM WWIGlobal.Sales.Category cc)
    GROUP BY co.Category
    ORDER BY co.Category
END;
GO

DROP FUNCTION IF EXISTS Sales.fnGetTotalSalesPerStockItemPerYearNewDataBase
GO
CREATE FUNCTION Sales.fnGetTotalSalesPerStockItemPerYearNewDataBase(
    @Description VARCHAR(100),
    @year VARCHAR(4)
)
RETURNS MONEY
AS
BEGIN
    SET @Description = (SELECT TOP(1)
        value
    FROM string_split(@Description,'('))
    SET @Description = (SELECT Replace(@Description,'250g',''))
    SET @Description = (SELECT Replace(@Description,'500g',''))
    SET @Description = (SELECT Replace(@Description,'5kg',''))
    SET @Description = (SELECT Replace(@Description,'5mm',''))
    SET @Description = (SELECT Replace(@Description,'9mm',''))
    SET @Description = (SELECT Replace(@Description,'18mm',''))
    SET @Description = (SELECT Replace(@Description,'48mmx75m',''))
    SET @Description = (SELECT Replace(@Description,'48mmx100m',''))
    SET @Description = (SELECT Replace(@Description,'50m',''))
    SET @Description = (SELECT Replace(@Description,'20m',''))
    SET @Description = (SELECT Replace(@Description,'10m',''))

    SET @Description = CASE
			WHEN @Description like '"The Gu"%'
				THEN '"The Gu" T-Shirt'
			WHEN @Description like '10 mm Anti static%'
				THEN '10mm Anti Static Bubble Wrap'
			WHEN @Description like '20 mm Anti static%'
				THEN '20mm Anti Static Bubble Wrap'
			WHEN @Description like '32 mm Anti static%'
				THEN '32mm Anti Static Bubble Wrap'
			WHEN @Description like '10 mm Double sided%'
				THEN '10mm Double Sided Bubble Wrap'
			WHEN @Description like '20 mm Double sided%'
				THEN '20mm Double Sided Bubble Wrap'
			WHEN @Description like '32 mm Double sided%'
				THEN '32mm Double Sided Bubble Wrap'
			WHEN @Description like '3 kg%'
				THEN 'Courier Post Bag'
			WHEN @Description like 'Air cushion m%'
				THEN 'Air Cushion Machine'
			WHEN @Description like 'Air cushion f%'
				THEN 'Air Cushion Film'
			WHEN @Description like 'Alien%'
				THEN 'Alien Officer Hoodie'
			WHEN @Description like 'Animal with%'
				THEN 'Animal with Big Feet Slippers'
			WHEN @Description like 'Black and orange f%'
				THEN 'Fragile Despatch Tape'
			WHEN @Description like 'Black and orange g%'
				THEN 'Glass with Care Despatch Tape'
			WHEN @Description like 'Black and orange h%'
				THEN 'Handle with Care Despatch Tape'
			WHEN @Description like 'Black and orange t%'
				THEN 'This Way Up Despatch Tape'
			WHEN @Description like 'Black and y%'
				THEN 'Heavy Despatch Tape'
			WHEN @Description like 'Shipping carton%'
				THEN 'Shipping Carton'
			WHEN @Description like 'Superhero%'
				THEN 'Superhero Jacket'
			WHEN @Description like 'Void fill%'
				THEN 'Void Fill Bag'
			WHEN @Description like 'White chocolate moon%'
				THEN 'White Chocolate Moon Rocks'
			WHEN @Description like 'White chocolate snow%'
				THEN 'White Chocolate Snow Balls'
			ELSE @Description
		END
    DECLARE @result MONEY
    SET @result =(SELECT SUM(Sales.fnCalcTotalPriceSale(od.SalesOrderDetailID))
    FROM WWIGlobal.Sales.SalesOrderHeader sh
        JOIN WWIGlobal.Sales.SalesOrderDetail od on od.SalesOrderID=sh.SalesOrderID
        JOIN WWIGlobal.Sales.ProductDescription pd on pd.DescriptionID=od.ProductID
    GROUP BY YEAR(sh.DueDate),pd.[Description]
    HAVING YEAR(sh.DueDate) =@year AND pd.[Description]=@Description)
    RETURN @result;
END
GO

DROP PROCEDURE IF EXISTS Sales.spGetTotalSalesPerYearPerStockItem
GO
CREATE PROCEDURE Sales.spGetTotalSalesPerYearPerStockItem
AS
BEGIN
    SELECT YEAR(s.[Delivery Date Key])'Year', si.[Stock Item], sum(s.[Total Including Tax])'Total Sales Old Database', Sales.fnGetTotalSalesPerStockItemPerYearNewDataBase(si.[Stock Item],YEAR(s.[Delivery Date Key]))'Total Sales New Database'
    FROM WWI_OldData.dbo.Sale s
        JOIN WWI_OldData.dbo.[Stock Item] si on si.[Stock Item Key]=s.[Stock Item Key]
    GROUP BY YEAR(s.[Delivery Date Key]),si.[Stock Item]
    HAVING YEAR(s.[Delivery Date Key]) IS NOT NULL
    ORDER BY [Stock Item], YEAR(s.[Delivery Date Key])
END
GO


DROP PROCEDURE IF EXISTS Sales.spNumberOfSalesBothBDsPerEmployee
GO
CREATE PROCEDURE Sales.spNumberOfSalesBothBDsPerEmployee
AS
BEGIN
    WITH
        NewSales
        AS
        (
            SELECT s.employeeID 'SalesEmployee', COUNT(*) 'SalesCount'
            FROM WWIGlobal.Sales.SalesOrderHeader s
            GROUP BY s.EmployeeID
        )
    SELECT e.Employee, COUNT(DISTINCT [WWI Invoice ID]) 'Old Sales', (SELECT ns.SalesCount
        FROM NewSales ns
            JOIN WWIGlobal.Sales.Employee ee on ee.EmployeeID=ns.SalesEmployee
        where ee.Name=e.Employee COLLATE Latin1_General_CI_AS) 'New Sales'
    FROM WWI_OldData.dbo.Sale s
        JOIN WWI_OldData.dbo.Employee e on e.[Employee Key]=s.[Salesperson Key]
    GROUP BY  e.Employee
    ORDER BY Employee
END
GO

DROP FUNCTION IF EXISTS Sales.fnGetTotalSalesPerCityPerYearNewBD
GO
CREATE FUNCTION Sales.fnGetTotalSalesPerCityPerYearNewBD(
    @year int,
    @cityName VARCHAR(30),
    @state VARCHAR(30)
)
RETURNS MONEY
AS
BEGIN
    SET @state = CASE
				WHEN EXISTS(SELECT *
    FROM WWIGlobal.Sales.State s
    WHERE s.Name=@state)
					THEN (SELECT s.Name
    FROM WWIGlobal.Sales.State s
    WHERE s.Name=@state)
				WHEN @state='Virgin Islands (US Territory)'
					THEN 'Virgin Islands, U.S.'
				WHEN @state='Massachusetts[E]'
					THEN 'Massachusetts'
				WHEN @state='Puerto Rico (US Territory)'
					THEN 'Puerto Rico'
				END;
    DECLARE @result MONEY
    SET @result=(SELECT SUM(Sales.fnCalcTotalPriceSale(sd.SalesOrderDetailID))
    FROM WWIGlobal.Sales.SalesOrderHeader sh
        JOIN WWIGlobal.Sales.SalesOrderDetail sd on sd.SalesOrderID=sh.SalesOrderID
        JOIN WWIGlobal.Sales.Customer c on c.CustomerID=sh.CustomerID
        JOIN WWIGlobal.Sales.Office o on o.OfficeID=c.CustomerOffice
        JOIN WWIGlobal.Sales.OfficeLocation ol on ol.LocationID=o.OfficeLocation
        JOIN WWIGlobal.Sales.City cty on cty.CityID=ol.City
        JOIN WWIGlobal.Sales.[State] st on st.Code=cty.[State]
    GROUP BY cty.Name,st.Name,YEAR(sh.DueDate)
    HAVING YEAR(sh.DueDate)=@year AND cty.Name=@cityName AND st.Name=@state)
    RETURN @result
END
GO

DROP PROCEDURE IF EXISTS spTotalSalesPerYearPerCity
GO
CREATE PROCEDURE spTotalSalesPerYearPerCity
AS
BEGIN
    SELECT YEAR(s.[Delivery Date Key])'Year', c.City, c.[State Province],sum(s.[Total Including Tax])'Total Sales Old Database ($)',Sales.fnGetTotalSalesPerCityPerYearNewBD(YEAR(s.[Delivery Date Key]),c.City,c.[State Province])'Total Sales New Database ($)'
    FROM WWI_OldData.dbo.Sale s
        JOIN WWI_OldData.dbo.City c on c.[City Key]=s.[City Key]
    GROUP BY YEAR(s.[Delivery Date Key]),c.City,c.[State Province]
    HAVING YEAR(s.[Delivery Date Key]) IS NOT NULL
    ORDER BY 1,2,3,4
END
GO

-- Verify Data Migration

-- Verifies the number of customers in both Databases
EXEC Sales.spNumberOfCustomersBothBDs;

-- Verifies the number of customers per category in both Databases
EXEC Sales.spNumberOfCustomersBothBDsPerCategory;

-- Verifies the number of sales per employee in both Databases
EXEC Sales.spNumberOfSalesBothBDsPerEmployee;

-- Verifies the total of sales per stock item in both Databases
EXEC Sales.spTotalValuePerProductBothBDs;

-- Verifies the total of sales per stock item per year in both Databases
EXEC Sales.spGetTotalSalesPerYearPerStockItem;

-- Verifies the number of sales per city per year in both Databases
EXEC spTotalSalesPerYearPerCity;