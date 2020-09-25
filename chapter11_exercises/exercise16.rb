contact_data = [["joe@email.com", "123 Main st.", "555-123-4567"],
            ["sally@email.com", "404 Not Found Dr.", "123-234-3454"]]

contacts = {"Joe Smith" => {}, "Sally Johnson" => {}}

tags = [:email, :address, :phone]

contacts.each_with_index do |(_, hash), index|
  data = contact_data[index]
  data.each_with_index { |item, data_index| hash[tags[data_index]] = item }
end

p contacts
