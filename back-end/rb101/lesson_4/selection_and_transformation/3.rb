def double_odd_indices_numbers(numbers)
  doubled_numbers = []
  index = 0

  loop do
    break if index == numbers.size

    current_number = numbers[index]
    current_number *= 2 if index.odd?
    doubled_numbers << current_number

    index += 1
  end

  doubled_numbers
end

my_numbers = [1, 4, 3, 7, 2, 6]
double_odd_indices_numbers(my_numbers) # => [1, 8, 3, 14, 2, 12]
