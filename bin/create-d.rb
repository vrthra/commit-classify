#!/scratch/gopinath/usr/bin/ruby
$:.unshift File.expand_path("lib")
require 'find'
require 'differ'
# For each project do, for each file, do, for each patch do.
# input is *.diff
#
# We process each diff by spliting it into chunks based on the
# chunk split line, and joins each old and new chunk into a single
# line.
# Next, the two lines are diffed, and the diffs + const are
# written to *.d

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

i = 0
Find.find('changes/') do |file|
  next if file !~ /\.diff$/
  next if File.exists?("#{file}.d")
  patches = parse_file(file)
  puts "#{file}.d"
  File.open("#{file}.d", 'w') do |f|
    patches.each do |p|
      f.puts "############ #{p[:name]}"
      ns =  p[:new].join("\n").gsub(/[(]/,' ( ').gsub(/[)]/,' ) ').gsub(/\[/,' [ ').gsub(/\]/,' ] ').gsub(/ +/,' ')
      os =  p[:old].join("\n").gsub(/[(]/,' ( ').gsub(/[)]/,' ) ').gsub(/\[/,' [ ').gsub(/\]/,' ] ').gsub(/ +/,' ')
      if ns.length < 1024 and os.length < 1024
        d = Differ.diff_by_token(ns, os)
        f.puts d.to_s.gsub(/\n/,"\t")
        f.puts ""
      end
    end
  end
  #i += 1
  #exit(1) if i > 100
end
