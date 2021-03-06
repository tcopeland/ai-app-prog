#!/usr/local/bin/ruby

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

class PlateauProfile
	attr_accessor :low, :low_plateau, :high_plateau, :high
	def initialize(low, low_plateau, high_plateau, high, excluder)
		@low = low	
		@low_plateau = low_plateau
		@high_plateau = high_plateau
		@high = high
		@excluder = excluder
	end
	def compute(value)
		if value < @low or value > @high
			return @excluder.evaluate(value, low, high)
		end
		tmp_low_plateau = @low_plateau
		tmp_high_plateau = @high_plateau
		tmp_high = @high
		tmp_low = @low

		value += -tmp_low
		if @low < 0.0
			tmp_low_plateau += -tmp_low
			tmp_high_plateau += -tmp_low
			tmp_high += -tmp_low
		else
			tmp_low_plateau -= tmp_low
			tmp_high_plateau -= tmp_low
			tmp_high -= tmp_low
		end
		tmp_low = 0
		upslope = (1.0/(tmp_low_plateau - tmp_low))
		downslope = (1.0/(tmp_high - tmp_high_plateau))
		if value< tmp_low
			return 0.0
		elsif value> tmp_high
			return 0.0
		elsif value>= tmp_low_plateau and value<=tmp_high_plateau
			return 1.0
		elsif value< tmp_low_plateau 
			return (value-tmp_low) * upslope
		elseif value> tmp_high_plateau
			return (tmp_high-value)*downslope
		end
		return 0.0
	end
end

class LowEndExcluder
	def evaluate(value, low, high)
		if value < low
      return 1.0
    end
    return 0.0
	end
end

class MiddleExcluder
	def evaluate(value, low, high)
		if value < low or value > high
      return 0.0
    end
	end
end

class HighEndExcluder
	def evaluate(value, low, high)
		if value < low
      return 0.0
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
	def normalize(input)
		input >= 0.5 ? 1 : 0
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

# Battery charger application
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
		@temperature_mf = TemperatureMembershipFunctions.new
		@battery_mf = BatteryMembershipFunctions.new
		@fuzzy = FuzzyOperations.new
		@count = 0
	end
	def charge_control(simulation, timer)
		@count += 1
		if (@count % 10) == 0
			if @fuzzy.normalize(@battery_mf.high.compute(simulation.voltage.current)) >0
				@mode = TrickleCharge.new
				timer.reset
			elsif @fuzzy.normalize(@temperature_mf.hot.compute(simulation.temperature.current)) > 0
				@mode = TrickleCharge.new
				timer.reset
			elsif @fuzzy.normalize(@fuzzy.and(@fuzzy.not(@battery_mf.high.compute(simulation.voltage.current)), @fuzzy.not(@temperature_mf.hot.compute(simulation.temperature.current)))) > 0
				@mode = FastCharge.new
				timer.reset
			end
		end
	end
end

class TemperatureMembershipFunctions	
	attr_accessor :cold, :warm, :hot
	def initialize
		@cold = PlateauProfile.new(15.0, 15.0, 15.0, 25.0, LowEndExcluder.new)
		@warm = PlateauProfile.new(15.0, 25.0, 35.0, 45.0, MiddleExcluder.new)
		@hot = PlateauProfile.new(35.0, 45.0, 45.0, 45.0, HighEndExcluder.new)
	end
end

class BatteryMembershipFunctions
	attr_accessor :low, :medium, :high
	def initialize
		@low = PlateauProfile.new(5.0, 5.0, 5.0, 10.0, LowEndExcluder.new)
		@medium = PlateauProfile.new(5.0, 10.0, 20.0, 25.0, MiddleExcluder.new)
		@high = PlateauProfile.new(25.0, 30.0, 30.0, 30.0, HighEndExcluder.new)
	end
end

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

# Predator/prey application
class PredatorMembershipFunctions
	attr_accessor :xleft, :farleft, :left, :center, :right, :farright, :xright
	def initialize
		@xleft = PlateauProfile.new(-180, -179, -70,-60, LowEndExcluder.new)
		@farleft = PlateauProfile.new(-80, -70, -20, -10, MiddleExcluder.new)
		@left = PlateauProfile.new(-15, -12, -3, -2, MiddleExcluder.new)
		@center = SpikeProfile.new(-2, 7)
		@right = PlateauProfile.new(2, 3, 12, 15, MiddleExcluder.new)
		@farright = PlateauProfile.new(10, 20, 70, 80, MiddleExcluder.new)
		@xright = PlateauProfile.new(60, 70, 179, 180, HighEndExcluder.new)
	end
end

class Position
	attr_accessor :x, :y
	def initialize(x,y)
		@x = x
		@y = y
	end
	def translate(x,y)
		@x += x
		@y += y
	end
	def to_s	
		"#{@x.to_i},#{@y.to_i}"
	end
end

class MovingObject
	attr_accessor :pos
	def initialize(pos, heading)
		@pos = pos
		@heading = heading
	end
	def move
		@pos.translate(@heading.x, @heading.y)
	end
	def to_s	
		"#{@pos}:#{@heading}"
	end
end

class Predator < MovingObject
	def initialize(pos, heading, prey)
		super(pos, heading)
		@prey = prey
		@membership = PredatorMembershipFunctions.new
	end
	def move
		super
		desired_heading = Math.atan2(@prey.pos.x - @pos.x, @prey.pos.y - @pos.y)/(Math::PI/180)
		if desired_heading < 0
			desired_heading = 360 - ((360-desired_heading)%360)
		end
		diff = desired_heading - @heading.angle
		if desired_heading < @heading.angle && diff > 0
			diff = -diff
		end
		pmf = PredatorMembershipFunctions.new
		fuz = FuzzyOperations.new	
		change = 0
		if fuz.normalize(pmf.xleft.compute(diff)) > 0
			change=-15
		elsif fuz.normalize(pmf.farleft.compute(diff)) > 0
			change=-8
		elsif fuz.normalize(pmf.left.compute(diff)) > 0
			change=-1
		elsif fuz.normalize(pmf.center.compute(diff)) > 0
			change=0
		elsif fuz.normalize(pmf.right.compute(diff)) > 0
			change=1
		elsif fuz.normalize(pmf.farright.compute(diff)) > 0
			change=8
		elsif fuz.normalize(pmf.xright.compute(diff)) > 0
			change=15
		end
		@heading.translate(change)
	end
end

class Heading
	attr_accessor :angle
	def initialize(initialAngle)
		@angle = initialAngle
	end
	def x
		return Math.sin(@angle*(Math::PI/180))
	end
	def y
		return Math.cos(@angle*(Math::PI/180))
	end
	def translate(angle)
		@angle += angle
		if @angle > 360
			@angle =- 360
		elsif @angle < 0
			@angle += 360
		end
	end
	def to_s	
		"#{@angle}"
	end
end

if __FILE__ == $0
	if ARGV[0] != nil and ARGV[0] == "battery"
		b = Battery.new
		s = Simulation.new(b)	
		t = Timer.new
		3000.times {|count|
			s.simulate(t)
			b.charge_control(s, t)
			t.bump
			if count % 25 == 0
				puts "#{count} #{s.voltage.current} #{s.temperature.current}"
			end
		}
	else
		prey = MovingObject.new(Position.new(20.0,20.0), Heading.new(60))
		predator = Predator.new(Position.new(80.0,80.0), Heading.new(90), prey)
		200.times {
			prey.move
			predator.move
			puts "#{prey.pos.x.to_i} #{prey.pos.y.to_i} #{predator.pos.x.to_i} #{predator.pos.y.to_i}"
			dist = Math.sqrt((prey.pos.x-predator.pos.x)**2 + (prey.pos.y-predator.pos.y)**2)
			if dist < 5.0
				exit
			end
		}		
	end	
end
