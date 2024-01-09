GO
CREATE DATABASE WWIGlobal
ON PRIMARY
(NAME = WWIGlobalDat,
FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\wwwiglobaldat.mdf',
SIZE = 100MB,
MAXSIZE = 200MB,
FILEGROWTH = 50MB),
FILEGROUP ProductDat
(NAME = WWIGlobal_ProductDat1,
FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\wwwiglobalproduct.ndf',
SIZE = 5MB,
MAXSIZE = 6MB,
FILEGROWTH = 1MB),
FILEGROUP SaleDat
(NAME = WWIGlobal_SaleDat1,
FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\wwwiglobalsale.ndf',
SIZE = 10MB,
MAXSIZE = 20MB,
FILEGROWTH = 10MB),
FILEGROUP LocDat
(NAME = WWIGlobal_LocDat1,
FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\wwwigloballoc.ndf',
SIZE = 5MB,
MAXSIZE = 6MB,
FILEGROWTH = 1MB),
FILEGROUP OfficeDat
(NAME = WWIGlobal_OfficeDat1,
FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\wwwiglobaloffice.ndf',
SIZE = 2MB,
MAXSIZE = 3MB,
FILEGROWTH = 1MB),
FILEGROUP PersonDat
(NAME = WWIGlobal_PersonDat1,
FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\wwwiglobalperson.ndf',
SIZE = 1MB,
MAXSIZE = 4MB,
FILEGROWTH = 3MB),
FILEGROUP MiscDat
(NAME = WWIGlobal_MiscDat1,
FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\wwwiglobalmisc.ndf',
SIZE = 1MB,
MAXSIZE = 1MB,
FILEGROWTH = 0MB),
FILEGROUP UserDat
(NAME = WWIGlobal_UserDat1,
FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\wwwiglobaluser.ndf',
SIZE = 1MB,
MAXSIZE = 5MB,
FILEGROWTH = 4MB),
FILEGROUP MetaDat
(NAME = WWIGlobal_MetaDat1,
FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\wwwiglobalmeta.ndf',
SIZE = 1MB,
MAXSIZE = 1MB,
FILEGROWTH = 0MB)
LOG ON
(NAME = WWIGlobalLog,
FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\wwwigloballog.ldf',
SIZE = 1MB,
MAXSIZE = 15MB,
FILEGROWTH = 14MB);
GO

USE WWIGlobal;
GO

CREATE SCHEMA Sales;
GO

CREATE SCHEMA Users;
GO

-- Create tables
CREATE TABLE WWIGlobal.Sales.Color
(
	ColorID INT NOT NULL,
	Name VARCHAR(30) NOT NULL,
	PRIMARY KEY (ColorID)
) ON MiscDat;
GO

CREATE TABLE WWIGlobal.Sales.SalesTerritory
(
	SalesTerritoryID INT NOT NULL,
	Name VARCHAR(50) NOT NULL,
	PRIMARY KEY (SalesTerritoryID),
) ON SaleDat;
GO

CREATE TABLE WWIGlobal.Sales.State
(
	Code VARCHAR(2) NOT NULL,
	Name VARCHAR(50) NOT NULL,
	SalesTerritory INT NOT NULL,
	PRIMARY KEY (Code),
	FOREIGN KEY (SalesTerritory) REFERENCES WWIGlobal.Sales.SalesTerritory(SalesTerritoryID)
) ON LocDat;
GO

CREATE TABLE WWIGlobal.Sales.Package
(
	PackageID INT,
	Name VARCHAR(30) NOT NULL,
	PRIMARY KEY (PackageID)
) ON MiscDat;
GO

CREATE TABLE WWIGlobal.Sales.City
(
	CityID INT NOT NULL,
	Name VARCHAR(30) NOT NULL,
	State VARCHAR(2) NOT NULL,
	PRIMARY KEY (CityID),
	FOREIGN KEY (State) REFERENCES WWIGlobal.Sales.State(Code)
) ON LocDat;
GO

CREATE TABLE WWIGlobal.Sales.Population
(
	CityID INT NOT NULL,
	Population INT NOT NULL
		PRIMARY KEY (CityID),
	FOREIGN KEY (CityID) REFERENCES WWIGlobal.Sales.City(CityID)
) ON LocDat;
GO

CREATE TABLE WWIGlobal.Sales.Category
(
	CategoryID INT NOT NULL,
	Name VARCHAR(20) NOT NULL,
	PRIMARY KEY (CategoryID)
) ON MiscDat;
GO

CREATE TABLE WWIGlobal.Sales.OfficeLocation
(
	LocationID INT IDENTITY(1,1),
	City INT ,
	PostalCode VARCHAR(10) NOT NULL,
	PRIMARY KEY(LocationID),
	FOREIGN KEY (City) REFERENCES WWIGlobal.Sales.City(CityID)
) ON OfficeDat;
GO

CREATE TABLE WWIGlobal.Sales.OfficeGroup
(
	GroupID INT IDENTITY(1,1),
	Name VARCHAR(30) NOT NULL,
	PRIMARY KEY (GroupID)
) ON OfficeDat;

CREATE TABLE WWIGlobal.Sales.Office
(
	OfficeID INT IDENTITY(1,1),
	OfficeParentID INT,
	OfficeGroup INT NOT NULL,
	OfficeLocation INT,
	PRIMARY KEY (OfficeID),
	FOREIGN KEY (OfficeParentID) REFERENCES WWIGlobal.Sales.Office(OfficeID),
	FOREIGN KEY (OfficeLocation) REFERENCES WWIGlobal.Sales.OfficeLocation(LocationID),
	FOREIGN KEY (OfficeGroup) REFERENCES WWIGlobal.Sales.OfficeGroup(GroupID)
) ON OfficeDat;
GO

CREATE TABLE WWIGlobal.Sales.Customer
(
	CustomerID INT IDENTITY(1,1),
	CustomerOffice INT NOT NULL,
	Category INT NOT NULL,
	PrimaryContact VARCHAR(40),
	PRIMARY KEY(CustomerID),
	FOREIGN KEY (Category) REFERENCES WWIGlobal.Sales.Category(CategoryID),
	FOREIGN KEY (CustomerOffice) REFERENCES WWIGlobal.Sales.Office(OfficeID)
) ON PersonDat;
GO

CREATE TABLE WWIGlobal.Sales.Employee
(
	EmployeeID INT IDENTITY(1,1),
	Name VARCHAR(30),
	PreferedName VARCHAR(30),
	PRIMARY KEY (EmployeeID)
) ON PersonDat;
GO

CREATE TABLE WWIGlobal.Sales.SalesEmployee
(
	EmployeeID INT NOT NULL,
	PRIMARY KEY (EmployeeID),
	FOREIGN KEY (EmployeeID) REFERENCES WWIGlobal.Sales.Employee(EmployeeID)
) ON SaleDat;
GO

CREATE TABLE WWIGlobal.Sales.Size
(
	SizeID INT IDENTITY(1,1),
	Size VARCHAR(40),
	PRIMARY KEY (SizeID)
) ON MiscDat;
GO

CREATE TABLE WWIGlobal.Sales.ProductDescription
(
	DescriptionID INT IDENTITY(1,1),
	Description VARCHAR(100),
	PRIMARY KEY (DescriptionID)
) ON ProductDat;
GO

CREATE TABLE WWIGlobal.Sales.Product
(
	ProductID INT IDENTITY(1,1),
	ProductDescription INT,
	Color INT NOT NULL,
	Size INT,
	Weight FLOAT,
	SellPackage INT,
	LeadTimeDays INT,
	TaxRate FLOAT NOT NULL,
	UnitPrice MONEY NOT NULL,
	RetailPrice MONEY NOT NULL,
	PRIMARY KEY (ProductID),
	FOREIGN KEY (Color) REFERENCES WWIGlobal.Sales.Color(ColorID),
	FOREIGN KEY (Size) REFERENCES WWIGlobal.Sales.Size(SizeID),
	FOREIGN KEY (SellPackage) REFERENCES WWIGlobal.Sales.Package(PackageID),
	FOREIGN KEY (ProductDescription) REFERENCES WWIGlobal.Sales.ProductDescription(DescriptionID)
) ON ProductDat;
GO

CREATE TABLE WWIGlobal.Sales.ChillerProducts
(
	ChillerID INT NOT NULL,
	PRIMARY KEY (ChillerID),
	FOREIGN KEY (ChillerID) REFERENCES WWIGlobal.Sales.Product(ProductID)
) ON ProductDat;
GO

CREATE TABLE WWIGlobal.Sales.SalesOrderHeader
(
	SalesOrderID INT IDENTITY(1,1),
	OrderDate DATE NOT NULL,
	DueDate DATE,
	CustomerID INT NOT NULL,
	BillToID INT NOT NULL,
	EmployeeID INT NOT NULL,
	TaxAmount MONEY NOT NULL,
	PRIMARY KEY (SalesOrderID),
	FOREIGN KEY (CustomerID) REFERENCES WWIGlobal.Sales.Customer(CustomerID),
	FOREIGN KEY (EmployeeID) REFERENCES WWIGlobal.Sales.SalesEmployee(EmployeeID)
) ON SaleDat;
GO

CREATE TABLE WWIGlobal.Sales.SalesOrderDetail
(
	SalesOrderID INT NOT NULL,
	SalesOrderDetailID INT IDENTITY(1,1),
	OrderQty INT NOT NULL,
	ProductID INT NOT NULL,
	PRIMARY KEY (SalesOrderID,SalesOrderDetailID),
	FOREIGN KEY (SalesOrderID) REFERENCES WWIGlobal.Sales.SalesOrderHeader(SalesOrderID),
	FOREIGN KEY (ProductID) REFERENCES WWIGlobal.Sales.Product(ProductID)
) ON SaleDat;
GO

CREATE TABLE WWIGlobal.Sales.PromotionType
(
	TypeID INT IDENTITY(1,1),
	PromotionDescription VARCHAR(100),
	PromotionDetails VARCHAR(30) NOT NULL
		PRIMARY KEY(TypeID)
) ON ProductDat;
GO

CREATE TABLE WWIGlobal.Sales.Promotions
(
	ProductID INT NOT NULL,
	PromotionType INT NOT NULL,
	DateStart DATE NOT NULL,
	DateEnd DATE,
	PRIMARY KEY(ProductID),
	FOREIGN KEY (ProductID) REFERENCES WWIGlobal.Sales.Product(ProductID),
	FOREIGN KEY (PromotionType) REFERENCES WWIGlobal.Sales.PromotionType(TypeID)
) ON ProductDat;
GO

CREATE TABLE WWIGlobal.Users.RegisteredUser
(
	Email VARCHAR(50) NOT NULL,
	CustomerID INT NOT NULL UNIQUE,
	Password VARCHAR(100) NOT NULL,
	PRIMARY KEY (Email),
	FOREIGN KEY (CustomerID) REFERENCES WWIGlobal.Sales.Customer (CustomerID)
) ON UserDat;
GO

CREATE TABLE WWIGlobal.Users.RecoverUsers
(
	Email VARCHAR(50) NOT NULL,
	Token VARCHAR(100) NOT NULL,
	ValidUntil DATETIME NOT NULL,
	PRIMARY KEY (Email),
	FOREIGN KEY
	(Email) REFERENCES WWIGlobal.Users.RegisteredUser(Email)
) ON UserDat;
GO

CREATE TABLE WWIGlobal.dbo.ErrorLog
(
	ErrorLogID INT IDENTITY(1,1),
	ErrorTime DATETIME NOT NULL,
	UserName SYSNAME NOT NULL,
	ErrorNumber INT NOT NULL,
	ErrorMessage VARCHAR(200),
	ErrorState INT,
	PRIMARY KEY(ErrorLogID)
)
GO

CREATE TABLE WWIGlobal.dbo.MetadataLog
(
	MetadataID INT IDENTITY(1,1),
	ExecuteDate DATETIME NOT NULL,
	PRIMARY KEY (MetadataID)
) ON MetaDat;
GO

CREATE TABLE WWIGlobal.dbo.MetadataLogDetail
(
	MetadataID INT NOT NULL,
	MetadataDeatilsID INT IDENTITY(1,1),
	TableName VARCHAR(50),
	ColumnName VARCHAR(50),
	DataType VARCHAR(20),
	MaxLength INT NOT NULL,
	Precision INT NOT NULL,
	isNullable BIT NOT NULL,
	isPrimaryKey BIT NOT NULL,
	isForeignKey BIT NOT NULL,
	PRIMARY KEY (MetadataDeatilsID),
	FOREIGN KEY (MetadataID) REFERENCES WWIGlobal.dbo.MetadataLog(MetadataID)
) ON MetaDat;
GO

CREATE TABLE WWIGlobal.dbo.SpaceOccupiedLog
(
	SpaceID INT IDENTITY(1,1),
	ExecuteDate DATETIME NOT NULL,
	PRIMARY KEY (SpaceID)
) ON MetaDat;
GO

CREATE TABLE WWIGlobal.dbo.SpaceOccupiedLogDetail
(
	SpaceID INT NOT NULL,
	SpaceDetailsID INT IDENTITY(1,1),
	TableName VARCHAR(50),
	NumberOfRows INT NOT NULL,
	SpaceUsed INT
		PRIMARY KEY (SpaceDetailsID),
	FOREIGN KEY (SpaceID) REFERENCES WWIGlobal.dbo.SpaceOccupiedLog(SpaceID)
) ON MetaDat;
GO