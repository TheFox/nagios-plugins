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
	
	res = /^(\d{1,11})(.?)$/.match(time_s)
	
	n = res[1].to_i
	h = {
		''  => n,
		's' => n,
		'm' => n * 60,
		'h' => n * 3600,
		'd' => n * 24 * 3600,
		'w' => n * 7 * 24 * 3600,
		'M' => n * 30.41 * 24 * 3600,
		'y' => n * 365 * 24 * 3600,
	}
	
	if not h.has_key?(res[2])
		raise 'Invalid time string: %s' % [time_s]
	end
	
	h[res[2]].to_i
end

def convert_computer_time(s)
	h = {
		'y' => 365 * 24 * 3600,
		'M' => 30.41 * 24 * 3600,
		'w' => 7 * 24 * 3600,
		'd' => 24 * 3600,
		'h' => 3600,
		'm' => 60,
	}
	
	prefix = ''
	if s < 0
		prefix = '-'
		s = s.abs
	end
	
	x = Hash.new
	h.each do |y, n|
		m = 0
		while s >= n && s >= 60 && m <= 1000
			m += 1
			
			if not x.has_key?(y)
				x[y] = 0
			end
			x[y] += 1
			
			s -= n
			
			if s < 60
				break
			end
		end
	end
	if s > 0 || x.keys.length == 0
		x['s'] = s.to_i
	end
	
	(
		'%s%s' % [
			prefix,
			x.map{ |k| '%d%s' % k.reverse }.join(''),
		]
	).strip
end

@options = {
	:repo => nil,
	:dst => nil,
	:git_data => nil,
	:git_pull_file => nil,
	:warning_n => 3600,
	:warning_s => '1h',
	:critical_n => 7200,
	:critical_s => '2h',
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
		@options[:warning_n] = convert_human_time(time)
		@options[:warning_s] = time
	end
	
	o.on('-c', '--critical <time>', 'Critical (For example: 3h)') do |time|
		@options[:critical_n] = convert_human_time(time)
		@options[:critical_s] = time
	end
	
	o.on('-p', '--pull-timeout <time>', 'Time between pulls') do |time|
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

diff_n = 0
diff_s = 'N/A'
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
		diff_n = Time.now.to_i - uts
		diff_s = convert_computer_time(diff_n)
	end
end

if diff_n >= @options[:critical_n]
	state = 2
elsif diff_n >= @options[:warning_n]
	state = 1
else
	state = 0
end

state_name = STATES[state]

perf_data = [
	state_name, diff_s, @options[:warning_s], @options[:critical_s], convert_computer_time(next_pull), git_pull ? 'Y' : 'N', # Normal Output
	diff_n, @options[:warning_n], @options[:critical_n],
]
puts "%s: diff=%s w=%s c=%s n=%s p?=%s | diff=%ds;%d;%s" % perf_data

exit state
