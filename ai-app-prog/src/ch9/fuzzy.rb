#!/usr/local/bin/ruby

class Simulation
	@voltage = 20.0
	@temperature = 12.0
	@timer = 0.0
	@load = [0.02, 0.04, 0.06, 0.08, 0.1]
	@current_load = 0.0
	def charge(t)
		result = Math.sin(t/100.0)
		return result < 0.0 ? 0.0:result 
	end
	def simulate	

	end
end

class Battery
	TRICKLE_CHARGE = 0
	FAST_CHARGE = 1
	@i = 0
	def charge_control
		tm = TemperatureMembership.new
		bm = BatteryMembership.new
		ops = FuzzyOperations.new
		i += 1
		if (i % 10) == 0
			if normalize(bm.voltage_high(voltage))
				mode = TRICKLE_CHARGE
			elsif normalize(tm.temp_hot(temperature))
				mode = TRICKLE_CHARGE
			elsif normalize(ops.and(ops.not(bm.voltage_high(voltage), tm.temp_hot(temperature))))
				mode = FAST_CHARGE
			end
		end
	end
end

class TemperatureMembership
	def temp_cold(temp)
		low = 15.0
		low_plateau = 15.0
		high_plateau = 15.0
		high = 25.0
		if temp < low 
			return 1.0	
		end
		if temp > high
			return 0.0
		end
		profiles = MembershipProfiles.new
		return profiles.plateau_profile(voltage, low, low_plateau, high_plateau, high)
	end
	def temp_medium(temp)
		low = 15.0
		low_plateau = 25.0
		high_plateau = 35.0
		high = 45.0
		if temp < low  || temp > high
			return 0.0	
		end
		profiles = MembershipProfiles.new
		return profiles.plateau_profile(voltage, low, low_plateau, high_plateau, high)
	end
	def temp_hot(temp)
		low = 35.0
		low_plateau = 45.0
		high_plateau = 45.0
		high = 45.0
		if temp < low 
			return 0.0	
		end
		if temp > high
			return 1.0
		end
		profiles = MembershipProfiles.new
		return profiles.plateau_profile(voltage, low, low_plateau, high_plateau, high)
	end
end

class BatteryMembership
	def voltage_low(voltage)
		low = low_plateau =  high_plateau = 5.0
		high = 10.0
		if voltage < low
			return 1.0
		end
		if voltage > high 
			return 0.0
		end
		profiles = MembershipProfiles.new
		return profiles.plateau_profile(voltage, low, low_plateau, high_plateau, high)
	end
	def voltage_medium(voltage)
		low = 5.0
		low_plateau = 10.0
		high_plateau = 20.0	
		high = 25.0
		if voltage < low || voltage > high
			return 0.0
		end
		profiles = MembershipProfiles.new
		return profiles.plateau_profile(voltage, low, low_plateau, high_plateau, high)
	end
	def voltage_high(voltage)
		low = 25.0
		low_plateau = 30.0
		high_plateau = 30.0
		high = 30.0
		if voltage < low
			return 0.0
		end
		if voltage > high 
			return 1.0
		end
		profiles = MembershipProfiles.new
		return profiles.plateau_profile(voltage, low, low_plateau, high_plateau, high)
	end
end

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

if __FILE__ == $0
	
end
