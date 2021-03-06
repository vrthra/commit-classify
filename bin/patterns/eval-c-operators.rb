#!/usr/bin/env ruby
require 'set'
$unknown = []
$g = {}
$g.default = 0
$g_check_small = true
$g_check_bug = false

def identify_type(str)
  s = str.strip.gsub(/ *,$/,'').gsub(/ *;/,'').gsub(/\(/,'').gsub(/\)/,'').gsub(/\[/,'').gsub(/\]/,'').gsub(/\{/,'').gsub(/\}/,'').gsub(/->/,'.')
  s.gsub!(/^[*&]+([a-zA-Z]+)/, '\1')
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

def clean(v)
  return v.gsub(/ /,'').gsub(/\(/,'').gsub(/\)/,'').gsub(/"/,'')
end

# binary: + - * / %
# unary : + -
# shortcut ++ --
# AORB : replace binary arith ops with other binary arith ops
# AORU : replace unary arith
# AORS : replace shortcut arith with other unary ops
# AOIU : Insert basic unary arithmetic operators
# AOIS : Insert shortcut arithmetic operators
# AODU : Delete basic unary arithmetic
# AODS : delete shortcut arith
#
# relational: > > < <= == !=
# ROR: replace relational,
#   replace predicate with true/false
#
# conditional: && || & | ^
#       unary: !
# COR: replace binary conditional ops
# COI: Insert unary conditional operator
# COD : Delete unary conditional
#
# shift: >> << >>>>
# SOR: replace shift ops
#
# logical: & | | ^
#   unary: ~
# LOC: replace binary logical
# LOI: insert unary logical operator
# LOD: Delete unary logical operator
#
# assignment: += -= *= /= %= &= |= ^= <<= >>= >>>=
# ASR: replace shortcut assignment operators with others
#
# OO
# Encapsulation:
# AMC: Access modifier change
#
# Inheritance:
# IHD: Hiding var delete
# IHI: Hiding var insert
# IOD: Overriding method deletion
# IOP: overriding method calling position change
# IOR: Overriding method rename
# ISI: super keyword insertion
# ISD: super deletion
# IPC: explicit call to parent constructor
#
# Polymorphism:
# PNC: New method call with child class type
# PMD: Membeer var declaration with parent class type
# PPD: Parameter variable declaration with child class type
# PCI: Type cast operator insertion
# PCC: Cast type change
# PCD: Type cast operator deletion
# PRV: Refernce assignment with other comparable variable
# OMR: Overloading method contents replace
# OMD: Overloading method deletion
# OAC: Arguments of overloading method call change.
#
# Java specific:
# JTI: insert this
# JTD: delete this keyword
# JSI: static modifier insertion
# JSD: static modifier deletion
# JID: member variable initializatin deletion
# JDC: Java support default constructor creation
# EOA: Reference assignment and content assignment replacement
# EAM: Accessor method change
# EMM: Modifier method change


# For now, we only look at changes where either the originating or the ending
# changes were one single word. (competant programmer/first order changes)

def id_operator(v)
  case v
  when /^(\+|-|\*|\/|%)$/
    return :a
  when /^(\||&|^)$/
    return :b
  when /^(\|\||&&)$/
    return :l
  when /^(<<|>>)$/
    return :s
  when /^(<|>|<=|>=|==|!=)$/
    return :r
  end
  case v
  when /^(\+|-|\*|\/|%)=$/
    return :a
  when /^(\||&|^)=$/
    return :b
  when /^=$/
    return :e
  when /^(<<|>>)=$/
    return :s
  end
  case v
  when /^(\+\+)/
    return :P
  when /^(--)/
    return :M
  when /(\+\+)$/
    return :p
  when /(--)$/
    return :m
  end
  case v
  when /!/
    return :n
  when /~/
    return :t
  end
  return :_
end

def check_ocor(v1, v2)
  i1 = id_operator(v1)
  i2 = id_operator(v2)
  if i1 != :_ and i2 != :_
    e = nil
    if v1 =~ /=$/ or v2 =~ /=$/
      e = "a"
    else
      e = "n"
    end
    key = "o#{i1}#{i2}#{e}"
    case key
    when /^(oaaa|oaan|obba|obbn|olln|orrn|ossa|ossn)$/
      $g['Ocor:' +key] += 1
    when/^(oaba|oaea|oabn|oaln|oarn|oasa|oasn|obaa|oban|obea|obln|obrn|obsa|obsn|oeaa|oeba|oesa|olan|olbn|olrn|olsn|oran|orbn|orln|orsn|osaa|osan|osba|osbn|osea|osln|osrn)$/
      $g['Oior:' +key] += 1
    when /^(o[pPmM][pPmM]o)$/
      $g['Oido:' +key] += 1
    when /^on.*$/
      $g['Oneg:olng'] += 1
    when /o.*n./
      $g['Oneg:olng'] += 1
    when /^ot.*$/
      $g['Oneg:obng'] += 1
    when /o.*t./
      $g['Oneg:obng'] += 1
    end
    return true
  else
    return false
  end
end

def check_unary(v1, v2)
  i1 = identify_type(v1)
  i2 = identify_type(v2)
  if (i1 == :unary_px || i1 == :unary_mx) && (i2 == :unary_xp || i2 == :unary_xm) # ++x -> x++
    $g['unary:pre_post'] += 1
    return true
  end
  if (i1 == :unary_px || i1 == :unary_xp) && (i2 == :unary_mx || i2 == :unary_xm)  # ++x++ -> --x--
    $g['unary:plus_minus'] += 1
    return true
  end
  return false

end

def check_replace_const(v1, v2)
  i1 = identify_type(v1)
  i2 = identify_type(v2)
  c = [:string,:numeric,:bool, :null, :char]
  if c.include?(i1) or c.include?(i2)
    if i1 == i2
      $g['const:const_x_const.' + i1.to_s] += 1
      return true
    end
    if (c.include?(i1) and i2 == :var)
      $g['const:const_x_var.'+ i1.to_s] += 1
      return true
    end
    if (c.include?(i2) and i1 == :var)
      $g['const:const_x_var.'+ i2.to_s] += 1
      return true
    end
    if i1 == :null or i2 == :null
      $g['const:null_x_other'] += 1
      return true
    end
    $g['const:other'] += 1
    return true
  end
  return false
end

def check_stmt(v1, v2)
  if v1 =~ /break/ and v2 =~ /continue/
    $g['sbrc:'] += 1
    return true
  end
  return false
end

def check_var(v1, v2)
  if identify_type(v1) == :var and identify_type(v2) == :var
    $g['var_x_var'] += 1
    return true
  end
  return false
end

def check_unarypm(v1, v2)
  if v1[2..-1] == v2
    case v1
    when /^--/
      $g['Unary:m_'] += 1
      return true
    when /^\+\+/
      $g['Unary:p_'] += 1
      return true
    end
  end
  if v1[0..-3] == v2
    case v1
    when /--$/
      $g['Unary:_m'] += 1
      return true
    when /\+\+$/
      $g['Unary:_p'] += 1
      return true
    end
  end
  return false
end

def check_neg(v1, v2)
  if v1[1..-1] == v2
    case v1
    when /^!/
      $g['Oneg:olng'] += 1
      return true
    when /^~/
      $g['Oneg:obng'] += 1
      return true
    when /^-/
      $g['Oneg:oang'] += 1
      return true
    end
  end
  return false
end


def check_labels(v1,v2)
  if v1 =~ /.*:$/ or v2 =~ /.*:$/
    $g['Labels:'] += 1
    return true
  end
  return false
end

def process_replacement(filename, v1, v2)
  $g[:total_change] += 1
  return if check_unarypm(v1,v2)
  return if check_unarypm(v2,v1)
  return if check_neg(v1,v2)
  return if check_neg(v2,v1)
  return if check_stmt(v1,v2)
  return if check_stmt(v2,v1)
  return if check_ocor(v1,v2)
  return if check_unary(v1,v2)
  return if check_unary(v2,v1)
  return if check_replace_const(v1,v2)
  return if check_var(v1, v2)
  return if check_labels(v1, v2)
  if (identify_type(v1) == :empty) || (identify_type(v1) == :empty)
  $g[:total_change] -= 1
  end
  #puts "#{v1}\t\t\t<>\t\t\t#{v2}"
  $g[:change_unclassified] += 1
  $unknown << [v1, v2]
end

def process_add(filename,l)
  # Do not do it if we have more than one change per chunk.
  if $g_check_small
    x = l.scan(/<\+</).length
    return if x > 1
  end

  case l
  when /<\+</
    matches = l.scan(/<\+<.*?>\+>/)
    matches.each do |match|
      m=match.gsub(/<\+</,'').gsub(/>\+>/,'').gsub(/[()\[\]]/,'').strip
      case m
      when /return/
        $g['Srsr:'] += 1
      when /^!$/
        $g['Oneg:olng'] += 1
      when /^~$/
        $g['Oneg:obng'] += 1
      when /^[-]$/
        $g['Oneg:oang'] += 1
      when /:$/
        $g['Labels:'] += 1
      when /^[+-] *1$/
        $g['Twiddle:vtvd'] += 1
      else
        $g['Rem:oth'] += 1
      end
    end

    $g[:total_rem] += 1
  end
end
def process_del(filename,l)
  # Do not do it if we have more than one change per chunk.
  if $g_check_small
    x = l.scan(/<-</).length
    return if x > 1
  end

  case l
  when /<-</
    matches = l.scan(/<\-<.*?>\->/)
    matches.each do |match|
      m=match.gsub(/<\+</,'').gsub(/>\+>/,'').gsub(/[()\[\]]/,'').strip
      case m
      when /return/
        $g['Srsr:'] += 1
      when /^!$/
        $g['Oneg:olng'] += 1
      when /^~$/
        $g['Oneg:obng'] += 1
      when /^[-]$/
        $g['Oneg:oang'] += 1
      when /:$/
        $g['Labels:'] += 1
      when /^[+-] *1$/
        $g['Twiddle:vtvd'] += 1
      else
         $g['Add:oth'] += 1
      end
    end
    $g[:total_add] += 1
  end
end

def process_change(filename,l)
  # Do not do it if we have more than one change per chunk.
  if $g_check_small
    x = l.scan(/<@</).length
    return if x > 1
  end

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
  if $g_check_small
    return if (lines.count{|s| s =~ /<@</ } > 1)
  end
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

#$bugs_sha = {}
#File.open('./bug.sha').each do |x|
#  x.chomp!
#  y = x[0..6]
#  $bugs_sha[y] = x
#end

$g_bugs = {}
File.readlines('all.nobug').each do |l|
  l.chomp!
  case l
  when /comments\/(.*)\/sha\.(.*)$/
    x = $2
    k = x[0..6]
    $g_bugs[k] ||= []
    $g_bugs[k] << $1
  end
end

def is_small(l, project, onechange)
  return true if !$g_check_small
  sha = get_sha_from_diffd(l)
  return onechange.include?(sha)
end
def is_bug(l, project)
  return true if !$g_check_bug
  sha = get_sha_from_diffd(l)
  return (!$g_bugs[sha].nil?) && $g_bugs[sha].include?(project)
end
def get_sha_from_diffd(l)
  shafile = l.gsub(/([0-9]+)\.diff\.d$/,'\1.sha').chomp
  sha = File.open(shafile).read.strip
  return sha
end
def check(l, project, onechange)
  return is_small(l, project, onechange) && is_bug(l, project)
end

def is_buggy(l)
  case l
  when /(.*\/[0-9]+)\.diff\.d$/
    sha = File.open($1 + ".sha").read.strip
    return false if $bugs_sha[sha].nil?
    return true
  else
    throw "Unknown #{l}"
  end
end

#STDIN.each do |l|
#  l.chomp!
#  process_file(l) #if is_buggy(l)
#end

File.readlines("meta/repos.lst").each do |project|
  project.chomp!
  STDERR.puts project
  onechange = Set.new File.open("changes/#{project}/.onechange").readlines.map(&:chomp).map{|x| x[0..6]}
  Dir.glob("changes/#{project}/**/*.diff.d") do |l|
    l.chomp!
    process_file(l) if check(l, project, onechange)
  end
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

