import mysql.connector  
from mysql.connector import Error  


class DBHelper:  
    """initiates and closes a connection with a MYSQL database allowing data to be returned and amended in the target database.
    """
    
    def __init__(
        self,
        host_name,
        database_name,
        user_name,
        user_password,
        ):

        self.host_name = host_name
        self.database_name = database_name
        self.user_name = user_name
        self.user_password = user_password

    def __connect__(self):
        """establishes a connection with the database
        """
        self.connection = mysql.connector.connect(host=self.host_name,
                database=self.database_name, user=self.user_name,
                password=self.user_password)

        # cursor object is used to execute SQL statements within the target database
        self.cursor = self.connection.cursor()  

        # confirms connection has been successful
        if self.connection.is_connected:  
            print 'connected db'

    def __disconnect__(self):  
        """disconnect from the target database
        """
        self.connection.close()

    def retrieve_data(self, SQL_query):  # method to execute SQL queries to return data ONLY
        """allows execution of SQL queries to return data only.
        
        Args:
            SQL_query: the query in SQL syntax to be executed in the target database.
        
        Returns:
            the data selected by the SQL_query
            
        Raises:
            the error code for the connection failure.
        """
        
        try:
            self.__connect__()

            self.cursor.execute(SQL_query)  
            # returns the data of the SQL query and stores the data in local variable 'results'
            results = self.cursor.fetchall()  

            # checks the length of the returned results. If multiple results are returned, the method returns this as a list,
            # else it will return the sole result as a string. This allows for ease of use in later code through dealing with a
            # string instead of a list. This is useful when searching for Keys within a table.

            if len(list(results)) > 1:
                return list(results)
            else:
                return str(results)

            self.__disconnect__
        except Error, e:

            print ('Could not connect - ', e)

    def execute_query(self, amend_SQL_query):  
        """execute SQL queries where that query amends the database.
        
        Args:
            amend_SQL_query: the query in SQL syntax to executed on the target database.
        
        Return:
            the amended data by the amend_SQL_query
        
        Raises:
            the error code for the connection failure and undoes any amendments to the target database.
        """
        
        try:
            self.__connect__()

            # allows multiple SQL queries to be passed in a list, and executed sequentially on the target database
            if isinstance(amend_SQL_query, list):
                for i in amend_SQL_query:
                    self.cursor.execute(i, multi=True)

                print 'Amend successful'
            else:
                self.cursor.execute(amend_SQL_query)
                print 'Amend successful'
                
            # confirms and commits all amends to the database
            self.connection.commit()  

            self.__disconnect__
        except Error, e:
            
            # if an error was encountered in any of the SQL queries, any changes are undone
            self.connection.rollback()  
            print e


test = DBHelper('localhost', 'world', 'root', 'Password123')

# orders all cities in the world by population in descending order
print test.retrieve_data('SELECT * FROM city ORDER BY Population DESC')  

# orders all cities in England by population with the highest populated city as the first row
print test.retrieve_data("SELECT Name FROM city where District = 'England' order by Population DESC"
                         )  

# returns the capital city (from table City) of each country listed in the Country table and its population. Then ordered by population descending.
# the two tables are joined by using the primary key 'ID' column on table City to match against the Capital column on table Country.
print test.retrieve_data('SELECT Country.Name, City.Name, City.population from Country INNER JOIN City ON Country.Capital = City.ID ORDER BY City.Population DESC'
                         )

# returns the top 10 most spoken languages across the world.
common_languages = \
    test.retrieve_data('SELECT language, count(Language) FROM countrylanguage GROUP BY Language ORDER BY count(Language) DESC LIMIT 10'
                       )
print common_languages

# insert a new row into table 'City'
test.execute_query("INSERT INTO City (Name, Countrycode, district,population) VALUES ('Tangiers','MAR', 'Tangiers',947952)"
                   )
# returns the unique City ID of Tangiers from table 'City' 
TangierCityID = \
    test.retrieve_data("SELECT ID FROM City WHERE Name = 'Tangiers' AND District = 'Tangiers'"
                       )

# delete 'Tangiers' from the City table using the previously retrieved unique ID
test.execute_query('DELETE FROM City WHERE ID = {}'.format(TangierCityID[2:6]))

# creates table 'Continent' which will be used to store each continent and its population
test.execute_query('CREATE TABLE IF NOT EXISTS Continent(Name Text NOT NULL, Population Double NOT NULL)'
                   )

# retrieves the unique continents for each country listed in the 'Country' table
list_of_continents_raw = \
    test.retrieve_data('SELECT DISTINCT Continent FROM Country')  
# to be used to store the names of each continent with non-alpha characters removed
list_of_continents_cleaned = []  

# stores each continent and its population, to be inserted later in table 'Continent'
Continent_Population = {}  

# iterates through the list of continents returned and stored in variable list_of_continents_raw, and cleans the returned value by removing non-alpha characters
for continent_name in list_of_continents_raw:
    continent_name_cleaned = str(continent_name)[2:-3]
    list_of_continents_cleaned.append(continent_name_cleaned)

# calculates the total population of each continent based on the countries on that contient
for continent in list_of_continents_cleaned:
    population = \
        test.retrieve_data("SELECT SUM(Population) FROM Country WHERE Continent = '{}'".format(str(continent)))
    int_population = ''

    # removes non-numerical values from the population. 
    for i in population:
        if i.isdigit() is True:
            int_population += i

    # adds the current name of the current continent and its population (cleaned) to a dictionary
    Continent_Population[continent] = int_population  

print Continent_Population

# adds each continent and its population to the table Continent in the 'world' database
for (key, value) in Continent_Population.items():
    test.execute_query("INSERT INTO Continent (Name, Population) VALUES ('{continent_name}', '{continent_population}')".format(continent_name=key,
                       continent_population=value))
