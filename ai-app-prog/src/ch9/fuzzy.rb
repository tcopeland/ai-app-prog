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

class ConstrainedValue
	attr_accessor :current
	def initialize(start, low, high)
		@current = start
		@low = low
		@high = high
	end
	def add(amount)
		@current += amount	
	end
	def subtract(amount)
		@current -= amount	
	end
	def constrain
		if @current < @low
			@current = @low
		elsif @current > @high
			@current = @high
		end
	end
end

class Simulation
	attr_accessor :temperature, :voltage
	LOAD = [0.02, 0.04, 0.06, 0.08, 0.1]

	def initialize(battery)
		@battery = battery
		@voltage = ConstrainedValue.new(20.0, 0.0, 35.0)
		@temperature = ConstrainedValue.new(12.0, 0.0, 40.0)
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
		@voltage.constrain
		if @battery.mode.kind_of? FastCharge
			if @voltage.current > 25
				@temperature.add (LOAD[@current_load] * (Math.sqrt(timer.elapsed)/25.0)) * 10.0
			elsif @voltage.current > 15
				@temperature.add (LOAD[@current_load] * (Math.sqrt(timer.elapsed)/20.0)) * 10.0
			else	
				@temperature.add (LOAD[@current_load] * (Math.sqrt(timer.elapsed)/15.0)) * 10.0
			end
		else 
			if @temperature.current > 20.0
				@temperature.subtract (LOAD[@current_load] * (Math.sqrt(timer.elapsed)/20.0)) * 10.0
			else
				@temperature.subtract (LOAD[@current_load] * (Math.sqrt(timer.elapsed)/100.0)) * 10.0
			end
		end
		@temperature.constrain
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
			if normalize(@bm.high(simulation.voltage)) >0
				@mode = TrickleCharge.new
				timer.reset
			elsif normalize(@tm.hot(simulation.temperature.current)) > 0
				@mode = TrickleCharge.new
				timer.reset
			elsif normalize(@ops.and(@ops.not(@bm.high(simulation.voltage)), @ops.not(@tm.hot(simulation.temperature.current)))) > 0
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
		@cold = PlateauProfile.new(15.0, 15.0, 15.0, 25.0)
		@warm = PlateauProfile.new(15.0, 25.0, 35.0, 45.0)
		@hot = PlateauProfile.new(35.0, 45.0, 45.0, 45.0)
	end
	def cold(temp)
		if temp < @cold.low 
			return 1.0	
		end
		if temp > @cold.high
			return 0.0
		end
		return @cold.compute(temp)
	end
	def warm(temp)
		if temp < @warm.low or temp > @warm.high
			return 0.0	
		end
		return @warm.compute(temp)
	end
	def hot(temp)
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
		@low = PlateauProfile.new(5.0, 5.0, 5.0, 10.0)
		@med = PlateauProfile.new(5.0, 10.0, 20.0, 25.0)
		@high = PlateauProfile.new(25.0, 30.0, 30.0, 30.0)
	end
	def low(voltage)
		if voltage.current < @low.low
			return 1.0
		end
		if voltage.current > @low.high 
			return 0.0
		end
		return @low.compute(voltage.current)
	end
	def medium(voltage)
		if voltage.current < @med.low or voltage.current > @med.high
			return 0.0
		end
		return @med.compute(voltage.current)
	end
	def high(voltage)
		if voltage.current < @high.low
			return 0.0
		end
		if voltage.current > @high.high 
			return 1.0
		end
		return @high.compute(voltage.current)
	end
end

class SpikeProfile
	def initialize(low, high)
		@low = low	
		@high = high
	end
	def compute(value)
		temp_low = @low
		temp_high = @high
    value += (-temp_low)
    if temp_low<0 and temp_high<0
      temp_high = -(temp_high-temp_low)
    elsif temp_low<0 and temp_high>0
      temp_high += -temp_low
    elsif temp_low>0 and temp_high>0
      temp_high -= temp_low
    end
    peak = temp_high/2.0
    temp_low = 0.0
    if value<peak
      return value/peak
    elsif value>peak
      return (temp_high-value)/peak
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
			puts "#{count},#{s.voltage.current},#{s.temperature.current}"
		end
	}	
end
