#!/usr/local/bin/ruby

class City
	attr_accessor :x, :y
	def initialize(x,y)
		@x = x
		@y = y
	end
end

class Ant
	attr_accessor :tour_length, :path_index, :tabu, :current_city, :next_city, :path
	def initialize(city)
		@current_city = city
		@next_city = -1
		@path_index = 1
		@tabu = Array.new(Simulation::MAX_CITIES, 0)
		@path = Array.new(Simulation::MAX_CITIES, -1)	
		@path[0] = @current_city
		@tour_length = 0.0
		@tabu[@current_city] = 1
	end
end

class Cities
	def initialize
		@cities = []
		(0..Simulation::MAX_CITIES-1).each { 
			@cities << City.new(rand(Simulation::MAX_DISTANCE), rand(Simulation::MAX_DISTANCE))
		}
	end
	def dist(x,y)
		return Math.sqrt((@cities[x].x - @cities[y].x).abs**2 + (@cities[x].y - @cities[y].y).abs**2)
	end
	def write(filename)
		File.open(filename, "w") {|f|
			@cities.each {|city|
				f.write "#{city.x} #{city.y}\n"
			}
		}
	end
	def get(index)
		return @cities[index]
	end
end

class Ants
	def initialize
		@ants = []
		city_index = 0
		(0..Simulation::MAX_ANTS-1).each {|x|
			@ants << Ant.new(city_index % (Simulation::MAX_CITIES-1))
			city_index += 1
		}	
	end
	def restart(best_so_far)
    city_index = 0
		@ants.each_index {|x| 
			if  best_so_far == nil or @ants[x].tour_length < best_so_far.tour_length
				best_so_far = @ants[x]
			end
      @ants[x] = Ant.new(city_index % (Simulation::MAX_CITIES-1))
      city_index += 1
		}
		return best_so_far
	end
	def simulate(distance, pheromone)
		moving = 0
		@ants.each_index {|k|
			if @ants[k].path_index < Simulation::MAX_CITIES
				@ants[k].next_city=select_next_city(@ants[k], pheromone, distance)
				@ants[k].tabu[@ants[k].next_city] = 1
				@ants[k].path_index += 1
				@ants[k].path[@ants[k].path_index] = @ants[k].next_city
				@ants[k].tour_length += distance[@ants[k].current_city][@ants[k].next_city]
				if @ants[k].path_index == Simulation::MAX_CITIES
					@ants[k].tour_length += distance[@ants[k].path[Simulation::MAX_CITIES-1]][@ants[k].path[0]]
				end
				@ants[k].current_city = @ants[k].next_city
				moving += 1
			end
		}
		return moving
	end
	def select_next_city(ant, pheromone, distance)
		denom = 0.0
		@ants.each_index {|x|
			if ant.tabu[x] == 0
				denom += ant_product(ant, x, pheromone, distance)
			end
		}
		city=0
		begin
			if ant.tabu[city % Simulation::MAX_CITIES] == 0 && rand() < ant_product(ant, city % Simulation::MAX_CITIES, pheromone, distance)/denom
				break
			end
			city += 1
		end until !true
		return city % Simulation::MAX_CITIES
	end
	def ant_product(ant,y, pheromone, distance)
		(pheromone[ant.current_city][y]**Simulation::ALPHA) * ((1.0/distance[ant.current_city][y])**Simulation::BETA)
	end
	def get(index)
		@ants[index]
	end
end

class Simulation
	MAX_CITIES = 20
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
		@cities = Cities.new
		@ants = Ants.new
	
		@distance = []
		@pheromone = []
		@best_so_far = nil
	
		(0..MAX_CITIES-1).each {|x|
			@distance[x] = []
			@pheromone[x] = []
			(0..MAX_CITIES-1).each {|y|
				@distance[x][y] = 0.0
				@pheromone[x][y] = INIT_PHEROMONE	
			}
		}

		(0..MAX_CITIES-1).each {|x|
			(0..MAX_CITIES-1).each {|y|
				if x != y and @distance[x][y] == 0.0	
					@distance[x][y] = @cities.dist(x,y)
					@distance[y][x] = @distance[x][y]
				end
			}
		}
		
		current_time = 0
		while current_time < MAX_TIME
			current_time += 1
			if @ants.simulate(@distance, @pheromone) == 0
				update_trails
				if current_time != MAX_TIME
					@best_so_far = @ants.restart(@best_so_far)
				end
				#puts "Time is #{current_time} #{@best_so_far.tour_length}"
			end
		end	
		puts "Best tour = #{@best_so_far.tour_length}\n\n"
		@cities.write("cities.txt")
		write_solution()
	end
	
	def update_trails
		@pheromone.each_index {|x|
			@pheromone.each_index {|y|
				if x != y
					@pheromone[x][y] *= (1.0 - RHO)
					if @pheromone[x][y] < 0.0
						@pheromone[x][y] = INIT_PHEROMONE
					end
				end
			}
		}

		@pheromone.each_index {|ant|
			@pheromone.each_index {|i|
				if i < MAX_CITIES-1
					from = @ants.get(ant).path[i]
					to = @ants.get(ant).path[i+1]	
				else
					from = @ants.get(ant).path[i]
					to = @ants.get(ant).path[0]
				end
				@pheromone[from][to] += (QVAL/@ants.get(ant).tour_length)
				@pheromone[to][from] = @pheromone[from][to]
			}
		}

		@pheromone.each_index {|x|
			@pheromone.each_index {|y|
				@pheromone[x][y] *= RHO
			}
		}
	end

	def write_solution()
		File.open("solution.txt", "w") {|f|
			(0..MAX_CITIES-1).each {|x|
				f.write "#{@cities.get(@best_so_far.path[x]).x} #{@cities.get(@best_so_far.path[x]).y}\n"
			}
			f.write "#{@cities.get(@best_so_far.path[0]).x} #{@cities.get(@best_so_far.path[0]).y}\n"
		}
	end
end

if __FILE__ == $0
	Simulation.new
end
