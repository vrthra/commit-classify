#!/scratch/gopinath/usr/bin/ruby
require 'differ'

original = "Epic lolcat fail!"
current  = "Epic wolfman fail!"

puts Differ.diff_by_char(current, original)
