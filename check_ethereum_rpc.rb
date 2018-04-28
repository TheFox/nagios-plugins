#!/usr/bin/env ruby

#require 'pp'

pwarn, pcrit = ARGV

pwarn = pwarn.to_f
pcrit = pcrit.to_f

percent = %x[/usr/local/bin/geth --exec 'eth.syncing.currentBlock / eth.syncing.highestBlock * 100' attach].to_f

# puts '%f %f' % [pwarn, pcrit]

state = 0
if percent >= pcrit
	print 'CRITICAL'
	state = 2
elsif percent >= pwarn
	print 'WARNING'
	state = 1
else
	print 'OK'
end

puts ': %.2f | sync=%.2f%%;%.1f;%.1f;0;100' % [percent, percent, pwarn, pcrit]
exit state
