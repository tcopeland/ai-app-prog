#!/usr/local/bin/ruby

class Member
	NUMBER_OF_QUEENS=8
	DX = [-1, 1, -1, 1]
	DY = [-1, 1, 1, -1]
	attr_accessor :energy, :solution
	def initialize(energy=0.0)
		@energy=energy
		@solution=Array.new(NUMBER_OF_QUEENS)
		0.upto(NUMBER_OF_QUEENS-1) {|x| @solution[x] = x}
		0.upto(NUMBER_OF_QUEENS-1) {|x| tweak}
	end

	def copy_into(dest)
		0.upto(NUMBER_OF_QUEENS-1) {|x|
			dest.solution[x] = @solution[x]
		}
		dest.energy = @energy
	end

	def tweak
		y=0
		x = rand(NUMBER_OF_QUEENS)
		begin
			y = rand(NUMBER_OF_QUEENS)
		end until x != y
		temp = @solution[x]
		@solution[x] = @solution[y]
		@solution[y] = temp
	end

	def emit_solution
		board = create_new_board
		0.upto(NUMBER_OF_QUEENS-1) {|x| 
			board[x][@solution[x]] = 'Q' 
		}
		0.upto(NUMBER_OF_QUEENS-1) {|x|
			0.upto(NUMBER_OF_QUEENS-1) {|y|
				putc board[x][y]
				putc ' '
			}	
			puts "\n"
		}	
		puts "\n\n"
	end
	def compute_energy
		board = create_new_board
		0.upto(NUMBER_OF_QUEENS-1) {|x|
			board[x][@solution[x]] = 'Q';
		}
		conflicts = 0
		0.upto(NUMBER_OF_QUEENS-1) {|i|
			x = i
			y = solution[i]
			0.upto(3) {|j|
				tempx = x
				tempy = y
				while true	
					tempx += DX[j]
					tempy += DY[j]
					if tempx<0 || tempx >= NUMBER_OF_QUEENS || tempy<0 || tempy>=NUMBER_OF_QUEENS 
						break
					end
					if board[tempx][tempy] == 'Q'
						conflicts += 1
					end
				end
			}
		}
		@energy = conflicts	
	end

	def create_new_board
		board = Array.new(NUMBER_OF_QUEENS, '.')
		board.each_index {|x| 
			board[x] = Array.new(NUMBER_OF_QUEENS, '.') 
		}
		return board
	end

end

class Emsa
	INITIAL_TEMPERATURE=30.0
	FINAL_TEMPERATURE=0.5
	ALPHA=0.99
	STEPS_PER_CHANGE=100

	def initialize(print_stats_to_file)
		timer=solution=0
		temperature=INITIAL_TEMPERATURE
	
		current=Member.new
		working=Member.new
		best=Member.new(100.0)

		current.compute_energy
		current.copy_into(working)
		
		stats = ""
		use_new=false
		output_interval = 0
		while temperature > FINAL_TEMPERATURE
			puts "Temperature: #{temperature}" unless output_interval % 20 != 0
			accepted = 0
			0.upto(STEPS_PER_CHANGE-1) {
				use_new = false	
				working.tweak
				working.compute_energy
	
				if working.energy <= current.energy
					use_new = true
				else
					calc = Math.exp(-(working.energy - current.energy)/temperature)
					if calc > rand()
						accepted += 1
						use_new = true
					end
				end
			}

			if use_new
				use_new = false
				working.copy_into(current)
				if current.energy < best.energy
					current.copy_into(best)
					solution = 1
				else
					current.copy_into(working)
				end
			end
			stats << "#{timer} #{temperature} #{best.energy} #{accepted}\n"
			timer += 1
			puts "Best energy: #{best.energy}" unless output_interval % 20 != 0
			temperature *= ALPHA	
			output_interval += 1
		end		
		
		if solution > 0
			best.emit_solution
		end
		
		if print_stats_to_file
			File.open("stats.txt", "w") {|file|
				file.write(stats)
			}
		end
	end
end

if __FILE__ == $0
	stats_file = false
	if ARGV.size > 0
		stats_file = ARGV.include?("-statsfile")
	end
	Emsa.new(stats_file)
end
