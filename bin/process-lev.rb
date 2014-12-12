#!/scratch/gopinath/usr/bin/ruby

require 'find'
require 'yaml'

map = {}

Find.find('changes/') do |file|
  next if file !~ /\.lev$/
  File.readlines(file).map(&:chomp).each do |line|
    case line
    when /@ (.*)\t<>\t(.*)/
      map[$1.strip] ||= []
      map[$1.strip] << $2.strip
    end
  end
end

puts "total = #{map.keys.length}"

punct = 0
swap = 0
mymap = {}
map.keys.each do |k|
  next if k.split(/ +/).length > 1
  (0..map[k].length).each do
    puts k.strip
  end
  #if k.strip =~ /^[^a-zA-Z0-9]+$/
  #  punct += 1
  #else if k.split(/ +/).sort == map[k].split(/ +/).sort
  #end
end
