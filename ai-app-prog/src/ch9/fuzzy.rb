#!/usr/local/bin/ruby

class TrickleCharge
	def load	
		return 1.0
	end 
end

class FastCharge
	def load	
		return 10.0
	end 
end

class Timer
	attr_accessor :elapsed
	def initialize
		@elapsed = 0
	end
	def reset
		@elapsed = 0
	end
	def bump
		@elapsed += 1
	end
end

class Voltage
	attr_accessor :volts
	def initialize(start)
		@volts = start
	end
	def add(amount)
		@volts += amount	
	end
	def subtract(amount)
		@volts -= amount	
	end
	def center
		if @volts < 0.0
			@volts = 0.0
		elsif @volts > 35.0
			@volts = 35.0
		end
	end
end

class Simulation
	attr_accessor :temperature, :voltage
	LOAD = [0.02, 0.04, 0.06, 0.08, 0.1]

	def initialize(battery)
		@battery = battery
		@voltage = Voltage.new(20.0)
		@temperature = 12.0
		@current_load = LOAD[0]
		@t=0.0
	end

	def charge
		result = Math.sin(@t/100.0)
		return result < 0.0 ? 0.0 : result
	end

	def simulate(timer)	
		if rand < 0.02
			@current_load = rand(LOAD.size)
		end
		@voltage.subtract LOAD[@current_load]
		@voltage.add (charge * Math.sqrt(timer.elapsed))/@battery.mode.load
		@voltage.center
		if @battery.mode.kind_of? FastCharge
			if @voltage.volts > 25
				@temperature += (LOAD[@current_load] * (Math.sqrt(timer.elapsed)/25.0)) * 10.0
			elsif @voltage.volts > 15
				@temperature += (LOAD[@current_load] * (Math.sqrt(timer.elapsed)/20.0)) * 10.0
			else	
				@temperature += (LOAD[@current_load] * (Math.sqrt(timer.elapsed)/15.0)) * 10.0
			end
		else 
			if @temperature > 20.0
				@temperature -= (LOAD[@current_load] * (Math.sqrt(timer.elapsed)/20.0)) * 10.0
			else
				@temperature -= (LOAD[@current_load] * (Math.sqrt(timer.elapsed)/100.0)) * 10.0
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
	attr_accessor :mode
	def initialize
		@mode = FastCharge.new
		@tm = TemperatureMembership.new
		@bm = BatteryMembership.new
		@ops = FuzzyOperations.new
		@count = 0
	end
	def charge_control(simulation, timer)
		@count += 1
		if (@count % 10) == 0
			if normalize(@bm.voltage_high(simulation.voltage)) >0
				@mode = TrickleCharge.new
				timer.reset
			elsif normalize(@tm.temp_hot(simulation.temperature)) > 0
				@mode = TrickleCharge.new
				timer.reset
			elsif normalize(@ops.and(@ops.not(@bm.voltage_high(simulation.voltage)), @ops.not(@tm.temp_hot(simulation.temperature)))) > 0
				@mode = FastCharge.new
				timer.reset
			end
		end
	end
	def normalize(input)
		input >= 0.5 ? 1 : 0
	end
end

class TemperatureMembership	
	def initialize
		@profiles = MembershipProfiles.new
	end
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
		return @profiles.plateau_profile(temp, low, low_plateau, high_plateau, high)
	end
	def temp_warm(temp)
		low = 15.0
		low_plateau = 25.0
		high_plateau = 35.0
		high = 45.0
		if temp < low or temp > high
			return 0.0	
		end
		return @profiles.plateau_profile(temp, low, low_plateau, high_plateau, high)
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
		return @profiles.plateau_profile(temp, low, low_plateau, high_plateau, high)
	end
end

class BatteryMembership
	def initialize
		@profiles = MembershipProfiles.new
	end
	def voltage_low(voltage)
		low = 5.0
		low_plateau = 5.0
		high_plateau = 5.0
		high = 10.0
		if voltage.volts < low
			return 1.0
		end
		if voltage.volts > high 
			return 0.0
		end
		return @profiles.plateau_profile(voltage.volts, low, low_plateau, high_plateau, high)
	end
	def voltage_medium(voltage)
		low = 5.0
		low_plateau = 10.0
		high_plateau = 20.0	
		high = 25.0
		if voltage.volts  < low or voltage.volts  > high
			return 0.0
		end
		return @profiles.plateau_profile(voltage.volts, low, low_plateau, high_plateau, high)
	end
	def voltage_high(voltage)
		low = 25.0
		low_plateau = 30.0
		high_plateau = 30.0
		high = 30.0
		if voltage.volts < low
			return 0.0
		end
		if voltage.volts > high 
			return 1.0
		end
		return @profiles.plateau_profile(voltage.volts, low, low_plateau, high_plateau, high)
	end
end

class MembershipProfiles
	def spike_profile(value, low, high)
		value += (-low)
		if low<0 and high<0
			high = -(high-low)
		elsif low<0 and high>0
			high += -low
		elsif low>0 and high>0
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
		if value< low
			return 0.0
		elsif value> high
			return 0.0
		elsif value>= low_plateau and value<=high_plateau
			return 1.0
		elsif value< low_plateau 
			return (value-low) * upslope
		elseif value> hi_plateau
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
		(a<b) ? a : b	
	end
	def not(a)
		1.0 - a
	end
end

if __FILE__ == $0
	b = Battery.new
	s = Simulation.new(b)	
	t = Timer.new
	3000.times {|count|
		s.simulate(t)
		b.charge_control(s, t)
		t.bump
		if count % 25 == 0
			puts "#{count},#{s.voltage.volts},#{s.temperature}"
		end
	}	
end
