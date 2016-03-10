require 'colorize'

module RacketLib
	class Print
		class << self
			def info(msg)
				puts "[*] #{msg}"
			end
	
			def status(msg)
				puts "[+] #{msg}"
			end
	
			def error(msg)
				puts "[x] #{msg}"
			end
		end
	end
end
