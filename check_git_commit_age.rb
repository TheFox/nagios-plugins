#!/usr/bin/env ruby

# Coypright (C) 2018 Christian Mayer <christian@fox21.at>

# Check the age of the last Git commit.


require 'optparse'
require 'pathname'
require 'time'

STATES = ['OK', 'WARNING', 'CRITICAL', 'UNKNOWN']

def write_file(path)
	File.open(path, 'w') do |file|
		file.write(Time.now.to_i.to_s)
	end
end

def read_file(path)
	File.read(path)
end

def convert_human_time(time_s)
	time_s = time_s.strip.gsub(/ /, '')
	
	s = 0
	if res = /^(\d{1,11})$/.match(time_s)
		# Seconds
		s = res[1].to_i
	elsif res = /^(\d{1,11})s$/.match(time_s)
		# Seconds
		s = res[1].to_i
	elsif res = /^(\d{1,10})m$/.match(time_s)
		# Minutes
		s = res[1].to_i * 60
	elsif res = /^(\d{1,6})h$/.match(time_s)
		# Hours
		s = res[1].to_i * 3600
	elsif res = /^(\d{1,4})d$/.match(time_s)
		# Days
		s = res[1].to_i * 24 * 3600
	elsif res = /^(\d{1,4})w$/.match(time_s)
		# Weeks
		s = res[1].to_i * 7 * 24 * 3600
	elsif res = /^(\d{1,3})M$/.match(time_s)
		# Months
		s = res[1].to_i * 30.41 * 24 * 3600
	elsif res = /^(\d{1,2})y$/.match(time_s)
		# Years
		s = res[1].to_i * 365 * 24 * 3600
	else
		raise 'Invalid time string: %s' % [time_s]
	end
	s.to_i
end

@options = {
	:repo => nil,
	:dst => nil,
	:git_data => nil,
	:git_pull_file => nil,
	:warning => 3600,
	:critical => 7200,
	:pull_timeout => nil,
}
opts = OptionParser.new do |o|
	o.banner = 'Usage: --repository <string> --destination -w <seconds> -c <seconds>'
	o.separator('')
	
	o.on('-r', '--repository <string>', 'URL/path to the Git repository.') do |repo|
		@options[:repo] = repo
	end
	
	o.on('-d', '--destination <string>', 'Path to local destination. For example /tmp/my-repo') do |dst|
		@options[:dst] = Pathname.new(dst).expand_path
		@options[:git_data] = Pathname.new('repo').expand_path(@options[:dst])
		@options[:git_pull_file] = Pathname.new('git_pull').expand_path(@options[:dst])
	end
	
	o.on('-w', '--warning <time>', 'Warning (For example: 1h)') do |time|
		@options[:warning] = convert_human_time(time)
	end
	
	o.on('-c', '--critical <time>', 'Critical (For example: 3h)') do |time|
		@options[:critical] = convert_human_time(time)
	end
	
	o.on('--pull-timeout <time>', 'Time between pulls') do |time|
		@options[:pull_timeout] = convert_human_time(time)
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
	@options[:dst].mkpath
end

if not @options[:git_data].exist?
	git_clone = system('git clone --quiet --depth 1 "%s" "%s"' % [@options[:repo], @options[:git_data].to_s])
	if not git_clone
		raise 'git clone failed'
	end
	
	write_file(@options[:git_pull_file])
end

diff = 0
next_pull = 0 # Pull always.
git_pull = false
Dir.chdir(@options[:dst]) do
	Dir.chdir(@options[:git_data]) do
		if not @options[:pull_timeout].nil?
			# Calc time for the next pull.
			last_pull = read_file(@options[:git_pull_file]).to_i
			next_pull = (Time.now - last_pull - @options[:pull_timeout]).to_i
		end
		
		if next_pull >= 0
			git_pull = system('git pull --quiet')
			if not git_pull
				raise 'git pull failed'
			end
			write_file(@options[:git_pull_file])
		end
		
		# Get the Unix Timestamp.
		uts = `git log -n 1 --pretty=format:%at`.to_i
		
		# Calc diff
		diff = Time.now.to_i - uts
	end
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
	state_name, diff, @options[:warning], @options[:critical], next_pull, git_pull ? 'Y' : 'N', # Normal Output
	diff, @options[:warning], @options[:critical],
]
puts "%s: diff=%ds (w=%ds c=%ds n=%ds p?=%s) | diff=%ds;%d;%d" % perf_data

exit state
