use WWIGlobal

select YEAR(sh.OrderDate) 'year' , SUM(sd.OrderQty*p.UnitPrice) as total
from Sales.SalesOrderDetail sd
	join Sales.SalesOrderHeader sh on sh.SalesOrderID=sd.SalesOrderID
	join Sales.Product p on p.ProductID=sd.ProductID
group by YEAR(sh.OrderDate) 
for JSON auto

select YEAR(sh.OrderDate) 'year' ,MONTH(sh.OrderDate) 'monthTotal.month', SUM(sd.OrderQty*p.UnitPrice) as 'monthTotal.total'
from Sales.SalesOrderDetail sd
	join Sales.SalesOrderHeader sh on sh.SalesOrderID=sd.SalesOrderID
	join Sales.Product p on p.ProductID=sd.ProductID
group by YEAR(sh.OrderDate),MONTH(sh.OrderDate) 
order by 1,2
for JSON path

select sh.CustomerID 'customer.id',og.Name 'customer.brand',sh.OrderDate 'orderDate',sd.OrderQty 'orderQuantity',pd.Description 'product.description',p.UnitPrice 'product.price'
from Sales.SalesOrderDetail sd
	join Sales.SalesOrderHeader sh on sh.SalesOrderID=sd.SalesOrderID
	join Sales.Product p on p.ProductID=sd.ProductID
	join Sales.ProductDescription pd on p.ProductDescription=pd.DescriptionID
	join Sales.Color c on c.ColorID=p.Color
	join Sales.Size s on s.SizeID= p.Size
	join Sales.Customer cus on cus.CustomerID=sh.CustomerID
	join Sales.Office o on o.OfficeID=cus.CustomerOffice
	join Sales.OfficeGroup og on og.GroupID=o.OfficeGroup
for JSON path