def valid_number?(number_string)
  number_string.to_i.to_s == number_string && number_string.to_i != 0
end

def request_integer(word = "a")
  loop do
    puts ">> Please enter #{word} positive or negative integer:"
    input = gets.chomp
    break input.to_i if valid_number?(input)
    puts ">> Invalid input. Only non-zero integers are allowed."
  end
end

number1 = nil
number2 = nil

loop do
  number1 = request_integer("the first")
  number2= request_integer("the second")
  break if number1 < 0 != number2 < 0
  puts ">> Sorry. One integer must be positive, one must be negative."
  puts ">> Please start over.\n\n"
end

result = number1 + number2

puts "#{number1} + #{number2} = #{result}"
