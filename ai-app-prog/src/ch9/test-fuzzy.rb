#!/usr/local/bin/ruby

require 'test/unit'
require 'fuzzy.rb'


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


