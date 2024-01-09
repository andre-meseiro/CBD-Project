-- Tests to the implemented procedures and functions in the programming file
USE WWIGlobal;
GO

-- Test procedure to create a sale
EXEC Sales.spCreateSale '2022-11-30', 1, 3, 4, 4.99;
EXEC Sales.spCreateSale '2022-12-20', 1, 3, 4, 5.99;
EXEC Sales.spCreateSale '2022-12-06', 1, 3, 4, 6.99;
EXEC Sales.spCreateSale '2022-12-14', 1, 3, 4, 7.99;

SELECT *
FROM WWIGlobal.Sales.SalesOrderHeader
WHERE TaxAmount = 4.99;

-- to return to original state: delete this OrderHeader

-- Test procedure to add a product to a sale
EXEC Sales.spAddProductToSale 63716, 1, 1;
EXEC Sales.spAddProductToSale 63716, 1, 215;

EXEC Sales.spAddProductToSale 63717, 1, 220;
EXEC Sales.spAddProductToSale 63717, 1, 2;

EXEC Sales.spAddProductToSale 63718, 1, 215;
EXEC Sales.spAddProductToSale 63718, 1, 220;

EXEC Sales.spAddProductToSale 63719, 1, 1;
EXEC Sales.spAddProductToSale 63719, 1, 2;

SELECT *
FROM WWIGlobal.Sales.SalesOrderDetail
WHERE SalesOrderID = 63716

-- Check for errors
SELECT *
FROM dbo.ErrorLog;

-- to return to original state: delete this OrderDetail

-- Test procedure to update product quantity on a sale
select *
FROM WWIGlobal.Sales.SalesOrderDetail
WHERE SalesOrderDetailID = 115378;

EXEC Sales.spUpdateProductQty 115378, 2;

select *
FROM WWIGlobal.Sales.SalesOrderDetail
WHERE SalesOrderDetailID = 115378;

-- to return to original state: execute the same procedure using 1 instead of 2

-- Test procedure to remove product
SELECT *
FROM WWIGlobal.Sales.SalesOrderHeader
WHERE SalesOrderID = 63718;

EXEC Sales.spRemoveProduct 115378, 1;

SELECT *
FROM WWIGlobal.Sales.SalesOrderHeader
WHERE SalesOrderID = 63718;

-- Test function to calculate the total price of a sale
SELECT Sales.fnCalcTotalPriceSale(115375) 'Total';

-- Test add Promotion To Product Sale
EXEC Sales.spUpdateProductQty 115380, 7;
EXEC Sales.spUpdateProductQty 115381, 3;
SELECT sd.SalesOrderID, sd.SalesOrderDetailID, p.ProductID , sd.OrderQty, p.UnitPrice, Sales.fnCalcTotalPriceSale(sd.SalesOrderDetailID) SubTotal
FROM WWIGlobal.Sales.SalesOrderDetail sd
    JOIN WWIGlobal.Sales.Product p on p.ProductID=sd.ProductID
WHERE SalesOrderID = 63718;

-- Create promotions
SELECT sd.SalesOrderID, sd.SalesOrderDetailID, p.ProductID , sd.OrderQty, p.UnitPrice, Sales.fnCalcTotalPriceSale(sd.SalesOrderDetailID) SubTotal
FROM WWIGlobal.Sales.SalesOrderDetail sd
    JOIN WWIGlobal.Sales.Product p on p.ProductID=sd.ProductID
WHERE SalesOrderID = 63718;

EXEC Sales.spCreatePromotion 215,'50','50% de Desconto','2022-11-20','2022-11-30'
EXEC Sales.spCreatePromotion 220,'100','100% de Desconto','2022-11-29','2022-11-30'

SELECT p.ProductID, pt.PromotionDescription, p.DateStart, p.DateEnd
FROM WWIGlobal.Sales.Promotions p
    JOIN WWIGlobal.Sales.PromotionType pt on pt.TypeID=p.PromotionType

SELECT sd.SalesOrderID, sd.SalesOrderDetailID, p.ProductID , sd.OrderQty, p.UnitPrice, Sales.fnCalcTotalPriceSale(sd.SalesOrderDetailID) SubTotal
FROM WWIGlobal.Sales.SalesOrderDetail sd
    JOIN WWIGlobal.Sales.Product p on p.ProductID=sd.ProductID
WHERE SalesOrderID = 63718;

EXEC Sales.spEditPromotionDate 215,'2022-11-29','2022-11-30'

SELECT p.ProductID, pt.PromotionDescription, p.DateStart, p.DateEnd
FROM WWIGlobal.Sales.Promotions p
    JOIN WWIGlobal.Sales.PromotionType pt on pt.TypeID=p.PromotionType

SELECT sd.SalesOrderID, sd.SalesOrderDetailID, p.ProductID , sd.OrderQty, p.UnitPrice, Sales.fnCalcTotalPriceSale(sd.SalesOrderDetailID) SubTotal
FROM WWIGlobal.Sales.SalesOrderDetail sd
    JOIN WWIGlobal.Sales.Product p on p.ProductID=sd.ProductID
WHERE SalesOrderID = 63717;

-- Test user insert 
DECLARE @counter INT
SET @counter = 1
while @counter <=10
BEGIN
    DECLARE @email VARCHAR(50)
    SET @email = CONCAT('user',@counter,'@email.com')
    DECLARE @password VARCHAR(50)
    SET @password = NEWID()
    exec Users.spAddUser @email,@counter,@password;
    Set @counter=@counter+1
END

SELECT *
FROM Users.RegisteredUser

EXEC Users.spEditUser 'user1@email.com','customerid','21'
--Recover a password from a user
EXEC Users.recoverPassword 'user1@email.com'
SELECT *
FROM WWIGlobal.Users.RecoverUsers
EXEC Users.spRemoveUser 'user1@email.com'

select *
from Sales.SalesOrderDetail

select Sales.fnCheckIfSaleAllowsChillerProducts(1) 'check'

-- Test accordance of delivery date to lead time days of product
SELECT sd.ProductID, p.LeadTimeDays, sh.OrderDate, sh.DueDate,Sales.fnVerifyDeliveryDate(sd.SalesOrderID) 'Accordance'
FROM WWIGlobal.Sales.SalesOrderDetail sd
    JOIN WWIGlobal.Sales.SalesOrderHeader sh on sh.SalesOrderID=sd.SalesOrderID
    JOIN WWIGlobal.Sales.Product p on p.ProductID=sd.ProductID
WHERE sd.SalesOrderID=63717

SELECT sd.ProductID, p.LeadTimeDays, sh.OrderDate, sh.DueDate,Sales.fnVerifyDeliveryDate(sd.SalesOrderID) 'Accordance'
FROM WWIGlobal.Sales.SalesOrderDetail sd
    JOIN WWIGlobal.Sales.SalesOrderHeader sh on sh.SalesOrderID=sd.SalesOrderID
    JOIN WWIGlobal.Sales.Product p on p.ProductID=sd.ProductID
WHERE sd.SalesOrderID=510

-- Executes the metadata sps
EXEC spAutoGenerateMetadata

SELECT *
FROM vTableMetadata v
ORDER BY v.[Table Name],v.[Column Name]

EXEC spAutoGenerateSpaceUsed

SELECT *
FROM vTableSizeOccupied v
ORDER BY v.[Number Of Rows] DESC, v.[Table Name]

-- Test Generate DML for RegisteredUser
EXEC spGenInserts 'RegisteredUser'
EXEC spGenUpdates 'RegisteredUser'
EXEC spGenDelete 'RegisteredUser'

EXEC registereduser_insert 'newEmail@email.com',250,'newPassword'
SELECT *
FROM Users.RegisteredUser
EXEC registereduser_update 'newEmail@email.com',137,'newNewPassword'
SELECT *
FROM Users.RegisteredUser
EXEC registereduser_delete 'newEmail@email.com'
SELECT *
FROM Users.RegisteredUser
