#!/scratch/gopinath/usr/bin/ruby
require 'bishop'
classifier = Bishop::Bayes.new { |probs,ignore| Bishop::robinson_fisher( probs, ignore ) }

i = 0
File.open('./1000.bug').readlines.each do |f|
  f.chomp!
  #STDERR.puts i.to_s, "b:",f
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
  classifier.train('bug', text.join(" "))
  #update()
  #m.system.train_bug(text.join(" "))
end
total = 0
bug = 0
feature = 0
File.open('./1000.feature').readlines.each do |f|
  f.chomp!
  #STDERR.puts i.to_s, "f:",f
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
  classifier.train('feature', text.join(" "))
  #lsi.add_item text.join(" "), :feature
  #update()
  #m.system.train_feature(text.join(" "))
end

def get_val(arr)
  v1,v2 = *arr
  if v1.nil?
    return :undef
  end
  if v2.nil?
    return v1[0]
  end
  if v1[1] >= v2[1]
    return 'bug'
  else
    return 'feature'
  end
end

#File.open('lsi.dump', 'w') do |f|
#  Marshal.dump(lsi, f)
#end
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
  #puts lsi.classify(text.join(" "))
  arr = classifier.guess(text.join(" "))
  v = get_val(arr)
  case v
  when /bug/
    bug += 1
  end
  total +=1
end
puts "#{(bug.to_f * 100  / total.to_f)}"
puts "--------Feature-----------"
total  = 0
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
  #puts lsi.classify(text.join(" "))
  #puts m.system.classify(text.join(" "))
  #puts classifier.classify(text.join(" "))
  arr = classifier.guess(text.join(" "))
  v = get_val(arr)
  case v
  when /feature/
    feature += 1
  end
  total  += 1
end
puts "#{(feature.to_f * 100  / total.to_f)}"
