from functools import reduce
from math import sqrt

#define input variable
x = input_list_length

#define function to determine factors
def factors(x):
    step = 2 if x%2 else 1
    return set(reduce(list.__add__,
    ([i, x//i] for i in range(1, int(sqrt(x))+1, step) if x % i == 0)))

#call function
factors_of_list_leng = factors(x)

#cull repeat data
factors_culled = set(factors_of_list_leng)

#sort from greatest to least factor - this means resolution defaults to lowest and can be increased. this makes it easier for the user to open the application, determine params, and only get a high-quality result when ready.
factors_list = list(factors_culled)
factors_sorted = sorted(factors_list, reverse=True)

#output
out = factors_sorted

print(out)