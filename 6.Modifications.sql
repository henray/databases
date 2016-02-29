/* First query will update cut percentage of all teams that have made more than $3 dollars to current cut percentage + 5% */

Update Product SET cutPercentage = cutPercentage + 0.05 
WHERE productID IN 
(
	SELECT Product.productID
	FROM Product, Productorderwarehouse, TeamMerchandiseTeam 
	WHERE Product.productID = TeamMerchandiseTeam.productID
	AND TeamMerchandiseTeam.productID = productorderwarehouse.productID 
	GROUP BY Product.productID
	HAVING sum(cutPercentage * quantity * (retailPrice - manufacturerPrice)) > 3
);

/* Second query will delete all player merchandise (in whole database) that have not made over $80 in total retail sales. */

DELETE FROM Product
WHERE productID NOT IN 
(
	SELECT DISTINCT Product.productID
	FROM Product, PlayerMerchandisePlayer, Productorderwarehouse
	WHERE Product.productID = PlayerMerchandisePlayer.productID
	AND PlayerMerchandisePlayer.productID = Productorderwarehouse.productID 
	GROUP BY Product.productID
	HAVING sum(quantity * retailPrice) > 80
);

/* Third query will delete all customers who have not ordered anything after 2014 */

DELETE FROM Customer
WHERE customerID IN
(
	SELECT Customer.customerID
	FROM Customer, Orders, CustomerOrder
	WHERE Customer.customerID = CustomerOrder.customerID
	AND Orders.orderID = CustomerOrder.orderID
	AND Orders.orderDate < '2013-12-31'
);

/* Fourth query
Creates a new table called ValuedCustomer and queries for customers who have spent over $50 in 
our store and inserts it into this table.  ValuedCustomer has the same attributes as Customer 
with an extra field total = total that the customer has spent. */


drop TABLE ValuedCustomer;
CREATE TABLE ValuedCustomer
(
	customerID int, 
	firstName varchar(50) NOT NULL, 
	lastName varchar(50) NOT NULL, 
	email varchar(50) UNIQUE NOT NULL, 
	address varchar(100) NOT NULL,
	total double precision,
	PRIMARY KEY (customerID)
);

CREATE OR REPLACE FUNCTION updateValuesWithLoop()
RETURNS void AS $BODY$
DECLARE
	a int;
	r double precision;
BEGIN
	FOR a IN SELECT customerID FROM Customer LOOP
		SELECT sum(retailPrice * quantity) INTO r
		FROM CustomerOrder, Orders, Product, ProductOrderWarehouse
		WHERE CustomerOrder.customerID = a
		AND Orders.orderID = ProductOrderWarehouse.orderID
		AND Orders.orderID = CustomerOrder.orderID
		AND ProductOrderWarehouse.productID = Product.productID;

		If (r > 50)
		THEN
			INSERT INTO ValuedCustomer(customerID, firstName, lastName, email, address) 
			SELECT * FROM Customer where Customer.customerID = a;
			UPDATE ValuedCustomer SET total = r WHERE customerID = a;
		END IF;
	END LOOP;
END
$BODY$
LANGUAGE 'plpgsql';

SELECT updateValuesWithLoop();
SELECT * FROM ValuedCustomer;