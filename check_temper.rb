#!/usr/bin/env ruby

# Coypright (C) 2019 Christian Mayer <christian@fox21.at>

# This script uses
#  https://github.com/urwen/temper
# to check the temperature. It must be available in PATH
# under temper.py file name.


require 'optparse'

STATES = ['OK', 'WARNING', 'CRITICAL', 'UNKNOWN']

@options = {
	:temper_bin => 'temper.py',
	:product => nil,
	:type => 'C', # If 'F' take D.G. Fahrenheit.
	:warning_val => nil,
	:critical_val => nil,
	:above => true,
}
opts = OptionParser.new do |o|
	o.banner = 'Usage: [--temper_bin <path>] [-f|--fahrenheit] [-p|--product <VENDOR_ID:PRODUCT_ID>] -w <val> -c <val> [--above|--below]'
	o.separator('')
	
	o.on('-b', '--temper_bin <path>', 'Path to temper.py script.') do |path|
		@options[:temper_bin] = path
	end
	
	o.on('-p', '--product <str>', 'VENDOR_ID:PRODUCT_ID string used for the --force argument for temper.py script.') do |product|
		@options[:product] = product
	end
	
	o.on('-f', '--fahrenheit', 'Take Fahrenheit. (Default Celsius)') do
		@options[:type] = 'F'
	end
	
	o.on('-w', '--warning <val>', 'Warning Value') do |val|
		@options[:warning_val] = val.to_f
	end
	
	o.on('-c', '--critical <val>', 'Critical Value') do |val|
		@options[:critical_val] = val.to_f
	end
	
	o.on('-a', '--above', 'Return WARNING/CRITICAL when value is above. (default)') do
		@options[:above] = true
	end
	
	o.on('-b', '--below', 'Return WARNING/CRITICAL when value is below.') do
		@options[:above] = false
	end
	
	o.on_tail('-h', '--help', 'Show this message.') do
		puts o
		puts
		exit 3
	end
end
ARGV << '-h' if ARGV.count == 0
commands = opts.parse(ARGV)

cmd_force = ''
if not @options[:product].nil?
	cmd_force = '--force %s' % [@options[:product]]
end

cmd = '%s %s' % [
	@options[:temper_bin], cmd_force
]
cmd_res = %x[#{cmd}]

if regex_res = cmd_res.match(/(\d{1,2}\.?\d?)#{@options[:type]}/)
	temper_val = regex_res[1].to_f
end

state = 0
additional_name = nil
if @options[:above]
	additional_name = 'Check above'
	
	if temper_val >= @options[:critical_val]
		state = 2
	elsif temper_val >= @options[:warning_val]
		state = 1
	end
else
	additional_name = 'Check below'
	
	if temper_val <= @options[:critical_val]
		state = 2
	elsif temper_val <= @options[:warning_val]
		state = 1
	end
end

state_name = STATES[state]

perf_data = [
	state_name, additional_name, temper_val, @options[:type], # Normal Output
	@options[:type], temper_val, @options[:warning_val], @options[:critical_val],
]
puts '%s: %s, %.1f %s | %s=%.1f;%.1f;%.1f' % perf_data

exit state
