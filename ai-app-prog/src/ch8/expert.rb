#!/usr/local/bin/ruby

class Rule
	attr_reader :name, :antecedents, :consequents
	def initialize(name)
		@name = name
		@antecedents, @consequents = [], []
	end
end

class Fact
	attr_reader :name, :result
	def initialize(name, result)
		@name, @result = name, result
	end
	def to_s
		"Fact (#{@name}, #{@result})"
	end
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
	def to_s
		@txt
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
		return if !toks[ctx.ptr].delim?

		ctx.bump(2) # skip delim and "defrule"
		ctx.rules << Rule.new(toks[ctx.ptr].txt)
	
		ctx.bump	
		while (ctx.ptr <= toks.size - 2) && toks[ctx.ptr].open?
			ctx.push(RuleParser.new)
			ctx.peek.handle(ctx, toks)
			ctx.pop
		end
		
		ctx.pop	
	end
end

class RuleParser
		def handle(ctx, toks)
			while toks[ctx.ptr].delim?
				ctx.bump # skip delim 
				ctx.push(FactParser.new(ctx.rules.last.antecedents))
				ctx.peek.handle(ctx, toks)
				ctx.pop
				ctx.bump # skip delim 
			end
			# move past the "=>"
			ctx.bump
			while toks[ctx.ptr].delim?
				ctx.bump # skip delim 
				ctx.push(FactParser.new(ctx.rules.last.consequents))
				ctx.peek.handle(ctx, toks)
				ctx.pop
				ctx.bump # skip delim 
			end
		end
end

class FactParser
	def initialize(arr)
		@arr = arr
	end
	def handle(ctx, toks)
		@arr << Fact.new(toks[ctx.ptr].txt, toks[ctx.ptr + 1].txt)
		ctx.bump
		ctx.bump
	end
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
	def bump(dist=1)
		@ptr += dist
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
