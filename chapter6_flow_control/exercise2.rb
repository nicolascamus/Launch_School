def over_10characters_to_all_caps(string = "no argument passed")
  string.length > 10 ? string.upcase : string
end

puts over_10characters_to_all_caps("unmodified")
puts over_10characters_to_all_caps("modified string")
