class Student: 
  def __init__(self,name,year):
    self.name = name
    self.year = year
    self.grades = []
  
  def add_grade(self, grade): #function to append a students grades to their grades list and check if it is a passing grade
    if type(grade) == Grade:
      self.grades.append(grade.score)
      Grade.is_passing(grade)
  
  def get_average(self): #returns a students average grade
    temp_score = 0
    counter = 0
    for i in self.grades:
      temp_score += i
      counter += 1
    average = temp_score / counter
    return average     

roger = Student('Roger van der Weyden', 10)
sandro = Student('Sandro Botticelli', 12)
pieter = Student('Pieter Bruegel the Elder', 8)

class Grade: #Class to govern grades
  minimum_passing = 65 #the minimum score required to pass
  
  def __init__(self,score):
    self.score = score
          
  def is_passing(self): #checks if the students entered grade is a passing grade
    if self.score == self.minimum_passing or self.score > self.minimum_passing:
      return print(self.score, 'is a passing score.')
    else:
      return print(self.score, 'is not a passing score')


pieter.add_grade(Grade(65))
pieter.add_grade(Grade(100))

print(pieter.get_average())

