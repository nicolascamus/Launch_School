# In the age hash:
ages = { "Herman" => 32, "Lily" => 30, "Grandpa" => 402, "Eddie" => 10 }
# remove people with age 100 and greater.

# Non-destructively:
filtered_ages = ages.reject { |_, age| age >= 100 }
p filtered_ages
p ages

# Destructively:
ages.delete_if { |_, age| age >= 100 }
p ages
