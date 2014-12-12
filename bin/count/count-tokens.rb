#!/usr/bin/env ruby
require 'set'
$g_check_small = true
$g_check_bug = true
$g_project = nil
$g_sha = nil
def clean(v)
  return v.gsub(/ /,'').gsub(/\(/,'').gsub(/\)/,'').gsub(/"/,'')
end
def process_replacement(filename, v1, v2)
  s1 = v1.strip.gsub(/ *,$/,'').gsub(/ *;/,'').gsub(/\(/,'').gsub(/\)/,'').gsub(/\[/,'').gsub(/\]/,'').gsub(/\{/,'').gsub(/\}/,'').gsub(/^[&*]+/,   '').gsub(/->/,'.')
  s2 = v2.strip.gsub(/ *,$/,'').gsub(/ *;/,'').gsub(/\(/,'').gsub(/\)/,'').gsub(/\[/,'').gsub(/\]/,'').gsub(/\{/,'').gsub(/\}/,'').gsub(/^[&*]+/,   '').gsub(/->/,'.')

  puts "#{$g_project} #{$g_sha} #{s1.split(/\b/).length} #{s2.split(/\b/).length}"
end

def process_add(filename,l)

  case l
  when /<\+</
    matches = l.scan(/<\+<.*?>\+>/)
    matches.each do |match|
      m=match.gsub(/<\+</,'').gsub(/>\+>/,'').gsub(/[()\[\]]/,'').strip
      puts "#{$g_project} #{$g_sha} 0 #{m.split(/\b/).length}"
    end

    #$g[:total_rem] += 1
  end
end
def process_del(filename,l)
  case l
  when /<-</
    matches = l.scan(/<\-<.*?>\->/)
    matches.each do |match|
      m=match.gsub(/<\+</,'').gsub(/>\+>/,'').gsub(/[()\[\]]/,'').strip
      puts "#{$g_project} #{$g_sha} #{m.split(/\b/).length} 0"
    end
    #$g[:total_add] += 1
  end
end

def process_change(filename,l)
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
      #if l1 > 1 || l2 > 1
      #  return
      #end
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
  lines.each do |l|
    begin
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
    rescue;
      STDERR.puts filename
    end
  end
end

$g_bugs = {}
File.readlines(ARGV[0]).each do |l|
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
  return false if !onechange.include?(sha)

  lines = File.readlines(l)
  count = 0
  lines.each do |s|
    case s
    when /<@</
      count += 1
    when /<\+</
      count += 1
    when /<-</
      count += 1
    end
  end
  return false if count > 1
  return true
end

def is_bug(l, project)
  return true if !$g_check_bug
  sha = get_sha_from_diffd(l)
  return (!$g_bugs[sha].nil?) && $g_bugs[sha].include?(project)
end
def get_sha_from_diffd(l)
  shafile = l.gsub(/([0-9]+).diff.d/,'\1.sha').chomp
  sha = File.open(shafile).read.strip
  return sha
end
def check(l, project, onechange)
  return is_small(l, project, onechange) && is_bug(l, project)
end

def shamap(project)
  shadir = Dir.glob("comments/#{project}/sha.*")
  hash = {}
  shadir.each do |sha|
    case sha
    when /.*\/sha\.(.*)/
      k = $1
      k = k[0..6]
      hash[k] = sha
    end
  end
  return hash
end

File.readlines("meta/repos.lst").each do |project|
  project.chomp!
  $g_project = project
  STDERR.puts project
  onechange = Set.new File.open("changes/#{project}/.onechange").readlines.map(&:chomp).map{|x| x[0..6]}
  shas = shamap(project)
  Dir.glob("changes/#{project}/**/*.diff.d") do |l|
    l.chomp!
    $g_sha = get_sha_from_diffd(l)
    puts shas[$g_sha] if check(l, project, onechange)
    #process_file(l) #if check(l, project, onechange)
  end
end

#STDIN.each do |l|
#  process_file(l.chomp)
#end

STDOUT.flush
