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
		p = RulesetParser.new
		c = Ctx.new
		p.handle(c, Tokenizer.new.tokenize("(defrule rulename)"))
		assert(c.rules.size == 1, "Should have parsed out 1 rule but parsed out #{c.rules.size}")
		assert(c.rules[0].name == "rulename", "Rule name should be 'rulename' but is #{c.rules[0].name}")
	end
end

class RuleParserTest < Test::Unit::TestCase
	def test_simple
		p = RuleParser.new
		c = Ctx.new
		c.rules << Rule.new("test")
		p.handle(c, Tokenizer.new.tokenize("has-hair ?)=>(add(is-hairy ?)"))
		assert(c.rules[0].antecedents.size == 1, "This rule should have 1 antecedent but has #{c.rules[0].antecedents.size}")
		assert(c.rules[0].antecedents[0].name == "has-hair", "Wrong name for antecedent: #{c.rules[0].antecedents[0].name}")
		assert(c.rules[0].antecedents[0].result == "?", "Wrong result for antecedent: #{c.rules[0].antecedents[0].result}")
	end
end

