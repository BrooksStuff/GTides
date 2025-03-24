#percent reduction calculator#

#define variables
part = int(subsampling_factor)
whole = int(list_length)

#calculate percentage
percent = (100 * (part / whole))

#print result
out_pct = (str(percent) + '%')
#print(str(out_pct) + '%')

out_float = percent
print(out_float)