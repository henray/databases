CREATE TABLE CustomerProductRating
(
	customerID int,
	productID int,
	ratings XML,
	PRIMARY KEY(customerID, productID),
	FOREIGN KEY(customerID) REFERENCES Customer(customerID) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (productID) REFERENCES Product(productID) ON DELETE CASCADE ON UPDATE CASCADE
)
