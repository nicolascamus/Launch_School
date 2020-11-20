require 'yaml'

OPTIONS_COLOR = ["\e[35m", "\e[0m"]
MESSAGES = YAML.load_file('mortgage_calculator_messages.yml')

def colorize(string)
  "#{OPTIONS_COLOR[0]}#{string}#{OPTIONS_COLOR[1]}"
end

def get_language
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

def result_color(num_string, justification_amount = 0)
  "\e[7m\e[1m #{num_string} \e[22m\e[27m".rjust(justification_amount)
end

def message(key)
  object = MESSAGES[LANGUAGE][key]
  if object.include?("%{c0}")
    format(object, c0: OPTIONS_COLOR[0], c1: OPTIONS_COLOR[1])
  elsif object.include?("%{b0}")
    format(object, b0: "\e[1m", b1: "\e[22m")
  elsif object.include?("%{i0}")
    format(object, i0: "\e[3m", i1: "\e[23m")
  else
    object
  end
end

def prompt(key, additional_string = "")
  puts "=> #{message(key)}" + additional_string
end

def valid_number?(num_string)
  chars = num_string.chars

  /\d/.match(num_string) &&
    chars.all? { |char| char =~ /[0123456789.]/ } &&
    chars.count(".") <= 1
end

def get_number(message)
  number = ""
  loop do
    prompt(message)
    number = gets.chomp
    if number == '0'
      next prompt("only_positive_numbers") unless message == 'interest_rate'
    end
    break if valid_number?(number)
    if message == 'interest_rate'
      prompt("invalid_input")
    else
      prompt("only_positive_numbers")
    end
  end

  number.to_r
end

def get_loan_duration(message)
  loan_duration = ""

  loop do
    loan_duration = get_number(message)
    break if (loan_duration.to_f * 12) % 1 == 0
    prompt("invalid_loan_duration")
  end

  loan_duration
end

def clear_screen
  system('clear') || system('cls')
end

def calculate_results(loan_amount, years, interest_rate)
  months = years * 12
  monthly_interest_rate = interest_rate / 100 / 12
  monthly_payment = calculate_monthly_payment(loan_amount, months,
                                              monthly_interest_rate)
  payments_total = monthly_payment * months
  interest_total = payments_total - loan_amount

  results = [monthly_payment, payments_total, interest_total]

  results.map { |item| item.round(2).to_f }
end

def calculate_monthly_payment(loan_amount, months, monthly_interest_rate)
  if monthly_interest_rate == 0
    loan_amount / months
  else
    loan_amount * (monthly_interest_rate / (1 -
      (1 + monthly_interest_rate)**-months))
  end
end

def display_results(results_array)
  results = results_array.map do |number|
    "$#{separate_thousands(number)}"
  end
  messages = [
    message("monthly_payment"),
    message("payments_total"),
    message("interest_total")
  ]

  messages.each.with_index do |message, index|
    puts "=> " + message.ljust(justification_amount(messages)) +
         (result_color(results[index].rjust(justification_amount(results))))
  end
end

def justification_amount(array_of_strings)
  (array_of_strings.map(&:length).sort)[-1]
end

def separate_thousands(number)
  number_characters = number.to_s.chars
  number_with_separators = []
  increase_count = false

  count = 1
  number_characters.reverse.each do |character|
    if count % 3 == 0
      number_with_separators.append(character, ",")
    else
      number_with_separators << character
    end

    count += 1 if increase_count
    increase_count = true if character == '.'
  end

  compose_number(number_with_separators)
end

def compose_number(number_array)
  number_array.pop if number_array[-1] == ","

  correct_punctuation(number_array.reverse.join)
end

def correct_punctuation(num_string)
  LANGUAGE == 'es' ? num_string.tr(',.', '.,') : num_string
end

def display_options
  answers = ""

  OPTIONS.each_value do |options|
    answers << "\n   #{colorize(options[0])}) #{options[-1]}"
  end

  answers
end

def yes_or_no?(message)
  options = [OPTIONS[:yes], OPTIONS[:no]].flatten
  prompt(message, display_options)

  answer = ""
  loop do
    answer = gets.chomp.downcase
    break if options.include?(answer)
    prompt("invalid_answer", display_options)
  end

  OPTIONS[:yes].include?(answer)
end

clear_screen
LANGUAGE = get_language
OPTIONS = { yes: message("options_yes"), no: message("options_no") }

prompt("welcome", "\n ")

restart_with_clear_screen = nil
loop do
  loan_amount = get_number("loan_amount")
  years = get_loan_duration("loan_duration")
  interest_rate = get_number("interest_rate")

  display_results(calculate_results(loan_amount, years, interest_rate))
  puts

  break unless yes_or_no?("another_calculation")
  if restart_with_clear_screen.nil?
    restart_with_clear_screen = yes_or_no?("clear_screen")
    clear_screen if restart_with_clear_screen
  elsif restart_with_clear_screen
    clear_screen
  end
end

prompt("thanks", "\n ")
