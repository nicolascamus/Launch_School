# How could the unnecessary duplication in the following method be removed?

#           def color_valid(color)
#             if color == "blue" || color == "green"
#               true
#             else
#               false
#             end
#           end

def color_valid(color)
  ["blue", "green"].include?(color)
end
