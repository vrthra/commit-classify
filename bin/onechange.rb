#!/usr/bin/ruby
# git diff --stat --name-only
exit(1) if ARGV[0].nil? || ARGV[0] !~ /\.[a-z]+$/
File.readlines('meta/repos.lst').each do |proj|
  proj.chomp!
  p proj
  phash = []
  next if File.exist?("changes/#{proj}/.onechange")
  File.open("changes/#{proj}/.onechange", "w") {}
  Dir.chdir("projects/#{proj}") do
    log=%x[git log --pretty='%H'].split(/\n/)
    log.each do |hash|
      hash.chomp!
      files = %x[git diff --stat --name-only #{hash}| grep \\#{ARGV[0]}\$]
      phash << hash if files.length > 1
    end
  end
  File.open("changes/#{proj}/.onechange", "w") do |f|
    f.puts phash.join("\n")
  end
  phash = []
end
