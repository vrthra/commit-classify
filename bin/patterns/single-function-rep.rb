#!/usr/bin/ruby
# The replacement could be one function with another,
# one function with a constant literal string/num/bool
# one function with an expression
# and the reverse.
example = <<EOF
51,52c50,51
<                 Just _ -> parseError "path given after -optP-include is empty!"
<                 _ -> parseError "missing -optP after -optP-include"
---
>                 Just _ -> fatal "path given after -optP-include is empty!"
>                 _ -> fatal "missing -optP after -optP-include"
128,130d126
@ fatal         <>       parseError
EOF



$global_data = {}
$global_data['function to function']  = 0
$global_data['string to string']  = 0
$global_data['numeric to numeric']   = 0
$global_data['bool to bool']   = 0

$global_data['replace fn']  = 0
$global_data['replace str']  = 0
$global_data['replace num']  = 0
$global_data['replace bool']  = 0

$global_data['function to string'] = 0
$global_data['function to numeric']   = 0
$global_data['function to bool']   = 0

$global_data['unclassified']          = 0
$global_data['lazy strict']          = 0

$global_data['std op']   = 0
$global_data['fn op']   = 0
$global_data['logical negation'] = 0
$global_data['empty arr'] = 0
$global_data['partial fn'] = 0
$global_data['empty'] = 0

def identify_type(str)
  case str.strip.gsub(/,$/,'').gsub(/\(/,'').gsub(/\)/,'').gsub(/\[/,'').gsub(/\]/,'').gsub(/\{/,'').gsub(/\}/,'')
  when /^[a-zA-Z][^ ]*$/
    return :single_function
  when /^".*"$/
    return :string_literal
  when /^[0-9Ee.-]+$/
    return :numeric_literal
  when /^(True|False)$/
    return :bool_literal
  when /^[^0-9A-Za-z]+$/
    return :std_op
  when /^`.*`$/
    return :fn_op
  when /^\[ *\]$/
    return :empty_arr
  when /^[^0-9A-Za-z]+ *[0-9A-Za-z]+$/
    return :fn_partial
  when /^ *$/
    return :empty
  else
    return :unknown
  end
end


def process_replacement(filename, one, two)
  cone = clean(one)
  ctwo = clean(two)
  if cone =~ /^(import|instance|qualified|type|data)/ or ctwo =~ /^(import|instance|qualified|type|data)/
    return
  end
  if (cone.gsub(/!/,'') == ctwo.gsub(/!/,''))
    $global_data['lazy strict'] += 1
    return
  end
  if cone.gsub(/not/,'') == ctwo.gsub(/not/,'')
    $global_data['logical negation'] += 1
  end

  case identify_type(one)
  when :single_function
    case identify_type(two)
    when :single_function
      $global_data['function to function'] += 1
    when :string_literal
      $global_data['function to string'] += 1
    when :numeric_literal
      $global_data['function to numeric'] += 1
    when :bool_literal
      $global_data['function to bool'] += 1
    else
      $global_data['replace fn'] += 1
    end
  when :string_literal
    case identify_type(two)
    when :single_function
      $global_data['function to string'] += 1
    when :string_literal
      $global_data['string to string'] += 1
    else
      $global_data['replace str'] += 1
    end
  when :numeric_literal
    case identify_type(two)
    when :single_function
      $global_data['function to numeric'] += 1
    when :numeric_literal
      $global_data['numeric to numeric'] += 1
    else
      $global_data['replace num'] += 1
    end
  when :bool_literal
    case identify_type(two)
    when :single_function
      $global_data['function to bool'] += 1
    when :bool_literal
      $global_data['bool to bool'] += 1
    else
      $global_data['replace bool'] += 1
    end
  when :std_op
      $global_data['std op'] += 1
  when :fn_op
      $global_data['fn op'] += 1
  when :empty_arr
      $global_data['empty arr'] += 1
  when :fn_partial
      $global_data['partial fn'] += 1
  when :empty
      $global_data['empty'] += 1
  else
    case identify_type(two)
    when :single_function
      $global_data['replace fn'] += 1
    when :string_literal
      $global_data['replace str'] += 1
    when :numeric_literal
      $global_data['replace num'] += 1
    when :bool_literal
      $global_data['replace bool'] += 1
    when :std_op
        $global_data['std op'] += 1
    when :fn_op
        $global_data['fn op'] += 1
    when :empty_arr
        $global_data['empty arr'] += 1
    when :fn_partial
        $global_data['partial fn'] += 1
    when :empty
        $global_data['empty'] += 1
    else
      $global_data['unclassified'] += 1
      #if one.split().length < 2 || two.split().length < 2
        STDERR.puts "> #{filename}"
        STDERR.puts "     #{one}\t<-\t#{two}"
        STDERR.puts ""
      #end
    end
  end

end

def clean(v)
  return v.gsub(/ /,'').gsub(/\(/,'').gsub(/\)/,'').gsub(/"/,'')
end

def process_change_line(filename,l)
    case l
    when /\{-/
      return
    when /@ (.*)\t<>\t(.*)/
      v1 = $1.strip
      v2 = $2.strip
      if clean(v1) == clean(v2)
        return
      end
      process_replacement(filename, v1, v2)
    end
end

def process_file(filename)
  lines = File.readlines(filename)
  lines.each do |l|
    l.chomp!
    case l
    when
      /^@/
        process_change_line(filename, l)
    else
    end
  end
end

STDIN.readlines.each do |l|
  l.chomp!
  process_file(l)
end

$global_data.each do |k,v|
  puts "#{k} = #{v}"
end
