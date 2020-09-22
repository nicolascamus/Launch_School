def countdown(positive_integer)
  puts positive_integer

  countdown(positive_integer - 1) if positive_integer > 0
end


countdown(15)



