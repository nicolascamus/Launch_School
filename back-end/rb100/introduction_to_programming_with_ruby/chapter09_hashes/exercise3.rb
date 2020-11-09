hsh = {a: 1, b: 2, c: 3}

puts "keys:"
hsh.each { |key, _value| p key }

puts "\nvalues:"
hsh.each { |_key, value| p value }

puts "\nkey-value pairs:"
hsh.each { |key, value| puts ":#{key} => #{value}" }
