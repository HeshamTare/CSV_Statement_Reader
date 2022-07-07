import csv
import datetime

def monthly_amounts(csv_file, *c_or_d): #function to return a dictionary organising the total credits or debits by year and month
    
    credit_or_debit_dictionary = {} #empty dictionary to be returned by the function

    for row in csv_file: 
        date_of_transaction = datetime.datetime.strptime(row['ï»¿ Date'], '%d/%m/%Y') #converts the date of the current row into a readable Python format
        
        if row['Type'] in c_or_d: #checks if the 'type' of the transaction is in the tuple 'c_or_d' argument
            transaction_amount = row['Debit/Credit'] #if the current transaction is what we are looking for, assigns the transaction value to the local variable 'transaction_amount'

            if date_of_transaction.year in credit_or_debit_dictionary: # checks if the year of the credit is in the dictionary
                
                if date_of_transaction.month in credit_or_debit_dictionary[date_of_transaction.year]: #checks if the month is in the dictionary under that year
                    current_amount = credit_or_debit_dictionary.get(date_of_transaction.year).get(date_of_transaction.month) #gets the current value for that month
                    credit_or_debit_dictionary[date_of_transaction.year][date_of_transaction.month] = current_amount + float(transaction_amount[3:]) #updates the value with the previous value + the credit value of the current row
                
                elif date_of_transaction.month not in credit_or_debit_dictionary[date_of_transaction.year]: #if the month is not in the year then creates the month as a key with credit as the value
                    credit_or_debit_dictionary[date_of_transaction.year][date_of_transaction.month] = float(transaction_amount[3:])
                
            elif date_of_transaction.year not in credit_or_debit_dictionary: #if year is not in dictionary then adds it to the dictionary with a nested dictionary as the value to contain the years
                credit_or_debit_dictionary[date_of_transaction.year] = {date_of_transaction.month: float(transaction_amount[3:])}
    
    return credit_or_debit_dictionary



#opens my csv bank statement with handler 'statement'
with open('midata4286.csv',newline='') as statement:
    bank_statement = csv.DictReader(statement)
        
    x = monthly_amounts(bank_statement,'CR') #returns a dictionary showing the total of all credits received organised by year and month. 

    print(x)

    total = 0 #holds the total of all values in the dictionary 'x'

    c_or_d_lst = [] #list to hold the value for each month. To be used to calculate percentage difference between each month

    for year, months in x.items(): #iterates through the key,value in dictionary 'x'
        for mon in months.values(): #iterates through the values of the nested dictinary of a year
            total += mon
            c_or_d_lst.append(mon)
    
    print(total)

    counter = 0 #used to reference an index in the list 'c_or_d_lst' allowing me to compare two months
    percent_diff = 0 #used to show the percentage difference between each month

    for amount in c_or_d_lst:
        if counter == c_or_d_lst.index(amount): #checks if we are on the first iteration and if so continues to the next without doing anything
            continue
        else: #will execute provided we have two different months to compare
            percent_diff = (((amount/c_or_d_lst[counter])-1)*100) #calculates percentage difference between the current month interation and previous month
            counter += 1
        print(percent_diff)
