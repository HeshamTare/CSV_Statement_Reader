def substring_between_letters(word, start, end):  # characters between the 'start' and 'end' characters will be returned
    """return the characters as a string between two given characters.
    
    Args:
        word: the word to be broken down between the 'start' and 'end' characters.
        start: the character to start breaking down the word from.
        end: the character to stop at.
    
    Returns:
        the characters between the specified 'start' and 'end' characters of the entered 'word'
    """
    
    start_index = 0
    end_index = 0
    
    # finds the index of the 'start' character
    for i in word:  
        if i == start:
            break
        else:
            start_index += 1
    
    # finds the index of the 'end' character
    for char in word:  
        if char == end:
            break
        else:
            end_index += 1

    # ensures characters exist between the specified 'start' and 'end'        
    if start_index + 1 == end_index or start_index == end_index:  
        return None
    else:
        
        # add 1 to 'start' index to prevent it being in the returned string
        start_index += 1  
        # ensures the specified 'start' and 'end' characters are in the provided 'word' else the whole word is returned
        if start in word and end in word[start_index:]:  
            return str(word[start_index:end_index])
        else:
            return word


print (substring_between_letters('apple', 'p', 'e'))
print (substring_between_letters('apple', 'a', 'e'))
