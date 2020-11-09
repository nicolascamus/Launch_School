def valid_number?(string)
  string.to_i.to_s == string
end

numerator =
  loop do
    puts ">> Please enter the numerator:"
    number = gets.chomp

    break number.to_i if valid_number?(number)

    puts "Invalid input. Only integers are allowed."
  end

denominator =
  loop do
    puts ">> Please enter the denominator:"
    number = gets.chomp

    next puts "Number can't be 0." if number == "0"

    break number.to_i if valid_number?(number)

    puts "Invalid input. Only integers are allowed."
  end

puts "#{numerator} / #{denominator} = #{numerator. / denominator.to_f}"
