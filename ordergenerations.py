import random
with open('orders.sql', 'w') as f:
	for i in range(0, 500):
		orderstring = ""
		orderstring += 'select * from placeAnOrder('
		custID = random.randint(0,99)
		qty = random.randint(1,50)
		payment = random.randint(0,2)
		paymenttype = ""
		if payment == 0:
			paymenttype = '\'visa\''
		elif payment == 1:
			paymenttype = '\'mastercard\''
		else:
			paymenttype = '\'american express\''
		prodID = random.randint(1, 1397)
		wid = random.randint(1,5)
		orderstring += str(custID) + ', ' + str(prodID) + ', ' + str(qty) + ', ' + paymenttype + ', ' + str(wid) + ');\n'
		f.write(orderstring)