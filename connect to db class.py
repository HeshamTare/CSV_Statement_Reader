import mysql.connector #imports mysql library to allow communication between Python and MySQL database
from mysql.connector import Error #imports mysql connector error list

class DBHelper: #class to connect with a MYSQL database allowing data to be returned and amended in the target database
    
    #The parameters within the __init__ dunder point to the target database to execute queries on
    def __init__(self,host_name,database_name,user_name,user_password): 
        
        self.host_name = host_name
        self.database_name = database_name
        self.user_name = user_name
        self.user_password = user_password

    #method to only accessible within the class. Establishes a connection with the target database
    def __connect__(self):
        self.connection = mysql.connector.connect(host = self.host_name, database = self.database_name, 
        user = self.user_name, password = self.user_password)

        self.cursor = self.connection.cursor() #cursor object is used to execute SQL statements within the target database

        if self.connection.is_connected: #if connection to the target database is successful, confirmation is provided
            print("connected db")
    
    def __disconnect__(self): #method to disconnect from the target database
        self.connection.close()
    
    def retrieve_data(self,SQL_query): #method to execute SQL queries to return data ONLY
        try:
            self.__connect__()
            
            self.cursor.execute(SQL_query) #executes the SQL query provided
            results = self.cursor.fetchall() #returns the data of the SQL query and stores the data in local variable 'results'
            
            #checks the length of the returned results. If multiple results are returned, the method returns this as a list,
            #else it will return the sole result as a string. This allows for ease of use in later code through dealing with a
            # string instead of a list. This is useful when searching for Keys within a table.
            if len(list(results)) > 1:
                return list(results)
            else:
                return str(results)

            self.__disconnect__

        except Error as e:
            print("Could not connect - ", e)
    
    def execute_query(self,amend_SQL_query): #method to execute SQL queries where that query amends the database
        try:
            self.__connect__()

            #the below if clause allows me to pass multiple SQL queries amending data in the database as a list, if only one
            #query is provided, only that one query will be executed in the else clause
            if isinstance(amend_SQL_query,list): 
                for i in amend_SQL_query:
                    self.cursor.execute(i, multi = True)

                print("Amend successful")                
            else:
                self.cursor.execute(amend_SQL_query)
                print("Amend successful") 

            self.connection.commit() #confirms and commits all amends to the database

            self.__disconnect__

        except Error as e:
            self.connection.rollback() #if an error was encountered in any of the SQL queries, any changes are undone 
            print(e)
        

#Instantiates 'test' as an object of the 'DBHelper' class providing a target database       
test = DBHelper('localhost', 'world', 'root', 'Password123') 


#retrieve data queries:

print(test.retrieve_data("SELECT * FROM city ORDER BY Population DESC")) #orders all cities in the world by population in descending order
print(test.retrieve_data("SELECT Name FROM city where District = 'England' order by Population DESC")) #orders all cities in England by population with the highest populated city as the first row

#query to return the capital city (from table City) of each country listed in the Country table and its population. This is then ordered by population descending.
#the two tables are joined by using the primary key 'ID' column on table City to match against the Capital column on table Country.
print(test.retrieve_data("SELECT Country.Name, City.Name, City.population from Country INNER JOIN City ON Country.Capital = City.ID ORDER BY City.Population DESC"))

#returns the top 10 most spoken languages across the world.
common_languages = test.retrieve_data("SELECT language, count(Language) FROM countrylanguage GROUP BY Language ORDER BY count(Language) DESC LIMIT 10")
print(common_languages)




#post / amend database queries:


##SQl query to insert a new row into table 'City'
test.execute_query("INSERT INTO City (Name, Countrycode, district,population) VALUES ('Tangiers','MAR', 'Tangiers',947952)")

##returns the unique City ID of Tangiers from table 'City' and stores it in the variable
TangierCityID = test.retrieve_data("SELECT ID FROM City WHERE Name = 'Tangiers' AND District = 'Tangiers'")

##SQL query to delete 'Tangiers' from the City table using the unique ID retrieved in the above query
test.execute_query("DELETE FROM City WHERE ID = {}".format(TangierCityID[2:6]))



#SQL query to create table 'Continent' which will be used to store each continent and its population
test.execute_query("CREATE TABLE IF NOT EXISTS Continent(Name Text NOT NULL, Population Double NOT NULL)") 

list_of_continents_raw = test.retrieve_data("SELECT DISTINCT Continent FROM Country") #retrieves the unique continents for each country listed in the 'Country' table
list_of_continents_cleaned = [] #to be used to store the names of each continent with non-alpha characters removed

Continent_Population = {} #dictionary to store each continent and its population, to be inserted later in table 'Continent'

#iterates through the list of continents returned and stored in variable list_of_continents_raw, and cleans the returned value by removing non-alpha characters
for continent_name in list_of_continents_raw:
    continent_name_cleaned = str(continent_name)[2:-3]
    list_of_continents_cleaned.append(continent_name_cleaned)        


#loop to calculate the total population of each continent based on the countries on that contient
for continent in list_of_continents_cleaned:
    population = test.retrieve_data("SELECT SUM(Population) FROM Country WHERE Continent = '{}'".format(str(continent)))
    int_population = ''

    #loops through each index in the variable population and removes non-numerical values. Any numerical values are then stored in the string int_population 
    for i in population:
        if i.isdigit() is True:
            int_population += i

    Continent_Population[continent] = int_population #adds the current name of the current continent and its population (cleaned) to a dictionary

print(Continent_Population)

#loop to add each continent and its population to the table Continent in the 'world' database
for key,value in Continent_Population.items():
    test.execute_query("INSERT INTO Continent (Name, Population) VALUES ('{continent_name}', '{continent_population}')".format
    (continent_name=key, continent_population=value))

