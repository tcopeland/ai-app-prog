#!/usr/local/bin/ruby

require 'test/unit'
require 'expert.rb'

class ParserTest < Test::Unit::TestCase
	def test_defrule
		p = Parser.new("(defrule init")
		p.parse
		assert(p.context.rules.size == 1)
	end
end

