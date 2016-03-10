require_relative 'racket_lib/print'
require_relative 'racket_lib/capture'

class RacketShell
	@@commands = [
		# Shorthand, Longhand
		# * This pair-like order must be maintained for operations on this array. *
		nil, :help,
		nil, :exit,    # Not actually a command: break condition.
		:np, :nextpkt,
		:ip, :inspectpkt,
		# nil, :save,
		# :mp, :manp,
		:sp, :savepkt,
		:rp, :readpkt,
		# :ap, :appendp,
		:fp, :flushpkt,
		# :pc, :printconf,
		:sh, :shell
	]

	def initialize(options = {})
		@CaptureLib = RacketLib::Capture.new(options[:iface], options[:promisc])
	end

	# Start of shell command functionality.
	def help
		head_msg = 'Commands are seperated by a shorthand and longhand, respectively. The commands recognised are as follows:'
		output = "\t#{head_msg}\n"
		output << "\t" << '-' * head_msg.length << "\n"

		@@commands.each_with_index do |command, index|
			output << "\t" << (command.nil? ? 'N/A' : command.to_s)
			output << "\n" if index.odd?
		end

		output
	end

	def nextpkt(amount = 1)
		amount = amount.to_i unless amount.is_a?(Integer)    # User-input is read in as a string.

		RacketLib::Print.status("Fetching #{amount} packets.\n\n")
		@CaptureLib.get(amount)
	end

	def inspectpkt(id)
		begin
			@CaptureLib.inspect(id)
		rescue IndexError
			RacketLib::Print.error("Packet #{id} does not exist.")
		end
	end

	def savepkt(filename)
		RacketLib::Print.status("Saving fetched packets to #{filename}.\n\n")
		@CaptureLib.to_file(filename)
	end

	def readpkt(filename)
		RacketLib::Print.status("Reading saved packets from #{filename}.\n\n")
		@CaptureLib.from_file(filename)
	end

	def flushpkt
		RacketLib::Print.status('Flushing packet storage.')
		@CaptureLib.reset
	end

	def shell(cmd)    # Shorthand alias: sh
		`#{cmd}` unless cmd.empty?
	end
	# End of shell command functionality.

	def exec(cmd, args)
		return if cmd.empty?
		return RacketLib::Print.error("Command '#{cmd}' does not exist. Enter 'help' for usage help.") unless @@commands.include?(cmd.to_sym)    # Spacing issue. :(

		params = [cmd.to_sym]
		params << args unless args.empty?

		send(*params)
	end

	def run
		loop do
			print "RacketShell> "
			cmd = gets.strip.partition(' ')

			break if cmd[0] == 'exit'

			begin
				puts exec(cmd[0], cmd[2]), "\n"
			rescue ArgumentError
				RacketLib::Print.error("Incorrect number of arguments (#{method(cmd[0].to_sym).arity} expected).\n\n")
			end
		end
	end

	# Alias methods for shorthand usage.
	(0...@@commands.length).step(2).each do |i|
		unless @@commands[i].nil? || @@commands[i.next].nil?
			alias_method @@commands[i], @@commands[i.next]
		end
	end
end
