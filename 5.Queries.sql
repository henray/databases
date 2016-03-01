/* First query will grab the total revenue of our store, using explicit join*/
SELECT sum(quantity * (retailPrice - manufacturerPrice)) 
FROM Product 
INNER JOIN productorderwarehouse 
ON productorderwarehouse.productID = Product.productID;

/* Second query will grab the players that have made over $80 from one specific team
	    The example team will be the Golden State Warriors, we use implicit join here */
SELECT playerNumber, teamName 
FROM Product, ProductOrderWarehouse, PlayerMerchandisePlayer 
WHERE ProductOrderWarehouse.productID = Product.productID 
	AND Product.productID = PlayerMerchandisePlayer.productID 
AND PlayerMerchandisePlayer.teamName = 'Golden State Warriors' 
GROUP BY playerNumber, teamName
HAVING sum(cutPercentage * quantity * (retailPrice - manufacturerPrice)) > 80

/*Third query will list all distinct productNames that were sold between 2014-01-01 and 2014-03-01*/

SELECT DISTINCT productName 
FROM Product 
INNER JOIN ProductOrderWarehouse 
ON Product.productID = ProductOrderWarehouse.productID 
INNER JOIN Orders 
ON ProductOrderWarehouse.orderID = Orders.orderID 
WHERE orderDate > '2014-01-01'  AND orderDate < '2014-03-01' 
ORDER BY productName DESC;

/* Fourth query will grab the customers who have paid with VISA on products that have come from Adidas*/
SELECT Customer.firstName, Customer.lastName FROM Customer 
WHERE Customer.customerID IN 
(SELECT DISTINCT customerID FROM CustomerOrder, Orders, Productorderwarehouse
WHERE CustomerOrder.orderID = Orders.orderID 
AND Orders.orderID = Productorderwarehouse.orderID 
AND Orders.payment = 'visa'
AND Productorderwarehouse.productID 
IN 
(
	SELECT productID 
	FROM ShipmentProduct, ShipmentSupplier
	WHERE ShipmentProduct.shipmentID = ShipmentSupplier.shipmentID 
	AND ShipmentSupplier.supplierName = 'Adidas'
) 
ORDER BY customerID);

/* Fifth query will get customer first and last name that have made an order that includes any Stephen Curry
product and the total order costs more than $50 */
SELECT DISTINCT firstname, lastname 
FROM productorderwarehouse
INNER JOIN Orders
ON productorderwarehouse.orderID = Orders.orderID 
INNER JOIN
(
	SELECT orderID 
	FROM Product  
	INNER JOIN ProductOrderWarehouse 
	ON Product.productID = ProductOrderWarehouse.productID
	WHERE productName LIKE 'Stephen Curry%' 
	INTERSECT
	SELECT orderID 
	From ProductOrderWarehouse
	INNER JOIN Product 
	ON ProductOrderWarehouse.productID = Product.productID
	GROUP BY orderID 
	HAVING sum(quantity * retailPrice) > 50
) AS stephenCurryOrders

ON Orders.orderID = stephenCurryOrders.orderID 
INNER JOIN CustomerOrder 
ON stephenCurryOrders.orderID = CustomerOrder.orderID
INNER JOIN Customer 
ON CustomerOrder.customerID = Customer.customerID;
