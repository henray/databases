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
RETURNS integer AS $BODY$
DECLARE
	oID integer;
	oDate date;
	wquantity integer;
BEGIN
	wquantity := (SELECT quantity FROM WarehouseProduct WHERE productID = pID AND warehouseID = wID);
	IF wquantity - qty < 0 THEN
		RAISE EXCEPTION 'There is not enough in the warehouse to place this order!';
	ELSE
		oID := (SELECT max(orderID) + 1 FROM Orders);
		oDate := current_date;
		INSERT INTO Orders VALUES (oID, pmethod, oDate);
		INSERT INTO CustomerOrder VALUES (cID, oID);
		INSERT INTO ProductOrderWarehouse VALUES (qty, pID, oID, wID);
		UPDATE WarehouseProduct SET quantity = quantity - qty
			WHERE productID = pID AND warehouseID = wID;
		RETURN oID;
	END IF;
END;
$BODY$
LANGUAGE 'plpgsql';

/*Moves products from one warehouse to a different warehouse*/
/*Takes in as input two warehouse IDs, the product ID, and the quantity*/
/*Returns true if the move succeeded and false if it failed*/
CREATE OR REPLACE FUNCTION moveWarehouses(wID1 integer, wID2 integer, pID integer, qty integer)
RETURNS BOOLEAN AS 
$BODY$
DECLARE
	wquantity integer;
BEGIN
	IF qty <= 0 THEN
		RAISE EXCEPTION 'The quantity entered is negative.';
	END IF;
	wquantity := (SELECT quantity FROM WarehouseProduct WHERE productID = pID AND warehouseID = wID1);
	IF wquantity - qty < 0 THEN
		RAISE EXCEPTION 'The warehouse does not have enough of the product in stock!';
	END IF;
	IF wquantity - qty = 0 THEN
		RAISE EXCEPTION 'The warehouse must have at least one unit of the product remaining!';
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


-- This is a multi-purpose procedure that given a threshold, we can increase or decrease the prices by an input modifier.
-- The decision the change the prices above or below the threshold is given by the input boolean above.
-- The modifier is a multiplier on the existing price.
-- If above is true, only the products that have sold quantity above the threshold are modified.
-- Likewise, if above is false, only the products that have sold quantity below the threshold are modified.
-- The items are modified by changing their retail price given by newPrice = oldPrice * modifier
-- e.g. changePrice(5, true, 1.1) = multiply the prices of all items that have been sold over 5 times by 1.1
--		changePrices(5, false, 0.9) = multiply the prices of all items that have been sold under 5 times by 0.9

CREATE OR REPLACE FUNCTION changePrices(threshold integer, above boolean, modifier double precision)
RETURNS TABLE(id integer, pname character varying, price double precision, qty bigint) AS
$BODY$
BEGIN
	IF threshold <= 0 THEN
		RAISE EXCEPTION 'Threshold needs to be a positive integer.';
	END IF;

	IF modifier < .8  THEN
		RAISE EXCEPTION 'Modifier too low. Price cannot be lowered by more than 20 percent at once.';
	END IF;

	IF modifier > 1.2 THEN
		RAISE EXCEPTION 'Modifier too high. Price cannot be raised by more than 20 percent at once.';
	END IF;
	
	IF above THEN
		UPDATE Product SET retailPrice = retailPrice * modifier
			WHERE productID IN 				
				(SELECT Product.productID FROM ProductOrderWarehouse, Product
				WHERE Product.productID = ProductOrderWarehouse.productID
				GROUP BY Product.productID
				HAVING sum(quantity) > threshold);
		RETURN QUERY
		SELECT Product.productID, productName, retailPrice, sum(quantity) FROM Product, ProductOrderWarehouse
		WHERE Product.productID = ProductOrderWarehouse.productID
		GROUP BY Product.productID
		HAVING sum(quantity) > threshold
		ORDER BY sum(quantity), retailPrice;
	ELSE 
		UPDATE Product SET retailPrice = retailPrice * modifier
			WHERE productID IN 				
				(SELECT Product.productID FROM ProductOrderWarehouse, Product
				WHERE Product.productID = ProductOrderWarehouse.productID
				GROUP BY Product.productID
				HAVING sum(quantity) < threshold);
		RETURN QUERY
		SELECT Product.productID, productName, retailPrice, sum(quantity) FROM Product, ProductOrderWarehouse
		WHERE Product.productID = ProductOrderWarehouse.productID
		GROUP BY Product.productID
		HAVING sum(quantity) < threshold
		ORDER BY sum(quantity), retailPrice;
	END IF;
END;
$BODY$
LANGUAGE 'plpgsql';

/*Retrieves all players for a team given. Used by playersalecount stored procedure in the GUI*/
/*CREATE OR REPLACE FUNCTION queryplayers(IN team character varying)
  RETURNS TABLE(jersey integer, name text) AS
$BODY$

BEGIN	
	RETURN QUERY SELECT playernumber, firstname || ' ' || lastname
	FROM player
	WHERE teamname = team
	ORDER BY playernumber;

END
$BODY$
LANGUAGE 'plpgsql';*/

/*Retrieves all the team names in the Team table*/
/*CREATE OR REPLACE FUNCTION queryTeamNames()
  Returns TABLE(teamName character varying) AS
$BODY$

BEGIN
	RETURN QUERY SELECT Team.teamName FROM Team
	ORDER BY Team.teamName ASC;
END
$BODY$
LANGUAGE 'plpgsql';*/

/*Retrieve all the warehouses in the Warehouse table*/
/*CREATE OR REPLACE FUNCTION queryWarehouses()
  Returns TABLE(warehouseID integer, address character varying) AS
$BODY$

BEGIN
	RETURN QUERY SELECT Warehouse.warehouseid, Warehouse.address FROM Warehouse
	ORDER BY Warehouse.warehouseid ASC;
END
$BODY$
LANGUAGE 'plpgsql';*/

/*Retrieve all the warehouses except for the inputted ID*/
/*CREATE OR REPLACE FUNCTION queryWarehousesExcept(wID integer)
  Returns TABLE(warehouseID integer, address character varying) AS
$BODY$

BEGIN
	RETURN QUERY 
	SELECT w1.warehouseid, w1.address 
	FROM Warehouse w1
	EXCEPT
	SELECT w2.warehouseID,w2.address 
	FROM Warehouse w2 
	WHERE w2.warehouseID = wID
	ORDER BY warehouseid ASC;
END
$BODY$
LANGUAGE 'plpgsql';*/


/*Retrieve all productIDs at the inputted warehouseID*/
/*CREATE OR REPLACE FUNCTION queryProductsAtWarehouse(wID integer)
  Returns TABLE(prodID integer) AS
$BODY$

BEGIN
	RETURN QUERY 
	SELECT productID FROM WarehouseProduct
	WHERE warehouseID = wID
	ORDER BY productID ASC;
END
$BODY$
LANGUAGE 'plpgsql';*/

/*Retrieve the quantity of the inputted productID*/
/*CREATE OR REPLACE FUNCTION queryProductQuantity(pID integer, wID integer)
  Returns TABLE(quant integer) AS
$BODY$

BEGIN
	RETURN QUERY 
	SELECT quantity FROM WarehouseProduct
	WHERE productID = pID AND warehouseID = wID;
END
$BODY$
LANGUAGE 'plpgsql';*/
