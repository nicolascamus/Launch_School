loop do
  puts "How many output lines do you want? Enter a number >= 3:"
  lines = gets.chomp.to_i
  next puts "please enter a number >= 3" if lines < 3
  lines.times {puts "Launch School is the best!"}
  break
end
