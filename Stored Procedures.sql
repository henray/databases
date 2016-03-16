/* Retrieve either the profit made from selling the products associated to the team given or retrieve profits for all teams if 'NBA' is given */
/*Takes in as input the teamname*/
/*Returns a table of the team and the profit that team has generated*/
CREATE OR REPLACE FUNCTION retrieveRevenue(teamName varchar(50)) 
RETURNS TABLE(
	team varchar(50),
	profit double precision
)
AS $BODY$
DECLARE teamvar ALIAS FOR $1;	
BEGIN
	IF teamvar = 'NBA' THEN 
		RETURN QUERY
		SELECT team.teamName, CASE WHEN sum(quantity * (retailPrice - manufacturerPrice)) IS NULL THEN 0
		ELSE sum(cast(quantity AS float) * (retailPrice - manufacturerPrice)) END AS profit 
		FROM Team
		INNER JOIN teamMerchandiseTeam
		ON team.teamName = teamMerchandiseTeam.teamName
		INNER JOIN Product
		ON teamMerchandiseTeam.productId = Product.productId
		LEFT OUTER JOIN ProductOrderWarehouse
		ON Product.productID = ProductOrderWarehouse.productID
		GROUP BY team.teamName
		ORDER BY teamName;
	ELSE
		RETURN QUERY
		SELECT teamvar AS teamName, CASE WHEN sum(quantity * (retailPrice - manufacturerPrice)) IS NULL THEN 0
		ELSE sum(cast(quantity AS float) * (retailPrice - manufacturerPrice)) END AS profit 
		FROM teamMerchandiseTeam
		INNER JOIN Product
		ON teamMerchandiseTeam.productId = Product.productId
		LEFT OUTER JOIN ProductOrderWarehouse
		ON Product.productID = ProductOrderWarehouse.productID
		WHERE teamMerchandiseTeam.teamName = teamvar
		GROUP BY teamvar;
	END IF;
END;
$BODY$
LANGUAGE plpgsql;



/* Retrieve the number of customers that have purchased a players' products */
/*Takes in as input the player number and the team*/
/*Returns an integer indicating the number of customers that have purchased that product*/
CREATE OR REPLACE FUNCTION playersalecount(playernum integer, playerteam character varying)
RETURNS integer AS
$BODY$
DECLARE
	customerCount int;
BEGIN	
	customerCount := (SELECT sum(quantity) -- orders with player products
					  FROM ProductOrderWarehouse
					  INNER JOIN (
						SELECT productId AS playerId -- product ids associated with player
						FROM PlayerMerchandisePlayer
						WHERE playernumber = playerNum AND teamname = playerTeam
					  ) AS playerProducts
					  ON ProductOrderWarehouse.productId = playerProducts.playerId);
	RETURN customerCount;
END
$BODY$
LANGUAGE 'plpgsql';


﻿/*Gets all customers that have ordered a specific product*/
/*Takes in as input the product ID*/
/*Returns the table of customerID, firstname, lastname, and the number of that product the customer bought*/
CREATE OR REPLACE FUNCTION customersFromProduct(productID integer)
RETURNS TABLE(id integer, firstname character varying, lastname character varying, quantity integer) AS
$BODY$
DECLARE
	pID ALIAS FOR $1;
BEGIN
	IF EXISTS(SELECT 1 FROM Product WHERE Product.productID = pID) THEN
		RETURN QUERY 	
		SELECT Customer.customerID, Customer.firstname, Customer.lastname, ProductOrderWarehouse.quantity 
		FROM Customer, Product, ProductOrderWarehouse, CustomerOrder, Orders
		WHERE Customer.customerID = CustomerOrder.customerID
		AND Orders.orderID = CustomerOrder.orderID
		AND Product.productID = ProductOrderWarehouse.productID
		AND Orders.orderID = ProductOrderWarehouse.orderID
		AND Product.productID = pID;
	ELSE
		RAISE EXCEPTION 'The product ID entered does not exist!';
	END IF;
END;
$BODY$
LANGUAGE 'plpgsql';

/*Places an order*/
/*Takes in as input the customer id, the product id, the quantity of the order, the payment method, and the warehouse ID*/
/*Returns true if the order was placed and false if it failed*/
CREATE OR REPLACE FUNCTION placeAnOrder(cID integer, pID integer, qty integer, pmethod payment_method, wID integer)
RETURNS BOOLEAN AS $BODY$
DECLARE
	oID integer;
	oDate date;
	wquantity integer;
BEGIN
	wquantity := (SELECT quantity FROM WarehouseProduct WHERE productID = pID AND warehouseID = wID);
	IF wquantity - qty < 0 THEN
		RETURN FALSE;
	ELSE
		oID := (SELECT max(orderID) + 1 FROM Orders);
		oDate := current_date;
		INSERT INTO Orders VALUES (oID, pmethod, oDate);
		INSERT INTO CustomerOrder VALUES (cID, oID);
		INSERT INTO ProductOrderWarehouse VALUES (qty, pID, oID, wID);
		UPDATE WarehouseProduct SET quantity = quantity - qty
			WHERE productID = pID AND warehouseID = wID;
		RETURN TRUE;
	END IF;
END;
$BODY$
LANGUAGE 'plpgsql';

/*Moves products from one warehouse to a different warehouse*/
/*Takes in as input two warehouse IDs, the product ID, and the quantity*/
/*Returns true if the move succeeded and false if it failed*/
CREATE OR REPLACE FUNCTION moveWarehouses(wID1 integer, wID2 integer, pID integer, qty integer)
RETURNS BOOLEAN AS $BODY$
DECLARE
	wquantity integer;
BEGIN
	wquantity := (SELECT quantity FROM WarehouseProduct WHERE productID = pID AND warehouseID = wID1);
	IF wquantity - qty < 0 THEN
		RETURN FALSE;
	ELSE
		UPDATE WarehouseProduct SET quantity = quantity - qty
			WHERE productID = pID AND warehouseID = wID1;
		UPDATE WarehouseProduct SET quantity = quantity + qty
			WHERE productID = pID AND warehouseID = wID2;
		RETURN TRUE;
	END IF;
END;
$BODY$
LANGUAGE 'plpgsql';

/*Increases or decreases the prices of products that have sold above/below a threshold amount and returns the table of updated products*/
/*Takes in as input the threshold price, and a boolean to indicate increase or decrease prices*/
/*Returns the table of productid, product_name, and the new price of the products that have been modified*/
CREATE OR REPLACE FUNCTION changePrices(threshold integer, increase boolean)
RETURNS TABLE(id integer, pname character varying, price double precision) AS
$BODY$
BEGIN
	IF increase THEN
		UPDATE Product SET retailPrice = retailPrice * 1.10
			WHERE productID IN 				
				(SELECT Product.productID FROM ProductOrderWarehouse, Product
				WHERE quantity >= threshold
				AND Product.productID = ProductOrderWarehouse.productID);
		RETURN QUERY
		SELECT productID, productName, retailPrice FROM Product
		WHERE productID IN 
			(SELECT Product.productID FROM ProductOrderWarehouse, Product
			WHERE quantity >= threshold
			AND Product.productID = ProductOrderWarehouse.productID);
	ELSE 
		UPDATE Product SET retailPrice = retailPrice * 0.90
			WHERE productID IN 				
				(SELECT Product.productID FROM ProductOrderWarehouse, Product
				WHERE quantity <= threshold
				AND Product.productID = ProductOrderWarehouse.productID);
		RETURN QUERY
		SELECT productID, productName, retailPrice FROM Product
		WHERE productID IN 
			(SELECT Product.productID FROM ProductOrderWarehouse, Product
			WHERE quantity <= threshold
			AND Product.productID = ProductOrderWarehouse.productID);
	END IF;
END;
$BODY$
LANGUAGE 'plpgsql';

SELECT * FROM changePrices(2, false)


/*Retrieves all players for a team given. Used by playersalecount stored procedure in the GUI*/
CREATE OR REPLACE FUNCTION queryplayers(IN team character varying)
  RETURNS TABLE(jersey integer, name text) AS
$BODY$

BEGIN	
	RETURN QUERY SELECT playernumber, firstname || ' ' || lastname
	FROM player
	WHERE teamname = team
	ORDER BY playernumber;

END
$BODY$
LANGUAGE plpgsql
  
CREATE OR REPLACE FUNCTION playersalecount(playernum integer, playerteam character varying)
RETURNS integer AS
$BODY$
DECLARE
	customerCount int;
BEGIN	
	IF EXISTS(SELECT * FROM Player WHERE teamName = playerteam AND playernumber = playernum) THEN
		customerCount := (SELECT sum(quantity) -- orders with player products
						  FROM ProductOrderWarehouse
						  INNER JOIN (
							SELECT productId AS playerId -- product ids associated with player
							FROM PlayerMerchandisePlayer
							WHERE playernumber = playerNum AND teamname = playerTeam
						  ) AS playerProducts
						  ON ProductOrderWarehouse.productId = playerProducts.playerId);
		RETURN customerCount;
	ELSE
		RAISE NOTICE 'Player does not exist!';	
	END IF;
END
$BODY$
LANGUAGE 'plpgsql';
