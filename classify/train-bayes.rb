#!/scratch/gopinath/usr/bin/ruby
require 'classifier'
require 'madeleine'
m = SnapshotMadeleine.new("bayes_data"){Classifier::Bayes.new('bug', 'feature')}
#lsi = Classifier::LSI.new
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
  #lsi.add_item text.join(" "), :bug
  m.system.train_bug(text.join(" "))
end
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
  #lsi.add_item text.join(" "), :feature
  m.system.train_feature(text.join(" "))
end

#File.open('lsi.dump') do |f|
#  Marshal.dump(lsi, f)
#end
#lsi_m = Marshal.load lsi_md
m.take_snapshot

