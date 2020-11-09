def is_odd?(integer)
  integer % 2 != 0
end

puts is_odd?(2)    # => false
puts is_odd?(5)    # => true
puts is_odd?(-17)  # => true
puts is_odd?(-8)   # => false
puts is_odd?(0)    # => false
puts is_odd?(7)    # => true

# Using remainder :
def remainder_odd?(integer)
  integer.remainder(2) != 0
end

puts "\ncomparing:"
puts remainder_odd?(2)   == is_odd?(2)
puts remainder_odd?(5)   == is_odd?(5)
puts remainder_odd?(-17) == is_odd?(-17)
puts remainder_odd?(-8)  == is_odd?(-8)
puts remainder_odd?(0)   == is_odd?(0)
puts remainder_odd?(7)   == is_odd?(7)
