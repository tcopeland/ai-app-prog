#!/usr/local/bin/ruby

TRICKLE_CHARGE = 0
FAST_CHARGE = 1

class Simulation
	attr_accessor :temperature, :voltage

	def initialize(battery)
		@battery = battery
		@voltage = 20.0
		@temperature = 12.0
		@timer = 0.0
		@load = [0.02, 0.04, 0.06, 0.08, 0.1]
		@current_load = 0.0
		@t=0.0
	end

	def reset_timer
		@timer = 0
	end

	def bump_timer
		@timer += 1
	end

	def charge
		result = Math.sin(@t/100.0)
		return result < 0.0 ? 0.0:result
	end

	def center_voltage
		if @voltage < 0.0
			@voltage = 0.0
		elsif @voltage > 35.0
			@voltage = 35.0
		end
	end
	
	def simulate	
		if rand < 0.02
			@current_load = rand(@load.size)
		end
		@voltage -= @load[@current_load]
		if @battery.get_mode == FAST_CHARGE	
			@voltage += charge * Math.sqrt(@timer)
		else
			@voltage += (charge * Math.sqrt(@timer))/10.0
		end
		center_voltage
		if @battery.get_mode == FAST_CHARGE
			if @voltage > 25
				@temperature += (@load[@current_load] * (Math.sqrt(@timer)/25.0)) * 10.0
			elsif voltage > 15
				@temperature += (@load[@current_load] * (Math.sqrt(@timer)/20.0)) * 10.0
			else	
				@temperature += (@load[@current_load] * (Math.sqrt(@timer)/15.0)) * 10.0
			end
		else 
			if @temperature > 20.0
				@temperature -= (@load[@current_load] * (Math.sqrt(@timer)/20.0)) * 10.0
			else
				@temperature -= (@load[@current_load] * (Math.sqrt(@timer)/100.0)) * 10.0
			end
		end
		if @temperature < 0.0	
			@temperature = 0.0
		elsif @temperature > 40.0
			@temperature = 40.0
		end
		@t += 1
	end
end

class Battery
	@mode = TRICKLE_CHARGE
	def initialize
		@count = 0
	end
	def charge_control(simulation)
		tm = TemperatureMembership.new
		bm = BatteryMembership.new
		ops = FuzzyOperations.new
		@count += 1
		if (@count % 10) == 0
			if normalize(bm.voltage_high(simulation.voltage))
				@mode = TRICKLE_CHARGE
				simulation.reset_timer
			elsif normalize(tm.temp_hot(simulation.temperature))
				@mode = TRICKLE_CHARGE
				simulation.reset_timer
			elsif normalize(ops.and(ops.not(bm.voltage_high(simulation.voltage), ops.not(tm.temp_hot(simulation.temperature)))))
				@mode = FAST_CHARGE
				simulation.reset_timer
			end
		end
	end
	def get_mode	
		return @mode
	end
	def normalize(input)
		return input >= 0.5 ? 1 : 0
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
		downslope = (1.0/(high - high_plateau))
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
	b = Battery.new
	s = Simulation.new(b)
	3000.times {|count|
		s.simulate
		b.charge_control(s)
		s.bump_timer
		puts "#{count}: V=#{s.voltage} T=#{s.temperature} Mode=#{b.get_mode == 0 ? 'Trickle' : 'Fast' }"
	}	
end
