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
SELECT * FROM ValuedCustomer;