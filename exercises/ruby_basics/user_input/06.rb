PASSWORD = "123456"

loop do
  print "Enter password: "
  break if gets.chomp == PASSWORD
  puts "Invalid password, try again"
end

puts "Hello!"
