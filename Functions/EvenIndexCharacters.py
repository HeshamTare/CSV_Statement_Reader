# function to return every other letter in a string


def every_other_letter(word):
    every_other_index = 0
    temp_strng = ''  # string to store every other letter

    for i in word:  # loops through each letter and checks if its index is even, if so it will be added to the 'temp_strng' variable
        if every_other_index % 2 > 0:
            every_other_index += 1
            continue
        else:
            temp_strng += i
            every_other_index += 1

    return temp_strng


print every_other_letter('Hello Hesham')
