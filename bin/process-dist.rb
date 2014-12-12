#!/bin/env ruby
# Clean up the distribution. of *.dist files.
$g = {}
$g.default = 0
STDIN.each do |l|
  l.chomp!
  s = l.split(/\s+/)
  case s[1]
  when /arithmetic_negation/
    $g['negation'] += s[0].to_i
  when /logical_negation/
    $g['negation'] += s[0].to_i
  when /bitwise_negation/
    $g['negation'] += s[0].to_i
  when /(string-string|numeric-numeric|char-char)/
    $g['const change'] += s[0].to_i
  when /(.*-string|.*-numeric|.*-char)/
    $g['const change'] += s[0].to_i
  when /(string-.*|numeric-.*|char-.*)/
    $g['const change'] += s[0].to_i
  else
    $g[s[1]] = s[0]
  end
end
$g.each do |k,v|
  puts "#{v} #{k}"
end
