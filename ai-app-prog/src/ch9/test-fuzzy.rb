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

class VoltageTest < Test::Unit::TestCase
	def test_simple
		v = Voltage.new(5)
		assert(v.volts == 5, "Constructor didn't set values")
		v.add 3
		assert(v.volts == 8, "Voltage.add busted")
		v.subtract 4
		assert(v.volts == 4, "Voltage.subtract busted")
	end
	def test_center_high
		v = Voltage.new(36)
		v.center
		assert(v.volts == 35.0, "Voltage.center didn't reign in high value")
	end
	def test_center_low
		v = Voltage.new(-2.0)
		v.center
		assert(v.volts == 0.0, "Voltage.center didn't reign in low value")
	end
end

class BatteryMembershipTest < Test::Unit::TestCase
	def test_low
		b = BatteryMembership.new	
		assert(b.voltage_low(Voltage.new(1.0)) == 1.0, "Voltage below low end should have resulted in 1.0")
		assert(b.voltage_low(Voltage.new(11.0)) == 0.0, "Voltage above high end should have resulted in 0.0")
	end
	def test_medium
		b = BatteryMembership.new	
		assert(b.voltage_medium(Voltage.new(2.0)) == 0.0, "Voltage below low end should have resulted in 0.0")
		assert(b.voltage_medium(Voltage.new(30.0)) == 0.0, "Voltage above high end should have resulted in 0.0")
	end
	def test_high
		b = BatteryMembership.new	
		assert(b.voltage_high(Voltage.new(20.0)) == 0.0, "Voltage below low end should have resulted in 0.0")
		assert(b.voltage_high(Voltage.new(35.0)) == 1.0, "Voltage above high end should have resulted in 1.0")
	end
end

class MembershipProfilesTest < Test::Unit::TestCase
	def test_spike
		mp = MembershipProfiles.new
		assert(mp.spike_profile(3, 2, 5).to_s[0..3] == "0.66", "Spike profile failed for value close to low")
		assert(mp.spike_profile(4, -5, 5).to_s[0..2] == "0.2", "Spike profile failed for value close to high with negative low")
		assert(mp.spike_profile(-5, -4, -1).to_s[0..3] == "1.33", "Spike profile failed for lots of negative values")
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


