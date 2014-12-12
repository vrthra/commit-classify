#!/scratch/gopinath/usr/bin/ruby
require 'classifier'
lsi = Classifier::LSI.new :auto_rebuild => false
i = 0
#$f = File.open('time','w+')
#$last = Time.now
#def update()
#  $now = Time.now
#  $f.puts "#{$now - $last}"
#  $f.flush
#  $last = $now
#end
File.open('./1000.bug').readlines.each do |f|
  f.chomp!
  STDERR.puts i.to_s, "b:",f
  i += 1
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
  lsi.add_item text.join(" "), :bug
  #update()
  #m.system.train_bug(text.join(" "))
end
File.open('./1000.feature').readlines.each do |f|
  f.chomp!
  STDERR.puts i.to_s, "f:",f
  i += 1
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
  lsi.add_item text.join(" "), :feature
  #update()
  #m.system.train_feature(text.join(" "))
end
#$f.close

lsi.build_index
total = 0
bug = 0
feature = 0

File.open('classify/lsi.dump', 'w') do |f|
  Marshal.dump(lsi, f)
end
#lsi_m = Marshal.load lsi_md
#m.take_snapshot
puts "--------Bug-----------"
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
  #puts m.system.classify(text.join(" "))
  v = lsi.classify(text.join(" "))
  case v.to_s.downcase
  when /bug/
    bug += 1
  end
  total += 1
end
puts "#{(bug.to_f * 100  / total.to_f)}"
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
  v = lsi.classify(text.join(" "))
  case v.to_s.downcase
  when /feature/
    feature += 1
  end
  total += 1
  #puts m.system.classify(text.join(" "))
end
puts "#{(feature.to_f * 100  / total.to_f)}"
