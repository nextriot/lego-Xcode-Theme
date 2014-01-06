require 'httparty'
require 'fileutils'
require 'ostruct'
include FileUtils

class String
  def dir?
    File.directory? self
  end
  def basename
    File.basename(self)
  end
  def stem
    File.basename(self, File.extname(self))
  end
  def x
    gsub(' ', '\\ ').gsub('"', '\\"').gsub("'", "\\'")
  end
end

class GitHub
  include HTTParty
  base_uri 'https://api.github.com'

  def self.headers
    {'User-Agent' => "mxclmade"}
  end

  def self.forks
    json = get("/repos/mxcl/omgthemes/forks", headers: headers)
    json = json.parsed_response
    json.each do |fork|
      yield OpenStruct.new({
        user: fork['owner']['login'],
        clone_url: fork['clone_url']
      })
    end
  end
end

def themes
  d = File.expand_path(File.dirname(__FILE__))
  Dir["**/*.dvtcolortheme"].sort_by{|fn| File.mtime(fn) }.reverse
end


########################################################################### prep
out = File.expand_path('out')
mkdir 'forks' unless 'forks'.dir?
mkdir out unless out.dir?

cd File.dirname(__FILE__)+'/forks'


######################################################################### --json
if ARGV[0] == '--json'
  json = themes.map do |theme|
    user = theme.split('/').first
    name = theme.stem
    theme =~ %r{#{user}/(.*)}
    {
      fork: user,
      name: name,
      raw:  $1
    }
  end
  puts JSON.fast_generate(json)
  exit 0
end


######################################################################### --pull
if ARGV[0] == '--pull'
  GitHub.forks do |fork|
    if not fork.user.dir?
      system "git clone #{fork.clone_url} #{fork.user}"
    else
      cd fork.user do
        system "git pull"
      end
    end
  end
  exit 0
end


########################################################################### main
mkf = File.open('Makefile', 'w')
all = []
themes.map do |theme|
  user = theme.split('/').first
  name = theme.stem
  fn = "#{user}_#{name}"  # spaces in filenames suck
  dst = "#{out}/#{fn}.dvtcolortheme"

  mkf.puts <<-end
../out/#{fn.x}.dvtcolortheme.css: #{theme.x}
\truby ../parse-dvtcolortheme.rb "$^" > "$@"

end

  all << "../out/#{fn.x}.dvtcolortheme.css"
end

all = all.join' '

mkf.puts "../out/themes.json: #{all}\n\truby ../generate.rb --json > $@"
mkf.puts "../out/index.html:\n\tcp ../index.html $@"
mkf.puts "../out/omgthemes.css:\n\tcp ../main.css $@"
mkf.puts "all: #{all} ../out/index.html ../out/omgthemes.css ../out/themes.json"
mkf.close
