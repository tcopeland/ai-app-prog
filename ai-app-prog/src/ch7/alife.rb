#!/usr/local/bin/ruby

class Location
	attr_accessor :x, :y
end

class Plant
	attr_accessor :location
end

class Agent
	attr_accessor :type, :energy, :parent, :age, :generation, :location, :direction, :inputs, :weight_oi, :biaso, :actions
	def initialize 
		@inputs = Array.new(ArtificialLife::MAX_INPUTS)
		@weight_oi = Array.new(ArtificialLife::MAX_INPUTS * ArtificialLife::MAX_OUTPUTS)
		@biaso = Array.new(ArtificialLife::MAX_INPUTS)
		@actions = Array.new(ArtificialLife::MAX_INPUTS)
	end
end

class OffsetPair
	attr_accessor :x_offset, :y_offset
end

class ArtificialLife
	TYPE_CARNIVORE=1
	TYPE_DEAD=-1
	HERB_FRONT=0
	CARN_FRONT=1
	PLANT_FRONT=2
	HERB_LEFT=3
	CARN_LEFT=4
	PLANT_LEFT=5
	HERB_RIGHT=6
	CARN_RIGHT=7
	PLANT_RIGHT=8
	HERB_PROXIMITY=9
	CARN_PROXIMITY=10
	PLANT_PROXIMITY=11
	MAX_INPUTS=12
	ACTION_TURN_LEFT=0
	ACTION_TURN_RIGHT=1
	ACTION_MOVE=2
	ACTION_EAT=3
	MAX_OUTPUTS=4
	TOTAL_WEIGHTS=((MAX_INPUTS * MAX_OUTPUTS) + MAX_OUTPUTS)
	HERB_PLANE=0
	CARN_PLANE=1
	PLANT_PLANE=2
	NORTH=0
	SOUTH=1
	EAST=2
	WEST=3
	MAX_DIRECTION=4


end


if __FILE__ == $0
	puts "Hi!"
end
