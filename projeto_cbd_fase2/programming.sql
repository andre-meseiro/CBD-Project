USE WWIGlobal;
GO

-- Error Handling
DROP PROCEDURE IF EXISTS spLogError
GO
CREATE PROCEDURE spLogError
AS
BEGIN
    INSERT INTO ErrorLog
        (ErrorNumber,UserName,ErrorTime,ErrorMessage,ErrorState)
    VALUES(ERROR_NUMBER(), SYSTEM_USER, GETDATE(), ERROR_MESSAGE(), ERROR_STATE())
END
GO

--Add a user 
DROP PROCEDURE IF EXISTS Users.spAddUser
GO
CREATE PROCEDURE Users.spAddUser(
    @email VARCHAR(50),
    @customerID INT,
    @password VARCHAR(100)
)
AS
BEGIN
    BEGIN TRY
    IF(@email IS NOT NULL AND @password IS NOT NULL AND @customerID IS NOT NULL) 
        BEGIN
        IF(NOT EXISTS(SELECT *
            FROM WWIGlobal.Users.RegisteredUser ru
            where ru.Email=@email) AND NOT EXISTS (SELECT *
            FROM WWIGlobal.Users.RegisteredUser ru
            where ru.CustomerID=@customerID
    ))
        INSERT INTO WWIGlobal.Users.RegisteredUser
        VALUES
            (@email, @customerID, @password);
            ELSE
            THROW 60000, 'Email already exists',1
    END
    ELSE
        THROW 60000, 'Invalid Parameters',1
    END TRY
    BEGIN CATCH
        SELECT ERROR_NUMBER()'Error Number', ERROR_MESSAGE()'Message', ERROR_STATE() 'State'
        EXEC spLogError
    END CATCH
END
GO

--Edits a user, receives the email, the property to change and the new value
DROP PROCEDURE IF EXISTS Users.spEditUser
GO
CREATE PROCEDURE Users.spEditUser(
    @email VARCHAR(50),
    @propertyToChange VARCHAR(20),
    @value VARCHAR(100)
)
AS
BEGIN
    BEGIN TRY
    IF(EXISTS(SELECT *
    FROM WWIGlobal.Users.RegisteredUser
    WHERE Email=@email))
    BEGIN
        IF(EXISTS(SELECT *
        FROM WWIGlobal.Users.RegisteredUser r
        WHERE r.Email=@email))
        BEGIN
            IF(UPPER(@propertyToChange)='CUSTOMERID')
            BEGIN
                UPDATE WWIGlobal.Users.RegisteredUser SET CustomerID=CAST(@value AS INT) WHERE Email=@email
            END
            ELSE
            BEGIN
                IF(UPPER(@propertyToChange)='PASSWORD')
                BEGIN
                    UPDATE WWIGlobal.Users.RegisteredUser SET [Password]=@value WHERE Email=@email
                END

            ELSE
                THROW 58000, 'Invalid Operation',1
            END
        END
    END
    ELSE
        THROW 58000, 'Invalid email',1
    END
    TRY
    BEGIN CATCH
    SELECT ERROR_NUMBER()'Error Number', ERROR_MESSAGE()'Message', ERROR_STATE() 'State'
    EXEC spLogError
    END CATCH
END
GO

--Remove User
DROP PROCEDURE IF EXISTS Users.spRemoveUser
GO
CREATE PROCEDURE Users.spRemoveUser(
    @email VARCHAR(50)
)
AS
BEGIN
    BEGIN TRY
    IF(EXISTS(SELECT *
    FROM WWIGlobal.Users.RegisteredUser
    WHERE Email=@email))
    BEGIN
        IF(EXISTS(SELECT *
        FROM WWIGlobal.Users.RecoverUsers r
        WHERE r.Email=@email))
        BEGIN
            DELETE FROM WWIGlobal.Users.RecoverUsers WHERE Email=@email
        END
        DELETE FROM WWIGlobal.Users.RegisteredUser WHERE Email=@email
    END
    ELSE
    THROW 58000, 'Invalid email',1
    END TRY
    BEGIN CATCH
        SELECT ERROR_NUMBER()'Error Number', ERROR_MESSAGE()'Message', ERROR_STATE() 'State'
        EXEC spLogError
    END CATCH
END
GO

--Add Promotion
DROP PROCEDURE IF EXISTS Sales.spCreatePromotion
GO
CREATE PROCEDURE Sales.spCreatePromotion
    (
    @productID INT,
    @promotionDetails VARCHAR(30),
    @PromotionDescription VARCHAR(100),
    @DateStart DATE,
    @DateEnd DATE
)
AS
BEGIN
    BEGIN TRY
    DECLARE @TypeID INT
    IF(NOT EXISTS(SELECT *
        FROM WWIGlobal.Sales.Product p
        WHERE @productID=p.ProductID) OR EXISTS(SELECT *
        FROM WWIGlobal.Sales.Promotions pp
        WHERE @productID = pp.ProductID))
    THROW 53000, 'Invalid Product ID',1
    IF(DATEDIFF(YEAR,@DateStart,@DateEnd)>=0 AND DATEDIFF(DAYOFYEAR,@DateStart,@DateEnd)>0)
        BEGIN
        IF(@promotionDetails NOT IN (SELECT pt.PromotionDetails
        FROM WWIGlobal.Sales.PromotionType pt))
            BEGIN
            IF(@promotionDetails in ('2->3','1->2','3->4') OR ((SELECT ISNUMERIC(@promotionDetails))=1))
            BEGIN
                INSERT INTO WWIGlobal.Sales.PromotionType
                    (PromotionDescription,PromotionDetails)
                VALUES
                    (@PromotionDescription, @promotionDetails)
                SET @TypeID = SCOPE_IDENTITY()
            END
            ELSE 
            THROW 52001, 'Invalid Promotion Type',1
        END
        ELSE
        BEGIN
            SET @TypeID = (SELECT pt.TypeID
            FROM WWIGlobal.Sales.PromotionType pt
            WHERE pt.PromotionDetails=@promotionDetails)
        END
        INSERT INTO WWIGlobal.Sales.Promotions
            (ProductID,PromotionType,DateStart,DateEnd)
        VALUES
            (@productID, @TypeID, @DateStart, @DateEnd)
    END
    ELSE
        THROW 52000, 'Invalid Promotion Date',1;
    END TRY
    BEGIN CATCH
    SELECT ERROR_NUMBER()'Error Number', ERROR_MESSAGE()'Message', ERROR_STATE() 'State'
    EXEC spLogError
    END CATCH
END
GO

--Edit Promotion Date
DROP PROCEDURE IF EXISTS Sales.spEditPromotionDate
GO
CREATE PROCEDURE Sales.spEditPromotionDate(
    @productID INT,
    @startDate DATE,
    @endDate DATE
)
AS
BEGIN
    BEGIN TRY
        IF(EXISTS(SELECT *
    FROM WWIGlobal.Sales.Promotions p
    WHERE @productID=p.ProductID))
        BEGIN
        IF(@startDate<=@endDate)
        BEGIN
            UPDATE WWIGlobal.Sales.Promotions SET DateStart=@startDate WHERE ProductID=@productID
            UPDATE WWIGlobal.Sales.Promotions SET DateEnd=@endDate WHERE ProductID=@productID
        END
        ELSE
            THROW 52000, 'Invalid Promotion Date',1;
    END
        ELSE
        THROW 53000, 'Invalid Product ID',1
    END
    TRY
    BEGIN CATCH
    SELECT ERROR_NUMBER()'Error Number', ERROR_MESSAGE()'Message', ERROR_STATE() 'State'
    EXEC spLogError
    END CATCH
END 
GO


-- Auxiliary function to check if a sale allows chiller products or not
DROP FUNCTION IF EXISTS Sales.fnCheckIfSaleAllowsChillerProducts
GO
CREATE FUNCTION Sales.fnCheckIfSaleAllowsChillerProducts(
    @SalesOrderID INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @allows BIT
    IF(NOT EXISTS(SELECT sd.ProductID
    FROM WWIGlobal.Sales.SalesOrderDetail sd
    WHERE sd.SalesOrderID=@SalesOrderID AND sd.ProductID NOT IN(SELECT ChillerID
        FROM WWIGlobal.Sales.ChillerProducts)))
        SET @allows = 1;
    ELSE
        SET @allows = 0;
    RETURN @allows
END
GO

-- Create a sale
DROP PROCEDURE IF EXISTS Sales.spCreateSale
GO
CREATE PROCEDURE Sales.spCreateSale(@DueDate DATE,
    @CustomerID INT,
    @BillToID INT,
    @EmployeeID INT,
    @TaxAmount MONEY)
AS
BEGIN
    INSERT INTO WWIGlobal.Sales.SalesOrderHeader
        (OrderDate, DueDate, CustomerID, BillToID, EmployeeID, TaxAmount)
    VALUES(GETDATE(), @DueDate, @CustomerID, @BillToID, @EmployeeID, @TaxAmount)
END;
GO

-- Add a product to a sale
DROP PROCEDURE IF EXISTS Sales.spAddProductToSale
GO
CREATE PROCEDURE Sales.spAddProductToSale(@SalesOrderID INT,
    @OrderQty INT,
    @ProductID INT)
AS
BEGIN
    BEGIN TRY
    IF (Sales.fnVerifyDeliveryDate(@SalesOrderID)=1)
    BEGIN
        IF (EXISTS (SELECT *
        FROM WWIGlobal.Sales.SalesOrderDetail sd
        WHERE sd.SalesOrderID=@SalesOrderID))
    BEGIN
            IF @ProductID IN(SELECT ChillerID
            FROM WWIGlobal.Sales.ChillerProducts)
        BEGIN
                IF ((SELECT Sales.fnCheckIfSaleAllowsChillerProducts(@SalesOrderID)) = 1)
                BEGIN
                    INSERT INTO WWIGLOBAL.Sales.SalesOrderDetail
                        (SalesOrderID, OrderQty, ProductID)
                    VALUES(@SalesOrderID, @OrderQty, @ProductID)
                END
            ELSE
                THROW 51001, 'The sale cannot contain products with and without Chiller Stock!', 1
            END
        ELSE
            BEGIN
                IF ((SELECT Sales.fnCheckIfSaleAllowsChillerProducts(@SalesOrderID)) = 1)
                    THROW 51001, 'The sale cannot contain products with and without Chiller Stock!', 1
                ELSE
                    BEGIN
                    INSERT INTO WWIGLOBAL.Sales.SalesOrderDetail
                        (SalesOrderID, OrderQty, ProductID)
                    VALUES(@SalesOrderID, @OrderQty, @ProductID)
                END
            END
        END
    ELSE
        INSERT INTO WWIGLOBAL.Sales.SalesOrderDetail
            (SalesOrderID, OrderQty, ProductID)
        VALUES(@SalesOrderID, @OrderQty, @ProductID)
    END
    ELSE
        THROW 51200, 'Product does not comply with lead days policy', 1
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER()'Error Number', ERROR_MESSAGE()'Message', ERROR_STATE()'State'
    EXEC spLogError
END CATCH
END;
GO

-- Update product quantity on a sale
DROP PROCEDURE IF EXISTS Sales.spUpdateProductQty
GO
CREATE PROCEDURE Sales.spUpdateProductQty(@SalesOrderDetailID INT,
    @NewOrderQty INT)
AS
BEGIN
    UPDATE WWIGlobal.Sales.SalesOrderDetail
	SET OrderQty = @NewOrderQty
	WHERE SalesOrderDetailID = @SalesOrderDetailID
END;
GO

-- Remove a product from a sale, with the option to also remove the sale if it has no products associated
DROP PROCEDURE IF EXISTS Sales.spRemoveProduct
GO
CREATE PROCEDURE Sales.spRemoveProduct(@SalesOrderDetailID INT,
    @DeleteSale BIT)
AS
BEGIN
    DECLARE @id INT
    SET @id = (SELECT SalesOrderID
    FROM WWIGlobal.Sales.SalesOrderDetail
    WHERE SalesOrderDetailID = @SalesOrderDetailID);

    DELETE FROM WWIGlobal.Sales.SalesOrderDetail WHERE SalesOrderDetailID = @SalesOrderDetailID;

    IF @DeleteSale = 1 AND NOT EXISTS(SELECT *
        FROM WWIGlobal.Sales.SalesOrderDetail
        WHERE SalesOrderID = @id)

		DELETE FROM WWIGlobal.Sales.SalesOrderHeader WHERE SalesOrderId = @id;
END;
GO

-- Calculate the total price of a sale (calculates the promotion discount if available)
DROP FUNCTION IF EXISTS Sales.fnCalcTotalPriceSale
GO
CREATE FUNCTION Sales.fnCalcTotalPriceSale(@SalesOrderDetailID INT)
RETURNS MONEY
AS
BEGIN
    DECLARE @productID INT
    DECLARE @totalPrice MONEY

    SET @productID=(SELECT od.ProductID
    FROM WWIGlobal.Sales.SalesOrderDetail od
    WHERE od.SalesOrderDetailID = @SalesOrderDetailID)

    IF(@productID IN (SELECT p.ProductID
    FROM WWIGlobal.Sales.Promotions p
    WHERE p.ProductID=@productID))
    BEGIN
        DECLARE @promotionDetails VARCHAR(50)
        DECLARE @dateStart DATE
        DECLARE @dateEnd DATE
        SET @promotionDetails = (SELECT pt.PromotionDetails
        FROM WWIGlobal.Sales.Promotions p
            JOIN WWIGlobal.Sales.PromotionType pt on pt.TypeID=p.PromotionType
        WHERE p.ProductID=@productID )

        SET @dateStart = (SELECT p.DateStart
        FROM WWIGlobal.Sales.Promotions p
        WHERE p.ProductID=@productID )

        SET @dateEnd = (SELECT p.DateEnd
        FROM WWIGlobal.Sales.Promotions p
        WHERE p.ProductID=@productID )

        IF(@dateStart<=GETDATE() AND @dateEnd>=GETDATE())
        BEGIN
            IF(ISNUMERIC(@promotionDetails)=1)
            BEGIN
                SET @totalPrice = (SELECT od.OrderQty * (p.UnitPrice - (p.UnitPrice*CAST(@promotionDetails AS INT)/100))
                FROM WWIGlobal.Sales.SalesOrderDetail od
                    JOIN WWIGlobal.Sales.Product p on od.ProductID = p.ProductID
                WHERE od.SalesOrderDetailID = @SalesOrderDetailID)
            END
        END
        ELSE
        BEGIN
            SET @totalPrice = (SELECT od.OrderQty * p.UnitPrice
            FROM WWIGlobal.Sales.SalesOrderDetail od
                JOIN WWIGlobal.Sales.Product p on od.ProductID = p.ProductID
            WHERE od.SalesOrderDetailID = @SalesOrderDetailID)
        END
    END
        ELSE
        BEGIN
        SET @totalPrice = (SELECT od.OrderQty * p.UnitPrice
        FROM WWIGlobal.Sales.SalesOrderDetail od
            JOIN WWIGlobal.Sales.Product p on od.ProductID = p.ProductID
        WHERE od.SalesOrderDetailID = @SalesOrderDetailID)
    END
    RETURN @totalPrice
END
GO

-- Implement a business rule that verifies that the delivery date is in accordance with the expected delivery time of a product
DROP FUNCTION IF EXISTS Sales.fnVerifyDeliveryDate
GO
CREATE FUNCTION Sales.fnVerifyDeliveryDate(@SalesOrderID INT)
RETURNS BIT
AS
BEGIN
    DECLARE @inAccordance BIT
    DECLARE @OrderDate DATE
    DECLARE @DueDate DATE
    DECLARE @ProductID INT
    DECLARE @LeadTimeDays INT

    SET @inAccordance = 1
    DECLARE lead_cursor CURSOR  
FOR SELECT sd.ProductID, p.LeadTimeDays, sh.OrderDate, sh.DueDate
    FROM WWIGlobal.Sales.SalesOrderDetail sd
        JOIN WWIGlobal.Sales.SalesOrderHeader sh on sh.SalesOrderID=sd.SalesOrderID
        JOIN WWIGlobal.Sales.Product p on p.ProductID=sd.ProductID
    WHERE sd.SalesOrderID=@SalesOrderID
    OPEN lead_cursor
    FETCH NEXT FROM  lead_cursor
INTO @productID,@LeadTimeDays,@OrderDate,@DueDate
    WHILE @@FETCH_STATUS = 0 AND @inAccordance=1
	BEGIN
        IF(DATEDIFF(DAY,@OrderDate,@DueDate)<=@LeadTimeDays)
            BEGIN
            SET @inAccordance=0
        END
        FETCH NEXT FROM  lead_cursor
	INTO @productID,@LeadTimeDays,@OrderDate,@DueDate
    END
    CLOSE lead_cursor
    DEALLOCATE lead_cursor
    RETURN @inAccordance
END
GO

--Sends a token to the user to recover the password
DROP PROCEDURE IF EXISTS Users.recoverPassword
GO
CREATE PROCEDURE Users.recoverPassword
    (@email VARCHAR(100))
AS
BEGIN
    BEGIN TRY
        IF(EXISTS(SELECT *
    FROM WWIGlobal.Users.RegisteredUser
    WHERE Email = @email))
        BEGIN
        IF(EXISTS(SELECT *
        FROM WWIGlobal.Users.RecoverUsers
        WHERE Email=@email))
        BEGIN
            DELETE FROM WWIGlobal.Users.RecoverUsers WHERE Email=@email
        END
        DECLARE @token VARCHAR(100)
        SET @token = NEWID()
        SELECT @email 'Email', @token'Token for password reset'
        INSERT INTO WWIGlobal.Users.RecoverUsers
        VALUES
            (@email, @token, DATEADD(HOUR,24,SYSDATETIME()))
    END
    ELSE
        THROW 55000, 'User email does not exist.', 1
    END TRY
    BEGIN CATCH
        SELECT ERROR_NUMBER()'Error Number', ERROR_MESSAGE()'Message', ERROR_STATE()'State'
        EXEC spLogError
    END CATCH
END
GO

--Checks the tokens for password reset and removes the ones that have expired
DROP PROCEDURE IF EXISTS Users.spCheckTokenValid
GO
CREATE PROCEDURE Users.spCheckTokenValid
AS
BEGIN
    DECLARE @email VARCHAR(50)
    DECLARE @validDate DATETIME
    DECLARE check_cursor CURSOR  
FOR SELECT Email, ValidUntil
    FROM WWIGlobal.Users.RecoverUsers
    OPEN check_cursor
    FETCH NEXT FROM  check_cursor
INTO @email,@validDate
    WHILE @@FETCH_STATUS = 0  
	BEGIN
        IF(SYSDATETIME()>@validDate)
        BEGIN
            DELETE FROM WWIGlobal.Users.RecoverUsers WHERE Email=@email
        END
        FETCH NEXT FROM  check_cursor
	INTO @email,@validDate
    END
    CLOSE check_cursor
    DEALLOCATE check_cursor
END
GO

-- Update product price on a sale
DROP PROCEDURE IF EXISTS Sales.spUpdateProductPrice
GO
CREATE PROCEDURE Sales.spUpdateProductPrice(@ProductID INT,
    @NewUnitPrice INT)
AS
BEGIN
    UPDATE WWIGlobal.Sales.Product
	SET UnitPrice = @NewUnitPrice
	WHERE ProductID = @ProductID
END;
GO