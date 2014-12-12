#!/usr/bin/env ruby
def clean(v)
  return v.gsub(/ /,'').gsub(/\(/,'').gsub(/\)/,'').gsub(/"/,'')
end
def process_replacement(filename, v1, v2)
  s1 = v1.strip.gsub(/ *,$/,'').gsub(/ *;/,'').gsub(/\(/,'').gsub(/\)/,'').gsub(/\[/,'').gsub(/\]/,'').gsub(/\{/,'').gsub(/\}/,'').gsub(/^[&*]+/,   '').gsub(/->/,'.')
  s2 = v2.strip.gsub(/ *,$/,'').gsub(/ *;/,'').gsub(/\(/,'').gsub(/\)/,'').gsub(/\[/,'').gsub(/\]/,'').gsub(/\{/,'').gsub(/\}/,'').gsub(/^[&*]+/,   '').gsub(/->/,'.')
  l1 = s1.split(/\b/).length
  l2 = s2.split(/\b/).length
  puts "#{l1} #{l2}" if l1 + l2 > 0
end

def process_add(filename,l)
  case l
  when /<\+</
    matches = l.scan(/<\+<.*?>\+>/)
    matches.each do |match|
      m=match.gsub(/<\+</,'').gsub(/>\+>/,'').strip.gsub(/ *,$/,'').gsub(/ *;/,'').gsub(/\(/,'').gsub(/\)/,'').gsub(/\[/,'').gsub(/\]/,'').gsub(/\{/,'').gsub(/\}/,'').gsub(/^[&*]+/, '').gsub(/->/,'.')
      l = m.split(/\b/).length
      puts "0 #{l}" if l > 0
      #if (m.split(/\b/).length == 1)
      #  puts match
      #end
    end

    #$g[:total_rem] += 1
  end
end
def process_del(filename,l)
  case l
  when /<-</
    matches = l.scan(/<\-<.*?>\->/)
    matches.each do |match|
      m=match.gsub(/<\-</,'').gsub(/>\->/,'').strip.gsub(/ *,$/,'').gsub(/ *;/,'').gsub(/\(/,'').gsub(/\)/,'').gsub(/\[/,'').gsub(/\]/,'').gsub(/\{/,'').gsub(/\}/,'').gsub(/^[&*]+/, '').gsub(/->/,'.')
      l = m.split(/\b/).length
      puts "#{l} 0" if l > 0
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

$g_sample = {}
$g_sample.default = []
def process_sample(name)
  lines = File.readlines(name).map{|x| x.encode(Encoding.find('ASCII'),$encoding_options)}
  lines.each do |l|
    case l
    when /^comments\/(.*)\/sha\.(.*)$/
      project = $1
      sha = $2
      $g_sample[project] << sha[0..6]
    end
  end
end

process_sample ARGV[0]

def get_sha_from_diffd(l)
  shafile = l.gsub(/([0-9]+)\.diff\.d$/,'\1.sha').chomp
  sha = File.open(shafile).read.strip
  return sha
end
def check(l, project)
  sha = get_sha_from_diffd(l)
  return $g_sample[project].include?(sha)
end

File.readlines("meta/repos.lst").each do |project|
  project.chomp!
  STDERR.puts project
  Dir.glob("changes/#{project}/**/*.diff.d") do |l|
    l.chomp!
    process_file(l) if check(l, project)
  end
end

#STDIN.each do |l|
#  process_file(l.chomp)
#end

STDOUT.flush
