# Given this nested Hash:
munsters = {
  "Herman" => { "age" => 32, "gender" => "male" },
  "Lily" => { "age" => 30, "gender" => "female" },
  "Grandpa" => { "age" => 402, "gender" => "male" },
  "Eddie" => { "age" => 10, "gender" => "male" },
  "Marilyn" => { "age" => 23, "gender" => "female"}
}
# figure out the total age of just the male members of the family.

munsters.values.inject(0) do |sum, info_hash|
  if info_hash['gender'] == 'male'
    sum + info_hash['age']
  else
    sum + 0
  end
end

# or:
munsters.map { |_, info| info['gender'] == 'male' ? info['age'] : 0 }.sum
