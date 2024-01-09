-- Índices

-- Pesquisa de vendas por cidade. Deve ser retornado o nome da cidade, o nome do vendedor, o total de vendas
-- (nota: cidades com o mesmo nome mas de diferentes estados deverão ser consideradas distintas);
use WWIGlobal;

select * from Sales.SalesOrderHeader;
select * from Sales.SalesEmployee;
select * from Sales.Employee;
select * from Sales.Customer;
select * from Sales.Office;
select * from Sales.OfficeLocation;
select * from Sales.City;

-- Query 1:
select distinct ct.Name as 'CityName', e.Name as 'EmployeeName' , count(*) as 'Total'
from WWIGlobal.Sales.SalesOrderHeader soh
join WWIGlobal.Sales.SalesEmployee se on se.EmployeeID = soh.EmployeeID
join WWIGlobal.Sales.Employee e on e.EmployeeID = se.EmployeeID
join WWIGlobal.Sales.Customer c on c.CustomerID = soh.CustomerID
join WWIGlobal.Sales.Office o on o.OfficeID = c.CustomerOffice
join WWIGlobal.Sales.OfficeLocation ol on ol.LocationID = o.OfficeLocation
join WWIGlobal.Sales.City ct on ct.CityID = ol.City
group by ct.Name, e.Name;

-- Índice 1:
USE [WWIGlobal]
GO
CREATE NONCLUSTERED INDEX [NONCI_SalesByCity]
ON [Sales].[SalesOrderHeader] ([CustomerID])
INCLUDE ([EmployeeID])
GO

-- Para as vendas calcular a taxa de crescimento de cada ano, face ao ano anterior, por categoria de cliente;
select * from Sales.SalesOrderHeader;
select * from Sales.Customer;
select * from Sales.Category;

-- Query 2 (function):
/* drop function Sales.fnCalculateTotalSalesYear */
GO
create function Sales.fnCalculateTotalSalesYear(@year int,@category varchar(50))
returns float
AS
begin
	DECLARE @previousYearTotal INT
	DECLARE @currentYearTotal INT
	
	SET @previousYearTotal = (select count(*) as 'TotalSales'
								from WWIGlobal.Sales.SalesOrderHeader soh
								join WWIGlobal.Sales.Customer c on c.CustomerID = soh.CustomerID
								join WWIGlobal.Sales.Category cg on cg.CategoryID = c.Category
								group by year(soh.OrderDate), cg.Name
								having YEAR(soh.OrderDate) = @year-1 AND cg.Name=@category)

	SET @currentYearTotal = (select count(*) as 'TotalSales'
								from WWIGlobal.Sales.SalesOrderHeader soh
								join WWIGlobal.Sales.Customer c on c.CustomerID = soh.CustomerID
								join WWIGlobal.Sales.Category cg on cg.CategoryID = c.Category
								group by year(soh.OrderDate), cg.Name
								having YEAR(soh.OrderDate) = @year AND cg.Name=@category)
	IF(@previousYearTotal is not null)
	BEGIN
		DECLARE @growth decimal(10,3)
		SET @growth = (@currentYearTotal - @previousYearTotal)
		SET @growth /= @previousYearTotal
	END
	ELSE
	BEGIN
		SET @growth = 0
	END
	return @growth
end
GO

-- Query 2:
select distinct year(soh.OrderDate) as 'Year', cg.Name as 'Category',Sales.fnCalculateTotalSalesYear(YEAR(soh.OrderDate),cg.Name) 'Growth Rate'
from WWIGlobal.Sales.SalesOrderHeader soh
join WWIGlobal.Sales.Customer c on c.CustomerID = soh.CustomerID
join WWIGlobal.Sales.Category cg on cg.CategoryID = c.Category
group by year(soh.OrderDate), cg.Name
order by year(soh.OrderDate);
GO

-- Índice 2:
USE [WWIGlobal]
GO
CREATE NONCLUSTERED INDEX [NONCI_GrowthRate]
ON [Sales].[SalesOrderHeader] ([CustomerID])
INCLUDE ([OrderDate])
GO

-- Nº de produtos (stockItem) nas vendas por categoria de produtos.
select * from WWIGlobal.Sales.SalesOrderHeader;
select * from WWIGlobal.Sales.SalesOrderDetail;
select * from WWIGlobal.Sales.Product;
select * from WWIGlobal.Sales.ProductDescription;

-- Query 3:
select sum(sod.OrderQty) as 'NumProducts', pd.Description as 'Category'
from WWIGlobal.Sales.SalesOrderHeader soh
join WWIGlobal.Sales.SalesOrderDetail sod on sod.SalesOrderID = soh.SalesOrderID
join WWIGlobal.Sales.Product p on p.ProductID = sod.ProductID
join WWIGlobal.Sales.ProductDescription pd on pd.DescriptionID = p.ProductDescription
group by pd.Description;