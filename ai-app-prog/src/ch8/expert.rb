#!/usr/local/bin/ruby

class Rule
end

class Fact
end

class Antecedent
end

class Consequent
end

class FactParser
end

class DefRuleParser
end

class Parser
	def parse(txt)
		ctx = Ctx.new
		txt.each {|x|
			if x == "("
				ctx.descend
			elsif x == ")"
				ctx.ascend
			end
		}	
	end
end

class Ctx
	def initialize
		@rules = []
	end
	def descend
		@depth += 1
	end
	def ascend
		@depth -= 1
	end
	def done
		@depth == 0
	end
end

class Expert
	def initialize(input)
		p = Parser.new(input)
		p.parse
	end
end

if __FILE__ == $0		
  e = Expert.new("winston.rbs")
end

