def select_fruit(hash)
  keys = hash.keys
  selected_fruits = {}
  counter = 0

  loop do
    break if keys.length == counter

    current_key = keys[counter]
    current_value = hash[current_key]

    selected_fruits[current_key] = current_value if current_value == 'Fruit'

    counter += 1
  end

  selected_fruits
end

produce = {
  'apple' => 'Fruit',
  'carrot' => 'Vegetable',
  'pear' => 'Fruit',
  'broccoli' => 'Vegetable'
}

select_fruit(produce) # => {"apple"=>"Fruit", "pear"=>"Fruit"}
