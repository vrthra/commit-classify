#!/scratch/gopinath/usr/bin/ruby
require 'classifier'
require 'madeleine'
m = SnapshotMadeleine.new("bayes_data"){Classifier::Bayes.new('bug','feature')}

puts "--------Bug-----------"
bug = 0
feature = 0
total = 0
File.open('./v.bug').readlines.each do |f|
  f.chomp!
  text = []
  File.open(f).readlines.each do |l|
    l.chomp!
    case l
    when /^(commit|Author|Date)/
      next
    when /^diff/
      break
    else
      text << l
    end
  end
  x = m.system.classify(text.join(" "))
  case x
  when /Bug/
    bug += 1
  end
  total += 1
  #puts lsi.classify(text.join(" "))
end
puts "#{(bug.to_f / total.to_f)}"
total = 0
puts "--------Feature-----------"
File.open('./v.feature').readlines.each do |f|
  f.chomp!
  text = []
  File.open(f).readlines.each do |l|
    l.chomp!
    case l
    when /^(commit|Author|Date)/
      next
    when /^diff/
      break
    else
      text << l
    end
  end
  x = m.system.classify(text.join(" "))
  case x
  when /Feature/
    feature += 1
  else
    #STDERR.puts f
  end
  total += 1
end
puts "#{(feature.to_f / total.to_f)}"
