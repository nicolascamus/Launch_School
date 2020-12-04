# Create a hash that expresses the frequency with which each letter occurs in
# this string:

statement = "The Flintstones Rock"

frequency = Hash.new(0)

statement.split.join.chars.each { |letter| frequency[letter] += 1 }
