use WWIGlobal;

-- Definition of isolation level for the process of adding a product to a sale
GO 
ALTER PROCEDURE Sales.spAddProductToSale(@SalesOrderID INT,
    @OrderQty INT,
    @ProductID INT)
AS
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
BEGIN TRANSACTION
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
	ROLLBACK TRANSACTION
END CATCH
END;
COMMIT TRANSACTION
GO

-- Definition of isolation level for the process of updating a product's price, making sure that the price in unfinished sales doesn't change
GO
ALTER PROCEDURE Sales.spUpdateProductPrice(@ProductID INT,
    @NewUnitPrice INT)
AS
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
BEGIN
    UPDATE WWIGlobal.Sales.Product
	SET UnitPrice = @NewUnitPrice
	WHERE ProductID = @ProductID
END;
COMMIT TRANSACTION
GO

-- Definition of isolation level for the process of calculating the total price of a sale, making sure that no products can be either added or removed from it
GO
ALTER FUNCTION Sales.fnCalcTotalPriceSale(@SalesOrderDetailID INT)
RETURNS MONEY
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL SNAPSHOT
    BEGIN TRANSACTION
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
        COMMIT TRANSACTION
    END
    RETURN @totalPrice
END
GO