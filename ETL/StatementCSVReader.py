import csv
import datetime


def monthly_amounts(csv_file, *c_or_d):  
    """organises the total credits or debits by year and month.
    
    Args:
        csv_file: CSV file containing data
        *c_or_d: the target column in the csv_file
    
    Returns:
        a dictionary containing all of the credits or debits by year:month
    """
    
    credit_or_debit_dictionary = {} 

    for row in csv_file:
        # converts the date of the current row into a readable Python format
        date_of_transaction = \
            datetime.datetime.strptime(row['\xc3\xaf\xc2\xbb\xc2\xbf Date'
                ], '%d/%m/%Y')  

        # checks if the 'type' of the transaction is in the tuple 'c_or_d' argument
        if row['Type'] in c_or_d:  
            transaction_amount = row['Debit/Credit']

            # checks if the year of the credit is in the dictionary
            if date_of_transaction.year in credit_or_debit_dictionary:  
                
                # checks if the month is in the dictionary under that year
                if date_of_transaction.month \
                    in credit_or_debit_dictionary[date_of_transaction.year]:  
                    # retrieves the current value for that month
                    current_amount = \
                        credit_or_debit_dictionary.get(date_of_transaction.year).get(date_of_transaction.month)  
                    # updates the value with the previous value + the credit value of the current row
                    credit_or_debit_dictionary[date_of_transaction.year][date_of_transaction.month] = \
                        current_amount + float(transaction_amount[3:])  
                
                # if the month is not in the year then creates the month as a key with credit as the value
                elif date_of_transaction.month \
                    not in credit_or_debit_dictionary[date_of_transaction.year]:
                    credit_or_debit_dictionary[date_of_transaction.year][date_of_transaction.month] = \
                        float(transaction_amount[3:])
                    
            # if year is not in dictionary then adds it to the dictionary with a nested dictionary as the value to contain the years
            elif date_of_transaction.year \
                not in credit_or_debit_dictionary:                                                                   
                credit_or_debit_dictionary[date_of_transaction.year] = \
                    {date_of_transaction.month: float(transaction_amount[3:])}

    return credit_or_debit_dictionary

with open('midata4286.csv', newline='') as statement:
    bank_statement = csv.DictReader(statement)
    
    # returns a dictionary showing the total of all credits received organised by year and month.
    x = monthly_amounts(bank_statement, 'CR')  

    print x
    
    # holds the total of all values in the dictionary 'x'
    total = 0  
    
    # list to hold the value for each month. To be used to calculate percentage difference between each month
    c_or_d_lst = []  
    
    #updates the value of each month
    for (year, months) in x.items(): 
        for mon in months.values():  
            total += mon
            c_or_d_lst.append(mon)

    print total
    
    # references an index in the list 'c_or_d_lst' allowing two months to be compared
    counter = 0  
    # shows the percentage difference between each month
    percent_diff = 0  

    for amount in c_or_d_lst:
        if counter == c_or_d_lst.index(amount):  
            continue
        else:
            # calculates percentage difference between the current month interation and previous month
            percent_diff = (amount / c_or_d_lst[counter] - 1) * 100  
            counter += 1
        print percent_diff
