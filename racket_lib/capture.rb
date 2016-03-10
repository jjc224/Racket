require 'packetfu'    # Packet class.

module RacketLib
	class Capture
		# Parameters: networking interface, capture in promiscuous mode.
		def initialize(iface, promisc = false)
			@iface    = iface
			@promisc  = promisc
			@capture  = PacketFu::Capture.new(:iface => iface, :promisc => promisc)
		end

		# Live capture for a number of seconds.
		# Default behaviour: indefinitely capture.
		def live(seconds = 0)
			if seconds > 0
				@capture.start
				sleep(seconds)
				@capture.save

				get_and_reset
			else
				@capture.show_live
			end
		end

		# Obtain a number of packets.
		# Default behaviour: get single/next packet.
		def get(amount = 1)
			@capture.start

			until @capture.array.size >= amount    # >=: sometimes multiple packets come seemingly simultaneously, disrupting the assumed linearity.
				@capture.save
			end

			# If the case occurs, simply pop the excess packets off the array.
			diff = @capture.array.size - amount
			diff.times { @capture.array.pop }

			parse_raw
		end

		def inspect(id)
			index = Integer(id)    # User input is read in as a string (either hex or decimal).
			raise IndexError if index >= @capture.array.size || index < 0

			pkt = @capture.array[index]
			p PacketFu::Packet.parse(pkt)
		end

		# Reset stream and array for new packet capturing.
		def reset
			@capture.clear
		end

		def to_file(filename)
			pcapFile = PacketFu::PcapFile.new
			pcapFile.array_to_file(:filename => filename, :array => @capture.array)
		end

		def from_file(filename)
			pcapFile = PacketFu::PcapFile.new
			parse_raw(pcapFile.read_packet_bytes(filename))
		end

		private

		# Process raw packet data into parsed/readable data.
		def parse_raw(array = @capture.array)
			array.map.with_index { |pkt, i| "0x%02X" % i << ' ' * 2 << PacketFu::Packet.parse(pkt).peek }
		end

		# Obtains the formatted packets and resets the stream and array for next capture.
		def get_and_reset
			packets = parse_raw
			reset

			packets
		end
	end
end
