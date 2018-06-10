#!/usr/bin/env ruby

# Coypright (C) 2018 Christian Mayer <christian@fox21.at>

# Check time until destination date.


require 'optparse'
require 'time'

STATES = ['OK', 'WARNING', 'CRITICAL', 'UNKNOWN']

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
	:date => nil,
	:warning_n => 3600 * 24 * 2,
	:warning_s => '2d',
	:critical_n => 3600 * 24,
	:critical_s => '1d',
}
opts = OptionParser.new do |o|
	o.banner = 'Usage: --date <string> -w <time> -c <time>'
	o.separator('')
	
	o.on('-d', '--date <string>', 'Destination Date') do |date|
		@options[:date] = Time.parse(date)
	end
	
	o.on('-w', '--warning <time>', 'Warning (For example: 1h)') do |time|
		@options[:warning_n] = convert_human_time(time)
		@options[:warning_s] = time
	end
	
	o.on('-c', '--critical <time>', 'Critical (For example: 3h)') do |time|
		@options[:critical_n] = convert_human_time(time)
		@options[:critical_s] = time
	end
	
	o.on_tail('-h', '--help', 'Show this message.') do
		puts o
		puts
		exit 3
	end
end
ARGV << '-h' if ARGV.count == 0
commands = opts.parse(ARGV)

# Calc diff
diff_n = @options[:date] - Time.now
diff_s = convert_computer_time(diff_n)

if diff_n <= @options[:critical_n]
	state = 2
elsif diff_n <= @options[:warning_n]
	state = 1
else
	state = 0
end

state_name = STATES[state]

perf_data = [
	state_name, diff_s, @options[:warning_s], @options[:critical_s], # Normal Output
	diff_n, @options[:warning_n], @options[:critical_n],
]
puts "%s: diff=%s w=%s c=%s | diff=%ds;%d;%s" % perf_data

exit state
