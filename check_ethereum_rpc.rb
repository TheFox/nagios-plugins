#!/usr/bin/env ruby

# Coypright (C) 2018 Christian Mayer <christian@fox21.at>

# Use Coin Market Cap API to get the current coin price.


require 'net/http'
require 'json'
require 'optparse'
# require 'pp'

def json_path(json, paths, level = 1)
	first = paths.shift
	
	if level >= 100
		raise 'Level %d reached' % [level]
	end
	
	if json.has_key?(first) && json[first].is_a?(Hash)
		json_path(json[first], paths, level + 1)
	else
		json[first].to_i(16)
	end
end

STATES = ['OK', 'WARNING', 'CRITICAL', 'UNKNOWN']

@options = {
	:hostname => 'localhost',
	:port => 8545,
	:warning => nil,
	:critical => nil,
	:above => true,
}
opts = OptionParser.new do |o|
	o.banner = 'Usage: --host <hostname> --port <number> -w <number> -c <number> [--below] <method> <json_path>'
	o.separator('')
	
	o.on('-H', '--host <hostname>', 'Hostname. Default: localhost') do |hostname|
		@options[:hostname] = hostname
	end
	
	o.on('-p', '--port <number>', 'Port Number') do |port|
		@options[:port] = port.to_i
	end
	
	o.on('-w', '--warning <number>', 'Warning Number') do |num|
		@options[:warning] = num.to_i
	end
	
	o.on('-c', '--critical <number>', 'Critical Number') do |num|
		@options[:critical] = num.to_i
	end
	
	o.on('-b', '--below', 'Return OK when price is below. Default: false') do
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
meth = commands.shift
path = commands.shift
paths = path.split('.')
path_slug = path.gsub(/\./, '-')

state = 0
noutput = 'N/A'

# Build URL.
url = 'http://%s:%d' % [
	@options[:hostname], @options[:port],
]

uri = URI(url)

# Make response to API.
request = Net::HTTP::Post.new(uri, {'Content-Type' => 'application/json'})
request.body = {
	'id' => 1,
	'jsonrpc' => '2.0',
	'method' => 'eth_syncing',
	'params' => {},
}.to_json

begin
	response = Net::HTTP.start(uri.hostname, uri.port) do |http|
		http.request(request)
	end
rescue Exception => e
	state = 3
	state_name = STATES[state]
	perf_data = [
		state_name, path_slug, # Normal Output
		path_slug, @options[:warning], @options[:critical],
	]
	puts '%s: %s=U HTTP REQUEST FAILED | %s=U;%d;%d;0;U' % perf_data
	exit state
end

# Parse JSON response to get Hash array.
json_response = JSON.parse(response.body)

result = json_response['result']

num = json_path(result, paths)

if @options[:above]
	if num > @options[:critical]
		state = 2
	elsif num > @options[:warning]
		state = 1
	end
else
	if num < @options[:critical]
		state = 2
	elsif num < @options[:warning]
		state = 1
	end
end

state_name = STATES[state]

perf_data = [
	state_name, path_slug, num, # Normal Output
	path_slug, num, @options[:warning], @options[:critical], num,
]
puts '%s: %s=%d | %s=%d;%d;%d;0;%d' % perf_data

exit state
