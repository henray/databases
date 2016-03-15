/* Retrieve either the profit made from selling the products associated to the team given or retrieve profits for all teams if 'NBA' is given */
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

SELECT * FROM retrieveRevenue('NBA');



/* Retrieve the number of customers that have purchased a players' products */
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

SELECT * FROM playersalecount(2, 'Atlanta Hawks');




﻿/*Gets all customers that have ordered a specific product*/
CREATE OR REPLACE FUNCTION customersFromProduct(productID integer)
RETURNS TABLE(id integer, firstname character varying, lastname character varying, quantity integer) AS
$BODY$
DECLARE
	pID ALIAS FOR $1;
BEGIN
	RETURN QUERY 	
	SELECT Customer.customerID, Customer.firstname, Customer.lastname, ProductOrderWarehouse.quantity FROM Customer, Product, ProductOrderWarehouse, CustomerOrder, Orders
	WHERE Customer.customerID = CustomerOrder.customerID
	AND Orders.orderID = CustomerOrder.orderID
	AND Product.productID = ProductOrderWarehouse.productID
	AND Orders.orderID = ProductOrderWarehouse.orderID
	AND Product.productID = pID;
END;
$BODY$
LANGUAGE 'plpgsql';

SELECT * FROM customersFromProduct(1);

/*Places an order*/
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

SELECT * FROM placeAnOrder(1, 1, 50, 'visa', 1)

/*Moves products from one warehouse to a different warehouse*/
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

SELECT * FROM moveWarehouses(5, 1, 1, 50)

/*Increases or decreases the prices of products that have sold above/below a threshold amount and returns the table of updated products*/
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
