#!/usr/bin/env ruby

# Coypright (C) 2018 Christian Mayer <christian@fox21.at>

# Check on IMDb if a TV series has ended.


require 'net/http'
require 'json'
require 'optparse'
require 'pp'

class ImdbError < RuntimeError
	attr_reader :state
	
	def initialize(msg = 'UNKNOWN', state = 3)
		@state = state
		super(msg)
	end
end

IMDB_TITLE_BASE_URL = 'https://www.imdb.com/title/%s/'
STATES = ['OK', 'WARNING', 'CRITICAL', 'UNKNOWN']

@options = {
	:url => nil,
	:title => nil,
	:is_series => false,
}
opts = OptionParser.new do |o|
	o.banner = 'Usage: [--url <string>|--title <id>] [--series]'
	o.separator('')
	
	o.on('-u', '--url <string>', 'URL') do |url|
		@options[:url] = url
	end
	
	o.on('-t', '--title <id>', 'ID. E.g. tt1837492') do |title|
		@options[:title] = title
		@options[:url] = IMDB_TITLE_BASE_URL % [title]
	end
	
	o.on('-s', '--series', 'Title is a TV series.') do
		@options[:is_series] = true
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
url = @options[:url]
uri = URI(url)

# Make response to API.
response = Net::HTTP.get(uri)

state = 0
msg = 'N/A'

begin
	if @options[:is_series]
		regex = /<meta property='og:title' content="(.{1,30}) .TV Series/
		names = response.scan(regex)
		if names.nil? || names.length == 0 || names.first.nil? || names.first.length == 0
			
			regex = /<title>(.{1,32}) \(\d{4}\) . IMDb<.title>/
			titles = response.scan(regex)
			if titles.nil? || titles.length == 0 || titles.first.nil? || titles.first.length == 0
				raise ImdbError.new('No Name found')
			else
				name = titles.first.first
			end
		else
			name = names.first.first
		end

		regex = />TV Series \((\d{4})[^0-9]{1,3}(\d{0,4})/
		dates = response.scan(regex)
		if dates.nil? || dates.length == 0 || dates.first.nil? || dates.first.length == 0
			raise ImdbError.new('No series: "%s"' % [name])
		end
		inner = dates.shift
		begin_year, end_year = inner.map{ |s| s.to_i }
		
		if end_year != 0 && end_year >= begin_year
			state = 2
			msg = 'TV Series "%s" (%d-%d) has ended' % [name, begin_year, end_year]
		else
			state = 0
			msg = 'TV Series "%s" (%d)' % [name, begin_year]
		end
	else
		raise ImdbError.new('Invalid options')
	end
rescue ImdbError => e
	state = e.state
	msg = e.message
end

state_name = STATES[state]

perf_data = [
	state_name, msg, # Normal Output
]
puts "%s: %s" % perf_data

exit state
