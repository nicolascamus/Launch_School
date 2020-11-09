ary = ['Dave', 7, 'Miranda', 3, 'Jason', 11]
new_ary = []
ary.each do |item|
           if item.class == String
            new_ary << [item]
           else
            new_ary.last << item
           end
         end

p new_ary




