def multiply(numbers_array, multiplier)
  doubled_numbers = []
  index = 0

  loop do
    break if index == numbers_array.size

    current_number = numbers_array[index]
    doubled_numbers << current_number * multiplier

    index += 1
  end

  doubled_numbers
end

my_numbers = [1, 4, 3, 7, 2, 6]
multiply(my_numbers, 3) # => [3, 12, 9, 21, 6, 18]
