require 'yaml'

CONFIG = YAML.load_file('config_rps_bonus_features.yml')

RESET_COLOR = "\e[0m"
OPTIONS_COLOR = ["\e[35m", RESET_COLOR]
WIN_COLOR = ["\e[32m", RESET_COLOR]
DEFEAT_COLOR = ["\e[31m", RESET_COLOR]
TIE_COLOR = ["\e[33m", RESET_COLOR]
GAME_NAME_COLOR = ["\e[3m\e[1m", "\e[22m\e[23m"]

PROMPT = "=> "
SCORE_ANIMATION_CHARS = { main: %w[\\ | / –], out: %w[· •] }

POINTS_PER_ROUND_WON = 1
WINNING_SCORE = 5
SCORES = { user: 0, computer: 0 }

STRING_FORMAT = {
  o0: OPTIONS_COLOR[0],
  o1: OPTIONS_COLOR[1],
  w0: WIN_COLOR[0],
  w1: WIN_COLOR[1],
  d0: DEFEAT_COLOR[0],
  d1: DEFEAT_COLOR[1],
  t0: TIE_COLOR[0],
  t1: TIE_COLOR[1],
  gn0: GAME_NAME_COLOR[0],
  gn1: GAME_NAME_COLOR[1],
  winning_score: WINNING_SCORE,
  points_prw: POINTS_PER_ROUND_WON,
  plural_pprw: POINTS_PER_ROUND_WON.abs == 1 ? "" : "s",
  plural_ws: WINNING_SCORE.abs == 1 ? "" : "s"
}

def colorize_option(string)
  "#{OPTIONS_COLOR[0]}#{string}#{OPTIONS_COLOR[1]}"
end

def bold(string)
  "\e[1m" + string + "\e[22m"
end

def get_language
  languages = CONFIG.keys.sort
  comma = "\e[0m, #{OPTIONS_COLOR[0]}"

  puts "=> Choose a language:" + available_languages

  language = ""
  loop do
    language = gets.chomp.downcase
    break if languages.include?(language)
    puts "=> Not a valid language. Please, choose one of the following: "\
         "#{colorize_option(languages.join(comma))}."
  end

  clear_screen
  language
end

def available_languages
  languages = CONFIG.keys.sort

  language_list = ""
  languages.each do |abbreviation|
    option = "#{colorize_option(abbreviation)}) "\
             "#{CONFIG[abbreviation]['language']}"

    language_list << align_to_prompt(option, trailing_newline: false)
  end

  language_list
end

def clear_screen
  system('clear') || system('cls')
end

def message(key)
  string = CONFIG[LANGUAGE]['messages'][key]

  string.include?("%{") ? format(string, STRING_FORMAT) : string
end

def prompt(key, additional_string = "", return_string: false)
  string = PROMPT + message(key) + additional_string

  return_string ? string : (puts string)
end

def align_to_prompt(string, trailing_newline: true, indentation_reducion: 0)
  spaces = " " * (PROMPT.length - indentation_reducion)
  new_string = "\n" + spaces + string

  trailing_newline ? new_string + "\n " : new_string
end

def get_name
  prompt('enter_name')

  name = ""
  loop do
    name = gets.chomp.split.join(" ")
    break if name.length.between?(2, 20)
    prompt("invalid_name")
  end

  name
end

def yes_or_no?(message, content_to_keep: nil, show_score: false)
  options = [VALID_ANSWERS[:yes], VALID_ANSWERS[:no]].flatten
  updated_screen_content = format_new_screen(content_to_keep, message)
  animation_parts = [updated_screen_content, message("invalid_answer"),
                     ANSWER_LIST]

  prompt(message, ANSWER_LIST)

  answer = ""
  loop do
    answer = gets.chomp.downcase
    break if options.include?(answer)
    animate_middle_string(animation_parts, show_score: show_score,
                                           skip_versus: true)
  end

  VALID_ANSWERS[:yes].include?(answer)
end

def valid_answers_list
  answers = ""

  VALID_ANSWERS.each_value do |options|
    answers << align_to_prompt("#{colorize_option(options[0])}) #{options[-1]}",
                               trailing_newline: false)
  end

  RESET_COLOR + answers
end

def format_new_screen(content_to_keep, message)
  new_prompt = prompt(message, return_string: true) + " "

  content_to_keep.nil? ? new_prompt : content_to_keep + "\n" + new_prompt
end

def animate_middle_string(array_of_strings, character_time: 0.021,
                          skip_versus: false, show_score: true)
  first_static_string = array_of_strings[0]
  string_to_animate = array_of_strings[1]
  second_static_string = array_of_strings[2]

  unless skip_versus
    display_versus_animation(first_static_string, second_static_string)
  end

  display_string_animation(first_static_string, string_to_animate,
                           second_static_string, character_time, show_score)
end

def display_versus_animation(user_choice, computer_choice)
  versus_time = 0.33
  character_time = 0.03
  animation_chars = %w[O o • · -]

  display_score
  puts user_choice + bold("VS") + computer_choice
  sleep(versus_time)

  animation_chars.each do |char|
    display_score
    puts user_choice + bold(char) + computer_choice
    sleep(character_time)
  end
end

def display_string_animation(first_static_string, string_to_animate,
                             second_static_string, character_time, show_score)
  skip_sleep = false
  animated_string = ""

  string_to_animate.each_char do |char|
    skip_sleep = skip_sleep?(skip_sleep, char, animated_string)

    show_score ? display_score : clear_screen

    animated_string << char
    puts first_static_string + animated_string + second_static_string

    sleep(character_time) unless skip_sleep
  end
end

def skip_sleep?(acual_state, character, animated_string)
  previous_character = animated_string[-1]

  acual_state ? previous_character != "m" : character == "\e"
end

def display_score(phrase = false)
  user_score = SCORES[:user].to_s
  computer_score = SCORES[:computer].to_s

  clear_screen
  puts score_table(user_score, computer_score)
  puts phrase if phrase
end

def score_table(user_score, computer_score)
  SCORE_TABLE_HEADER + table_row(user_score, computer_score) + "\n "
end

def table_row(first_item, second_item)
  "\n" + table_contents(first_item, second_item) + "\n" +
    table_horizontal_border
end

def table_contents(first_item, second_item)
  first_item_centered = first_item.center(cell_length(PLAYER_NAME))
  second_item_centered = second_item.center(cell_length(COMPUTER))

  "| " + first_item_centered + " | " + second_item_centered + " |"
end

def cell_length(name)
  column = [name, WINNING_SCORE.to_s]
  column.map(&:length).max
end

def table_horizontal_border
  first_length = cell_length(PLAYER_NAME)
  second_length = cell_length(COMPUTER)

  "+--" + table_line(first_length) + "--" + table_line(second_length)
end

def table_line(length)
  ("-" * length) + "+"
end

def set_computer_move
  RULES.keys.sample
end

def get_user_move(previous_result_message)
  invalid_choice_alert = format_new_screen(previous_result_message,
                                           'invalid_choice')
  animation_parts = [invalid_choice_alert, message('try_again'), MOVE_LIST]

  prompt('select_move', MOVE_LIST)

  choice = ""
  loop do
    choice = gets.chomp.downcase
    break if VALID_MOVE_CHOICES.include?(choice)
    animate_middle_string(animation_parts, skip_versus: true)
  end

  chosen_move(choice)
end

def available_moves_list
  moves = RULES.keys
  alignment_compensation = indentation_reducion_amount

  options = ""
  moves.each do |move|
    input_options = RULES[move]['options']
    abbreviation = input_options[-1]
    move_name = input_options[0]

    options << align_to_prompt(format_abbreviation(abbreviation) + move_name,
                               trailing_newline: false,
                               indentation_reducion: alignment_compensation)
  end

  options
end

def indentation_reducion_amount
  first_abbreviation_length = MOVE_ABBREVIATIONS[0].length
  max_abbreviation_lenght = MOVE_ABBREVIATIONS.map(&:length).max

  if first_abbreviation_length < max_abbreviation_lenght
    amount = max_abbreviation_lenght - first_abbreviation_length

    amount >= PROMPT.length ? PROMPT.length - 1 : amount
  else
    0
  end
end

def format_abbreviation(abbreviation)
  max_abbreviation_lenght = MOVE_ABBREVIATIONS.map(&:length).max
  amount = max_abbreviation_lenght - abbreviation.length
  spaces = " " * amount
  ending_chars = ") "

  spaces + colorize_option(abbreviation) + ending_chars
end

def chosen_move(choice)
  moves = RULES.keys

  moves.each do |move|
    return move if RULES[move]['options'].include?(choice)
  end
end

def set_winner(user_choice, computer_choice)
  if first_player_wins?(user_choice, computer_choice)
    "user"
  elsif computer_choice == user_choice
    "tie"
  else
    "computer"
  end
end

def first_player_wins?(first_player_choice, second_player_choice)
  RULES[first_player_choice]['beats'].keys.include?(second_player_choice)
end

def result_phrase_parts(user_choice, computer_choice, winner)
  user_move = PROMPT + RULES[user_choice]['options'][0].capitalize + " "
  computer_move = " " + RULES[computer_choice]['options'][0]
  linking_string = set_linking_string(user_choice, computer_choice, winner)

  [user_move, linking_string, computer_move]
end

def set_linking_string(user_choice, computer_choice, winner)
  case winner
  when 'user'
    RULES[user_choice]['beats'][computer_choice]
  when 'computer'
    RULES[user_choice]['loses_to'][computer_choice]
  else
    "~◊~"
  end
end

def compose_phrase(array_of_strings, winner)
  phrase = array_of_strings.join
  round_winner_mesagge = align_to_prompt(partial_result_message(winner))

  match_ended =
    if winner == 'tie'
      false
    else
      SCORES[winner.to_sym] + POINTS_PER_ROUND_WON >= WINNING_SCORE
    end

  match_ended ? phrase + "\n " : phrase + round_winner_mesagge
end

def partial_result_message(winner)
  case winner
  when 'user'     then message('won_round')
  when 'computer' then message('lost_round')
  else                 message('tie')
  end
end

def update_score(winner)
  SCORES[winner.to_sym] += POINTS_PER_ROUND_WON unless winner == "tie"
end

def reset_score
  SCORES[:user] = 0
  SCORES[:computer] = 0
end

def score_update_animation(winner, phrase = "")
  repeat = 1
  sleep_duration = 0.045

  case winner
  when 'user'
    animate_user_score(repeat, sleep_duration, phrase)
  when 'computer'
    animate_computer_score(repeat, sleep_duration, phrase)
  when 'reset'
    animate_score_reset(2, sleep_duration)
  end
end

def animate_user_score(repeat, sleep_duration, phrase)
  static_score = SCORES[:computer].to_s

  repeat.times do
    SCORE_ANIMATION_CHARS[:main].each do |char|
      refresh_screen_content(score_table(char, static_score),
                             sleep_duration, phrase)
    end
  end

  SCORE_ANIMATION_CHARS[:out].each do |char|
    refresh_screen_content(score_table(char, static_score),
                           sleep_duration / 1.5, phrase)
  end
end

def animate_computer_score(repeat, sleep_duration, phrase)
  static_score = SCORES[:user].to_s

  repeat.times do
    SCORE_ANIMATION_CHARS[:main].each do |char|
      refresh_screen_content(score_table(static_score, char), sleep_duration,
                             phrase)
    end
  end

  SCORE_ANIMATION_CHARS[:out].each do |char|
    refresh_screen_content(score_table(static_score, char),
                           sleep_duration / 1.5, phrase)
  end
end

def animate_score_reset(repeat, sleep_duration)
  repeat.times do
    SCORE_ANIMATION_CHARS[:main].each do |char|
      refresh_screen_content(score_table(char, char), sleep_duration)
    end
  end

  SCORE_ANIMATION_CHARS[:out].each do |char|
    refresh_screen_content(score_table(char, char), sleep_duration / 1.5)
  end
end

def refresh_screen_content(string, sleep_duration, phrase = false)
  clear_screen
  puts string
  puts phrase if phrase
  sleep(sleep_duration)
end

def match_winner(return_message_key: false)
  key_modifier = return_message_key ? "_wins" : ""

  SCORES.each do |player, score|
    return "#{player}#{key_modifier}" if score == WINNING_SCORE
  end

  "nobody yet"
end

def display_content(string)
  match_winner == "nobody yet" ? clear_screen : display_score
  puts string
end

def display_rules
  loop do
    clear_screen
    puts message('rules') + "\n "
    prompt('press_enter')
    break if gets == "\n"
  end
end

def display_result_of_round(result_phrase_array, winner)
  character_time = winner == 'tie' ? 0.06 : 0.04

  animate_middle_string(result_phrase_array, character_time: character_time)
end

def update_score_with_animation(result_phrase, winner)
  score_update_animation(winner, result_phrase)
  update_score(winner)
  display_score(result_phrase)
end

def match_result_string(last_result_message)
  match_winner_message = prompt(match_winner(return_message_key: true),
                                return_string: true)
  last_result_message + "\n" + match_winner_message
end

def reset_score_with_animation
  reset_score
  score_update_animation("reset")
  display_score
end

clear_screen

LANGUAGE = get_language
PLAYER_NAME = get_name

COMPUTER = message('computer')
SCORE_TABLE_HEADER = table_horizontal_border + table_row(PLAYER_NAME, COMPUTER)
VALID_ANSWERS = { yes: message("options_yes"), no: message("options_no") }
ANSWER_LIST = valid_answers_list
RULES = CONFIG[LANGUAGE]['rules']
VALID_MOVE_CHOICES = RULES.map { |choice, _| RULES[choice]['options'] }.flatten
MOVE_ABBREVIATIONS = RULES.map { |choice, _| RULES[choice]['options'][-1] }
MOVE_LIST = available_moves_list

welcome_message = prompt('welcome', "\n ", return_string: true)

display_content(welcome_message)
display_rules if yes_or_no?('show_rules', content_to_keep: welcome_message)
display_score

loop do
  result_message = nil

  loop do
    user_choice = get_user_move(result_message)
    computer_choice = set_computer_move
    winner = set_winner(user_choice, computer_choice)

    result_phrase_array = result_phrase_parts(user_choice, computer_choice,
                                              winner)
    result_message = compose_phrase(result_phrase_array, winner)

    display_result_of_round(result_phrase_array, winner)
    update_score_with_animation(result_message, winner)

    break unless match_winner == "nobody yet"
  end

  match_result = match_result_string(result_message)

  display_content(match_result)

  break unless yes_or_no?('play_again', content_to_keep: match_result,
                                        show_score: true)
  reset_score_with_animation
end

prompt("great_match", " #{PLAYER_NAME}!#{align_to_prompt(message('goodbye'))}")
