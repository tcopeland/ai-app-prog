#!/usr/local/bin/ruby

require 'test/unit'
require 'expert.rb'

class TokenizerTest < Test::Unit::TestCase
	def test_tokenize_delimiters
		t = Tokenizer.new
		t.tokenize("(")
		assert(t.tokens.size == 1, "#{t.tokens.size} tokens, should be 1")
	end
	def test_discard_ws
		t = Tokenizer.new
		t.tokenize("   (  \n\r\t  \t  ")
		assert(t.tokens.size == 1, "#{t.tokens.size} tokens, should be 1")
	end
	def test_command
		t = Tokenizer.new
		t.tokenize("(defrule")
		assert(t.tokens.size == 2)
		assert(t.tokens[1].kind_of?(CmdToken))
		assert(t.tokens[1].defrule?)
	end
	def test_discard_comments
		t = Tokenizer.new
		t.tokenize("; this is a comment, followed by a defrule   \n (defrule")
		assert(t.tokens.size == 2)
	end
end

class RulesetParserTest < Test::Unit::TestCase
	def test_simple
		t = Tokenizer.new
		t.tokenize("(defrule rulename)")
		p = RulesetParser.new
		c = Ctx.new
		p.handle(c, t.tokens[0])
		p.handle(c, t.tokens[1])
		p.handle(c, t.tokens[2])
		p.handle(c, t.tokens[3])
		assert(c.rules.size == 1, "Should have parsed out 1 rule but parsed out #{c.rules.size}")
		assert(c.rules[0].name == "rulename", "Rule name should be 'rulename' but is #{c.rules[0].name}")
	end
end

