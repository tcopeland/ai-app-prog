#!/usr/local/bin/ruby

class City
	attr_accessor :x, :y
	def initialize(x,y)
		@x = x
		@y = y
	end
end

class Ant
	def initialize(city)
		@current_city = city
		@next_city = -1
		@path_index = 1
		@tabu = []
		@path = []	
		(0..(Simulation::MAX_CITIES-1)).each {|x|
			@tabu[x] = 0
			@path[x] = -1
		}
		@path[0] = @current_city
		@tour_length = 0.0
		@tabu[@current_city] = 1
	end
end

class Simulation
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

	def initialize
		@cities = []
		@ants = []
		@distance = []
		@pheromone = []
		@best = MAX_TOUR
		@best_index = 0
	
		(0..(MAX_CITIES-1)).each {|x|
			@cities[x] =City.new(rand(MAX_DISTANCE), rand(MAX_DISTANCE))
			(0..(MAX_CITIES-1)).each {|y|
				@distance[x][y] = 0.0
				@pheromone[x][y] = INIT_PHEROMONE	
			}
		}

		(0..(MAX_CITIES-1)).each {|x|
			(0..(MAX_CITIES-1)).each {|y|
				if x != y and @distance[x][y] == 0.0	
					xd = abs(@cities[x].x - @cities[y].x)
					yd = abs(@cities[x].y - @cities[y].y)
					@distance[x][y] = Math.sqrt(xd**2 + yd**2)
					@distance[y][x] = @distance[x][y]
				end
			}
		}

		city_index = 0
		(0..(MAX_ANTS-1)).each {|x|
			if city_index == MAX_CITIES
				city_index = 0
			end
			city_index += 1
			@ants[x] = Ant.new(city_index)
		}	
	end

	def abs(x)
		if x<0
			return -x
		end
		return x
	end
end

if __FILE__ == $0
	puts Common::MAX_CITIES
end
