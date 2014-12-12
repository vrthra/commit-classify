#!/usr/bin/env ruby
$unknown = []
$g = {}
$g.default = 0

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

def process_replacement(filename, v1, v2, f)
  #f.puts "#{v1.split(/ +/).length}\t#{v2.split(/ +/).length}"
  f.puts "#{v1}\t#{v2}"
end

def process_add(filename,l)
  case l
  when /<+</
    $g[:add] += 1
  end
end
def process_del(filename,l)
  case l
  when /<-</
    $g[:rem] += 1
  end
end
def process_change(filename,l)
    # If the number of changes are greater than one, then ignore
    x = l.scan(/<@</).length
    return if x > 1

    case l
    when /<@</
      matches = l.scan(/<@<.*?>@>/)
      matches.each do |match|
        m=match.gsub(/<@</,'').gsub(/>@>/,'')
        val = m.split(/\t<>\t/)
        # we ignore the change if both parts are larger than 1
        v1 = val[0].strip.gsub(/\t/,' ')
        v2 = val[1].strip.gsub(/\t/,' ')
        l1 = v1.gsub(/[\[\]()]/,' ').gsub(/,/,' ').split(/\s+/).length
        l2 = v2.gsub(/[\[\]()]/,' ').gsub(/,/,' ').split(/\s+/).length
        # If the number of tokens involved in both sides are greater than one,
        # then ignore.
        if l1 > 1 || l2 > 1
          return
        end
        if clean(v1) == clean(v2)
          return
        end
        process_replacement(filename, v1, v2)
      end
    end
end

def process_file(filename)
  lines = File.readlines(filename)
  if (lines.count{|s| s =~ /<@</ } > 1)
  # Return if more than one chunk in the file.
    return
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
        #process_add(filename, l[2..-1])
        #process_del(filename, l[2..-1])
    end
  end
end
STDIN.each do |l|
  process_file(l.chomp)
end
end

