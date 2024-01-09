use WWIGlobal

DELETE Users.RegisteredUser

IF NOT EXISTS (SELECT * FROM sys.columns
WHERE Name = 'Password' AND Object_ID = Object_ID('Users.RegisteredUser'))
BEGIN
	ALTER TABLE Users.RegisteredUser
	ADD Password varchar(100)
END
GO

-- Test user insert 
DECLARE @counter INT
SET @counter = 1
WHILE @counter <=10
BEGIN
    DECLARE @email VARCHAR(50)
    SET @email = CONCAT('user',@counter,'@email.com')
    DECLARE @password VARCHAR(50)
    SET @password = CONCAT('password', CAST(@counter AS varchar(2)))
    INSERT INTO Users.RegisteredUser(Email,CustomerID,Password) values (@email,@counter,@password)
    Set @counter=@counter+1
END

-- Password Hashing

IF NOT EXISTS (SELECT * FROM sys.columns
WHERE Name = 'HashedPassword' AND Object_ID = Object_ID('Users.RegisteredUser'))
BEGIN
	ALTER TABLE Users.RegisteredUser
	ADD HashedPassword varchar(100)
END
GO

DECLARE @email varchar(50)
DECLARE @password varchar(100)
DECLARE users_cursor CURSOR  
FOR SELECT ru.Email, ru.Password 
	FROM Users.RegisteredUser ru
OPEN users_cursor
FETCH NEXT FROM users_cursor
INTO @email, @password
WHILE @@FETCH_STATUS = 0  
BEGIN
	UPDATE Users.RegisteredUser
	SET HashedPassword = HASHBYTES('MD5',@password)
	WHERE Email=@email
	FETCH NEXT FROM  users_cursor
	INTO @email, @password;
END
CLOSE users_cursor
DEALLOCATE users_cursor
GO

ALTER TABLE Users.RegisteredUser
DROP COLUMN Password

If exists (SELECT *
		FROM Users.RegisteredUser
		WHERE Email = 'user1@email.com' AND HashedPassword = HashBytes('MD5', 'password1'))
	BEGIN
		SELECT 'Password Matched'
	END
ELSE
	BEGIN
		SELECT 'Password Did Not Match'
	END

SELECT * 
FROM Users.RegisteredUser

-- Encrypt Prices of Products with Symmetric Key
CREATE MASTER KEY ENCRYPTION
BY PASSWORD = 'CBD123'
GO

CREATE CERTIFICATE EncryptProductPrices
WITH SUBJECT = 'Encypt Product Prices'
GO

CREATE SYMMETRIC KEY ProductPriceKey
WITH ALGORITHM = AES_128 ENCRYPTION
BY CERTIFICATE EncryptProductPrices

ALTER TABLE Sales.Product
ADD UnitPriceEncrypted VARBINARY(128)
GO

ALTER TABLE Sales.Product
ADD RetailPriceEncrypted VARBINARY(128)
GO

OPEN SYMMETRIC KEY ProductPriceKey DECRYPTION
BY CERTIFICATE EncryptProductPrices
UPDATE Sales.Product
SET UnitPriceEncrypted = ENCRYPTBYKEY(KEY_GUID('ProductPriceKey'), CAST (UnitPrice AS varchar(10)))
CLOSE SYMMETRIC KEY ProductPriceKey
GO

OPEN SYMMETRIC KEY ProductPriceKey DECRYPTION
BY CERTIFICATE EncryptProductPrices
UPDATE Sales.Product
SET RetailPriceEncrypted = ENCRYPTBYKEY(KEY_GUID('ProductPriceKey'), CAST (RetailPrice AS varchar(10)))
CLOSE SYMMETRIC KEY ProductPriceKey
GO

ALTER TABLE Sales.Product
DROP COLUMN RetailPrice

ALTER TABLE Sales.Product
DROP COLUMN UnitPrice

OPEN SYMMETRIC KEY ProductPriceKey DECRYPTION
BY CERTIFICATE EncryptProductPrices
SELECT p.ProductID, CONVERT(varchar(10),DECRYPTBYKEY(p.UnitPriceEncrypted)) 'Unit Price',CONVERT(varchar(10),DECRYPTBYKEY(p.UnitPriceEncrypted)) 'Retail Price'
FROM Sales.Product p

SELECT * FROM Sales.Product