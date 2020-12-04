flintstones = ["Fred", "Barney", "Wilma", "Betty", "Pebbles", "BamBam"]
# turn this array into a hash where the names are the keys and the
# values are the positions in the array.

flintstones_hash = {}
flintstones.each_with_index { |name, index| flintstones_hash[name] = index }
