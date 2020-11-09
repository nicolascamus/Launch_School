puts "Welcome to Calculator!"

puts "What's the first integer?"
number1 = gets.chomp.to_i

puts "What's the second integer?"
number2 = gets.chomp.to_i

puts "What operation would you like to perform? "\
     "1) add 2) subtract 3) multiply 4) divide"
operator = gets.chomp

result =
  case operator
  when "1"
    number1 + number2
  when "2"
    number1 - number2
  when "3"
    number1 * number2
  when "4"
    number1 / number2.to_f
  end

puts "The result is #{result}"
