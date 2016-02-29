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

CREATE TABLE Player
(
	playerNumber int NOT NULL CHECK (playerNumber >= 0),
	accountNumber int UNIQUE NOT NULL,
	firstName varchar(50) NOT NULL,
	lastname varchar(50) NOT NULL,
	teamName varchar(50) NOT NULL,
	PRIMARY KEY(playerNumber, teamName),
	FOREIGN KEY(teamName) REFERENCES Team(teamName) ON DELETE CASCADE ON UPDATE CASCADE
);