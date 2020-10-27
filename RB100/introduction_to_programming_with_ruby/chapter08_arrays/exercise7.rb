arr = %w[a b c d e f g]

arr.each_with_index { |item, index| puts "arr[#{index}]:  \"#{item}\"" }
