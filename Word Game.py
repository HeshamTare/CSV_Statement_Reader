letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
points = [1, 3, 3, 2, 1, 4, 2, 4, 1, 8, 5, 1, 3, 4, 1, 3, 10, 1, 1, 1, 1, 4, 4, 8, 4, 10]

letter_to_points = {key:value for key, value in zip(letters, points)} #merges the two lists (letters and points) into a dictionary

letter_to_points[" "] = 0 #adds the points value for an empty space

print(letter_to_points)

#this function returns the points for a word
def score_word(word):
  point_total = 0
  
  #loops through each character and returns the points for that character from the letter_to_points dictionary
  for char in word.upper():
    point_total += letter_to_points.get(char,0)
  return point_total 

player_to_words = {"player1" : ["BLUE", "TENNIS", "EXIT"], "Player2": ["EARTH", "EYES", "MACHINE"], "Player 3": ["ERASER", "BELLY", "HUSKY"], "Player 4": ["ZAP", "COMA", "PERIOD"]}

#calculates the points of each player in the dictionary 'player_to_words' and returns a dictionary showing each player and their points. Also used to update a players points when a new word is played.
def update_point_totals(word):
  player_to_points = {}
  for player, words in player_to_words.items():
    player_points = 0
    for char in words:
      player_points += score_word(char)
    player_to_points[player] = player_points
  return player_to_points


#allows a player to play a word and will add that player and their points to the 'player_to_points' dictionary
def play_word(player, word):
  if player in player_to_words.keys():
    player_to_words[player].append(word)
  else:
    player_to_words[player] = word
  return update_point_totals(word)
  

print(play_word("hesham","HESHAM"))