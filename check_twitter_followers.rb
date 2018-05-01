#!/usr/bin/env ruby

# Coypright (C) 2018 Christian Mayer <christian@fox21.at>

# Check Twitter Followers of any given user.


require 'net/http'
require 'json'
require 'optparse'

API_BASE_URL = 'https://twitter.com/%s'
STATES = ['OK', 'WARNING', 'CRITICAL', 'UNKNOWN']

@options = {
	:nick => nil,
	:warning_followers => nil,
	:critical_followers => nil,
	:above => false,
}
opts = OptionParser.new do |o|
	o.banner = 'Usage: --user <nick> -w <followers> -c <followers> [--above]'
	o.separator('')
	
	o.on('-n', '--user <nick>', 'Twitter @Nick') do |nick|
		@options[:nick] = nick
	end
	
	o.on('-w', '--warning <followers>', 'Warning Followers') do |followers|
		@options[:warning_followers] = followers.to_i
	end
	
	o.on('-c', '--critical <followers>', 'Critical Followers') do |followers|
		@options[:critical_followers] = followers.to_i
	end
	
	o.on('-a', '--above', 'Return OK when followers are below. Default: false') do
		@options[:above] = true
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
url = API_BASE_URL % [@options[:nick]]

uri = URI(url)

# Make response to API.
response = Net::HTTP.get(uri)

matches = response.scan(/ title="([^ ]{1,}) Follower" data-nav="followers"/)

state = 0
if matches.count > 0
	followers_s = matches.first.first
	followers = followers_s.gsub(/\./, '').to_i
else
	puts 'UNKNOWN'
	exit 3
end

if @options[:critical_followers].nil? && @options[:warning_followers].nil?
	# Only collect data. Do not compare anything. It's always fine.
	
	perf_data = [
		followers, # Normal Output
		followers,
	]
	puts 'OK: %d Followers | followers=%d' % perf_data
	exit 0
end

if @options[:above]
	if followers > @options[:critical_followers]
		state = 2
	elsif followers > @options[:warning_followers]
		state = 1
	end
else
	if followers < @options[:critical_followers]
		state = 2
	elsif followers < @options[:warning_followers]
		state = 1
	end
end

state_name = STATES[state]

perf_data = [
	state_name,	followers, # Normal Output
	followers, @options[:warning_followers], @options[:critical_followers], followers,
]
puts '%s: %d Followers | followers=%d;%d;%d;0;%d' % perf_data

exit state
