#!/usr/local/bin/ruby

require 'test/unit'
require 'adaptive_resonance_theory.rb'

class VectorTest < Test::Unit::TestCase
	def test_constructor
		v = Vector.new([1,0,0,1])
		assert(v.set?(0))
	end
	def test_magnitude
		v = Vector.new(5)
		v.set(1)
		v.set(3)
		assert(v.magnitude == 2)
	end
	def test_set
		v = Vector.new(5)
		v.set(1)
		assert(v.set?(1))
	end
	def test_clear
		v = Vector.new(5)
		v.set(1)
		v.clear(1)
		assert(!v.set?(1))
	end
	def test_bitwise_and
		v = Vector.new(5)
		v.set(2)
		w = Vector.new(5)
		w.set(2)
		x = v.bitwise_and(w)
		assert(x.set?(2))	
	end
	def test_add_in
		v = Vector.new(5)
		v.set(2)
		w = Vector.new(5)
		w.set(2)
		v.add(w)
		assert(v.value(2) == 2)	
	end
end
