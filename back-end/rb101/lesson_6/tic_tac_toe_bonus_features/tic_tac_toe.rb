require 'yaml'
require 'io/console'
require 'timeout'

MESSAGES = YAML.load_file('tic_tac_toe_messages.yml')

ROUNDS_TO_WIN = 5
MIN_BOARD_SIZE = 3
MIN_WINNING_LINE_LENGTH = 4
MARKING_CHARS_MAX_AMOUNT = 2

SQUARE_WIDTH = 8
SQUARE_HEIGHT = 3
EMPTY_SPACE = " " * SQUARE_WIDTH

PROMPT = "=> "
PROMPT_LENGTH = PROMPT.size
BOLD = ["\e[1m", "\e[22m"]
DIM = ["\e[2m", "\e[22m"]
ITALIC = ["\e[3m", "\e[23m"]
REVERSE_COLORS = ["\e[7m", "\e[27m"]
DECORATION_LENGTH = DIM.join.size
OPTION_INDICATOR = ") "
OPTION_INDICATOR_SIZE = OPTION_INDICATOR.size

def check_ruby_version(version)
  required_version = Gem::Version.new(version)
  users_version = Gem::Version.new(RUBY_VERSION)

  return if users_version >= required_version

  clear_screen
  prompt("update_ruby", string_formatter: { min_version: version,
                                            user_version: users_version })
  sleep 3
  abort
end

def bold(string)
  colorize(BOLD, string)
end

def dim(string)
  colorize(DIM, string)
end

def reverse_colors(string)
  colorize(REVERSE_COLORS, string)
end

def italic(string)
  colorize(ITALIC, string)
end

def colorize(color_array, string)
  color_array[0] + string + color_array[1]
end

def message(key, string_formatter: {}, location: MESSAGES)
  string = location[key]
  string_format = STRING_FORMAT.merge(string_formatter)

  string.include?("%{") ? format(string, string_format) : string
end

def prompt(key, additional_string = "", new_screen: false, string_formatter: {})
  prompt_message = PROMPT + message(key, string_formatter: string_formatter) +
                   additional_string

  clear_screen if new_screen

  puts split_string_to_fit_window(prompt_message, indent: PROMPT_LENGTH)
end

def clear_screen
  system('clear') || system('cls')
end

def align_to_prompt(string, leading_newline: true)
  spaces = " " * PROMPT_LENGTH
  new_string = spaces + string

  leading_newline ? "\n" + new_string : new_string
end

def split_string_to_fit_window(string, indent: 0, left_margin: 0)
  window_width = IO.console.winsize[1] - 1
  lines_and_lengths =
    string.split("\n").map { |line| [line, amount_of_characters(line)] }

  return string if string_fits?(left_margin, lines_and_lengths, window_width)

  indentation = " " * (indent + left_margin)

  formatted_lines(lines_and_lengths, indentation, window_width, left_margin)
end

def amount_of_characters(string)
  extra_amount = string.include?(" ") ? 0 : 1
  text = string.include?("\e") ? string.gsub(/\e\[(\d+)m/, '') : string

  text.size + extra_amount
end

def string_fits?(left_margin, lines_and_lengths, width)
  left_margin.zero? && lines_and_lengths.all? { |(_, length)| length <= width }
end

def formatted_lines(lines_and_lengths, indentation, window_width, left_margin)
  lines_and_lengths.map do |line, line_length|
    if line_length + left_margin <= window_width
      " " * left_margin + line
    else
      words = line.split(/ /)

      compose_lines(words, indentation, window_width, left_margin)
    end
  end
end

def compose_lines(words, indentation, max_length, line_length)
  new_line = first_line(line_length)
  lines = []

  words.each do |word|
    length_of_word = amount_of_characters(word)

    if line_length + length_of_word - 1 > max_length
      lines << new_line.join(" ")
      new_line = ["#{indentation}#{word}"]
      line_length = amount_of_characters(new_line[0]) + 1
    else
      new_line << word
      line_length += length_of_word
    end
  end

  lines + [new_line.join(" ")]
end

def first_line(first_line_length)
  first_line_length < 1 ? [] : [" " * (first_line_length - 1)]
end

def board_size_string(size)
  "#{size}x#{size}"
end

def display_welcome_and_overview
  is_customizable_on_every_board = MIN_BOARD_SIZE > MIN_WINNING_LINE_LENGTH
  first_separation, second_separation =
    is_customizable_on_every_board ? [2, 1] : [1, 2]

  clear_screen
  display_message("welcome_and_overview")

  MESSAGES['customizable_aspects'].each do |number, parts|
    display_message('description', left_margin: 2, indent: 3, location: parts)

    next puts if number == 'number2' && is_customizable_on_every_board
    display_message('additional_info', left_margin: 5, location: parts)
  end

  display_blank_lines(first_separation)
  display_message("rounds_to_win") if ROUNDS_TO_WIN > 1

  display_blank_lines(second_separation)
  press_enter_to_continue("continue")
end

def display_message(key, format: {}, left_margin: 0, indent: 0,
                    location: MESSAGES)
  string = message(key, location: location, string_formatter: format)
  puts split_string_to_fit_window(string, left_margin: left_margin,
                                          indent: indent)
end

def display_blank_lines(amount)
  amount.times { puts }
end

def press_enter_to_continue(message)
  prompt(message)

  loop do
    break if gets.chomp == ""
  end
end

def set_board_size
  refresh_list_key = "r"

  loop do
    max_board_size = calculate_max_board_size
    range = (MIN_BOARD_SIZE..max_board_size)

    next request_window_resizing if range.size < 1

    sizes = range.map { |number| [number.to_s, "#{number}x#{number}"] }
    options = sizes + [refresh_list_key]

    prompt('choose_board_size', create_options_list(sizes), new_screen: true)
    display_message("note", left_margin: PROMPT_LENGTH)

    chosen_option = select_option(options)
    return chosen_option.to_i unless chosen_option == refresh_list_key
  end
end

def calculate_max_board_size
  height, width = IO.console.winsize

  height_max_board_size = (height - 2) / (SQUARE_HEIGHT + 1)
  width_max_board_size = (width + 1) / (SQUARE_WIDTH + 1)

  [height_max_board_size, width_max_board_size].min
end

def request_window_resizing
  prompt('enlarge_window', new_screen: true)
  print "\e7" # save cursor position

  loop do
    break if calculate_max_board_size >= MIN_BOARD_SIZE
    sleep 0.3
    print "\e8" # restore cursor position
  end

  absorb_useless_input
end

def absorb_useless_input
  loop do
    input =
      begin
        Timeout.timeout(0.0003) { gets.chomp }
      rescue Timeout::Error
        nil
      end

    break if input.nil?
  end
end

def create_options_list(options)
  max_option_size = options.map { |option| option[0].size }.max
  decorated_option_size =
    max_option_size + DECORATION_LENGTH + OPTION_INDICATOR_SIZE
  list = ""

  options.each do |option, description|
    decorated_option = bold_option(option, decorated_option_size, description)
    list << align_to_prompt(decorated_option)
  end

  list
end

def select_option(options)
  loop do
    choice = clean_whitespaces(gets.chomp, "").downcase.delete("\"'")

    return choice if options.flatten.include?(choice)
    prompt("invalid_option")
  end
end

def clean_whitespaces(string, separator = " ")
  string.split.join(separator)
end

def get_integer(message, range, new_screen: false)
  return range.max if range.size == 1
  prompt(message, new_screen: new_screen)

  integer = nil
  loop do
    integer = clean_whitespaces(gets.chomp)
    integer = integer.to_i if valid_integer?(integer)
    break if range.include?(integer)

    format_hash = compose_format_hash(range, "integer_")
    prompt("out_of_range", string_formatter: format_hash)
  end

  integer
end

def valid_integer?(num_string)
  return false if num_string == ""
  num_string.chars.all? { |char| char =~ /[0-9]/ }
end

def compose_format_hash(range, between_word="")
  min = range.min
  max = range.max

  if max - min > 1
    and_or = message("and")
    to_or = message("to")
    between = message(between_word + "between") + " "
  else
    and_or = message("or")
    to_or = message("or")
    between = ""
  end

  { min_num: min, max_num: max, and_or: and_or, between: between, to_or: to_or }
end

def set_winning_line_length
  clear_screen

  if SQUARES_PER_ROW > MIN_WINNING_LINE_LENGTH
    get_integer('winning_line_length', MIN_WINNING_LINE_LENGTH..SQUARES_PER_ROW)
  else
    SQUARES_PER_ROW
  end
end

def create_board_rows_array
  board = []
  number_of_squares = SQUARES_PER_ROW**2

  SQUARES_PER_ROW.times do
    board << []
  end

  (1..number_of_squares).each do |num|
    index = (num - 1) / SQUARES_PER_ROW
    board[index] << num.to_s
  end

  board
end

def create_board_columns_array
  ROWS.map.with_index do |_, index|
    ROWS.map { |row| row[index] }.flatten
  end
end

def create_board_diagonals_array
  amount_per_direction_at_top = SQUARES_PER_ROW - WINNING_LINE_LENGTH + 1
  diagonals_amount = (1 + (amount_per_direction_at_top - 1) * 2) * 2
  diagonals = []
  diagonals_amount.times { diagonals << [] }

  append_diagonals_converging_in_first_row!(diagonals,
                                            amount_per_direction_at_top)
  append_remaining_diagonals!(diagonals, amount_per_direction_at_top)

  diagonals
end

def append_diagonals_converging_in_first_row!(diagonals, amount)
  ROWS.each_with_index do |row, row_index|
    (0...amount).to_a.each do |diagonal_index|
      index = row_index + diagonal_index

      next unless index < SQUARES_PER_ROW

      mirror_append_to_first_array!(diagonals, diagonal_index, row, index)
    end
  end
end

def append_remaining_diagonals!(diagonals, amount)
  (amount - 1).times do |lap|
    starting_row = lap + 1
    length = ROWS.length - starting_row

    ROWS[starting_row, length].each_with_index do |row, row_index|
      diagonal_index = amount + lap

      mirror_append_to_first_array!(diagonals, diagonal_index, row, row_index)
    end
  end
end

def mirror_append_to_first_array!(first_array, first_index, second_array,
                                  second_index)
  first_index_mirror = mirror_index(first_index)
  second_index_mirror = mirror_index(second_index)

  first_array[first_index] << second_array[second_index]
  first_array[first_index_mirror] << second_array[second_index_mirror]
end

def mirror_index(index)
  -(index + 1)
end

def create_board_horizontal_divisor
  line = "-" * SQUARE_WIDTH
  divisor = ""

  (SQUARES_PER_ROW - 1).times { divisor << line + "+" }

  divisor + line + "\n"
end

def create_row_string(row_array, rows=ROWS)
  is_last_row = rows.find_index(row_array) == SQUARES_PER_ROW - 1
  center_amount = SQUARE_WIDTH + bold("").length
  row_string = graphic_board_row(row_array, center_amount)

  is_last_row ? row_string : row_string + GAME_BOARD_HORIZONTAL_LINE
end

def graphic_board_row(row_array, center_amount)
  additional_length = reverse_colors("").length + center_amount
  row_string = ""

  SQUARE_HEIGHT.times do |lap|
    if lap == SQUARE_HEIGHT / 2
      row_array.each do |item|
        item = item.to_i > 0 ? dim(item) : bold(item)
        amount = item.length > center_amount ? additional_length : center_amount
        row_string << item.center(amount) + "|"
      end

      row_string[-1] = "\n"
    else
      row_string << HEIGHT_FILLER + "\n"
    end
  end

  row_string
end

def reset_board!
  SQUARES_PER_ROW.times do |row|
    SQUARES_PER_ROW.times do |column|
      number = (row * SQUARES_PER_ROW) + (column + 1)
      item = ROWS[row][column]
      replace_string!(item, number.to_s)
      AVAILABLE_SQUARES[number - 1] = number.to_s
    end

    GAME_BOARD_STRING[row] = create_row_string(ROWS[row])
  end
end

def replace_string!(string, new_string)
  string[0..-1] = new_string
end

def display_board(winner: nil)
  colorize_line!(winner) unless winner.nil?

  clear_screen
  puts GAME_BOARD_STRING
  puts
end

def colorize_line!(winner)
  winning_rows_indices = winning_rows_indices(POSSIBLE_WINNING_LINES)
  winning_line_marks =
    POSSIBLE_WINNING_LINES_BY_PLAYER[winner].select do |line|
      winning_line?(line)
    end

  winning_line_marks[0].each do |mark|
    replace_string!(mark, reverse_colors(" #{mark} "))
  end

  winning_rows_indices.each do |row_index|
    GAME_BOARD_STRING[row_index] = create_row_string(ROWS[row_index])
  end
end

def winning_rows_indices(hash)
  winning_line_numbers =
    hash.select do |_, lines|
      lines.any? { |line| winning_line?(line) }
    end

  rows =
    winning_line_numbers.keys.map { |number| row_and_column_numbers(number)[0] }

  rows.uniq
end

def winning_line?(line)
  line.uniq.length == 1
end

def set_players!
  max_amount = ((SQUARES_PER_ROW**2 - 1) / (WINNING_LINE_LENGTH - 1)) / 2

  display_settings_and_allowed_amount_of_players(max_amount)

  users = get_integer("users_amount", (1..max_amount))
  min_computers = users == 1 ? 1 : 0
  max_computers = users == max_amount ? 0 : max_amount - users
  computers = get_integer("computers_amount", (min_computers..max_computers))

  create_players_hashes!(users, computers)
end

def display_settings_and_allowed_amount_of_players(max_amount)
  message_start = max_amount == 2 ? message("only") : message("up_to")
  string_format = {
    amount: max_amount,
    only_upto: message_start,
    size: SQUARES_PER_ROW,
    consecutive_squares: WINNING_LINE_LENGTH
  }

  prompt("settings", string_formatter: string_format, new_screen: true)
  puts
  prompt("max_amount_of_players", string_formatter: string_format)
  puts
end

def create_players_hashes!(users_amount, computers_amount)
  used = { names: [], marks: [] }
  players = { computers: computers_amount, users: users_amount }

  players.each do |player_type, amount|
    hash = player_type == :users ? USERS : COMPUTERS

    amount.times do |index|
      name = set_name(player_type, index + 1, used[:names], amount)
      used[:names] << name
      marking_chars = get_marking_chars(name, used[:marks])
      used[:marks] << marking_chars

      hash[name] = marking_chars
    end
  end
end

def set_name(player_type, player_number, used_names, total)
  case player_type
  when :users
    get_name(player_number, used_names, total)
  when :computers
    number = total == 1 ? "" : " #{player_number}"
    "#{message('computer_name')}#{number}"
  end
end

def get_name(player_number, used_names, total)
  if total == 1
    prompt("name_of_one_user", new_screen: true)
  else
    prompt("enter_name", " #{player_number}", new_screen: true)
  end

  get_input("name", (3..MAX_NAME_LENGTH), used_names)
end

def set_max_name_lenght
  max_chars_used_by_mark = " ()".size + MARKING_CHARS_MAX_AMOUNT
  second_width = cell_width("score")
  board_width = table_horizontal_line(first_width: max_chars_used_by_mark,
                                      second_width: second_width).size
  available_space = IO.console.winsize[1] - board_width

  [available_space, 20].min
end

def get_marking_chars(player_name, used_marks)
  formatter = { player_name: player_name }

  prompt('marking_characters', string_formatter: formatter, new_screen: true)
  display_message("marker_example", left_margin: PROMPT_LENGTH)

  get_input("mark", (1..MARKING_CHARS_MAX_AMOUNT), used_marks)
end

def get_input(type, range, used_strings)
  formatter = compose_format_hash(range).merge({ type: message(type) })
  input = ""

  loop do
    input = clean_whitespaces(gets.chomp)

    if contains_computer_name?(input)
      next prompt('cant_contain_computer')
    elsif string_already_taken?(input, used_strings)
      next prompt("#{type}_taken")
    end

    break if valid_string?(input, range)
    prompt("invalid_chars", string_formatter: formatter)
  end

  input
end

def contains_computer_name?(string)
  computer_name = message('computer_name').upcase

  string.upcase.include?(computer_name)
end

def string_already_taken?(string, used_strings)
  used_strings = used_strings.map(&:upcase)

  used_strings.include?(string.upcase)
end

def valid_string?(input_str, range)
  range.include?(input_str.length) &&
    input_str.chars.none? { |char| char =~ /[0-9\e\b\\]/ }
end

def set_turns
  available_players = [COMPUTERS.keys, USERS.keys].flatten
  playing_order = []

  prompt('who_starts', new_screen: true)

  loop do
    display_players_list(available_players)
    transfer_player_between_arrays!(available_players, playing_order)

    break if available_players.empty?
    prompt('who_plays_next', new_screen: true)
  end

  playing_order
end

def display_players_list(available_players)
  max_option_size = PLAYER_NAMES.size.to_s.size + OPTION_INDICATOR_SIZE
  decorated_option_size = max_option_size + DECORATION_LENGTH
  players_list = ""

  PLAYER_NAMES.each_with_index do |name, index|
    option_number = (index + 1).to_s
    decorated_text =
      decorate_option_by_availability(name, available_players, option_number,
                                      max_option_size, decorated_option_size)

    players_list << "#{decorated_text}\n"
  end

  puts split_string_to_fit_window(players_list, left_margin: PROMPT_LENGTH,
                                                indent: max_option_size)
end

def decorate_option_by_availability(item, available_items, option_number,
                                    max_option_size, decorated_option_size)
  if item_already_used?(item, available_items)
    dim_option(option_number, max_option_size, item)
  else
    bold_option(option_number, decorated_option_size, item)
  end
end

def item_already_used?(item, available_items)
  available_items.index(item).nil?
end

def dim_option(option_number, max_option_size, item)
  number = option_number + OPTION_INDICATOR

  dim(number.ljust(max_option_size) + item)
end

def bold_option(option_number, decorated_option_size, item)
  decorated_number = bold(option_number) + OPTION_INDICATOR

  decorated_number.ljust(decorated_option_size) + item
end

def transfer_player_between_arrays!(available_players, playing_order)
  loop do
    choice = selected_player(clean_whitespaces(gets.chomp), available_players)

    next prompt('invalid_option') if choice.nil?

    playing_order << available_players.delete(choice)
    playing_order << available_players.pop if available_players.size == 1
    break
  end
end

def selected_player(choice, available_choices)
  return nil if choice == ""

  if valid_integer?(choice)
    return nil if choice.to_i == 0
    player_name = PLAYER_NAMES[choice.to_i - 1]

    available_choices.index(player_name) ? player_name : nil
  else
    available_choices.each { |name| return name if name.casecmp?(choice) }
    nil
  end
end

def initialize_decorations_hash
  decorations_by_player = Hash.new { |hash, key| hash[key] = {} }

  PLAYER_NAMES.each do |player|
    ["dim", "bold"].each do |decoration|
      decorations_by_player[player][decoration] =
        decorated_name_and_mark(player, decoration)
    end
  end

  decorations_by_player
end

def decorated_name_and_mark(name, dim_or_bold)
  case dim_or_bold
  when "dim"
    name + " #{dim("(#{PLAYERS[name]})")}"
  when "bold"
    bold(name) + " (\"#{PLAYERS[name]}\")"
  end
end

def initialize_possible_winning_lines
  possible_winning_lines = Hash.new { |hash, key| hash[key] = [] }

  subdivde_board_and_group_by_square_number!(possible_winning_lines)

  possible_winning_lines
end

def subdivde_board_and_group_by_square_number!(hash)
  max_sublines_per_line = SQUARES_PER_ROW - WINNING_LINE_LENGTH + 1

  subdivide_line!(max_sublines_per_line, ROWS, hash)
  subdivide_line!(max_sublines_per_line, COLUMNS, hash)
  subdivide_line!(max_sublines_per_line, DIAGONALS, hash)
end

def subdivide_line!(max_sublines_per_line, array_of_lines, hash)
  max_sublines_per_line.times do |index|
    array_of_lines.each do |line|
      divided_line = line[index, WINNING_LINE_LENGTH]

      next if divided_line.nil? || divided_line.length < WINNING_LINE_LENGTH
      divided_line.each { |square| hash[square] << divided_line }
    end
  end
end

def initialize_lines_that_player_may_win
  possible_winning_lines = {}

  PLAYERS.each_key { |name| possible_winning_lines[name] = [] }

  possible_winning_lines
end

def reset_possible_winning_lines!
  reset_values_to_empty_arrays!(POSSIBLE_WINNING_LINES_BY_PLAYER)
  reset_values_to_empty_arrays!(POSSIBLE_WINNING_LINES)

  subdivde_board_and_group_by_square_number!(POSSIBLE_WINNING_LINES)
end

def reset_values_to_empty_arrays!(hash)
  hash.each do |key, _|
    hash[key] = []
  end
end

def start_new_round!
  reset_board!
  reset_possible_winning_lines!
end

def set_scores_to_zero
  scores = {}

  PLAYERS.each_key { |player| scores[player] = 0 }

  scores
end

def update_score!(scores, winner)
  scores[winner] += 1
end

def display_scores(scores)
  sorted_scores = sort_and_decorate(scores)
  score_board = SCOREBOARD_HEADER

  sorted_scores.each do |player, score|
    score_board += table_row(player, FIRST_COLUMN_WIDTH,
                             score.to_s, SECOND_COLUMN_WIDTH)
  end

  puts(score_board + "\n ")
end

def sort_and_decorate(scores)
  sorted_scores = scores.sort_by { |_, score| -score }

  sorted_scores.map do |name, score|
    [PLAYER_DECORATIONS[name]["dim"], score]
  end
end

def cell_width(column_name)
  header_length = message(column_name).length
  items_max_length =
    case column_name
    when "player" then find_max_player_name_length
    when "score"  then ROUNDS_TO_WIN.to_s.length
    end

  [header_length, items_max_length].max
end

def find_max_player_name_length
  decoration_length = dim("").size
  lengths =
    PLAYER_NAMES.map do |name, _|
      PLAYER_DECORATIONS[name]["dim"].size - decoration_length
    end

  lengths.max
end

def score_header(first_length, second_length, include_horizontal_line: true)
  first_item_centered = header_text("player", first_length)
  second_item_centered = header_text("score", second_length)

  header = "\n  " + first_item_centered + " | " + second_item_centered + "  \n"

  return header unless include_horizontal_line
  header + SCOREBOARD_HORIZONATL_LINE
end

def header_text(title, length)
  italic(message(title)).center(length + italic("").length)
end

def table_horizontal_line(first_width: FIRST_COLUMN_WIDTH,
                          second_width: SECOND_COLUMN_WIDTH)
  "+--" + cell_line(first_width) + "--" + cell_line(second_width)
end

def cell_line(length)
  ("-" * length) + "+"
end

def table_row(first_item, first_length, second_item, second_length)
  "\n" + table_contents(first_item, first_length, second_item, second_length) +
    "\n" + SCOREBOARD_HORIZONATL_LINE
end

def table_contents(first_item, first_length, second_item, second_length)
  first_length += dim("").length
  second_length += bold("").length

  first_item_padded = first_item.ljust(first_length)
  second_item_padded = bold(second_item).center(second_length)

  "| " + first_item_padded + " | " + second_item_padded + " |"
end

def get_player_choice(player)
  if player.start_with?(message("computer_name"))
    computer_choice(player).clone
  else
    get_user_move(player)
  end
end

def get_user_move(player)
  prompt("choose_square", " #{PLAYER_DECORATIONS[player]['bold']}")

  square_number = ""
  loop do
    square_number = gets.chomp

    break if AVAILABLE_SQUARES.include?(square_number)
    prompt('invalid_square_number')
  end

  square_number
end

def computer_choice(computer_name)
  if choose_middle_square?
    highest_amount_of_available_lines(middle_squares)
  else
    return diagonal_move(computer_name) if make_diagonal_move?

    players_squares_marked =
      lines_by_amount_of_marked_squares(USERS.keys + [computer_name])

    square_from_most_risky_line(players_squares_marked,
                                priority_order(computer_name))
  end
end

def choose_middle_square?
  return false unless first_round?

  middle_squares.intersection(AVAILABLE_SQUARES).size > 0
end

def first_round?
  AVAILABLE_SQUARES.size > SQUARES_PER_ROW**2 - PLAYERS_MARKS.size
end

def middle_squares
  index = (SQUARES_PER_ROW + 1) / 2 - 1

  if SQUARES_PER_ROW.odd?
    [ROWS[index][index]]
  else
    squares =
      [ROWS[index][index, 2], ROWS[index + 1][index, 2]].flatten -
      PLAYERS_MARKS

    squares.intersection(used_diagonal)
  end
end

def highest_amount_of_available_lines(squares, computer_squares = [])
  return squares[0] if squares.size == 1

  lines_without_marks = unused_lines

  squares_by_amount_of_lines =
    squares.group_by do |square_number|
      lines_without_marks[square_number].length +
        computer_squares.count(square_number)
    end

  squares_by_amount_of_lines.max[1].flatten.sample
end

def unused_lines
  available_lines = {}

  POSSIBLE_WINNING_LINES.each do |square_number, lines|
    available_lines[square_number] = lines.select do |line|
      line.intersection(PLAYERS_MARKS).empty?
    end
  end

  available_lines
end

def make_diagonal_move?
  players_amount = 2
  marked_squares_amount = SQUARES_PER_ROW**2 - AVAILABLE_SQUARES.size

  return false unless PLAYERS.size == 2
  return true if three_consecutive_marks_in_one_diagonal?(marked_squares_amount)
  return false unless marked_squares_amount <= players_amount

  DIAGONALS.any? { |line| line.intersection(PLAYERS_MARKS).length > 0 }
end

def three_consecutive_marks_in_one_diagonal?(marked_squares_amount)
  return false unless marked_squares_amount == 3

  used_diagonal =
    DIAGONALS.select { |line| (line - (line - PLAYERS_MARKS)).size == 3 }[0]

  return false if used_diagonal.nil?

  successive_marks = 0
  used_diagonal.each do |item|
    PLAYERS_MARKS.include?(item) ? successive_marks += 1 : successive_marks = 0

    return true if successive_marks == 3
  end

  false
end

def diagonal_move(computer_name)
  marked_squares_amount = SQUARES_PER_ROW**2 - AVAILABLE_SQUARES.size

  if marked_squares_amount == 3
    ignore_distraction(computer_name)
  else
    continue_in_same_diagonal(computer_name)
  end
end

def ignore_distraction(computer_name)
  squares =
    POSSIBLE_WINNING_LINES_BY_PLAYER[computer_name].flatten.uniq

  most_dangerous_square(squares, computer_name, computer_name)
end

def continue_in_same_diagonal(computer_name)
  diagonal = used_diagonal
  computer_mark = [COMPUTERS[computer_name]]

  numbers =
    diagonal.select.with_index do |square, index|
      previous_element = diagonal[index - 1] unless index == 0
      next_element = diagonal[index + 1]
      square.to_i != 0 &&
        [previous_element, next_element].intersection(PLAYERS_MARKS).size > 0
    end

  numbers =
    marks_near_amounts(numbers, computer_mark).max[1]

  highest_amount_of_available_lines(numbers)
end

def used_diagonal
  diagonals_by_squares_marked =
    DIAGONALS.group_by do |diagonal|
      diagonal.intersection(PLAYERS_MARKS).size
    end

  diagonals_by_squares_marked.max[1].flatten
end

def marks_near_amounts(square_numbers, marks)
  amounts = {}

  square_numbers.each do |square|
    near_amount = 0

    POSSIBLE_WINNING_LINES[square].each do |line|
      index = line.index(square)
      near_amount += 1 if marks.include?(line[index + 1])
      next if index == 0
      near_amount += 1 if marks.include?(line[index - 1])
    end

    amounts[square] = near_amount
  end

  amounts.keys.group_by { |square| amounts[square] }
end

def lines_by_amount_of_marked_squares(players)
  lines_by_squares_marked = {}

  players.each do |player|
    lines_by_squares_marked[player] =
      group_by_amount_of_marked_squares(player)
  end

  lines_by_squares_marked
end

def group_by_amount_of_marked_squares(player)
  possible_winning_lines =
    POSSIBLE_WINNING_LINES_BY_PLAYER[player].map do |line|
      line - PLAYERS_MARKS
    end

  possible_winning_lines.group_by do |line|
    WINNING_LINE_LENGTH - line.length
  end
end

def priority_order(player_playing_now)
  before, after =
    PLAYING_ORDER.partition do |player|
      PLAYING_ORDER.index(player) < PLAYING_ORDER.index(player_playing_now)
    end

  after.shift

  [player_playing_now] + after + before
end

def square_from_most_risky_line(players_squares_marked, priority_order)
  max_possible_marked_squares = WINNING_LINE_LENGTH - 1

  (1..max_possible_marked_squares).each do |amount_to_win|
    marked_squares = WINNING_LINE_LENGTH - amount_to_win

    result = square_from_nearest_player(players_squares_marked, marked_squares,
                                        priority_order)

    return result unless result.nil?
  end

  highest_amount_of_available_lines(AVAILABLE_SQUARES)
end

def square_from_nearest_player(players_squares_marked, marked_squares_amount,
                               priority_order)
  computer_name = priority_order[0]

  priority_order.each do |player|
    player_hash = players_squares_marked[player]
    next if player_hash.nil?
    lines = player_hash[marked_squares_amount]
    next if lines.nil?

    amount_of_repetitions =
      lines.flatten!.group_by { |square_number| lines.count(square_number) }

    squares = amount_of_repetitions.max[1].uniq

    return most_dangerous_square(squares, player, computer_name)
  end

  nil
end

def most_dangerous_square(squares, player, computer_name)
  return squares[0] if squares.size == 1

  filtered_squares = squares_that_block_more_lines(squares)

  unless player == computer_name
    filtered_squares =
      squares_that_lengthen_computer_lines(filtered_squares, computer_name)
  end

  highest_amount_of_available_lines(filtered_squares)
end

def squares_that_block_more_lines(dangerous_squares)
  users_possible_winning_lines =
    POSSIBLE_WINNING_LINES_BY_PLAYER.select do |player, _|
      USERS.keys.include?(player)
    end

  users_possible_winning_lines =
    users_possible_winning_lines.values.flatten - PLAYERS_MARKS

  most_repeated_numbers(dangerous_squares, users_possible_winning_lines)
end

def most_repeated_numbers(numbers_to_group, array_where_to_count)
  most_repeated =
    numbers_to_group.group_by do |number|
      array_where_to_count.count(number)
    end

  most_repeated.max[1]
end

def squares_that_lengthen_computer_lines(squares, computer_name)
  lines_by_squares_marked =
    group_by_amount_of_marked_squares(computer_name)

  return squares if lines_by_squares_marked.empty? || squares.size == 1

  max_amount = lines_by_squares_marked.max[0]

  [*(1..max_amount)].reverse.each do |marked_amount|
    lines = lines_by_squares_marked[marked_amount]

    next if lines.flatten!.intersection(squares).empty?

    return most_repeated_numbers(squares, lines)
  end

  squares
end

def player_marks_a_square!(player, square_number)
  mark_square!(PLAYERS[player], square_number)

  AVAILABLE_SQUARES.delete(square_number)
  update_possible_winning_lines!(player, square_number)
end

def mark_square!(player_mark, integer_string)
  row, column = row_and_column_numbers(integer_string)
  square_number = ROWS[row][column]

  replace_string!(square_number, player_mark)

  GAME_BOARD_STRING[row] = create_row_string(ROWS[row])

  display_animated_mark(row, column, player_mark)
end

def row_and_column_numbers(integer_string)
  integer = integer_string.to_i
  row = (integer - 1) / SQUARES_PER_ROW
  column = (integer - 1) % SQUARES_PER_ROW

  [row, column]
end

def display_animated_mark(row, column, player_mark)
  graphic_board = GAME_BOARD_STRING.map(&:clone)
  rows = ROWS.map(&:clone)

  3.times do |lap|
    style =
      (lap + 1).odd? ? reverse_colors(" #{player_mark} ") : bold(player_mark)
    rows[row][column] = style
    graphic_board[row] = create_row_string(rows[row], rows)

    clear_screen
    puts graphic_board
    sleep(0.21)
  end
end

def update_possible_winning_lines!(player, square_number)
  lines_to_remove = useless_lines(POSSIBLE_WINNING_LINES[square_number])

  lines_to_remove.each do |line|
    remove_item_from_each_hash_value!(line, POSSIBLE_WINNING_LINES)
    remove_item_from_each_hash_value!(line, POSSIBLE_WINNING_LINES_BY_PLAYER)
  end

  add_new_possible_winning_lines!(player, square_number)
end

def useless_lines(array_of_lines)
  array_of_lines.select do |line|
    line.intersection(PLAYERS_MARKS).length > 1
  end
end

def remove_item_from_each_hash_value!(item, hash)
  hash.each_value do |subarray|
    subarray.delete(item)
  end
end

def add_new_possible_winning_lines!(player, square_number)
  player_may_win = POSSIBLE_WINNING_LINES_BY_PLAYER[player]

  POSSIBLE_WINNING_LINES[square_number].each do |line|
    player_may_win << line unless player_may_win.include?(line)
  end
end

def round_ended?(square_number, player)
  mark_of_completed_line(square_number) || tie?(player)
end

def mark_of_completed_line(square_number)
  POSSIBLE_WINNING_LINES[square_number].each do |line|
    return line[0] if winning_line?(line)
  end

  nil
end

def tie?(player)
  available_lines = POSSIBLE_WINNING_LINES.values.flatten(1).uniq

  return true if available_lines.empty?

  lines_by_squares_left =
    available_lines.group_by do |line|
      (line - PLAYERS_MARKS).size
    end

  possible_winners_marks = closest_to_winning(lines_by_squares_left)
  distance = distance_to_nearest_possible_winner(player, possible_winners_marks)
  repetitions = lines_by_squares_left.min[0] - 1

  impossible_to_complete_a_line?(repetitions, distance)
end

def closest_to_winning(lines_by_squares_left)
  lines_by_squares_left.min[1].flatten.intersection(PLAYERS_MARKS)
end

def distance_to_nearest_possible_winner(player_who_just_marked, risky_marks)
  return 0 if risky_marks.empty?

  previous_index = PLAYING_ORDER.index(player_who_just_marked)
  cycle = (PLAYING_ORDER * 2)[previous_index + 1, PLAYERS_MARKS.size]
  marks_order = cycle.map { |name| PLAYERS[name] }
  distances = []

  risky_marks.each do |mark|
    distances << marks_order.index(mark)
  end

  distances.min
end

def impossible_to_complete_a_line?(repetitions, distance)
  AVAILABLE_SQUARES.size <= PLAYERS_MARKS.size * repetitions + distance
end

def round_winner(square_number)
  winner_mark = mark_of_completed_line(square_number)

  return nil if winner_mark.nil?

  PLAYERS.key(winner_mark)
end

def display_winner(winner, scores)
  return prompt("tie") if winner.nil?

  message = match_ended?(scores) ? "won_the_match" : "won_this_round"

  prompt(message, string_formatter: { player_name: winner })
end

def display_winner_and_scores(winner, scores)
  display_board(winner: winner)
  display_winner(winner, scores)
  display_scores(scores)
end

def match_ended?(scores)
  scores.values.include?(ROUNDS_TO_WIN)
end

def play_again?
  options = VALID_ANSWERS.values

  prompt('play_again', create_options_list(options))

  VALID_ANSWERS[:yes].include?(select_option(options))
end

STRING_FORMAT = {
  b0: BOLD[0],
  b1: BOLD[1],
  d0: DIM[0],
  d1: DIM[1],
  i0: ITALIC[0],
  i1: ITALIC[1],
  r0: REVERSE_COLORS[0],
  r1: REVERSE_COLORS[1],
  indentation: " " * PROMPT_LENGTH,
  min_board_size: board_size_string(MIN_BOARD_SIZE),
  winning_score: ROUNDS_TO_WIN,
  customizable_min_size: board_size_string(MIN_WINNING_LINE_LENGTH + 1)
}

check_ruby_version('2.7.0')

display_welcome_and_overview

SQUARES_PER_ROW = set_board_size
WINNING_LINE_LENGTH = set_winning_line_length

ROWS = create_board_rows_array
COLUMNS = create_board_columns_array
DIAGONALS = create_board_diagonals_array
AVAILABLE_SQUARES = ROWS.flatten

MAX_NAME_LENGTH = set_max_name_lenght
USERS = {}
COMPUTERS = {}
set_players!
PLAYERS = COMPUTERS.merge(USERS)
PLAYER_NAMES = PLAYERS.keys
PLAYERS_MARKS = PLAYERS.values
PLAYING_ORDER = set_turns

POSSIBLE_WINNING_LINES = initialize_possible_winning_lines
POSSIBLE_WINNING_LINES_BY_PLAYER = initialize_lines_that_player_may_win

HEIGHT_FILLER = (1...SQUARES_PER_ROW).map { |_| EMPTY_SPACE + "|" }.join
GAME_BOARD_HORIZONTAL_LINE = create_board_horizontal_divisor
GAME_BOARD_STRING = ROWS.map { |row| create_row_string(row) }

PLAYER_DECORATIONS = initialize_decorations_hash
FIRST_COLUMN_WIDTH = cell_width("player")
SECOND_COLUMN_WIDTH = cell_width("score")
SCOREBOARD_HORIZONATL_LINE = table_horizontal_line
SCOREBOARD_HEADER = score_header(FIRST_COLUMN_WIDTH, SECOND_COLUMN_WIDTH)

VALID_ANSWERS = { yes: message("options_yes"), no: message("options_no") }

loop do
  scores = set_scores_to_zero

  loop do
    start_new_round!
    square_number = ""

    catch :round_ended do
      loop do
        PLAYING_ORDER.each do |player|
          display_board
          square_number = get_player_choice(player)
          player_marks_a_square!(player, square_number)
          throw :round_ended if round_ended?(square_number, player)
        end
      end
    end

    winner = round_winner(square_number)
    update_score!(scores, winner) unless winner.nil?
    display_winner_and_scores(winner, scores)

    break if match_ended?(scores)
    press_enter_to_continue("next_round")
  end

  break unless play_again?
end

prompt('goodbye')
