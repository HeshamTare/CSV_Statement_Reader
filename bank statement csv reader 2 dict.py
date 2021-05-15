import csv
import datetime

def monthly_amounts(csv_file, *c_or_d):
    credit_or_debit_dictionary = {}

        
    for row in csv_file:
        date_of_transaction = datetime.datetime.strptime(row['ï»¿ Date'], '%d/%m/%Y')
        
        if row['Type'] in c_or_d: # checks if the current row is a credit
            credit = row['Debit/Credit'] # if it is it assigns the string value of the credit to this variable
            
            if date_of_transaction.year in credit_or_debit_dictionary: # checks if the year of the credit is in the dictionary
                
                if date_of_transaction.month in credit_or_debit_dictionary[date_of_transaction.year]: # checks if the month is in the dictionary under that year
                    current_amount = credit_or_debit_dictionary.get(date_of_transaction.year).get(date_of_transaction.month) #gets the current credit value for that month
                    credit_or_debit_dictionary[date_of_transaction.year][date_of_transaction.month] = current_amount + float(credit[3:]) #overwrites the value with the previous value + the credit value of the current row
                
                elif date_of_transaction.month not in credit_or_debit_dictionary[date_of_transaction.year]: #if the month is not in the year then creates the month as a key and credit as a value
                    credit_or_debit_dictionary[date_of_transaction.year][date_of_transaction.month] = float(credit[3:])
                
            elif date_of_transaction.year not in credit_or_debit_dictionary: #if year is not in dictionary this creates it, and then creates a nested dictionary containing the months for that year
                credit_or_debit_dictionary[date_of_transaction.year] = {date_of_transaction.month: float(credit[3:])}
    
    return credit_or_debit_dictionary



#opens my csv bank statement with handler 'statement'
with open('midata4286.csv',newline='') as statement:
    bank_statement = csv.DictReader(statement)
    
    x = monthly_amounts(bank_statement,'CR')#'VIS', 'DD', 'ATM', 'BP', ')))')

    print(x)

    total = 0

    c_or_d_lst = []

    for year, months in x.items():
        for mon in months.values():
            total += mon
            c_or_d_lst.append(mon)
    
    print(total)

    counter = 0
    percent_diff = 0

    for i in c_or_d_lst:
        if c_or_d_lst[counter] == i:
            continue
        else:
            percent_diff = c_or_d_lst[counter-1] / i 
        print(percent_diff)



    print(c_or_d_lst)


    # credit_dictionary = {}
    # debit_dictionary = {}


    
    # for row in bank_statement:
    #     date_of_transaction = datetime.datetime.strptime(row['ï»¿ Date'], '%d/%m/%Y')

    #     if row['Type'] == 'CR': # checks if the current row is a credit
    #         credit = row['Debit/Credit'] # if it is it assigns the string value of the credit to this variable

    #         if date_of_transaction.year in credit_dictionary: # checks if the year of the credit is in the dictionary

    #             if date_of_transaction.month in credit_dictionary[date_of_transaction.year]: # checks if the month is in the dictionary under that year
    #                current_amount = credit_dictionary.get(date_of_transaction.year).get(date_of_transaction.month) #gets the current credit value for that month
    #                credit_dictionary[date_of_transaction.year][date_of_transaction.month] = current_amount + float(credit[3:]) #overwrites the value with the previous value + the credit value of the current row
                
    #             elif date_of_transaction.month not in credit_dictionary[date_of_transaction.year]: #if the month is not in the year then creates the month as a key and credit as a value
    #                 credit_dictionary[date_of_transaction.year][date_of_transaction.month] = float(credit[3:])
        
    #         elif date_of_transaction.year not in credit_dictionary: #if year is not in dictionary this creates it, and then creates a nested dictionary containing the months for that year
    #             credit_dictionary[date_of_transaction.year] = {date_of_transaction.month: float(credit[3:])}
        

    # print(credit_dictionary)
        
    
    
   
  