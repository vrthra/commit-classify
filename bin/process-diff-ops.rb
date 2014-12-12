#!/scratch/gopinath/usr/bin/ruby
require 'find'
require 'differ'
# For each project do, for each file, do, for each patch do.
# input is *.diff
#
# We process each diff by spliting it into chunks based on the
# chunk split line, and joins each old and new chunk into a single
# line.
# Next, the two lines are diffed, and the diffs between them are
# written to *.lev

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
