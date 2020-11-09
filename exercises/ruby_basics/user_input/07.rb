PASSWORD = "User15-3"
USERNAME = "Wachipioli"

loop do
  print ">> Enter username: "
  username_try = gets.chomp

  print ">> Enter password: "
  password_try = gets.chomp

  break if username_try == USERNAME && password_try == PASSWORD
  puts "Invalid credentials, try again"
end

puts "Hello!"
