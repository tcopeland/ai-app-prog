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
	def initialize(x,y)
		@x_offset = x
		@y_offset = y
	end
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

	# these may turn into instance variables
	MAX_FOOD_ENERGY=15
	MAX_ENERGY=60
	REPRODUCE_ENERGY=0.9
	MAX_AGENTS=36
	MAX_PLANTS=35
	MAX_GRID=30
	MAX_STEPS=1000000

	NORTH_FRONT = [OffsetPair.new(-2,-2), OffsetPair.new(-2,-1), OffsetPair.new(-2,0), OffsetPair.new(-2,1), OffsetPair.new(-2,2), OffsetPair.new(9,9)]
	NORTH_LEFT = [OffsetPair.new(0,-2), OffsetPair.new(-1,-2), OffsetPair.new(9,9)]
	NORTH_RIGHT = [OffsetPair.new(0,2), OffsetPair.new(-1,2), OffsetPair.new(9,9)]
	NORTH_PROX = [OffsetPair.new(0,-1), OffsetPair.new(-1,-1), OffsetPair.new(-1,0), OffsetPair.new(-1,1), OffsetPair.new(0,1), OffsetPair.new(9,9)]
	WEST_FRONT = [OffsetPair.new(2,-2), OffsetPair.new(1,-2), OffsetPair.new(0,-2), OffsetPair.new(-1,-2), OffsetPair.new(-2,-2), OffsetPair.new(9,9)]
	WEST_LEFT = [OffsetPair.new(2,0), OffsetPair.new(2,-1), OffsetPair.new(9,9)]
	WEST_RIGHT = [OffsetPair.new(-2,0), OffsetPair.new(-2,-1), OffsetPair.new(9,9)]
	WEST_PROX = [OffsetPair.new(1,0), OffsetPair.new(1,-1), OffsetPair.new(0,-1), OffsetPair.new(-1,-1), OffsetPair.new(-1,0), OffsetPair.new(9,9)]

	def initialize(args)
		seed_population = args.include?("--seed-population")
		emit_runtime_trend = args.include?("--emit-runtime-trend")
		no_grow = args.include?("--no-grow")
		carnivore_to_plant = args.include?("--carnivore-to-plant")
		no_reproduction = args.include?("--no-reproduction")
		step = args.include?("--step")
		if args.include?("--help") or args.include?("-h") 
			usage
			exit(1)
		end
	end

	def getWeight
     rand(9)-1
	end

	def usage
		puts "./alife [--seed-population] [--emit-runtime-trend] [--no-grow] [--carnivore-to-plant] [--no-reproduction] [--step]"
	end
end

if __FILE__ == $0
	life = ArtificialLife.new(ARGV)
end
