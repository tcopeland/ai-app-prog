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

class PlateauProfile
	attr_accessor :low, :low_plateau, :high_plateau, :high
	def initialize(low, low_plateau, high_plateau, high)
		@low = low	
		@low_plateau = low_plateau
		@high_plateau = high_plateau
		@high = high
	end
	def compute(value)
		tmplp = @low_plateau
		tmphp = @high_plateau
		tmph = @high
		value += -@low
		if @low < 0.0
			tmplp += -@low
			tmphp += -@low
			tmph += -@low
		else
			tmplp -= @low
			tmphp -= @low
			tmph -= @low
		end
		tmpl = 0
		upslope = (1.0/(tmplp - tmpl))
		downslope = (1.0/(tmph - tmphp))
		if value< tmpl
			return 0.0
		elsif value> tmph
			return 0.0
		elsif value>= tmplp and value<=tmphp
			return 1.0
		elsif value< tmplp 
			return (value-tmpl) * upslope
		elseif value> tmphp
			return (tmph-value)*downslope
		end
		return 0.0
	end
end

class TemperatureMembership	
	def initialize
		@profiles = MembershipProfiles.new
		@cold = PlateauProfile.new(15.0, 15.0, 15.0, 25.0)
		@warm = PlateauProfile.new(15.0, 25.0, 35.0, 45.0)
		@hot = PlateauProfile.new(35.0, 45.0, 45.0, 45.0)
	end
	def temp_cold(temp)
		if temp < @cold.low 
			return 1.0	
		end
		if temp > @cold.high
			return 0.0
		end
		return @cold.compute(temp)
	end
	def temp_warm(temp)
		if temp < @warm.low or temp > @warm.high
			return 0.0	
		end
		return @warm.compute(temp)
	end
	def temp_hot(temp)
		if temp < @hot.low 
			return 0.0	
		end
		if temp > @hot.high
			return 1.0
		end
		return @hot.compute(temp)
	end
end

class BatteryMembership
	def initialize
		@profiles = MembershipProfiles.new
		@low = PlateauProfile.new(5.0, 5.0, 5.0, 10.0)
		@med = PlateauProfile.new(5.0, 10.0, 20.0, 25.0)
		@high = PlateauProfile.new(25.0, 30.0, 30.0, 30.0)
	end
	def voltage_low(voltage)
		if voltage.volts < @low.low
			return 1.0
		end
		if voltage.volts > @low.high 
			return 0.0
		end
		return @low.compute(voltage.volts)
	end
	def voltage_medium(voltage)
		if voltage.volts < @med.low or voltage.volts > @med.high
			return 0.0
		end
		return @med.compute(voltage.volts)
	end
	def voltage_high(voltage)
		if voltage.volts < @high.low
			return 0.0
		end
		if voltage.volts > @high.high 
			return 1.0
		end
		return @high.compute(voltage.volts)
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
