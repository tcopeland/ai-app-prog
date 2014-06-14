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
					break if tempx<0 || tempx >= NUMBER_OF_QUEENS || tempy<0 || tempy>=NUMBER_OF_QUEENS 
					conflicts +=1 if board[tempx][tempy] == 'Q'
				end
			}
		}
		@energy = conflicts	
	end

	def create_new_board
		board = Array.new(NUMBER_OF_QUEENS, '.')
		board.each_index {|x| board[x] = Array.new(NUMBER_OF_QUEENS, '.') }
		0.upto(NUMBER_OF_QUEENS-1) {|x| board[x][@solution[x]] = 'Q'; }
		board
	end

end

class Emsa
	INITIAL_TEMPERATURE=30.0
	FINAL_TEMPERATURE=0.5
	ALPHA=0.99
	STEPS_PER_CHANGE=100
	
	def initialize(verbose)
		@verbose = verbose
		@stats = ""
		@solution_found = false
	end

	def go
		timer=0
		temperature=INITIAL_TEMPERATURE
	
		current=Member.new
		working=Member.new
		@best=Member.new(100.0)

		current.compute_energy
		current.copy_into(working)
		
		use_new=false
		output_interval = 0
		while temperature > FINAL_TEMPERATURE
			puts "Temperature: " + temperature.to_s unless output_interval % 20 != 0 or !@verbose

			accepted = 0
			0.upto(STEPS_PER_CHANGE-1) {
				use_new = false	
				working.tweak
				working.compute_energy
	
				if working.energy <= current.energy
					use_new = true
				else
					calc = Math.exp(-(working.energy - current.energy)/temperature)
					if calc > rand
						accepted += 1
						use_new = true
					end
				end
			}

			if use_new
				use_new = false
				working.copy_into(current)
				if current.energy < @best.energy
					current.copy_into(@best)
					@solution_found = true
				else
					current.copy_into(working)
				end
			end
			@stats << "#{timer} #{temperature} #{@best.energy} #{accepted}\n"
			timer += 1
			puts "Best energy: #{@best.energy}" unless output_interval % 20 != 0 or !@verbose
			temperature *= ALPHA	
			output_interval += 1
		end		
	end
	def print_stats_to_file
		File.open("stats.txt", "w") {|file| file.write(@stats) }
	end
	def best_energy
		@best.energy
	end
	def solved
		@best.energy == 0
	end
	def print_board
		@best.emit_solution unless !@solution_found
	end
end

if __FILE__ == $0
	while true
		e = Emsa.new(ARGV.include?("-v"))
		e.go
		if e.solved
			puts "Solved!"
			e.print_board
			e.print_stats_to_file unless !ARGV.include?("-statsfile")
			break
		else 
			puts "Failure, energy = #{e.best_energy}, retrying"
		end
	end
end
