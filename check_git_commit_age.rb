#!/usr/bin/env ruby

# Coypright (C) 2018 Christian Mayer <christian@fox21.at>

# Check the age of the last Git commit.


require 'optparse'
require 'pathname'
require 'time'
require 'pp'

STATES = ['OK', 'WARNING', 'CRITICAL', 'UNKNOWN']

@options = {
	:repo => nil,
	:dst => nil,
	:warning => 3600,
	:critical => 7200,
}
opts = OptionParser.new do |o|
	o.banner = 'Usage: --repository <string> --destination -w <seconds> -c <seconds>'
	o.separator('')
	
	o.on('-r', '--repository <string>', 'URL/path to the Git repository.') do |repo|
		@options[:repo] = repo
	end
	
	o.on('-d', '--destination <string>', 'Path to local destination. For example /tmp/my-repo') do |dst|
		@options[:dst] = Pathname.new(dst).expand_path
	end
	
	o.on('-w', '--warning <number>', 'Warning Seconds') do |num|
		@options[:warning] = num.to_i
	end
	
	o.on('-c', '--critical <number>', 'Critical Seconds') do |num|
		@options[:critical] = num.to_i
	end
	
	o.on_tail('-h', '--help', 'Show this message.') do
		puts o
		puts
		exit 3
	end
end
ARGV << '-h' if ARGV.count == 0
commands = opts.parse(ARGV)

if not @options[:dst].exist?
	if not system('git clone --quiet --depth 1 "%s" "%s"' % [@options[:repo], @options[:dst].to_s])
		raise 'git clone failed'
	end
end

diff = 0
Dir.chdir(@options[:dst]) do
	if not system('git pull --quiet')
		raise 'git pull failed'
	end
	
	# Get the Unix Timestamp.
	uts = `git log -n 1 --pretty=format:%at`.to_i
	
	diff = Time.now.to_i - uts
end

if diff >= @options[:critical]
	state = 2
elsif diff >= @options[:warning]
	state = 1
else
	state = 0
end

state_name = STATES[state]

perf_data = [
	state_name, diff, @options[:warning], @options[:critical], # Normal Output
	diff, @options[:warning], @options[:critical],
]
puts "%s: diff=%ds (w=%ds c=%ds) | diff=%ds;%d;%d" % perf_data

exit state
