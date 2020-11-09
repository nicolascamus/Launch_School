# Our predict_weather method should output a message indicating whether a sunny
# or cloudy day lies ahead. However, the output is the same every time the
# method is invoked. Why? Fix the code so that it behaves as expected

# because it is selecting a string instead of a boolean vlaue, and strings
# allways evaluate to true

def predict_weather
  sunshine = ['true', 'false'].sample

  if sunshine
    puts "Today's weather will be sunny!"
  else
    puts "Today's weather will be cloudy!"
  end
end

predict_weather

# fixed:
def predict_weather
  sunshine = [true, false].sample

  if sunshine
    puts "Today's weather will be sunny!"
  else
    puts "Today's weather will be cloudy!"
  end
end

predict_weather
