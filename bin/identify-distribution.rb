#!/usr/bin/env ruby
$g = {}
$g.default = 0
def identify_type(str)
  s = str.strip.gsub(/ *,$/,'').gsub(/ *;/,'').gsub(/\(/,'').gsub(/\)/,'').gsub(/\[/,'').gsub(/\]/,'').gsub(/\{/,'').gsub(/\}/,'').gsub(/^[&*]+/,'').gsub(/->/,'.')
  case s.strip
  when /^!.*$/
    return :logical_negation
  when /^-.*$/
    return :arithmetic_negation
  when /^~.*$/
    return :bitwise_negation
  when /^[a-zA-Z_][a-zA-Z0-9._]*$/
    return :var
  when /^".*"$/
    return :string
  when /^'.*'$/
    return :char
  when /^[0-9EexXUL.-]+$/
    return :numeric
  when /^-?0[Xx][0-9AaBbCcDdEeFf]+$/
    return :numeric
  when /^(true|false)$/
    return :bool
  when /^\+\+/
    return :unary_px
  when /\+\+$/
    return :unary_xp
  when /^--$/
    return :unary_mx
  when /--$/
    return :unary_xm
  when /^[<>+*%\/-=]+$/
    return :std_op
  when /^null$/
    return :null
  when /^ *$/
    return :empty
  else
    return :unknown
  end
end

#def identify_type(str)
#  s = str.strip.gsub(/ *,$/,'').gsub(/ *;/,'').gsub(/\(/,'').gsub(/\)/,'').gsub(/\[/,'').gsub(/\]/,'').gsub(/\{/,'').gsub(/\}/,'').gsub(/^[&*]+/,'').gsub(/->/,'.')
#  case s
#  when /^!.*$/
#    return :logical_negation
#  when /^[a-zA-Z_][a-zA-Z0-9._]*$/
#    return :var
#  when /^".*"$/
#    return :string
#  when /^[0-9EexXL.-]+$/
#    return :numeric
#  when /^-?0[Xx][0-9AaBbCcDdEeFf]+$/
#    return :numeric
#  when /^(true|false)$/
#    return :bool
#  when /[+-]+$/
#    return :unary_stmt
#  when /^[<>+*%\/-=]+$/
#    return :std_op
#  when /^null$/
#    return :null
#  when /^ *$/
#    return :empty
#  else
#    return s
#  end
#end

def clean(v)
  return v.gsub(/ /,'').gsub(/\(/,'').gsub(/\)/,'').gsub(/"/,'')
end

STDIN.each do |l|
  s = l.split(/\t/).map{|x| x.strip}
  ['-', '!', '~', '\+\+', '--'].each do |x|
    if s[0] =~ /^#{x}/ and s[1] =~ /^#{x}/
      s[0] = s[0][1..-1].strip
      s[1] = s[1][1..-1].strip
    end
    if s[0] =~ /#{x}$/ and s[1] =~ /#{x}$/
      s[0] = s[0][0..-2].strip
      s[1] = s[1][0..-2].strip
    end
  end
  s = s.map{|x| identify_type(x)}.sort
  $g["#{s[0]}-#{s[1]}"] += 1
  #puts "#{s[0]}\t<>\t#{s[1]}"
end
$g.keys.each do |k|
  puts "#{$g[k]} #{k}"
end
