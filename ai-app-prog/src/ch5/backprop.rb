#!/usr/local/bin/ruby

class BackProp
	def run
		err=0.0
		i,sample,iterations,sum=0
		out = ""
		file = File.open("stats.txt", "w")
		file.close			
	end
end

if __FILE__ == $0
	BackProp.new.run
end
