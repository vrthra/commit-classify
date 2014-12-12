#!/usr/bin/env ruby

$g = {}
$g.default = 0
$unknown = []

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
  when /^-?[0-9EeuUFfLlxX.-]+$/
    return :numeric
  when /^-?0[Xx][0-9AaBbCcDdEeFf]+$/
    return :numeric
  when /^(true|false)$/
    return :bool
  when /^(TRUE|FALSE)$/
    return :bool
  when /^\+\+/
    return :unary_px
  when /\+\+$/
    return :unary_xp
  when /^--$/
    return :unary_mx
  when /--$/
    return :unary_xm
  when /^[<>+*%\/-=!]+$/
    return :std_op
  when /^[-+*\/%&|^<>]+=$/
    return :std_assign
  when /^null$/
    return :null
  when /^NULL$/
    return :NULL
  when /^ *$/
    return :empty
  else
    return s
  end
end


def xidentify_type(str)
  case str.strip.gsub(/,$/,'').gsub(/\(/,'').gsub(/\)/,'').gsub(/\[/,'').gsub(/\]/,'').gsub(/\{/,'').gsub(/\}/,'')
  when /^!.*$/
    return :logical_negation
  when /^[a-zA-Z][a-zA-Z0-9._]*$/
    return :function
  when /^".*"$/
    return :string
  when /^[0-9Ee.-]+$/
    return :numeric
  when /^(true|false)$/
    return :bool
  when /^[<>+*%\/-]+$/
    return :std_op
  when /^null$/
    return :null
  when /^ *$/
    return :empty
  else
    return :unknown
  end
end

def clean(v)
  return v.gsub(/ /,'').gsub(/\(/,'').gsub(/\)/,'').gsub(/"/,'')
end

# For now, we only look at changes where either the originating or the ending
# changes were one single word. (competant programmer/first order changes)
def conditionals_boundary_mutator(v1,v2)
  [v1,v2].each do |v|
    return true if v =~ /^(<|<=|>|>=)$/
  end
  return false
end

def negate_conditionals_mutator(v1,v2)
  [v1,v2].each do |v|
    return true if v =~ /^(==|!=|<=|>=|<|>)$/
  end
  return false
end

def math_mutator(v1,v2)
  [v1,v2].each do |v|
    return true if v =~ /^(\+|-|\*|\/|%|\&|\||\^|<<|>>|>>>)$/
  end
  return false
end

def increments_mutator(v1,v2)
  return true if v1 =~ /^\+\+/ and v2 =~ /^--/
  return true if v1 =~ /^--/ and v2 =~ /^\+\+/
  return true if v1 =~ /\+\+$/ and v2 =~ /--$/
  return true if v1 =~ /--$/ and v2 =~ /\+\+$/
  return true if v1 =~ /^\+\+/ and v2 =~ /\+\+$/
  return true if v1 =~ /^--/ and v2 =~ /--$/
  return false
end

def invert_negatives_mutator(v1,v2)
  return true if v1 =~ /^[-]/ and v2 =~ /[^-]$/
  return true if v1 =~ /^[^-]/ and v2 =~ /[-]$/
  return false
end

def inline_constant_mutator(v1,v2)
  x1 = identify_type(v1)
  x2 = identify_type(v2)
  return true if x1 == :bool and x2 == :bool
  return true if x1 == :string and x2 == :string
  return true if x1 == :numeric and x2 == :numeric
  return false
end

def constructor_call_mutator(v1,v2)
  return true if v1 =~ /^null$/ or v2 =~ /^null$$/
  return false
end


def process_replacement(filename, v1, v2)
  $g[:total] += 1
  if conditionals_boundary_mutator(v1,v2)
    $g[:conditionals_mutator] += 1
    #STDERR.puts "#{v1} <>#{v2}"
    return
  end
  if negate_conditionals_mutator(v1,v2)
    $g[:negate_conditionals_mutator] += 1
    return
  end
  if math_mutator(v1,v2)
    $g[:math_mutator] += 1
    return
  end
  if increments_mutator(v1,v2)
    $g[:increments_mutator] += 1
    return
  end
  if invert_negatives_mutator(v1,v2)
    $g[:invert_negatives_mutator] += 1
    return
  end
  if inline_constant_mutator(v1,v2)
    $g[:inline_constant_mutator] += 1
    return
  end
  if constructor_call_mutator(v1,v2)
    $g[:constructor_call_mutator] += 1
    return
  end


  $g[:unclassified] += 1
end

def process_add(filename,l)
end
def process_del(filename,l)
end

def process_change(filename,l)
  # Do not do it if we have more than one change per chunk.
  x = l.scan(/<@</).length
  return if x > 1

  case l
  when /<@</
    matches = l.scan(/<@<.*?>@>/)
    matches.each do |match|
      m=match.gsub(/<@</,'').gsub(/>@>/,'')
      val = m.split(/\t<>\t/)
      v1 = val[0].gsub(/\t/,' ').strip
      v2 = val[1].gsub(/\t/,' ').strip
      l1 = v1.gsub(/[\[\]()]/,' ').strip.split(/ +/).length
      l2 = v2.gsub(/[\[\]()]/,' ').strip.split(/ +/).length
      # we ignore the change if both parts are larger than 1
      if l1 > 1 || l2 > 1
        return
      end
      if clean(v1) == clean(v2)
        return
      end
      # Strip prefix/suffix common in both.
      ['\+\+', '--', '*', '-', '~', '!'].each do |op|
        if v1.start_with?(op) && v2.start_with?(op)
          v1 = v1[op.length..-1].strip
          v2 = v2[op.length..-1].strip
        end
        if v1.end_with?(op) && v2.end_with?(op)
          v1 = v1[0..-(op.length+1)].strip
          v2 = v2[0..-(op.length+1)].strip
        end
      end
      process_replacement(filename, v1, v2)
    end
  end
end

def process_file(filename)
  lines = File.readlines(filename)
  # Return if there is more than one chunk per file.
  return if (lines.count{|s| s =~ /<@</ } > 1)
  lines.each do |l|
    l.chomp!
    case l
    when /^ *$/
      # skip
    when /^#/
      #skip
    else
        process_change(filename, l[2..-1])
        process_add(filename, l[2..-1])
        process_del(filename, l[2..-1])
    end
  end
end

STDIN.each do |l|
  process_file(l.chomp)
end

$g.each do |k,v|
  puts "#{k} #{v}"
end
STDOUT.flush
File.open('unknown.txt', 'w') do |f|
  $unknown.each do |k|
    f.puts "#{k[0]}\t#{k[1]}"
  end
end
File.open('unknownx.txt', 'w') do |f|
  $unknown.each do |k|
    f.puts "#{identify_type(k[0])}\t<>\t#{identify_type(k[1])}"
  end
end

