#!/usr/bin/ruby
# git diff --stat --name-only
File.readlines('meta/repos.lst').each do |proj|
  proj.chomp!
  p proj
  phash = []
  next if File.exist?("changes/#{proj}/.simplehash")
  File.open("changes/#{proj}/.simplehash", "w") {}
  Dir.chdir("projects/#{proj}") do
    log=%x[git log --pretty='%H'].split(/\n/)
    log.each do |hash|
      hash.chomp!
      files = %x[git diff --stat --name-only #{hash}| grep \.hs\$]
      phash << hash if files.length > 1
    end
  end
  File.open("changes/#{proj}/.simplehash", "w") do |f|
    f.puts phash.join("\n")
  end
  phash = []
end
