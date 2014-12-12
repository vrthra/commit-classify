#!/usr/bin/ruby

(0..9).each do |i|
  puts "mv all.#{i} all.all.#{i}"
  #puts "mv all.bug.#{i} all.bug.#{i}"
  puts "mv all.bug.small.#{i} small.bug.#{i}"
  puts "mv all.nobug.#{i} all.bug.#{i}"
  puts "mv all.nobug.small.#{i} small.nobug.#{i}"
  puts "mv all.small.#{i} small.all.#{i}"
end

__END__
all.0
all.1
all.2
all.3
all.4
all.5
all.6
all.7
all.8
all.9
all.bug.0
all.bug.1
all.bug.2
all.bug.3
all.bug.4
all.bug.5
all.bug.6
all.bug.7
all.bug.8
all.bug.9
all.bug.small.0
all.bug.small.1
all.bug.small.2
all.bug.small.3
all.bug.small.4
all.bug.small.5
all.bug.small.6
all.bug.small.7
all.bug.small.8
all.bug.small.9
all.nobug.0
all.nobug.1
all.nobug.2
all.nobug.3
all.nobug.4
all.nobug.5
all.nobug.6
all.nobug.7
all.nobug.8
all.nobug.9
all.nobug.small.0
all.nobug.small.1
all.nobug.small.2
all.nobug.small.3
all.nobug.small.4
all.nobug.small.5
all.nobug.small.6
all.nobug.small.7
all.nobug.small.8
all.nobug.small.9
all.small.0
all.small.1
all.small.2
all.small.3
all.small.4
all.small.5
all.small.6
all.small.7
all.small.8
all.small.9
