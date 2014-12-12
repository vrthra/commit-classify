#!/scratch/gopinath/usr/bin/ruby

require 'find'
require 'yaml'

map = {}

Find.find('changes/') do |file|
  next if file !~ /\.lev$/
  File.readlines(file).map(&:chomp).each do |line|
    case line
    when /@ (.*)\t<>\t(.*)/
      map[$1.strip] ||= 0
      map[$1.strip] += 1
    end
  end
end

#puts "total = #{map.keys.length}"

punct = 0
swap = 0
changelen = {}
map.keys.each do |k|
  l = k.split(/ +/).length
  changelen[l] ||= 0
  changelen[l] += map[k]
end

puts "changelength,count"
changelen.keys.sort.each do |k|
  puts "#{k},#{changelen[k]}"
end
