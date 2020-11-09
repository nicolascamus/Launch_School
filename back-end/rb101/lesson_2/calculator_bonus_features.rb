require 'yaml'

def colorize(string)
  "#{OPTIONS_COLOR[0]}#{string}#{OPTIONS_COLOR[1]}"
end

def result_color(num_string)
  "\e[7m\e[1m #{num_string} \e[22m\e[27m"
end

def set_language
  available_languages = MESSAGES.keys.sort
  puts "=> Choose a language:"
  available_languages.each do |key|
    puts "   #{colorize(key)}: #{MESSAGES[key]['language']}"
  end

  language = ""
  loop do
    language = gets.chomp.downcase
    break if MESSAGES.keys.include?(language)
    puts "=> Not a valid language. Please, choose one of the following: "\
         "#{colorize(available_languages.join(', '))}."
  end

  language
end

def message(key)
  object = MESSAGES[LANGUAGE][key]
  if object.include?("%{c0}")
    format(object, c0: OPTIONS_COLOR[0], c1: OPTIONS_COLOR[1])
  else
    object
  end
end

def prompt(key, additional_string = "")
  puts "=> #{message(key)}" + additional_string
end

def valid_number?(num_string)
  chars = num_string.chars
  return false unless /\d/.match(num_string) &&
                      chars.all? { |char| char =~ /[0123456789.-]/ }
  return false unless chars.count(".") <= 1 && chars.count("-") <= 1

  chars.include?("-") ? num_string.start_with?("-") : true
end

def number_type(num_string)
  num_string.include?(".") ? num_string.to_f : num_string.to_i
end

def operation_word(operator)
  word =
    case operator
    when "1"
      "adding"
    when "2"
      "subtracting"
    when "3"
      "multiplying"
    when "4"
      "dividing"
    end

  word
end

def get_name
  name = ""
  loop do
    name = gets.chomp
    break unless name.split.empty?
    prompt("invalid_name")
  end

  name
end

def get_number(message)
  number = ""
  loop do
    prompt(message)
    number = gets.chomp
    break if valid_number?(number)
    prompt("invalid_number")
  end

  number_type(number)
end

def get_operator
  prompt("operator_prompt")
  puts message("operator_options")

  operator = ""
  loop do
    operator = gets.chomp
    break if %w(1 2 3 4).include?(operator)
    prompt("invalid_operator")
    puts message("operator_options")
  end

  operator
end

def calculate_result(number1, number2, operator)
  operation_result =
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

  operation_result
end

def zero_division?(number2, operator)
  dividing_by_zero = operator == "4" && number2 == 0
  if dividing_by_zero
    clear_screen
    prompt("zero_division")
  end

  dividing_by_zero
end

def clear_screen
  system('clear') || system('cls')
end

def display_options
  options_yes = message("options_yes")
  options_no = message("options_no")
  "\n   #{colorize(options_yes[0])}) #{options_yes[-1]}"\
  "\n   #{colorize(options_no[0])}) #{options_no[-1]}"
end

def yes_or_no?(message)
  options_yes = message("options_yes")
  options_no = message("options_no")
  options = [options_yes, options_no].flatten

  prompt(message, display_options)

  answer = ""
  loop do
    answer = gets.chomp.downcase
    break if options.include?(answer)
    prompt("invalid_answer", display_options)
  end

  options_yes.include?(answer)
end

OPTIONS_COLOR = ["\e[35m", "\e[0m"]
MESSAGES = YAML.load_file('calculator_messages.yml')

clear_screen
LANGUAGE = set_language

prompt("welcome")
name = get_name
prompt("greeting", "#{name}!")

restart_with_clear_screen = nil
loop do
  number1 = get_number("first_number")
  number2 = get_number("second_number")
  operator = get_operator
  next if zero_division?(number2, operator)

  prompt(operation_word(operator), message("the_two_numbers"))

  operation_result = calculate_result(number1, number2, operator)
  prompt("result", result_color(operation_result.to_s))
  puts

  break unless yes_or_no?("another_calculation")
  if restart_with_clear_screen.nil?
    restart_with_clear_screen = yes_or_no?("clear_screen")
    clear_screen if restart_with_clear_screen
  elsif restart_with_clear_screen
    clear_screen
  end
end

prompt("thanks")
