#!/usr/local/bin/ruby

require 'test/unit'
require 'expert.rb'

class TokenizerTest < Test::Unit::TestCase
	def test_tokenize_delimiters
		t = Tokenizer.new
		t.parse("(")
		assert(t.tokens.size == 1, "#{t.tokens.size} tokens, should be 1")
	end
	def test_discard_ws
		t = Tokenizer.new
		t.parse("   (  \n\r\t  \t  ")
		assert(t.tokens.size == 1, "#{t.tokens.size} tokens, should be 1")
	end
	def test_command
		t = Tokenizer.new
		t.parse("(defrule")
		assert(t.tokens.size == 2)
		assert(t.tokens[1].kind_of?(CmdToken))
		assert(t.tokens[1].defrule?)
	end
	def test_discard_comments
		t = Tokenizer.new
		t.parse("; this is a comment, followed by a defrule   \n (defrule")
		assert(t.tokens.size == 2)
	end
end

