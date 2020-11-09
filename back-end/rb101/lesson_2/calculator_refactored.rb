def prompt(message)
  puts "=> #{message}"
end

def valid_number?(num_string)
  num_string.to_i != 0 || num_string.start_with?("0")
end

def operation_message(operator)
  case operator
  when "1"
    "Adding"
  when "2"
    "Subtracting"
  when "3"
    "Multiplying"
  when "4"
    "Dividing"
  end
end

prompt("Welcome to Calculator! Enter your name:")

name = ""
loop do
  name = gets.chomp
  break unless name.empty?
  prompt("Please enter a valid name:")
end

prompt("Hi, #{name}!")

loop do
  number1 = ""
  loop do
    prompt("What's the first integer?")
    number1 = gets.chomp
    break number1 = number1.to_i if valid_number?(number1)
    prompt("Not a valid number. Please, try again.")
  end

  number2 = ""
  loop do
    prompt("What's the second integer?")
    number2 = gets.chomp
    break number2 = number2.to_i if valid_number?(number2)
    prompt("Not a valid number. Please, try again.")
  end

  operator_prompt = <<-MSG
What operation would you like to perform?
   1) add
   2) subtract
   3) multiply
   4) divide
  MSG

  prompt(operator_prompt)

  operator = ""
  loop do
    operator = gets.chomp
    break if %w(1 2 3 4).include?(operator)
    prompt("Not a valid operator. Must choose: 1, 2, 3 or 4.")
  end

  prompt("#{operation_message(operator)} the two numbers...")

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

  prompt("The result is #{result}")

  prompt("Do you want to perform another calculation? (Y to calculate again")
  answer = gets.chomp
  break unless answer.downcase.start_with?("y")
end

prompt("Thank you for using calculator. Good bye!")
