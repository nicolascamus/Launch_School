hash1 = {a: 1, b: 2, c: 3}
hash2 = {d: 4, e: 5, f: 18}

=begin
The merge method returns a new hash and does not mutate neither the caller nor
the hash passed as an argument.

=end

p hash1.merge(hash2)    # => {:a=>1, :b=>2, :c=>3, :d=>4, :e=>5, :f=>18}
p hash1                 # => {:a=>1, :b=>2, :c=>3}
p hash2                 # => {:d=>4, :e=>5, :f=>18}

=begin
The  merge!  method mutates the caller by adding to it the contents of the hash
passed as an argument and returns the modified hash. It does not mutate the
hash passed as an argument.
=end

p hash1.merge!(hash2)    # => {:a=>1, :b=>2, :c=>3, :d=>4, :e=>5, :f=>18}
p hash1                  # => {:a=>1, :b=>2, :c=>3, :d=>4, :e=>5, :f=>18}
p hash2                  # => {:d=>4, :e=>5, :f=>18}
