#!/usr/local/bin/ruby

class MembershipProfiles
	def spike_profile(value, low, high)
		value += (-low)
		if low<0 && high<0
			high = -(high-low)
		elsif low<0 && high>0
			high += -low
		elsif low>0 && high>0
			high -= low
		end
		peak = high/2.0
		low = 0.0
		if value<peak
			return value/peak
		elsif value>peak
			return (high-value)/peak
		end
		return 1.0
	end
	def plateau_profile(value, low, low_plateau, high_plateau, high)
		value += -low
		if low < 0.0
			low_plateau += -low
			high_plateau += -low
			high += -low
		else
			low_plateau -= low
			high_plateau -= low
			high -= low
		end
		low = 0
		upslope = (1.0/(low_plateau - low))
		downslope = (1/0/(high - high_plateau))
		if value < low
			return 0.0
		elsif value > high
			return 0.0
		elsif value>= low_plateau && value<=high_plateau
			return 1.0
		elsif value < low_plateau 
			return (value-low) * upslope
		elseif value > hi_plateau
			return (high-value)*downslope
		end
		return 0.0
	end
end

class FuzzyOperations
	def and(a, b)
		(a>b) ? a : b	
	end
	def or(a, b)
		(a>b) ? b : a	
	end
	def not(a)
		1.0 - a
	end
end
