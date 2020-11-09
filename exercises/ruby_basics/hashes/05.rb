# Use Hash#each to iterate over numbers and print each element's key/value pair.

numbers = {
  high:   100,
  medium: 50,
  low:    10
}

numbers.each { |key, value| puts "a #{key} number is #{value}"}

# Expected output:
# A high number is 100.
# A medium number is 50.
# A low number is 10.
