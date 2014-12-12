#!/scratch/gopinath/usr/bin/ruby
require 'find'
require 'differ'
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
    begin
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
    rescue
    end
  end
  patches << patch if patch
  patches
end

Find.find('changes/') do |file|
  next if file !~ /\.diff$/
  next if File.exists?("#{file}.lev")
  patches = parse_file(file)
  puts "#{file}.lev"
  File.open("#{file}.lev", 'w') do |f|
    patches.each do |p|
      f.puts "############ #{p[:name]}"
      ns =  p[:new].join(' ')
      os =  p[:old].join(' ')
      if ns.length < 1024 and os.length < 1024
        Differ.diff_by_token(ns, os).format_as(:raw).each do |c|
          case c.class.to_s
          when /Differ::Change/
            f.puts c
          end
        end
        f.puts ""
      end
    end
  end
end
