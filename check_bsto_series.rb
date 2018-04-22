#!/usr/bin/env ruby

# Coypright (C) 2018 Christian Mayer <christian@fox21.at>


require 'net/http'
require 'json'
require 'optparse'
require 'pp'

API_BASE_URL = 'https://bs.to/serie/%s/%d'

@options = {
	:series_name => nil,
	:series_saison => nil,
	:warn_episode => nil,
	:critical_episode => nil,
	:lang => 'en',
	:unknown_state => 3,
}
opts = OptionParser.new do |o|
	o.banner = 'Usage: --series <name> --saison <number> -w <episode> -c <episode> --lang en|de'
	o.separator('')
	
	o.on('-n', '--series <name>', 'Series Name') do |series_name|
		@options[:series_name] = series_name
	end
	
	o.on('-s', '--saison <name>', 'Saison Number') do |saison|
		@options[:series_saison] = saison.to_i
	end
	
	o.on('-w', '--warn <episode>', 'Warning Episode') do |episode|
		@options[:warn_episode] = episode.to_i
	end
	
	o.on('-c', '--critical <episode>', 'Critical Episode') do |episode|
		@options[:critical_episode] = episode.to_i
	end
	
	o.on('-l', '--lang <string>', 'Language: English or German') do |lang|
		@options[:lang] = lang.downcase
	end
	
	o.on('-u', '--unknown <int>', 'Treat UNKNOWN state with different status code. Default: 3') do |unknown_state|
		@options[:unknown_state] = unknown_state.to_i
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
url = API_BASE_URL % [@options[:series_name], @options[:series_saison]]

uri = URI(url)

# Make response to API.
response = Net::HTTP.get(uri)

not_found_pos = response.index('Staffel nicht gefunden')
if not not_found_pos.nil?
	puts 'UNKNOWN -- Saison not found'
	exit @options[:unknown_state]
end

# Search the beginning position of the episodes table.
table_beginning_pos = response.index('<table class="episodes">')

# Cut everything above the table beginning to get the table end.
table = response[table_beginning_pos..-1]

# Search the end position of the table.
# Hopefully there is no other table inside the table.
table_end_pos = table.index('</table>')

# Cut everything below the table.
table = table[0...table_end_pos]

regex_s = [
	'<tr>',
		'<td>',
			'<a href="[^"]{6,}" title="([^"]{1,})">(\d{1,3})<.a>', # Title, Episode Number
		'<.td>',
		'<td>',
			'<a [^>]{20,}>[^<]{1,}<s([tp]).{10}', # Language based on the HTML tag.
].join('\s{0,20}') # Whitespace between HTML tags.

regex = Regexp.new(regex_s)

episodes = table.scan(regex)

state = 0 # OK
title = 'N/A'
etitle = nil
id = 0
eid = nil
lang = 'N/A'
elang = nil
episodes.each do |episode|
	etitle, eid, etag = episode
	
	etitle = etitle.strip
	eid = eid.to_i
	elang = etag == 't' ? 'de' : 'en'
	
	case @options[:lang]
	when 'en'
		# puts "episode: #%d %s (%s) '%s'" % [eid, etag, elang, etitle]
		
		if eid >= @options[:critical_episode]
			state = 2
			title = etitle
			id = eid
			lang = elang
			break
		elsif eid >= @options[:warn_episode]
			state = 1
			title = etitle
			id = eid
			lang = elang
			# contine loop
		end
	when 'de'
		if elang == 'de'
			# puts "episode: #%d %s (%s) '%s'" % [eid, etag, elang, etitle]
			
			if eid >= @options[:critical_episode]
				state = 2
				title = etitle
				id = eid
				lang = elang
				break
			elsif eid >= @options[:warn_episode]
				state = 1
				title = etitle
				id = eid
				lang = elang
				# contine loop
			end
		end
	end
end

if state == 0
	title = etitle
	id = eid
	lang = elang
end

state_name = ['OK', 'WARNING', 'CRITICAL', 'UNKNOWN'][state]

puts '%s -- #%d %s %s|%d,%s,%s,%d,%d,%s' % [state_name, id, lang, title,
	id, lang, title, @options[:warn_episode], @options[:critical_episode], @options[:lang]]

exit state
