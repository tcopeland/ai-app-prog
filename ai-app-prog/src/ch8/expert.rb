#!/usr/local/bin/ruby

class Rule
	attr_reader :name
	def initialize(name)
		@name = name
	end
end

class Fact
end

class FactParser
end

class Token
	attr_reader :txt
	def initialize(txt)
		@txt = txt
	end
	def delim?
		false
	end
	def defrule?
		false
	end
end

class DelimiterToken < Token
	def delim?
		true
	end
	def open?
		@txt = "("
	end
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
	def tokenize(txt)
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
		@tokens
	end
	private
	def shift_accumulator
		@tokens << CmdToken.new(@cur)
		@cur = ""
	end
end

class RulesetParser
	def handle(ctx, toks)
		# bail out now if no rules
		return if !toks[ctx.ptr]delim?

		ctx.ptr += 2 # skip delim and defrule
		ctx.rules << Rule.new(toks[ctx.ptr].to_s)
	
		while toks[ctx.ptr].open?
			ctx.push(RuleParser.new)
			ctx.pop
		end
		
		ctx.pop	
	end
end

class RuleParser
end

class FactParser
end	

class Ctx
	attr_reader :rules, :ptr
	def initialize
		@ptr = 0
		@rules = []
		@parser_stack = [RulesetParser.new]
	end
	def push(s)
		@parser_stack << s
	end
	def pop
		@parser_stack.delete_at(@parser_stack.size-1)
	end
	def peek
		@parser_stack.last
	end
end

class Parser
	attr_reader :rules
	def initialize(input)
		toks = Tokenizer.new.tokenize(input.kind_of?(File) ? File.read(input) : input)
		ctx = Context.new
		ctx.peek.handle(ctx, toks)	
	end
end


class Expert
	def initialize(input)
		p = Parser.new(input)		
	end
end

if __FILE__ == $0		
  e = Expert.new("winston.rbs")
end

