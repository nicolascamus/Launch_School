# A notably missing method is something provided in Rails, but not in Ruby
# itself...`titleize`. This method in Ruby on Rails creates a string that has
# each word capitalized as it would be in a title. For example, the string:

words = "the flintstones rock"

# would be: words = "The Flintstones Rock"
# Write your own version of the rails `titleize` implementation.

def titleize(string)
  capitalized_words = []

  string.split.each { |word| capitalized_words << word.capitalize }

  capitalized_words.join(" ")
end

def titleize!(string)
  words = string.split

  words.each do |word|
    index = string.index(word)

    string[index] = string[index].upcase
  end

  string
end

# Non-mutating:
p titleize(words)
p words

# Mutating:
p titleize!(words)
p words
