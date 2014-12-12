#!/scratch/insta/bin/ruby

# split the diff into + and - files (along with the respective line numbers)
# move the - and + to the end followed by original line number
# for each line in one group, take the first token (or two if the first one is
# a punctuation). Look for a line that starts with that string in the other
# group. If more than one is found, take the closest match in edit distance.

# Possible operators to look for
# - Swap
# - Replace at the same location (and types : is it arithmetic, logic or
#   otherwise)
# - Insertion/deletion of a symbol

