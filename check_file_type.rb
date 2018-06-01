#!/usr/bin/env ruby

# Coypright (C) 2018 Christian Mayer <christian@fox21.at>

# Check file type.


require 'net/http'
require 'json'
require 'optparse'
require 'open3'
require 'pathname'

STATES = ['OK', 'WARNING', 'CRITICAL', 'UNKNOWN']

@options = {
	:file => nil,
	:regexp => nil,
	:ignore_missing => false,
}
opts = OptionParser.new do |o|
	o.banner = 'Usage: --file <path> --regexp <string>'
	o.separator('')
	
	o.on('-f', '--file <path>', 'File Path') do |file|
		@options[:file] = Pathname.new(file).expand_path
	end
	
	o.on('-r', '--regexp <string>', 'RegExp String') do |regexp|
		@options[:regexp] = Regexp.new(regexp)
	end
	
	o.on('-i', '--ignoremissing', 'Ignore missing file.') do
		@options[:ignore_missing] = true
	end
	
	o.on_tail('-h', '--help', 'Show this message.') do
		puts o
		puts
		exit 3
	end
end
ARGV << '-h' if ARGV.count == 0
commands = opts.parse(ARGV)

if @options[:file].exist?
	cmd = 'file -b %s' % [@options[:file].to_s]

	stdout, stderr, status = Open3.capture3(cmd)

	if @options[:regexp].match(stdout)
		state = 0
	else
		state = 2
	end
	
	sformat = '%s: %s -- %s'
	perf_data = [
		STATES[state], @options[:file].to_s, stdout,
	]
else
	state = @options[:ignore_missing] ? 0 : 2
	sformat = '%s: %s file not found'
	perf_data = [
		STATES[state], @options[:file].to_s,
	]
end

puts sformat % perf_data

exit state
