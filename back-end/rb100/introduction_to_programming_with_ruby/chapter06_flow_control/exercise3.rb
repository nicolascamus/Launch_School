=begin
If we follow the instructions to the letter, negative numbers and floating-point
values between 50 and 51 should not be categorized.

Instructions:
Write a program that takes a number from the user between 0 and 100 and reports
back whether the number is between 0 and 50, 51 and 100, or above 100.
=end

print "Please, type a number between 0 and 100: "
number = gets.chomp.to_f

case number
when 0..50 then puts "Number between 0 and 50"
when 51..100 then puts "Number between 51 and 100"
when 100..Float::INFINITY then puts "Number over 100"
else puts "Uncategorized number"
end
