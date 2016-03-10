require 'optparse'
require 'socket'
require_relative 'racket_shell'
require_relative 'racket_lib/print'
require_relative 'racket_lib/capture'

# Use a hash of ipv4 => hostname for discovered nodes.

def my_ipv4_info
	Socket.ip_address_list.find { |interface| interface.ipv4_private? }
end

options           = {:iface => Pcap.lookupdev}    # Set the network interface to the default device (can be reassigned by the user).
live_capture_secs = 0                             # <= 0 value for RacketLib::Capture#live(seconds) causes it to capture indefinitely (default behaviour).
ARGV << '-h' if ARGV.empty?                       # To output help/options banner if no argument is specified.

opt_parser = OptionParser.new do |opts|
	opts.banner = 'Usage: racket.rb [options]'

	opts.on('-i', '--interactive', 'Spawn interactive/inline shell for enhanced packet inspection capability.') do |interactive|
		options[:interactive] = interactive
	end

	opts.on('-w iface', '--interface iface', 'Use network interface iface.') do |iface|
		options[:iface] = iface
	end

	# Doc: fast, first to try, unreliable due to host-based firewalls blocking ICMP traffic by default (e.g. Windows Firewall).
	opts.on('-d', '--discovery', 'Host discovery via ping sweep.') do |ping_sweep|
		options[:ping_sweep] = ping_sweep
	end

	opts.on('-l', '--live_capture [seconds]', 'Live packet capture indefinitely or for a given number of seconds.') do |live_capture|
		options[:live_capture] = true
		live_capture_secs      = live_capture.to_f unless live_capture.nil?
	end

	opts.on('-p', '--promisc', 'Packet capture in promiscuous mode.') do |promisc|
		options[:promisc] = promisc
	end

	opts.on('-f', '--readfile fname', 'Read raw, saved packets from a pcap file fname.') do |readfile|
		options[:readfile] = readfile
	end

	opts.on('-o', '--log fname', 'Log (in append mode) session to output file fname.') do |log|
		options[:log] = log
	end
end.parse!

# This should always remain before any I/O of the actual session begins for ideal capture.
if options[:log]
	log_stream = IO.popen("tee #{options[:log]}", 'a')

	STDOUT.reopen(log_stream)
	# Still need to somehow get STDIN.
	STDERR.reopen(log_stream)
end

RacketLib::Print.info("Network interface: #{options[:iface]}\n\n")
RacketLib::Print.status('Discovering hosts via ping sweep.')                                                                        if options[:ping_sweep]
RacketLib::Print.status('Capturing network traffic live' << (live_capture_secs <= 0 ? '.' : " for #{live_capture_secs} seconds."))  if options[:live_capture]
RacketLib::Print.status('Network interface set to capture in promiscuous mode.')                                                    if options[:promisc]
puts # Newline.

RacketShell.new(options).run                                                            if options[:interactive]
puts RacketShell.new(options).readpkt(options[:readfile])                               if options[:readfile]
puts RacketLib::Capture.new(options[:iface], options[:promisc]).live(live_capture_secs) if options[:live_capture]

# p [my_ipv4_info.ip_address, my_ipv4_info.getnameinfo[0]]
