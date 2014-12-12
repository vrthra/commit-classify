#!/usr/bin/env ruby

$g = {}
$g.default = 0

def identify_type(str)
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

def process_add_line(filename,l)
end
def process_rem_line(filename,l)
end
def process_change_line(filename,l)
    case l
    when /(.*)\t<>\t(.*)/
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
        process_change_line(filename, l[2..-1])
    when
      /^\+/
        process_add_line(filename, l[2..-1])
    when
      /^-/
        process_rem_line(filename, l[2..-1])
    else
    end
  end
end

STDIN.each do |l|
  process_file(l.chomp)
end

$g.each do |k,v|
  puts "#{k} = #{v}"
end
