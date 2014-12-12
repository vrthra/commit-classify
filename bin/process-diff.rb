#!/usr/bin/ruby
require 'find'
# For each project do, for each file, do, for each patch do.
# input is *.diff

def levenshtein(first, second)
  matrix = [(0..first.length).to_a]
  (1..second.length).each do |j|
    matrix << [j] + [0] * (first.length)
  end

  (1..second.length).each do |i|
    (1..first.length).each do |j|
      if first[j-1] == second[i-1]
        matrix[i][j] = matrix[i-1][j-1]
      else
        matrix[i][j] = [
          matrix[i-1][j],
          matrix[i][j-1],
          matrix[i-1][j-1],
        ].min + 1
      end
    end
  end
  return matrix.last.last
end

def edit_distance(o)
  new = o[:new]
  old = o[:old]
  newx = new.join(' ').split(/\s+|\b|"/)
  oldx = old.join(' ').split(/\s+|\b|"/)
  levenshtein(newx, oldx)
end

def parse_file(difffile)
  # split it by lines not starting with either < or > which are patches.
  patches = []
  patch = nil
  File.readlines(difffile).each do |line|
    line.chomp!
    case line
    when /^<(.*)/
      patch[:new] << $1
    when /^>(.*)/
      patch[:old] << $1
    when /^---/
    when /^\\ No newline at end of file/
    else
      patches << patch if patch
      name = line
      patch = {:name => name, :new => [], :old => []}
    end
  end
  patches << patch if patch
  patches
end

f = File.open('out.txt', 'w')
Find.find('changes/') do |file|
  next if file !~ /\.diff$/
  p file
  patches = parse_file(file)
  patches.each do |p|
    nl =  p[:new].join(' ').length
    ol =  p[:old].join(' ').length
    if nl < 1024 and ol < 1024
      puts ">#{nl + ol} #{file} :#{p[:name]}"
      f.puts "\"#{file}:#{p[:name]}\",#{nl},#{edit_distance(p)}"
    else
      puts "\t ignored: #{p[:name]}"
    end
    STDOUT.flush
  end
  f.flush
end
f.close
