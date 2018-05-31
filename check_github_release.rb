#!/usr/bin/env ruby

# Coypright (C) 2018 Christian Mayer <christian@fox21.at>

# Check a release number of a GitHub repo.


require 'rss'
require 'optparse'
require 'rubygems'
require 'pp'

# module Gem
# 	class Version
# 		def to_i
# 			items = self.version.split('.').map{ |s| s.to_i }.reverse
# 			n = 0
# 			e = 0
# 			items.each do |i|
# 				n += (10 ** e) * i
# 				e += 3
# 			end
# 			n
# 		end
# 	end
# end

STATES = ['OK', 'WARNING', 'CRITICAL', 'UNKNOWN']

@options = {
	:name => nil,
	:warning => Gem::Version.new('0.0.0'),
	:critical => Gem::Version.new('0.0.0'),
	# :release => false,
	:cmd => nil,
	:cmdregexp => nil,
}
opts = OptionParser.new do |o|
	o.banner = 'Usage: --name <user/repo> -w <number> -c <number>'
	o.separator('')
	
	o.on('-n', '--name <user/repo>', 'Repository Name. Example: ethereum/go-ethereum') do |name|
		@options[:name] = name
	end
	
	o.on('-w', '--warning <number>', 'Warning Number') do |num|
		@options[:warning] = Gem::Version.new(num)
	end
	
	o.on('-c', '--critical <number>', 'Critical Number') do |num|
		@options[:critical] = Gem::Version.new(num)
	end
	
	# o.on('-c', '--release', 'Releases Only') do
	# 	@options[:release] = true
	# end
	
	o.on('--cmd <string>', 'Run command to check version.') do |cmd|
		@options[:cmd] = cmd
	end
	
	o.on('--cmdregexp <string>', 'RegExp to catch command output.') do |cmdregexp|
		# puts "regexp: '#{cmdregexp}'"
		@options[:cmdregexp] = Regexp.new(cmdregexp)
	end
	
	o.on_tail('-h', '--help', 'Show this message.') do
		puts o
		puts
		exit 3
	end
end
ARGV << '-h' if ARGV.count == 0
commands = opts.parse(ARGV)

# Build URL.
url = 'https://github.com/%s/releases.atom' % [
	@options[:name]
]

latest_version = Gem::Version.new('0.0.0')
open(url) do |rss|
	feed = RSS::Parser.parse(rss)
	
	feed.items.each do |item|
		version_items = item.id.content.split('/')
		version = Gem::Version.new(version_items.last.gsub(/^v\.?/, ''))
		
		if version > latest_version
			latest_version = version
		end
	end
end

state = 3

if @options[:cmd].nil?
	if latest_version >= @options[:critical]
		state = 2
	elsif latest_version >= @options[:warning]
		state = 1
	else
		state = 0
	end
else
	require 'open3'
	stdout, stderr, status = Open3.capture3(@options[:cmd])
	
	if 0 == status.exitstatus
		res = @options[:cmdregexp].match(stdout)
		
		@options[:critical] = Gem::Version.new(res[1])
		
		if latest_version > @options[:critical]
			state = 2
		else
			state = 0
		end
	end
end

state_name = STATES[state]

perf_data = [
	state_name, @options[:name], latest_version, @options[:warning], @options[:critical], # Normal Output
]
puts "%s: %s=%s (w=%s c=%s)" % perf_data

exit state
