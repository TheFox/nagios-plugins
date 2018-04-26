#!/usr/bin/env ruby

# Coypright (C) 2018 Christian Mayer <christian@fox21.at>

# Use Coin Market Cap API to get the current coin price.


require 'net/http'
require 'json'
require 'optparse'

API_BASE_URL = 'https://api.coinmarketcap.com/v1/ticker/%s/?convert=%s'
STATES = ['OK', 'WARNING', 'CRITICAL', 'UNKNOWN']

@options = {
	:coin => nil,
	:fiat => 'USD',
	:fiat_lower => 'usd',
	:warning_price => nil,
	:critical_price => nil,
	:above => true,
}
opts = OptionParser.new do |o|
	o.banner = 'Usage: --coin <id> --fiat <name> -w <price> -c <price> [--below]'
	o.separator('')
	
	o.on('-n', '--coin <id>', 'Coin ID') do |coin|
		@options[:coin] = coin
	end
	
	o.on('-f', '--fiat <name>', 'Fiat Name (EUR, USD, etc)') do |fiat|
		@options[:fiat] = fiat.to_s
		@options[:fiat_lower] = @options[:fiat].downcase
	end
	
	o.on('-w', '--warning <price>', 'Warning Price') do |price|
		@options[:warning_price] = price.to_f
	end
	
	o.on('-c', '--critical <price>', 'Critical Price') do |price|
		@options[:critical_price] = price.to_f
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

# Build URL.
url = API_BASE_URL % [@options[:coin], @options[:fiat]]
uri = URI(url)

# Make response to API.
response = Net::HTTP.get(uri)

# Parse JSON response to get Hash array.
json_response = JSON.parse(response)

# Take the first coin.
coin = json_response.first

# Build key for coin field.
fiat_key = 'price_%s' % [@options[:fiat_lower]]
if coin.has_key?(fiat_key)
	coin_price = coin[fiat_key].to_f
else
	# If we don't find a key report UNKNOWN state.
	puts 'UNKNOWN'
	exit 1
end

state = 0
additional_name = nil
if @options[:above]
	additional_name = 'Price above'
	
	if coin_price > @options[:critical_price]
		state = 2
	elsif coin_price > @options[:warning_price]
		state = 1
	end
else
	additional_name = 'Price below'
	
	if coin_price < @options[:critical_price]
		state = 2
	elsif coin_price < @options[:warning_price]
		state = 1
	end
end

state_name = STATES[state]

perf_data = [
	state_name, additional_name, @options[:coin], @options[:fiat], coin_price, # Normal Output
	@options[:coin], coin_price, @options[:warning_price], @options[:critical_price],
]
puts '%s: %s -- %s = %s %.2f | %s=%.2f;%d;%d' % perf_data

exit state
