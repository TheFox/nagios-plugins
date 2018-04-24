#!/usr/bin/env ruby

require 'pp'

pwarn, pcrit = ARGV

pwarn = pwarn.to_f
pcrit = pcrit.to_f

percent = %x[/usr/local/bin/geth --exec 'eth.syncing.currentBlock / eth.syncing.highestBlock * 100' attach].to_f

if percent >= pcrit
	puts 'CRITICAL %.2f >= %.2f|%.2f' % [percent, pcrit, percent]
	exit 2
elsif percent >= pwarn
	puts 'WARNING %.2f => %.2f|%.2f' % [percent, pwarn, percent]
	exit 1
end

puts 'OK %.2f|%.2f' % [percent, percent]
exit 0
