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

class Cities
	def initialize
		@cities = []
	end
	def add_new
			@cities << City.new(rand(Simulation::MAX_DISTANCE), rand(Simulation::MAX_DISTANCE))
	end
	def dist_x(x, y)
		(@cities[x].x - @cities[y].x).abs
	end
	def dist_y(x, y)
		(@cities[x].y - @cities[y].y).abs
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
		@cities = Cities.new
		@ants = []
		@distance = []
		@pheromone = []
		@best = Ant.new(0)
		@best.tour_length = 500000
	
		(0..(MAX_CITIES-1)).each {|x|
			@cities.add_new
			@distance[x] = []
			@pheromone[x] = []
			(0..(MAX_CITIES-1)).each {|y|
				@distance[x][y] = 0.0
				@pheromone[x][y] = INIT_PHEROMONE	
			}
		}

		(0..(MAX_CITIES-1)).each {|x|
			(0..(MAX_CITIES-1)).each {|y|
				if x != y and @distance[x][y] == 0.0	
					@distance[x][y] = Math.sqrt((@cities.dist_x(x,y))**2 + (@cities.dist_y(x,y))**2)
					@distance[y][x] = @distance[x][y]
				end
			}
		}

		city_index = 0
		(0..(MAX_ANTS-1)).each {|x|
			if city_index == (MAX_CITIES-1)
				city_index = 0
			end
			@ants[x] = Ant.new(city_index)
			city_index += 1
		}	
	end
	
	def restart_ants
     city_index = 0
		(0..(MAX_ANTS-1)).each {|x| 
			if @ants[x].tour_length < @best.tour_length
				@best = @ants[x]
			end
			if city_index == (MAX_CITIES-1)
        city_index = 0
      end
      @ants[x] = Ant.new(city_index)
      city_index += 1
		}
	end
	
	def ant_product(x,y)
		(@pheromone[x][y]**ALPHA) * ((1.0/@distance[x][y])**BETA)
	end

	def select_next_city(ant)
		denom = 0.0
		(0..(MAX_CITIES-1)).each {|x|
			if @ants[ant].tabu[x] == 0
				denom += ant_product(@ants[ant].current_city, x)
			end
		}
		city=0
		begin
			p=0.0
			city += 1
			if city >= MAX_CITIES
				city = 0
			end
			if @ants[ant].tabu[city] == 0
				p = ant_product(@ants[ant].current_city, city)/denom
				if rand() < p
					break
				end
			end
		end until !true
		return city
	end

	def simulate_ants
		moving = 0
		(0..(MAX_ANTS-1)).each {|k|
			if @ants[k].path_index < MAX_CITIES
				@ants[k].next_city=select_next_city(k)
				@ants[k].tabu[@ants[k].next_city] = 1
				@ants[k].path_index += 1
				@ants[k].path[@ants[k].path_index] = @ants[k].next_city
				@ants[k].tour_length += @distance[@ants[k].current_city][@ants[k].next_city]
				if @ants[k].path_index == MAX_CITIES
					@ants[k].tour_length += @distance[@ants[k].path[MAX_CITIES-1]][@ants[k].path[0]]
				end
				@ants[k].current_city = @ants[k].next_city
				moving += 1
			end
		}
		return moving
	end
	
	def update_trails
		(0..(MAX_CITIES-1)).each {|x|
			(0..(MAX_CITIES-1)).each {|y|
				if x != y
					@pheromone[x][y] *= (1.0 - RHO)
					if @pheromone[x][y] < 0.0
						@pheromone[x][y] = INIT_PHEROMONE
					end
				end
			}
		}

		(0..(MAX_ANTS-1)).each {|ant|
			(0..(MAX_CITIES-1)).each {|i|
				if i < MAX_CITIES-1
					from = @ants[ant].path[i]
					to = @ants[ant].path[i+1]	
				else
					from = @ants[ant].path[i]
					to = @ants[ant].path[0]
				end
				@pheromone[from][to] += (QVAL/@ants[ant].tour_length)
				@pheromone[to][from] = @pheromone[from][to]
			}
		}

		(0..(MAX_CITIES-1)).each {|x|
			(0..(MAX_CITIES-1)).each {|y|
				@pheromone[x][y] *= RHO
			}
		}
	end

	def emit_data_file(ant)
		@cities.write("cities.txt")
		File.open("solution.txt", "w") {|f|
			(0..(MAX_CITIES-1)).each {|x|
				f.write "#{@cities.get(ant.path[x]).x} #{@cities.get(ant.path[x]).y}\n"
			}
			f.write "#{@cities.get(ant.path[0]).x} #{@cities.get(ant.path[0]).y}\n"
		}
	end
	
	def main
		current_time = 0
		while current_time < MAX_TIME
			current_time += 1
			if simulate_ants == 0
				update_trails
				if current_time != MAX_TIME
					restart_ants
				end
				#puts "Time is #{current_time} #{@best.tour_length}"
			end
		end	
		puts "Best tour = #{@best.tour_length}\n\n"
		emit_data_file(@best)
	end
end

if __FILE__ == $0
	s = Simulation.new
	s.main
end
