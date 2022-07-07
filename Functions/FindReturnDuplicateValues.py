def get_repeated_number(lis):
    """find and return repeated numbers within a list.
    
    Args:
        lis: the list to search for duplications.
        
    Returns:
        a new list containing only the repeated numbers.
    """
    
    # empty list to store repeated numbers.
    repeated_numbers = []  
    # loops through each index in the list and compares the value to all other indexes in the list.
    for i in range(len(lis)):  
        for x in range(len(lis)):
            # prevents comparing the same index to itself.
            if i == x:  
                continue
            elif lis[i] == lis[x]:
                # checks if the number has already been recorded as a repeating number.
                if lis[i] in repeated_numbers:  
                    continue
                else:
                    repeated_numbers.append(lis[i])
    return repeated_numbers


lis_num = [
    5,
    7,
    10,
    9,
    2,
    11,
    2,
    11,
    ]
print (get_repeated_number(lis_num))
