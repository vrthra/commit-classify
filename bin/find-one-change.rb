#!/usr/bin/ruby
# for i in $(seq 1 100); do ~/find-one-changex.rb c < all.bug & sleep 1; done
$ext=ARGV[0]
$project = nil
$sha = nil
$g_check_one_file = true

exit 1 if $ext.nil? || $ext =~ /^$/

def process_comment(c_p_sha)
  lines = []
   File.readlines(c_p_sha).each do |line|
       case line
       when /^[+++]{3} [^\/]+\/(.*\.#{$ext})$/
         lines << $1
       end
   end
   lines
end

$f = {}

STDIN.each do |c_p_sha|
  c_p_sha.chomp!
  case c_p_sha
  when /comments\/(.*)\/sha\.([^\/]+)$/
    $project = $1
    $sha = $2
    prj = "onechange/all.#{$project.gsub(/\//,'~')}"
    next if File.exists?(prj) && $f[prj].nil?
    $f[prj] ||= File.open(prj, 'w+')
    short_sha = $sha[0..6]
    lines = process_comment(c_p_sha)
    next if lines.length > 1 && $g_check_one_file
    lines.each do |file|
      Dir.glob("changes/#{$project}/#{file}/*.sha").each do |d|
        l = File.readlines(d).join('').strip
        if l == short_sha
          case d
          when /^(.*\/[0-9]+)\.sha$/
            if File.exists?("#{$1}.diff.d")
              l = File.readlines("#{$1}.diff.d").grep(/^############/).length
              # These are the one hunk changes in single files.
              if l == 1
                #puts c_p_sha
                $f[prj].puts c_p_sha
                $f[prj].flush
              end
            end
          end
        end
      end
    end
  else
    throw c_p_sha
  end
end
$f.values.each do |f|
  f.close
end
