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
	COMMENT_START = ";"
	DELIMITER = Regexp.new('\(|\)')
	WHITESPACE = Regexp.new('\s')
	attr_reader :tokens
	def initialize
		@tokens = []
		@cur = ""
		@discarding = false
	end
	def parse(txt)
		txt.each_byte {|x|
			c = x.chr
			if @discarding
				@discarding = false if x == 10
			elsif c == COMMENT_START
				shift_accumulator if !@cur.empty?
				@discarding = true
			elsif DELIMITER.match(c)
				shift_accumulator if !@cur.empty?
				@tokens << DelimiterToken.new(c)
			elsif WHITESPACE.match(c)
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

