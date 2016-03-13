import random
def generatexml(rating, custID, prodID):
	desctext = ""
	stringbuilder = ""
	if rating == 1:
		desctext = "THIS PRODUCT SUCKS"
	elif rating == 2:
		desctext = "THIS PRODUCT ALMOST SUCKS"
	elif rating == 3:
		desctext = "THIS PRODUCT IS OKAY"
	elif rating == 4:
		desctext = "THIS PRODUCT IS GOOD"
	elif rating == 5:
		desctext = "THIS PRODUCT IS GREAT"
	stringbuilder += "INSERT INTO CustomerProductRating VALUES(" + str(custID) + ", " + str(prodID) + ", "
	stringbuilder += "'<rate customerID=\"" + str(custID) + "\" productID=\"" + str(prodID) + "\">"
	stringbuilder += "<star>" + str(rating) + "</star>"
	stringbuilder += "<description>" + desctext + "</description>"
	stringbuilder += "</rate>');\n"
	return stringbuilder

customers = list(range(100))*4
random.shuffle(customers)

products = list(range(1, 51))*8
random.shuffle(products)

dups = dict()
with open("ratinginserts.sql", 'w') as f:
	for i in range(len(customers)):
		if customers[i] in dups and products[i] in dups[customers[i]]:
			continue
		if customers[i] not in dups:
			dups[customers[i]] = list()
			dups[customers[i]].append(products[i])
		dups[customers[i]].append(products[i])
		rating = random.randint(1,5)
		f.write(generatexml(rating, customers[i], products[i]))