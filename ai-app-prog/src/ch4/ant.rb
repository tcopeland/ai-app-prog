#!/usr/local/bin/ruby

class City
	attr_accessor :x, :y
	def initialize(x,y)
		@x = x
		@y = y
	end
end

class Ant
	def initialize
		@current_city = 0
		@next_city = 0
		@path_index = 0
		@tabu = []
		@path = []	
		@tour_length = 0
	end
end

class Common
	MAX_CITIES = 15
	MAX_DISTANCE = 100
	MAX_TOUR = MAX_CITIES * MAX_DISTANCE
	MAX_ANTS = 20
	ALPHA = 1.0
	BETA = 5.0	
	RHO = 0.5
	QVAL = 100
	MAX_TOURS = 500
	MAX_TIME = MAX_TOURS * MAX_CITIES
	INIT_PHEROMONE = 1.0 / MAX_CITIES
end

if __FILE__ == $0
	puts Common::MAX_CITIES
end
