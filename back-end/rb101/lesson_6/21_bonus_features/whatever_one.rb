require 'yaml'
require 'io/console'
require 'timeout'

MESSAGES = YAML.load_file('whatever_one.yml')

ROUNDS_TO_WIN = 5
MAX_HAND_POINTS = 51
DEALER_POINTS_TO_STAY = MAX_HAND_POINTS - 4
FIRST_HAND_AMOUNT = 2
CARDS_PER_HIT = 1

PROMPT = "=> "
PROMPT_LENGTH = PROMPT.size
BOLD = ["\e[1m", "\e[22m"]
DIM = ["\e[2m", "\e[22m"]
ITALIC = ["\e[3m", "\e[23m"]
REVERSE_COLORS = ["\e[7m", "\e[27m"]
DECORATION_LENGTH = DIM.join.size
OPTION_INDICATOR = ") "
OPTION_INDICATOR_SIZE = OPTION_INDICATOR.size
STRING_FORMAT = {
  b0: BOLD[0],
  b1: BOLD[1],
  d0: DIM[0],
  d1: DIM[1],
  i0: ITALIC[0],
  i1: ITALIC[1],
  r0: REVERSE_COLORS[0],
  r1: REVERSE_COLORS[1],
  indentation: " " * PROMPT.size,
  winning_score: ROUNDS_TO_WIN
}

CARD_WIDTH = 7
CARD_HEIGHT = 7
HORIZONTAL_LINE = "─"
VERTICAL_LINE = "│"
CARD_TOP = "┌" + (HORIZONTAL_LINE * CARD_WIDTH) + "┐"
CARD_BOTTOM = "└" + (HORIZONTAL_LINE * CARD_WIDTH) + "┘"
CARD_EMPTY_BODY_SECTION =
  [VERTICAL_LINE + (" " * CARD_WIDTH) + VERTICAL_LINE] * ((CARD_HEIGHT - 5) / 2)

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

def message(key, string_formatter: {})
  string = MESSAGES[key]
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
  spaces = " " * PROMPT.length
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

def display_welcome
  clear_screen
  prompt("welcome", string_formatter: { game_name: MAX_HAND_POINTS,
                                        rounds_to_win: ROUNDS_TO_WIN })
  press_enter_to_continue("ready?")
end

def press_enter_to_continue(message)
  puts
  prompt(message)

  loop do
    break if gets.chomp == ""
  end
end

def initialize_participants
  [:dealer, :player].each do |participant|
    PARTICIPANTS[participant][:cards] = []
    PARTICIPANTS[participant][:valid_points] = [0]
    PARTICIPANTS[participant][:hand_points] = [0]
    PARTICIPANTS[participant][:chose_stay] = false
  end
end

def new_deck!
  DECK[0..-1] = CARD_FACES.product(SUITS).shuffle
  POSSIBLE_PLAYER_CARD_VALUES[0..-1] =
    ([2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10, 11] * 4).sort
  DECK.uniq!
end

def round_ended?
  hand_scores = get_values_from_participants(:valid_points)

  hand_scores.any?(&:empty?) || both_participants_stayed?
end

def get_values_from_participants(key)
  PARTICIPANTS.map { |(_, attributes)| attributes[key] }
end

def both_participants_stayed?
  PARTICIPANTS[:dealer][:chose_stay] && PARTICIPANTS[:player][:chose_stay]
end

def stop_giving_cards?(participant, attributes)
  attributes[:chose_stay] || dealers_first_hand?(participant) ||
    attributes[:valid_points].empty?
end

def dealers_first_hand?(participant)
  return false unless participant == :dealer

  given_cards = get_values_from_participants(:cards).flatten(1).size

  given_cards == FIRST_HAND_AMOUNT
end

def show_hidden_card?(participant)
  participant == :dealer &&
    PARTICIPANTS[participant][:cards].size == FIRST_HAND_AMOUNT
end

def display_cards(now_playing = nil)
  return if dealers_first_hand?(now_playing)
  sleep 0.6 if delay_screen_update?

  clear_screen

  PARTICIPANTS.each do |participant, attributes|
    if [now_playing, participant].all?(:dealer)
      prompt("dealers_turn")
    else
      prompt("#{participant}_cards")
    end

    display_participant_cards(participant, attributes, now_playing)
    puts
  end
end

def delay_screen_update?
  get_values_from_participants(:chose_stay).any? { |decision| decision }
end

def display_participant_cards(participant, attributes, now_playing)
  cards_per_row = max_amount_of_cards_per_row
  cards = attributes[:cards]
  cards = hide_card(cards) if hide_card?(participant, now_playing)
  grouped_cards_sections = group_cards_sections(cards)

  loop do
    break if grouped_cards_sections[0].empty?

    grouped_cards_sections.each do |section|
      puts section.select.with_index { |_, index| index < cards_per_row }.join
      section.delete_if.with_index { |_, index| index < cards_per_row }
    end
  end
end

def max_amount_of_cards_per_row
  loop do
    width = IO.console.winsize[1]
    max_amount = width / (CARD_WIDTH + 2)
    max_amount > 0 ? (return max_amount) : request_window_resizing
  end
end

def request_window_resizing
  prompt('enlarge_window', new_screen: true)
  print "\e7"

  loop do
    break if IO.console.winsize[1] / (CARD_WIDTH + 2) > 0
    sleep 0.3
    print "\e8"
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

def hide_card?(participant, now_playing)
  participant == :dealer && now_playing == :player
end

def hide_card(cards)
  cards = cards.clone
  cards[1] = ["?", "?"]

  cards
end

def group_cards_sections(cards)
  grouped_cards_sections = (1..CARD_HEIGHT).to_a.map { |_| [] }

  cards.each do |card|
    card_sections(card).each_with_index do |section, index|
      grouped_cards_sections[index] << section
    end
  end

  grouped_cards_sections
end

def card_sections(card)
  top_card_value = add_borders(card[0].ljust(CARD_WIDTH))
  suit = add_borders(card[1].center(CARD_WIDTH))
  bottom_card_value = add_borders(card[0].rjust(CARD_WIDTH))

  [CARD_TOP, top_card_value, CARD_EMPTY_BODY_SECTION, suit,
   CARD_EMPTY_BODY_SECTION, bottom_card_value, CARD_BOTTOM].flatten
end

def add_borders(string)
  VERTICAL_LINE + string + VERTICAL_LINE
end

def stay?(participant)
  hand_scores = PARTICIPANTS[participant][:valid_points]
  return false if hand_scores[0].zero?

  case participant
  when :dealer
    max_hand_score = hand_scores.max

    max_hand_score >= DEALER_POINTS_TO_STAY ||
      max_hand_score > max_possible_player_score
  when :player
    prompt("hit_or_stay")
    message("stay").include?(select_option(message("valid_hit_stay")))
  end
end

def max_possible_player_score
  amount_of_cards = PARTICIPANTS[:player][:cards].size

  POSSIBLE_PLAYER_CARD_VALUES.last(amount_of_cards).sum
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

def give_cards!(attributes)
  attributes[:cards].empty? ? DECK.pop(2) : DECK.pop(1)
end

def update_cards_and_hand_points!(participant, participant_attributes, cards)
  cards.each do |card|
    participant_attributes[:cards] << card

    card_value = card_points(card)
    cards_points = participant_attributes[:hand_points]
    updated_points = card_value.product(cards_points).map(&:sum).uniq
    participant_attributes[:hand_points] = updated_points

    participant_attributes[:valid_points] =
      updated_points.reject { |score| score > MAX_HAND_POINTS }

    update_possible_player_card_values(card_value) if participant == :dealer
  end
end

def card_points(card)
  card_value = card[0]

  return [card_value.to_i] if card_value.to_i > 0

  if card_value == "A"
    [1, 11]
  else
    [10]
  end
end

def update_possible_player_card_values(card_value)
  value_index = POSSIBLE_PLAYER_CARD_VALUES.index(card_value.last)
  POSSIBLE_PLAYER_CARD_VALUES.delete_at(value_index)
end

def find_round_winner
  player_hand_points = get_hand_score(:player)
  dealer_hand_points = get_hand_score(:dealer)

  if player_hand_points == dealer_hand_points
    nil
  elsif player_hand_points > dealer_hand_points
    :player
  else
    :dealer
  end
end

def get_hand_score(participant)
  score = PARTICIPANTS[participant][:valid_points]

  score.empty? ? 0 : score.max
end

def update_rounds_won(round_winner, rounds_won)
  rounds_won[round_winner] += 1 unless round_winner.nil?
end

def display_scores(rounds_won)
  player_score = rounds_won[:player].to_s
  dealer_score = rounds_won[:dealer].to_s

  puts
  puts score_table(player_score, dealer_score)
end

def score_table(user_score, computer_score)
  SCORE_TABLE_HEADER + table_row(user_score, computer_score) + "\n "
end

def table_row(first_item, second_item)
  "\n" + table_contents(first_item, second_item) + "\n" +
    TABLE_HORIZONTAL_LINE
end

def table_contents(first_item, second_item)
  first_item_centered = first_item.center(cell_length(PLAYER))
  second_item_centered = second_item.center(cell_length(DEALER))

  "| " + first_item_centered + " | " + second_item_centered + " |"
end

def cell_length(name)
  column = [name, ROUNDS_TO_WIN.to_s]
  column.map(&:length).max
end

def table_horizontal_border
  first_length = cell_length(PLAYER)
  second_length = cell_length(DEALER)

  "+--" + table_line(first_length) + "--" + table_line(second_length)
end

def table_line(length)
  ("-" * length) + "+"
end

def score_header
  rounds_won = message("rounds_won")
  decoration_length = rounds_won.size - amount_of_characters(rounds_won)

  rounds_won.center(TABLE_HORIZONTAL_LINE.size + decoration_length) + "\n" +
    TABLE_HORIZONTAL_LINE + table_row(PLAYER, DEALER)
end

def game_ended?(rounds_won)
  rounds_won.values.any? { |score| score == ROUNDS_TO_WIN }
end

def display_winner(winner, round_or_match)
  points = get_values_from_participants(:valid_points).map(&:max)
  return prompt("tie", string_formatter: { points: points.max }) if winner.nil?

  message = "#{winner}_#{round_or_match}"
  opponent = ([:dealer, :player] - [winner]).last

  if busted?(opponent)
    display_busted_message(opponent, round_or_match)
  else
    prompt(message, string_formatter: { winner: points.max, loser: points.min })
  end
end

def busted?(opponent)
  get_hand_score(opponent).zero?
end

def display_busted_message(opponent, round_or_match)
  points = PARTICIPANTS[opponent][:hand_points].min
  round_or_match = round_or_match.include?("round") ? "round" : "match"
  busted_message = "#{opponent}_busted_#{round_or_match}"

  prompt(busted_message, string_formatter: { points: points })
end

def play_again?
  options = VALID_ANSWERS.values

  prompt('play_again', create_options_list(options))

  VALID_ANSWERS[:yes].include?(select_option(options))
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

def bold_option(option_abbreviation, decorated_option_size, item)
  decorated_abbreviation = bold(option_abbreviation) + OPTION_INDICATOR

  decorated_abbreviation.ljust(decorated_option_size) + item
end

VALID_ANSWERS = { yes: message("options_yes"), no: message("options_no") }
DEALER = message("dealer")
PLAYER = message("player")
TABLE_HORIZONTAL_LINE = table_horizontal_border
SCORE_TABLE_HEADER = score_header

CARD_FACES = [*('2'..'10')] + %w(J Q K A)
SUITS = %w(♠ ♥ ♦ ♣)

DECK = []
POSSIBLE_PLAYER_CARD_VALUES = []
PARTICIPANTS = Hash.new { |hash, key| hash[key] = {} }

display_welcome

loop do
  rounds_won = { player: 0, dealer: 0 }
  round_winner = nil

  loop do
    initialize_participants
    new_deck!

    until round_ended?
      PARTICIPANTS.each do |participant, attributes|
        until stop_giving_cards?(participant, attributes)
          display_cards(participant) if show_hidden_card?(participant)
          attributes[:chose_stay] = stay?(participant)
          next if attributes[:chose_stay]
          new_cards = give_cards!(attributes)
          update_cards_and_hand_points!(participant, attributes, new_cards)

          display_cards(participant)
        end
      end
    end

    display_cards
    round_winner = find_round_winner
    update_rounds_won(round_winner, rounds_won)
    display_scores(rounds_won)

    break if game_ended?(rounds_won)

    display_winner(round_winner, "won_this_round")
    press_enter_to_continue("next_round")
  end

  display_winner(round_winner, "won_the_match")
  break unless play_again?
end

prompt("goodbye")
