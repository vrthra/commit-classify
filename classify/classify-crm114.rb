#!/scratch/gopinath/usr/bin/ruby
#require 'rubygems'
require 'classifier'
require 'crm114'
classifier = Classifier::CRM114.new([:bug, :feature])

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
  classifier.train!(:bug, text.join(" "))
  #update()
  #m.system.train_bug(text.join(" "))
end
btotal = 0
ftotal = 0
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
  classifier.train!(:feature, text.join(" "))
  #lsi.add_item text.join(" "), :feature
  #update()
  #m.system.train_feature(text.join(" "))
end
if false
encoding_options = {
  :invalid           => :replace,  # Replace invalid byte sequences
  :undef             => :replace,  # Replace anything not defined in ASCII
  :replace           => '',        # Use a blank for those replacements
  :universal_newline => true       # Always break lines with \n
}
File.open('./all').readlines.each do |f|
  f.chomp!
  text = []
  File.open(f).readlines.each do |l|
    l = l.encode Encoding.find('ASCII'), encoding_options
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
  case classifier.classify(text.join(" "))
  when /bug/
    puts f
  end
end
exit(0)
end

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
  case classifier.classify(text.join(" "))[0]
  when /bug/
    bug += 1
  end
  btotal +=1
end
puts "#{(bug.to_f * 100  / btotal)}"
puts "--------Feature-----------"
ftotal  = 0
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
  case classifier.classify(text.join(" "))[0]
  when /feature/
    feature += 1
  end
  ftotal  += 1
end
puts "#{(feature.to_f * 100  / ftotal)}"
puts "#{(bug.to_f + feature) * 100 / (ftotal + btotal)}"
