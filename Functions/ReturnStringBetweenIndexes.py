#function to return the characters as a string between two given spaces
def substring_between_letters(word,start,end): #characters between the 'start' and 'end' characters will be returned
  start_index = 0
  end_index = 0

  for i in word: #returns the index of the 'start' character
    if i == start:
      break
    else:
      start_index += 1

  for char in word: #returns the index of the 'end' character 
        if char == end:
          break
        else:
          end_index += 1

  if start_index + 1 == end_index or start_index == end_index: #checks if the returned index's are the same or if there is only -/+ 1 differnece between the two (meaning no characters will be between the two) and returns None if true
    return None
  else: #provided there are characters between the 'start' and 'end' index's this will return the characters
    start_index += 1 #add 1 to 'start' index so as not to include it in the returned string
    if start in word and end in word[start_index:]: #checks that both 'start' and 'end' characters are in the provided 'word' else it returns the whole word
      return str(word[start_index:end_index])
    else:
      return word


print(substring_between_letters("apple", "p", "e"))
print(substring_between_letters("apple", "a", "e"))
