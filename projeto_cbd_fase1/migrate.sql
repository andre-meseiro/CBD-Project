USE WWIGlobal;
GO

-- Procedure to migrate the Color registries FROM  the old database to the new database.
DROP PROCEDURE IF EXISTS color_migrate;
GO
CREATE PROCEDURE color_migrate
AS
BEGIN
	DECLARE @oldCode INT;
	DECLARE @oldColor VARCHAR(20)
	DECLARE color_cursor CURSOR  
FOR SELECT c.IdColor, c.Color
	FROM WWI_OldData.dbo.Color c;
	OPEN color_cursor
	FETCH NEXT FROM  color_cursor
INTO @oldCode,@oldColor;
	WHILE @@FETCH_STATUS = 0  
	BEGIN
		IF(@oldCode NOT IN (SELECT c.ColorID
		FROM WWIGlobal.Sales.Color c))
		INSERT INTO WWIGlobal.Sales.Color
		VALUES(@oldCode, @oldColor);
		FETCH NEXT FROM  color_cursor
	INTO @oldCode,@oldColor;
	END
	CLOSE color_cursor
	DEALLOCATE color_cursor
END;	
GO

-- Procedure to migrate the State registries FROM  the old database to the new database.
DROP PROCEDURE IF EXISTS state_migrate;
GO
CREATE PROCEDURE state_migrate
AS
BEGIN
	DECLARE @oldCode VARCHAR(2);
	DECLARE @oldState VARCHAR(50)
	DECLARE @cityState VARCHAR(30)
	DECLARE @stateTerritory INT;
	DECLARE state_cursor CURSOR  
FOR SELECT s.Code, s.Name
	FROM WWI_OldData.dbo.States s;
	OPEN state_cursor
	FETCH NEXT FROM  state_cursor
INTO @oldCode,@oldState;
	WHILE @@FETCH_STATUS = 0  
	BEGIN
		SET @cityState = 
			CASE	
				WHEN @oldState='Virgin Islands, U.S.'
					THEN 'Virgin Islands (US Territory)'
				WHEN @oldState='Massachusetts'
					THEN 'Massachusetts[E]'
				WHEN @oldState='Puerto Rico'
					THEN 'Puerto Rico (US Territory)'
				ELSE @oldState
			END;

		SET @stateTerritory=(SELECT st.SalesTerritoryID
		FROM WWIGlobal.Sales.SalesTerritory st
		WHERE st.Name=
																		(SELECT c.[Sales Territory] COLLATE Latin1_General_CI_AS
		FROM WWI_OldData.dbo.City c
		GROUP BY c.[State Province],c.[Sales Territory]
		HAVING c.[State Province]=@cityState));
		IF(@stateTerritory is null)
		SET @stateTerritory = 9
		IF(@oldCode NOT IN (SELECT s.Code
		FROM WWIGlobal.Sales.State s))
		INSERT INTO WWIGlobal.Sales.State
		VALUES(@oldCode, @oldState, @stateTerritory);

		FETCH NEXT FROM  state_cursor
	INTO @oldCode,@oldState;
	END
	CLOSE state_cursor
	DEALLOCATE state_cursor
END;	
GO

-- Procedure to migrate the Package registries FROM  the old database to the new database.
DROP PROCEDURE IF EXISTS package_migrate;
GO
CREATE PROCEDURE package_migrate
AS
BEGIN
	DECLARE @oldPackageID INT;
	DECLARE @oldPackage VARCHAR(50)
	DECLARE package_cursor CURSOR  
FOR SELECT p.IdPackage, p.Package
	FROM WWI_OldData.dbo.Package p;
	OPEN package_cursor
	FETCH NEXT FROM  package_cursor
INTO @oldPackageID,@oldPackage;
	WHILE @@FETCH_STATUS = 0  
	BEGIN
		IF((@oldPackage !='N/A') AND @oldPackageID NOT IN (SELECT p.PackageID
			FROM WWIGlobal.Sales.Package p))
		INSERT INTO WWIGlobal.Sales.Package
		VALUES(@oldPackageID, @oldPackage);
		FETCH NEXT FROM  package_cursor
	INTO @oldPackageID,@oldPackage;
	END
	CLOSE package_cursor
	DEALLOCATE package_cursor
END;	
GO

-- Procedure to migrate the City registries FROM  the old database to the new database.
DROP PROCEDURE IF EXISTS city_migrate
GO
CREATE PROCEDURE city_migrate
AS
BEGIN
	DECLARE @count INT;
	DECLARE @oldName VARCHAR(30);
	DECLARE @oldState VARCHAR(50);
	DECLARE @stateCode VARCHAR(2);
	DECLARE @population INT;
	DECLARE city_cursor CURSOR  
FOR SELECT c.City, c.[State Province], c.[Latest Recorded Population]
	FROM WWI_OldData.dbo.City c;
	OPEN city_cursor
	FETCH NEXT FROM  city_cursor
INTO @oldName,@oldState,@population;
	SET @count=1;
	WHILE @@FETCH_STATUS = 0  
	BEGIN
		SET @stateCode = 
			CASE
				WHEN EXISTS(SELECT *
		FROM WWIGlobal.Sales.State s
		WHERE s.Name=@oldState)
					THEN (SELECT s.Code
		FROM WWIGlobal.Sales.State s
		WHERE s.Name=@oldState)
				WHEN @oldState='Virgin Islands (US Territory)'
					THEN 'VI'
				WHEN @oldState='Massachusetts[E]'
					THEN 'MA'
				WHEN @oldState='Puerto Rico (US Territory)'
					THEN 'PR'
				END;
		IF(not exists(SELECT *
		FROM WWIGlobal.Sales.City c
		GROUP BY c.State,c.Name
		HAVING c.Name=@oldName AND c.State=@stateCode))
				BEGIN
			INSERT INTO WWIGlobal.Sales.City
				(CityID, Name,State)
			VALUES
				(@count, @oldName, @stateCode);
			IF(@population!=0 AND not exists(SELECT *
				FROM WWIGlobal.Sales.Population
				WHERE CityID=@count))
					INSERT INTO WWIGlobal.Sales.Population
				(CityID,Population)
			VALUES
				(@count, @population);
			SET @count=@count+1;
		END
		FETCH NEXT FROM  city_cursor
		INTO @oldName,@oldState,@population;
	END
	CLOSE city_cursor
	DEALLOCATE city_cursor
END;
GO

-- Procedure to migrate the Sales Territories registries FROM  the old database to the new database.
DROP PROCEDURE IF EXISTS salesTerritory_migrate;
GO
CREATE PROCEDURE salesTerritory_migrate
AS
BEGIN
	DECLARE @territory VARCHAR(50);
	DECLARE @count INT;
	DECLARE salesTerritory_cursor CURSOR
FOR SELECT c.[Sales Territory]
	FROM WWI_OldData.dbo.City c;
	OPEN salesTerritory_cursor
	FETCH NEXT FROM  salesTerritory_cursor  
INTO @territory;
	SET @count = 1;
	WHILE @@FETCH_STATUS = 0  
	BEGIN
		IF(not exists(SELECT *
		FROM WWIGlobal.Sales.SalesTerritory s
		WHERE s.Name=@territory))
			BEGIN
			INSERT INTO WWIGlobal.Sales.SalesTerritory
				(SalesTerritoryID,Name)
			VALUES
				(@count, @territory);
			SET @count=@count+1;
		END
		FETCH NEXT FROM  salesTerritory_cursor  
	INTO @territory;
	END
	CLOSE salesTerritory_cursor
	DEALLOCATE salesTerritory_cursor
END
GO

-- Procedure to migrate the Category registries FROM  the old database to the new database.
DROP PROCEDURE IF EXISTS category_migrate;
GO
CREATE PROCEDURE category_migrate
AS
BEGIN
	DECLARE @oldCode INT;
	DECLARE @oldCategory VARCHAR(20)
	DECLARE category_cursor CURSOR  
FOR SELECT c.IdCategory, c.Name
	FROM WWI_OldData.dbo.Category c;
	OPEN category_cursor
	FETCH NEXT FROM  category_cursor
INTO @oldCode,@oldCategory;
	WHILE @@FETCH_STATUS = 0  
	BEGIN
		IF(@oldCode NOT IN (SELECT c.CategoryID
		FROM WWIGlobal.Sales.Category c))
		INSERT INTO WWIGlobal.Sales.Category
		VALUES(@oldCode, @oldCategory);
		FETCH NEXT FROM  category_cursor
	INTO @oldCode,@oldCategory;
	END
	CLOSE category_cursor
	DEALLOCATE category_cursor
END;	
GO

-- Procedure to migrate the Custumers registries FROM  the old database to the new database.
DROP PROCEDURE IF EXISTS customer_migrate;
GO
CREATE PROCEDURE customer_migrate
AS
BEGIN
	DECLARE @oldCustomer VARCHAR(40);
	DECLARE @oldCategory VARCHAR(20);
	DECLARE @oldContact VARCHAR(30);
	DECLARE @oldPostalCode VARCHAR(10);
	DECLARE @oldGroup VARCHAR(20);
	DECLARE customer_cursor CURSOR  
FOR SELECT c.Customer, c.Category, c.[Primary Contact], c.[Postal Code], c.[Buying Group]
	FROM WWI_OldData.dbo.Customer c;
	OPEN customer_cursor
	FETCH NEXT FROM  customer_cursor
INTO @oldCustomer,@oldCategory,@oldContact,@oldPostalCode,@oldGroup;
	WHILE @@FETCH_STATUS = 0  
	BEGIN
		DECLARE @city VARCHAR(30);
		DECLARE @state VARCHAR(5);
		DECLARE @cityID INT;
		DECLARE @locationID INT;
		DECLARE @customerID INT;
		DECLARE @groupID INT;
		DECLARE @officeID INT;
		DECLARE @parentID INT;
		DECLARE @categoryID INT;
		IF(not exists(SELECT *
		FROM WWIGlobal.Sales.OfficeGroup og
		WHERE @oldGroup=og.Name))
			INSERT INTO WWIGlobal.Sales.OfficeGroup
			(Name)
		VALUES
			(@oldGroup);
		SET @groupID = (SELECT og.GroupID
		FROM WWIGlobal.Sales.OfficeGroup og
		WHERE @oldGroup=og.Name);
		SET @city =(SUBSTRING(@oldCustomer,14,50));
		IF(@city!='(Head Office)')
			begin
			SET @city = (replace(@city,'(',''))
			SET @city = (replace(@city,')',''))
			SET @state = (SELECT value
			FROM STRING_SPLIT(@city,',')
			WHERE trim(value) in (SELECT s.Code
			FROM WWIGlobal.Sales.State s))
			SET @city = (SELECT top(1)
				value
			FROM STRING_SPLIT(@city,','))
			SET @cityID = (SELECT c.CityID
			FROM WWIGlobal.Sales.City c
			WHERE c.Name=trim(@city) AND c.State=trim(@state))
			INSERT INTO WWIGlobal.Sales.OfficeLocation
				(City,PostalCode)
			VALUES
				(@cityID, @oldPostalCode)
			SET @parentID = (SELECT o.OfficeID
			FROM WWIGlobal.Sales.Office o
				join WWIGlobal.Sales.OfficeLocation ol on ol.LocationID=o.OfficeLocation
			WHERE o.OfficeGroup=@groupID AND ol.City is null)
		end
		else
			begin
			INSERT INTO WWIGlobal.Sales.OfficeLocation
				(PostalCode)
			VALUES
				(@oldPostalCode)
			SET @parentID = null
		end
		SET @locationID = SCOPE_IDENTITY();
		INSERT INTO WWIGlobal.Sales.Office
			(OfficeGroup,OfficeLocation,OfficeParentID)
		VALUES
			(@groupID, @locationID, @parentID)
		SET @officeID = SCOPE_IDENTITY();
		SET @categoryID = 
			CASE
				WHEN EXISTS(SELECT *
		FROM WWIGlobal.Sales.Category c
		WHERE c.Name=@oldCategory)
					THEN (SELECT c.CategoryID
		FROM WWIGlobal.Sales.Category c
		WHERE c.Name=@oldCategory)
				WHEN @oldCategory='GiftShop'
					THEN 3
				WHEN @oldCategory='Quiosk'
					THEN 5
				END;

		INSERT INTO WWIGlobal.Sales.Customer
			(CustomerOffice,Category,PrimaryContact)
		VALUES
			(@officeID, @categoryID, @oldContact);
		FETCH NEXT FROM  customer_cursor
	INTO @oldCustomer,@oldCategory,@oldContact,@oldPostalCode,@oldGroup;
	END
	CLOSE customer_cursor
	DEALLOCATE customer_cursor
END;	
GO

-- Procedure to migrate the employee registries FROM  the old database to the new database.
DROP PROCEDURE IF EXISTS employee_migrate;
GO
CREATE PROCEDURE employee_migrate
AS
BEGIN
	DECLARE @oldEmployeeName VARCHAR(30);
	DECLARE @oldEmployeePreferedName VARCHAR(30);
	DECLARE @oldSalesEmployee INT;
	DECLARE employee_cursor CURSOR  
FOR SELECT e.Employee, e.[Preferred Name], e.[Is Salesperson]
	FROM WWI_OldData.dbo.Employee e
	OPEN employee_cursor
	FETCH NEXT FROM  employee_cursor
	INTO @oldEmployeeName,@oldEmployeePreferedName,@oldSalesEmployee;
	WHILE @@FETCH_STATUS = 0  
	BEGIN
		IF(NOT EXISTS (SELECT *
		FROM WWIGlobal.Sales.Employee e
		WHERE e.Name=@oldEmployeeName))
		INSERT INTO WWIGlobal.Sales.Employee
			(Name,PreferedName)
		VALUES
			(@oldEmployeeName, @oldEmployeePreferedName);
		IF(@oldSalesEmployee=1)
			INSERT INTO WWIGlobal.Sales.SalesEmployee
		VALUES(SCOPE_IDENTITY());
		FETCH NEXT FROM  employee_cursor
		INTO @oldEmployeeName,@oldEmployeePreferedName,@oldSalesEmployee;
	END
	CLOSE employee_cursor
	DEALLOCATE employee_cursor
END;	
GO

-- Procedure to migrate the Stock Items registries FROM the old database to the new database.
DROP PROCEDURE IF EXISTS product_migrate;
GO
CREATE PROCEDURE product_migrate
AS
BEGIN
	DECLARE @oldKey INT;
	DECLARE @oldStockItem VARCHAR(100);
	DECLARE @oldColor VARCHAR(30);
	DECLARE @oldSellingPackage VARCHAR(20);
	DECLARE @oldSize VARCHAR(30);
	DECLARE @oldWeight FLOAT;
	DECLARE @oldTax FLOAT;
	DECLARE @oldUnitPrice MONEY;
	DECLARE @oldRetailPrice MONEY;
	DECLARE @isChiller BIT;
	DECLARE @LeadTimeDays INT;
	DECLARE @sizeID INT;
	DECLARE @colorID INT;
	DECLARE @packageID INT;
	DECLARE @descriptionID INT;
	DECLARE @productID INT;
	DECLARE product_cursor CURSOR  
FOR SELECT s.[Stock Item Key], s.[Stock Item], s.Color, s.[Selling Package], s.[Size], s.[Typical Weight Per Unit], s.[Tax Rate], s.[Unit Price], s.[Recommended Retail Price], [Is Chiller Stock], s.[Lead Time Days]
	FROM WWI_OldData.dbo.[Stock Item] s
	OPEN product_cursor
	FETCH NEXT FROM  product_cursor
	INTO @oldKey, @oldStockItem,@oldColor,@oldSellingPackage,@oldSize,@oldWeight,@oldTax,@oldUnitPrice,@oldRetailPrice,@isChiller,@LeadTimeDays
	WHILE @@FETCH_STATUS = 0  
	BEGIN
		IF(NOT EXISTS(SELECT s.Size
		FROM WWIGlobal.Sales.Size s
		WHERE s.Size=@oldSize))
			INSERT INTO WWIGlobal.Sales.Size
			(Size)
		values
			(@oldSize);
		SET @sizeID = (SELECT s.SizeID
		FROM WWIGlobal.Sales.Size s
		WHERE s.Size = @oldSize)

		SET @colorID = (SELECT c.ColorID
		FROM WWIGlobal.Sales.Color c
		WHERE c.Name=@oldColor)

		SET @packageID =(SELECT p.PackageID
		FROM WWIGlobal.Sales.Package p
		WHERE p.Name=@oldSellingPackage)

		SET @oldStockItem = (SELECT TOP(1)
			value
		FROM string_split(@oldStockItem,'('))
		SET @oldStockItem = (SELECT Replace(@oldStockItem,'250g',''))
		SET @oldStockItem = (SELECT Replace(@oldStockItem,'500g',''))
		SET @oldStockItem = (SELECT Replace(@oldStockItem,'5kg',''))
		SET @oldStockItem = (SELECT Replace(@oldStockItem,'5mm',''))
		SET @oldStockItem = (SELECT Replace(@oldStockItem,'9mm',''))
		SET @oldStockItem = (SELECT Replace(@oldStockItem,'18mm',''))
		SET @oldStockItem = (SELECT Replace(@oldStockItem,'48mmx75m',''))
		SET @oldStockItem = (SELECT Replace(@oldStockItem,'48mmx100m',''))
		SET @oldStockItem = (SELECT Replace(@oldStockItem,'50m',''))
		SET @oldStockItem = (SELECT Replace(@oldStockItem,'20m',''))
		SET @oldStockItem = (SELECT Replace(@oldStockItem,'10m',''))


		SET @oldStockItem = CASE
			WHEN @oldStockItem like '"The Gu"%'
				THEN '"The Gu" T-Shirt'
			WHEN @oldStockItem like '10 mm Anti static%'
				THEN '10mm Anti Static Bubble Wrap'
			WHEN @oldStockItem like '20 mm Anti static%'
				THEN '20mm Anti Static Bubble Wrap'
			WHEN @oldStockItem like '32 mm Anti static%'
				THEN '32mm Anti Static Bubble Wrap'
			WHEN @oldStockItem like '10 mm Double sided%'
				THEN '10mm Double Sided Bubble Wrap'
			WHEN @oldStockItem like '20 mm Double sided%'
				THEN '20mm Double Sided Bubble Wrap'
			WHEN @oldStockItem like '32 mm Double sided%'
				THEN '32mm Double Sided Bubble Wrap'
			WHEN @oldStockItem like '3 kg%'
				THEN 'Courier Post Bag'
			WHEN @oldStockItem like 'Air cushion m%'
				THEN 'Air Cushion Machine'
			WHEN @oldStockItem like 'Air cushion f%'
				THEN 'Air Cushion Film'
			WHEN @oldStockItem like 'Alien%'
				THEN 'Alien Officer Hoodie'
			WHEN @oldStockItem like 'Animal with%'
				THEN 'Animal with Big Feet Slippers'
			WHEN @oldStockItem like 'Black and orange f%'
				THEN 'Fragile Despatch Tape'
			WHEN @oldStockItem like 'Black and orange g%'
				THEN 'Glass with Care Despatch Tape'
			WHEN @oldStockItem like 'Black and orange h%'
				THEN 'Handle with Care Despatch Tape'
			WHEN @oldStockItem like 'Black and orange t%'
				THEN 'This Way Up Despatch Tape'
			WHEN @oldStockItem like 'Black and y%'
				THEN 'Heavy Despatch Tape'
			WHEN @oldStockItem like 'Shipping carton%'
				THEN 'Shipping Carton'
			WHEN @oldStockItem like 'Superhero%'
				THEN 'Superhero Jacket'
			WHEN @oldStockItem like 'Void fill%'
				THEN 'Void Fill Bag'
			WHEN @oldStockItem like 'White chocolate moon%'
				THEN 'White Chocolate Moon Rocks'
			WHEN @oldStockItem like 'White chocolate snow%'
				THEN 'White Chocolate Snow Balls'
			ELSE @oldStockItem
		END

		IF(NOT EXISTS(SELECT *
		FROM WWIGlobal.Sales.ProductDescription pd
		WHERE pd.Description=@oldStockItem))
			INSERT INTO WWIGlobal.Sales.ProductDescription
			(Description)
		VALUES(@oldStockItem);

		SET @descriptionID = (SELECT pd.DescriptionID
		FROM WWIGlobal.Sales.ProductDescription pd
		WHERE pd.Description=@oldStockItem)

		IF(NOT EXISTS(SELECT *
		FROM WWIGlobal.Sales.Product p
		WHERE p.ProductDescription = @descriptionID AND p.Color = @colorID AND p.Size = @sizeID))
		BEGIN
			INSERT INTO WWIGlobal.Sales.Product
				(ProductDescription,Color,[Size],Weight,SellPackage,LeadTimeDays,TaxRate,UnitPrice,RetailPrice)
			VALUES
				(@descriptionID, @colorID, @sizeID, @oldWeight, @packageID, @LeadTimeDays, @oldTax, @oldUnitPrice, @oldRetailPrice)
			SET @productID = SCOPE_IDENTITY();
			IF(@isChiller=1)
				INSERT INTO WWIGlobal.Sales.ChillerProducts
			VALUES
				(@productID);
		END
		FETCH NEXT FROM  product_cursor
		INTO @oldKey, @oldStockItem,@oldColor,@oldSellingPackage,@oldSize,@oldWeight,@oldTax,@oldUnitPrice,@oldRetailPrice,@isChiller,@LeadTimeDays
	END
	CLOSE product_cursor
	DEALLOCATE product_cursor
END;	
GO

-- Procedure to migrate the Sales registries FROM the old database to the new database.
DROP PROCEDURE IF EXISTS sale_migrate;
GO
CREATE PROCEDURE sale_migrate
AS
BEGIN
	DECLARE @oldbuyingGroup VARCHAR(40);
	DECLARE @oldCustomer VARCHAR(50);
	DECLARE @oldStockItem VARCHAR(100);
	DECLARE @employee VARCHAR(40);
	DECLARE @oldSize VARCHAR(30);
	DECLARE @oldColor VARCHAR(20);
	DECLARE @City VARCHAR(30);
	DECLARE @State VARCHAR(40);
	DECLARE @oldInvoiceID INT;
	DECLARE @oldProductID INT;


	DECLARE @salesOrderID INT;
	DECLARE @customerID INT;
	DECLARE @parentID INT;
	DECLARE @cityID INT;
	DECLARE @oldInvoiceDate DATE;
	DECLARE @oldDueDate DATE;
	DECLARE @employeeID INT;
	DECLARE @productID INT;
	DECLARE @productDescriptionID INT;
	DECLARE @sizeID INT;
	DECLARE @colorID INT;
	DECLARE @quantity INT;
	DECLARE @taxRate FLOAT;

	DECLARE sale_cursor CURSOR  
FOR select co.[Buying Group] , co.Customer, s.[Invoice Date Key], s.[Delivery Date Key], e.Employee, s.[WWI Invoice ID], s.[Stock Item Key], s.Quantity, s.[Tax Rate]
	from WWI_OldData.dbo.Sale s
		join WWI_OldData.dbo.Customer co on co.[WWI Customer ID]=s.[Customer Key]
		join WWI_OldData.dbo.Employee e on e.[Employee Key]=s.[Salesperson Key]
	OPEN sale_cursor
	FETCH NEXT FROM  sale_cursor
	INTO @oldbuyingGroup,@oldCustomer,@oldInvoiceDate,@oldDueDate,@employee,@oldInvoiceID,@oldProductID,@quantity,@taxRate
	WHILE @@FETCH_STATUS = 0  
	BEGIN
		SET @city =(SUBSTRING(@oldCustomer,14,50));
		SET @city = (replace(@city,'(',''))
		SET @city = (replace(@city,')',''))
		SET @state = (SELECT value
		FROM STRING_SPLIT(@city,',')
		WHERE trim(value) in (SELECT s.Code
		FROM WWIGlobal.Sales.State s))
		SET @city = (SELECT top(1)
			value
		FROM STRING_SPLIT(@city,','))
		SET @cityID = (SELECT c.CityID
		FROM WWIGlobal.Sales.City c
		WHERE c.Name=trim(@city) AND c.State=trim(@state))

		IF(@cityID IS NOT NULL)
		BEGIN
			SET @CustomerID = (SELECT c.CustomerID
			FROM WWIGlobal.Sales.Customer c
				JOIN WWIGlobal.Sales.Office o on o.OfficeID=c.CustomerOffice
				JOIN WWIGlobal.Sales.OfficeLocation ol on ol.LocationID=o.OfficeLocation
				JOIN WWIGlobal.Sales.OfficeGroup og on og.GroupID=o.OfficeGroup
				JOIN WWIGlobal.Sales.City cty on cty.CityID=ol.City
			WHERE og.Name=@oldbuyingGroup AND ol.City=@cityID)
		END
		ELSE
			SET @customerID = (SELECT c.CustomerID
		FROM WWIGlobal.Sales.Customer c
			JOIN WWIGlobal.Sales.Office o on o.OfficeID=c.CustomerOffice
			JOIN WWIGlobal.Sales.OfficeGroup og on og.GroupID=o.OfficeGroup
			JOIN WWIGlobal.Sales.OfficeLocation ol on ol.LocationID=o.OfficeLocation
		WHERE og.Name=@oldbuyingGroup AND ol.City IS NULL)

		SET @parentID =( SELECT o.OfficeParentID
		FROM WWIGlobal.Sales.Customer c
			JOIN WWIGlobal.Sales.Office o on o.OfficeID=c.CustomerOffice
		WHERE c.CustomerID=@customerID)

		SET @employeeID= (SELECT e.EmployeeID
		FROM WWIGlobal.Sales.SalesEmployee se
			JOIN WWIGlobal.Sales.Employee e on e.EmployeeID=se.EmployeeID
		WHERE e.Name=@employee)
		IF(@parentID IS NOT NULL AND NOT EXISTS(SELECT *
			FROM WWIGlobal.Sales.SalesOrderHeader sh
			WHERE sh.CustomerID=@CustomerID AND sh.OrderDate=@oldInvoiceDate AND sh.EmployeeID=@employeeID))
			INSERT INTO WWIGlobal.Sales.SalesOrderHeader
			(OrderDate,DueDate,CustomerID,BillToID,EmployeeID,TaxAmount)
		VALUES
			(@oldInvoiceDate, @oldDueDate, @customerID, @parentID, @employeeID, @taxRate);
		IF(@parentID IS NULL AND NOT EXISTS(SELECT *
			FROM WWIGlobal.Sales.SalesOrderHeader sh
			WHERE sh.CustomerID=@CustomerID AND sh.OrderDate=@oldInvoiceDate AND sh.EmployeeID=@employeeID))
			INSERT INTO WWIGlobal.Sales.SalesOrderHeader
			(OrderDate,DueDate,CustomerID,BillToID,EmployeeID,TaxAmount)
		VALUES
			(@oldInvoiceDate, @oldDueDate, @customerID, @customerID, @employeeID, @taxRate);

		SET @salesOrderID =(SELECT sh.SalesOrderID
		FROM WWIGlobal.Sales.SalesOrderHeader sh
		WHERE sh.CustomerID=@customerID AND sh.OrderDate=@oldInvoiceDate AND sh.EmployeeID=@employeeID)

		SET @oldStockItem = (SELECT si.[Stock Item]
		FROM WWI_OldData.dbo.[Stock Item] si
		WHERE si.[Stock Item Key]=@oldProductID)

		SET @oldSize=(SELECT si.[Size]
		FROM WWI_OldData.dbo.[Stock Item] si
		WHERE si.[Stock Item Key]=@oldProductID)

		SET @sizeID = (SELECT s.SizeID
		FROM WWIGlobal.Sales.Size s
		WHERE s.Size = @oldSize)

		SET @oldColor = (SELECT si.Color
		FROM WWI_OldData.dbo.[Stock Item] si
		WHERE si.[Stock Item Key]=@oldProductID)

		SET @colorID = (SELECT c.ColorID
		FROM WWIGlobal.Sales.Color c
		WHERE c.Name=@oldColor)

		SET @oldStockItem = (SELECT TOP(1)
			value
		FROM string_split(@oldStockItem,'('))
		SET @oldStockItem = (SELECT Replace(@oldStockItem,'250g',''))
		SET @oldStockItem = (SELECT Replace(@oldStockItem,'500g',''))
		SET @oldStockItem = (SELECT Replace(@oldStockItem,'5kg',''))
		SET @oldStockItem = (SELECT Replace(@oldStockItem,'5mm',''))
		SET @oldStockItem = (SELECT Replace(@oldStockItem,'9mm',''))
		SET @oldStockItem = (SELECT Replace(@oldStockItem,'18mm',''))
		SET @oldStockItem = (SELECT Replace(@oldStockItem,'48mmx75m',''))
		SET @oldStockItem = (SELECT Replace(@oldStockItem,'48mmx100m',''))
		SET @oldStockItem = (SELECT Replace(@oldStockItem,'50m',''))
		SET @oldStockItem = (SELECT Replace(@oldStockItem,'20m',''))
		SET @oldStockItem = (SELECT Replace(@oldStockItem,'10m',''))


		SET @oldStockItem = CASE
			WHEN @oldStockItem like '"The Gu"%'
				THEN '"The Gu" T-Shirt'
			WHEN @oldStockItem like '10 mm Anti static%'
				THEN '10mm Anti Static Bubble Wrap'
			WHEN @oldStockItem like '20 mm Anti static%'
				THEN '20mm Anti Static Bubble Wrap'
			WHEN @oldStockItem like '32 mm Anti static%'
				THEN '32mm Anti Static Bubble Wrap'
			WHEN @oldStockItem like '10 mm Double sided%'
				THEN '10mm Double Sided Bubble Wrap'
			WHEN @oldStockItem like '20 mm Double sided%'
				THEN '20mm Double Sided Bubble Wrap'
			WHEN @oldStockItem like '32 mm Double sided%'
				THEN '32mm Double Sided Bubble Wrap'
			WHEN @oldStockItem like '3 kg%'
				THEN 'Courier Post Bag'
			WHEN @oldStockItem like 'Air cushion m%'
				THEN 'Air Cushion Machine'
			WHEN @oldStockItem like 'Air cushion f%'
				THEN 'Air Cushion Film'
			WHEN @oldStockItem like 'Alien%'
				THEN 'Alien Officer Hoodie'
			WHEN @oldStockItem like 'Animal with%'
				THEN 'Animal with Big Feet Slippers'
			WHEN @oldStockItem like 'Black and orange f%'
				THEN 'Fragile Despatch Tape'
			WHEN @oldStockItem like 'Black and orange g%'
				THEN 'Glass with Care Despatch Tape'
			WHEN @oldStockItem like 'Black and orange h%'
				THEN 'Handle with Care Despatch Tape'
			WHEN @oldStockItem like 'Black and orange t%'
				THEN 'This Way Up Despatch Tape'
			WHEN @oldStockItem like 'Black and y%'
				THEN 'Heavy Despatch Tape'
			WHEN @oldStockItem like 'Shipping carton%'
				THEN 'Shipping Carton'
			WHEN @oldStockItem like 'Superhero%'
				THEN 'Superhero Jacket'
			WHEN @oldStockItem like 'Void fill%'
				THEN 'Void Fill Bag'
			WHEN @oldStockItem like 'White chocolate moon%'
				THEN 'White Chocolate Moon Rocks'
			WHEN @oldStockItem like 'White chocolate snow%'
				THEN 'White Chocolate Snow Balls'
			ELSE @oldStockItem
		END

		SET @productDescriptionID = (SELECT pd.DescriptionID
		FROM WWIGlobal.Sales.ProductDescription pd
		WHERE pd.[Description]=@oldStockItem)

		SET @productID = (SELECT p.ProductID
		FROM WWIGlobal.Sales.Product p
		WHERE p.ProductDescription=@productDescriptionID AND p.Color=@colorID AND p.[Size]=@sizeID)

		INSERT INTO WWIGlobal.Sales.SalesOrderDetail
			(SalesOrderID,OrderQty,ProductID)
		VALUES
			(@salesOrderID, @quantity, @productID)

		FETCH NEXT FROM  sale_cursor
		INTO @oldbuyingGroup,@oldCustomer,@oldInvoiceDate,@oldDueDate,@employee,@oldInvoiceID,@oldProductID,@quantity,@taxRate
	END
	CLOSE sale_cursor
	DEALLOCATE sale_cursor
END;	
GO

-- Executes the migration procedures
EXEC salesTerritory_migrate;

EXEC state_migrate;

EXEC category_migrate;

EXEC city_migrate;

EXEC customer_migrate;

EXEC employee_migrate;

EXEC color_migrate;

EXEC package_migrate;

EXEC product_migrate;

EXEC sale_migrate;