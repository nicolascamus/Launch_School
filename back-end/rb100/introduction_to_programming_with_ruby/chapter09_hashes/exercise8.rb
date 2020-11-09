  words =  ['demo', 'none', 'tied', 'evil', 'dome', 'mode', 'live',
    'fowl', 'veil', 'wolf', 'diet', 'vile', 'edit', 'tide',
    'flow', 'neon']

anagrams = {}

words.each do |word|
  key = word.chars.sort.to_s

  anagrams.has_key?(key) ? anagrams[key] << word : anagrams[key] = [word]
end

anagrams.each { |_key, value| p value }

