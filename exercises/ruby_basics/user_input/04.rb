answer = nil

loop do
  puts "Do you want me to print something? (y/n): "
  answer = gets.chomp.downcase
  break puts "input received" if %w(y , n).include?(answer)
  puts "invalid input"
end

puts "Something" if answer == "y"
