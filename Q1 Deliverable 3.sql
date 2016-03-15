/*1. This query retrieves the relevant customers and products information as well as the rating (star, description) 
of the customer for each product that he or she has rated 3 stars or above*/
SELECT Cpr.customerID, Cus.firstName, Cus.lastName, Cpr.productID, 
(xpath('//rate/star/text()', ratings))[1]::text::int AS Star,
(xpath('//rate/description/text()', ratings))[1]::text AS Description
FROM CustomerProductRating Cpr
INNER JOIN Customer Cus
ON Cpr.customerID = Cus.customerID
WHERE (xpath('//rate[star>=3]', ratings))[1]::text != ''
ORDER BY customerid, star;


/*2. select all customer that have rated products with IDs between
30 and 40 as well as their ratings and descriptions */
SELECT customerID, productID, (xpath('//rate/star/text()', ratings))[1]::text::int AS Star,
(xpath('//rate/description/text()', ratings))[1]::text AS Description
FROM customerProductRating
WHERE (xpath('/rate[@productID >= 30 and @productID <= 40]', ratings))[1]::text != ''
ORDER BY customerId, star;

