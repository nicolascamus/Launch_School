VALID_CHOICES = %w[rock paper scissors]

def first_player_wins?(first_player, second_player)
  (first_player == 'rock' && second_player == 'scissors') ||
    (first_player == 'paper' && second_player == 'rock') ||
    (first_player == 'scissors' && second_player == 'paper')
end

def display_results(player, computer)
  if first_player_wins?(player, computer)
    prompt("You won!")
  elsif computer == player
    prompt("It's a tie!")
  else
    prompt("Computer won!")
  end
end

def prompt(message)
  puts "=> #{message}"
end

loop do
  choice = ''
  loop do
    prompt("Choose one: #{VALID_CHOICES.join(', ')}")
    choice = gets.chomp

    if VALID_CHOICES.include?(choice)
      break
    else
      prompt("That's not a valid choice!")
    end
  end

  computer_choice = VALID_CHOICES.sample

  prompt("You chose: #{choice}; Computer chose: #{computer_choice}")

  display_results(choice, computer_choice)

  prompt("Do you want to play again?")
  answer = gets.chomp
  break unless answer.downcase.start_with?('y')
end

prompt("Thank you for playing. Goodbye!")
