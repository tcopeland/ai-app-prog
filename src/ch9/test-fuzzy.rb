#!/usr/local/bin/ruby

require 'test/unit'
require 'fuzzy.rb'

class TimerTest < Test::Unit::TestCase
	def test_bump
		t = Timer.new
		t.bump
		assert(t.elapsed == 1, "Timer.bump didn't increase elapsed time")
	end
	def test_reset
		t = Timer.new
		t.bump
		t.reset
		assert(t.elapsed == 0, "Timer.reset didn't zero elapsed time")
	end
end

class ConstrainedValueTest < Test::Unit::TestCase
	def test_simple
		v = ConstrainedValue.new(5, 0.0, 35.0)
		assert(v.current == 5, "Constructor didn't set values")
		v.add 3
		assert(v.current == 8, "ConstrainedValue.add busted")
		v.subtract 4
		assert(v.current == 4, "ConstrainedValue.subtract busted")
	end
	def test_constrain_high
		v = ConstrainedValue.new(36, 0.0, 35.0)
		v.constrain
		assert(v.current == 35.0, "ConstrainedValue.constrain didn't reign in high value")
	end
	def test_constrain_low
		v = ConstrainedValue.new(-2.0, 0.0, 35.0)
		v.constrain
		assert(v.current == 0.0, "ConstrainedValue.constrain didn't reign in low value")
	end
end

class BatteryMembershipFunctionsTest < Test::Unit::TestCase
	def test_low
		b = BatteryMembershipFunctions.new	
		assert(b.low.compute(ConstrainedValue.new(1.0, 0.0, 35.0).current) == 1.0, "Voltage below low end should have resulted in 1.0")
		assert(b.low.compute(ConstrainedValue.new(11.0, 0.0, 35.0).current) == 0.0, "Voltage above high end should have resulted in 0.0")
	end
	def test_medium
		b = BatteryMembershipFunctions.new	
		assert(b.medium.compute(ConstrainedValue.new(2.0, 0.0, 35.0).current) == 0.0, "Voltage below low end should have resulted in 0.0")
		assert(b.medium.compute(ConstrainedValue.new(30.0, 0.0, 35.0).current) == 0.0, "Voltage above high end should have resulted in 0.0")
	end
	def test_high
		b = BatteryMembershipFunctions.new	
		assert(b.high.compute(ConstrainedValue.new(20.0, 0.0, 35.0).current) == 0.0, "Voltage below low end should have resulted in 0.0")
		assert(b.high.compute(ConstrainedValue.new(35.0, 0.0, 35.0).current) == 1.0, "Voltage above high end should have resulted in 1.0")
	end
end

class SpikeProfileTest < Test::Unit::TestCase
	def test_simple
		p = SpikeProfile.new(2,5)
		assert(p.compute(3).to_s[0..3] == "0.66", "Spike profile failed for value close to low")
		p = SpikeProfile.new(-5,5)
		assert(p.compute(4).to_s[0..2] == "0.2", "Spike profile failed for value close to high with negative low")
		p = SpikeProfile.new(-4,-1)
		assert(p.compute(-5).to_s[0..3] == "1.33", "Spike profile failed for lots of negative values")
	end
end

class FuzzyOperationsTest < Test::Unit::TestCase
	def test_and
		f = FuzzyOperations.new
		assert(f.and(2,3) == 3, "Fuzzy and should result in larger value")	
	end
	def test_or
		f = FuzzyOperations.new
		assert(f.or(2,3) == 2, "Fuzzy or should result in smaller value")	
	end
	def test_not
		f = FuzzyOperations.new
		assert(f.not(0.2) == 0.8, "Fuzzy not should result in 1.0 - value")	
	end
end


