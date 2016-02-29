/* Addresses where product was shipped:
This view is used to return a table with productID, address, and customerID. 
This is to see where each product is sold, which will aid with determining which 
warehouses should stock certain items for cheaper/quicker shipping without revealing 
sensitive customer information. */

CREATE VIEW sale_map AS
WITH Product_customers AS ( -- gets customerID and productID
	SELECT productID, customerID
	FROM ProductOrderWarehouse 
	INNER JOIN CustomerOrder
	ON ProductOrderWarehouse.orderID = CustomerOrder.orderID
)
SELECT productID, address, Customer.customerID
FROM Customer 
INNER JOIN Product_customers
ON Customer.customerID = Product_customers.customerID
ORDER BY productID;

/*Update Statement to test*/
Update sale_map SET address = 'Canada' WHERE customerid = '79';

/*This second view shows all products that have been sold in 
all orders along with the retail price and quantities in each order. 
This view is now updatable by default because we are querying from more than one table. 
However, it is updatable for the retail price since we have created a rule where if a user 
tries to update the view, it will instead update the underlying table product and set the 
retail price to the new price specified in the query. */

CREATE VIEW ProductsSold AS
SELECT productname, retailprice, quantity 
FROM Product 
INNER JOIN productorderwarehouse 
ON Product.productID = Productorderwarehouse.productID;
CREATE RULE visitProductsSold 
AS ON UPDATE TO ProductsSold 
DO INSTEAD UPDATE product 
SET retailprice = NEW.retailprice 
WHERE productname = NEW.productname;

/*Update Statement to test rule*/
Update ProductsSold SET retailprice = 100 WHERE productname = 'NBA Keychain';

