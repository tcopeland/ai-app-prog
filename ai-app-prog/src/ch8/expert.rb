#!/usr/local/bin/ruby

class Rule
end

class Fact
end

class FactParser
end

class Token
	def initialize(txt)
		@txt = txt
	end
end

class DelimiterToken < Token
end

class CmdToken < Token
	def defrule?
		@txt == "defrule"
	end
end

class Tokenizer
	attr_reader :tokens
	def initialize
		@tokens = []
		@cur = ""
	end
	def parse(txt)
		txt.each_byte {|x|
			c = x.chr
			if c == '(' || c == ')'
				shift_accumulator if !@cur.empty?
				@tokens << DelimiterToken.new(c)
			elsif c =~ /\s/
				shift_accumulator if !@cur.empty?
			else 
				@cur << c
			end
		}
		shift_accumulator if !@cur.empty?	
	end
	private
	def shift_accumulator
		@tokens << CmdToken.new(@cur)
		@cur = ""
	end
end

class Expert
	def initialize(input)
	end
end

if __FILE__ == $0		
  e = Expert.new("winston.rbs")
end

