def every_other_letter(word):
    """Removes every other letter in a string.
    
    Args:
        word: the string from which every other letter will be removed.
        
    Returns:
        the remaining letters in the string.
    """
    every_other_index = 0
    # string to store every other letter
    temp_strng = ''  
    
    # loops through each letter and checks if its index is even, if so it will be added to the 'temp_strng' variable
    for i in word:  
        if every_other_index % 2 > 0:
            every_other_index += 1
            continue
        else:
            temp_strng += i
            every_other_index += 1

    return temp_strng


print every_other_letter('Hello Hesham')
