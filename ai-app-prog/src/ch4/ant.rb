#!/usr/local/bin/ruby

class City
	attr_accessor :x, :y
	def initialize(x,y)
		@x = x
		@y = y
	end
end

class Ant
	attr_accessor :tour_length
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
		@best = Ant.new
		@best.tour_length = 500000
	
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
	
	def restart_ants
		(0..(MAX_ANTS-1)).each {|x| 
			if @ants[x].tour_length < @best.tour_length
				@best = @ants[x]
			end
			if city_index == MAX_CITIES
        city_index = 0
      end
      city_index += 1
      @ants[x] = Ant.new(city_index)
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
		if denom == 0.0
			puts "Denom should not be 0.0!"
			exit
		end
		to=0
		begin
			p=0.0
			to += 1
			if to >= MAX_CITIES
				to = 0
			end
			if @ants[ant].tabu[to] == 0
				p = ant_product(@ants[ant].current_city, to)/denom
				if rand() < p
					break
				end
			end
		end until !true	
	end

	def simulate_ants
		moving = 0
		(0..(MAX_ANTS-1)).each {|k|
			if @ants[k].path_index < MAX_CITIES
				@ants[k].next_city=select_next_city(k)
				@ants[k].tabu[@ants[k].next_city] = 1a
				@ants[k].path_index += 1
				@ants[k].path[@ants[k].path_index] = @ants[k].next_city
				@ants[k].tour_length += distance[@ants[k].current_city][@ants[k].next_city]
				if @ants[k].path_index == MAX_CITIES
					@ants[k].tour_length += distance[@ants[k].path[MAX_CITIES-1]][@ants[k].path[0]]
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
		f = File.new("cities.dat", "w")
		(0..(MAX_CITIES-1)).each {|x|
			f.write "#{@cities[x].x} #{@cities[x].y}"
		}
		f.close

		f = File.new("solution.dat", "w")
		(0..(MAX_CITIES-1)).each {|x|
			f.write "#{@cities[@ants[ant].path[city]].x} #{@cities[@ants[ant].path[city]].y}"
		}
		f.write "#{@cities[@ants[ant].path[0]].x} #{@cities[@ants[ant].path[0]].y}"
		f.close
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
