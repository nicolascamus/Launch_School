contact_data = [["joe@email.com", "123 Main st.", "555-123-4567"],
            ["sally@email.com", "404 Not Found Dr.", "123-234-3454"]]

contacts = {"Joe Smith" => {}, "Sally Johnson" => {}}


contacts.each_with_index do |key_value, index|
  key = key_value[0]
  data = contact_data[index]
  contacts[key] = {email: data[0], address: data[1], phone: data[2]}
end

p contacts
