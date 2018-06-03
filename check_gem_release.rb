#!/usr/bin/env ruby

# Coypright (C) 2018 Christian Mayer <christian@fox21.at>

# Check a release number of a RubyGems repo.


require 'rss'
require 'optparse'
require 'rubygems'
require 'pp'

STATES = ['OK', 'WARNING', 'CRITICAL', 'UNKNOWN']

@options = {
	:name => nil,
	:warning => Gem::Version.new('0.0.0'),
	:critical => Gem::Version.new('0.0.0'),
	:skip_pre => false,
	:limit => nil,
}
opts = OptionParser.new do |o|
	o.banner = 'Usage: --name <repo_name> -w <number> -c <number>'
	o.separator('')
	
	o.on('-n', '--name <repo_name>', 'Repository Name. Example: redcarpet') do |name|
		@options[:name] = name
	end
	
	o.on('-w', '--warning <number>', 'Warning Number') do |num|
		@options[:warning] = Gem::Version.new(num)
	end
	
	o.on('-c', '--critical <number>', 'Critical Number') do |num|
		@options[:critical] = Gem::Version.new(num)
	end
	
	o.on('-s', '--skip-pre', 'Skip pre versions. (Like RC)') do
		@options[:skip_pre] = true
	end
	
	o.on('-l' '--limit <number>', 'Limit latest versions.') do |limit|
		@options[:limit] = limit.to_i
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
url = 'https://rubygems.org/gems/%s/versions.atom' % [
	@options[:name]
]

latest_version = Gem::Version.new('0.0.0')
open(url) do |rss|
	feed = RSS::Parser.parse(rss, false)
	
	limit = @options[:limit]
	feed.items.each do |item|
		version_items = item.id.content.split('/')
		version_s = version_items.last.gsub(/^v\.?/, '')
		version_o = Gem::Version.new(version_s)
		
		if @options[:skip_pre] && /\.pre\./.match(version_s)
			next
		end
		
		if version_o > latest_version
			latest_version = version_o
		end
		
		if not limit.nil?
			if limit > 0
				limit -= 1
			else
				break
			end
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
puts "%s: %s=%s w=%s c=%s" % perf_data

exit state
