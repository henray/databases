CREATE TYPE payment_method as ENUM ( 'visa', 'mastercard', 'american express', 'paypal');

CREATE TABLE Customer
(
	customerID int, 
	firstName varchar(50) NOT NULL, 
	lastName varchar(50) NOT NULL, 
	email varchar(50) UNIQUE NOT NULL, 
	address varchar(100) NOT NULL,
	PRIMARY KEY (customerID)
);

CREATE TABLE Product
(
	manufacturerPrice double precision NOT NULL CHECK (manufacturerPrice > 0),
	retailPrice double precision NOT NULL CHECK (retailPrice > 0),
	cutPercentage double precision,
	CHECK (cutPercentage > 0),
	CHECK (cutPercentage < 1),
	productName varchar(50) UNIQUE NOT NULL,
	productID int,
	PRIMARY KEY (productID)
);

CREATE TABLE Orders
(
	orderID int,
	payment payment_method NOT NULL,	
	orderDate date NOT NULL,
	PRIMARY KEY (orderID)
);

CREATE TABLE Warehouse
(
	warehouseID int,
	address varchar(100) NOT NULL,
	PRIMARY KEY(warehouseID)
);

CREATE TABLE Supplier
(
	supplierName varchar(50),
	address varchar(100) NOT NULL,
	PRIMARY KEY(supplierName)
);

CREATE TABLE Shipment
(
	shipmentID int,
	shipmentDate date NOT NULL,
	PRIMARY KEY(shipmentID)
);

CREATE TABLE Team
(
	teamName varchar(50),
	accountNumber int UNIQUE NOT NULL,
	PRIMARY KEY(teamName)
);

CREATE TABLE Player
(
	playerNumber int NOT NULL CHECK (playerNumber >= 0),
	accountNumber int UNIQUE NOT NULL,
	firstName varchar(50) NOT NULL,
	lastname varchar(50) NOT NULL,
	teamName varchar(50) NOT NULL,
	PRIMARY KEY(playerNumber, teamName),
	FOREIGN KEY(teamName) REFERENCES Team(teamName)
);

CREATE TABLE TeamMerchandise
(
	productID int,
	PRIMARY KEY(productID),
	FOREIGN KEY (productID) REFERENCES Product(productID)
);

CREATE TABLE PlayerMerchandise
(
	productID int,
	PRIMARY KEY (productID),
	FOREIGN KEY (productID) REFERENCES Product(productID)
);

CREATE TABLE CustomerOrder
(
	customerID int NOT NULL,
 	orderID int,
	PRIMARY KEY(orderID),
	FOREIGN KEY(customerID) REFERENCES Customer(customerID),
	FOREIGN KEY(orderID) REFERENCES Orders(orderID)
);

CREATE TABLE ProductOrderWarehouse
(
	quantity int NOT NULL CHECK (quantity > 0),
	productID int,
	orderID int,
	warehouseID int,
	PRIMARY KEY(productID, orderID, warehouseID),
	FOREIGN KEY(productID) REFERENCES Product(productID),
	FOREIGN KEY(orderID) REFERENCES Orders(orderID),
	FOREIGN KEY(warehouseID) REFERENCES Warehouse(warehouseID)
);

CREATE TABLE ShipmentSupplier
(
	supplierName varchar(50) NOT NULL,
	shipmentID int,
	PRIMARY KEY (shipmentID),
	FOREIGN KEY (shipmentID) REFERENCES Shipment(shipmentID),
	FOREIGN KEY (supplierName) REFERENCES Supplier(supplierName)
);

CREATE TABLE ShipmentWarehouse
(
	shipmentID int,
	warehouseID int NOT NULL,
	PRIMARY KEY(shipmentID),
	FOREIGN KEY(shipmentID) REFERENCES Shipment(shipmentID),
	FOREIGN KEY(warehouseID) REFERENCES Warehouse(warehouseID)
);

CREATE TABLE ShipmentProduct
(
	quantity int NOT NULL CHECK (quantity > 0),
	shipmentID int,
	productID int,
	PRIMARY KEY (shipmentID, productID),
	FOREIGN KEY (shipmentID) REFERENCES Shipment(shipmentID),
	FOREIGN KEY (productID) REFERENCES Product(productID)
);

CREATE TABLE WarehouseProduct
(
	quantity int NOT NULL CHECK (quantity > 0),
	warehouseID int,
	productID int,
	PRIMARY KEY(warehouseID, productID),
	FOREIGN KEY (warehouseID) REFERENCES Warehouse(warehouseID),
	FOREIGN KEY (productID) REFERENCES Product(productID)
);

CREATE TABLE TeamMerchandiseTeam
(
	productID int, 
	teamName varchar(50),
	PRIMARY KEY (productID), 
	FOREIGN KEY (productID) REFERENCES TeamMerchandise(productID),
	FOREIGN KEY (teamName) REFERENCES Team(teamName)
);

CREATE TABLE PlayerMerchandisePlayer
(
	productID int, 
	playerNumber int,
	teamName varchar(50),
	PRIMARY KEY (productID),
	FOREIGN KEY (productID) REFERENCES PlayerMerchandise(productID),
	FOREIGN KEY (playerNumber, teamName) REFERENCES Player(playerNumber, teamName)
);