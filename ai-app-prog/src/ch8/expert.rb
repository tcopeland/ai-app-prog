#!/usr/local/bin/ruby

class Rule
end

class Fact
end

class Antecedent
end

class Consequent
end

class Parser
	def initialize(f)
		@filename = f
	end
	def parse
			
	end
end

class Expert
	def initialize(filename)
		p = Parser.new(filename)
		p.parse
	end
end

if __FILE__ == $0		
  e = Expert.new("winston.rbs")
end

