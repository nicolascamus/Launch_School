# Show two different ways to put the expected "Four score and " in front of the
# following string:
famous_words = "seven years ago..."

## Solution:

"Four score and " + famous_words # non-mutating
# or
famous_words.prepend("Four score and ") # mutating
