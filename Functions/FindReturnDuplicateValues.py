# function to find and return any repeated numbers within a list


def get_repeated_number(lis):
    repeated_numbers = []  # empty list to store any numbers which are repeated
    for i in range(len(lis)):  # these nested for loops loop through each index in the list and compares it to all other indexes in the list
        for x in range(len(lis)):
            if i == x:  # if comparing to itself, ignore and continue
                continue
            elif lis[i] == lis[x]:
                if lis[i] in repeated_numbers:  # checks if the number has already been recorded as a repeating number
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
print get_repeated_number(lis_num)
