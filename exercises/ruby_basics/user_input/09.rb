
loop do
  puts "How many output lines do you want? Enter a number >= 3 (Q to quit):"
  input = gets.chomp
  break puts "Goodbye!" if input.upcase == "Q"

  lines = input.to_i
  next puts "That's not enough lines" if lines < 3

  while lines > 0
    puts "Launch School is the best!"
    lines -= 1
  end
end
