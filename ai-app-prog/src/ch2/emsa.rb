#!/usr/local/bin/ruby

class Member
	DX = [-1, 1, -1, 1]
	DY = [-1, 1, 1, -1]
	attr_accessor :energy, :solution
	def initialize
		@energy=0.0
		@solution=Array.new(Emsa::MAX_LENGTH)
		0.upto(Emsa::MAX_LENGTH-1) {|x| @solution[x] = x}
		0.upto(Emsa::MAX_LENGTH-1) {|x| tweak}
	end

	def copy_into(dest)
		0.upto(Emsa::MAX_LENGTH-1) {|x|
			dest.solution[x] = @solution[x]
		}
		dest.energy = @energy
	end

	def tweak
		y=0
		x = rand(Emsa::MAX_LENGTH)
		begin
			y = rand(Emsa::MAX_LENGTH)
		end until x != y
		temp = @solution[x]
		@solution[x] = @solution[y]
		@solution[y] = temp
	end

	def emit_solution
		board = create_new_board
		0.upto(MAX_LENGTH-1) {|x| 
			board[x][@solution[x]] = 'Q' 
		}
		0.upto(MAX_LENGTH-1) {|x|
			0.upto(MAX_LENGTH-1) {|y|
				p board[x][y]
			}	
			puts "\n"
		}	
		puts "\n\n"
	end
	def compute_energy
		board = create_new_board
		0.upto(Emsa::MAX_LENGTH-1) {|x|
			board[x][@solution[x]] = 'Q';
		}
		conflicts = 0
		0.upto(Emsa::MAX_LENGTH-1) {|i|
			x = i
			y = solution[i]
			0.upto(3) {|j|
				tempx = x
				tempy = y
				while true	
					tempx += DX[j]
					tempy += DY[j]
					if tempx<0 || tempx >= Emsa::MAX_LENGTH || tempy<0 || tempy>=Emsa::MAX_LENGTH 
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
		board = Array.new(Emsa::MAX_LENGTH, '.')
		board.each_index {|x| 
			board[x] = Array.new(Emsa::MAX_LENGTH, '.') 
		}
		return board
	end

end

class Emsa
	MAX_LENGTH=30
	INITIAL_TEMPERATURE=30.0
	FINAL_TEMPERATURE=0.5
	ALPHA=0.99
	STEPS_PER_CHANGE=100

	def initialize
		timer=solution=use_new=0
		temperature=INITIAL_TEMPERATURE
	
		current=Member.new
		working=Member.new
		best=Member.new

		File.open("stats.txt", "w") {|file|
			current.compute_energy
			best.energy = 100.0	
			
			current.copy_into(working)
		
			while temperature > FINAL_TEMPERATURE
				puts "Temperature: #{temperature}"
				accepted = 0
				0.upto(STEPS_PER_CHANGE-1) {
					use_new = 0	
					working.tweak
					working.compute_energy
	
					if working.energy <= current.energy
						use_new = 1
					else
						calc = Math.exp(-(working.energy - current.energy)/temperature)
						if calc > rand()
							accepted += 1
							use_new = 1
						end
					end
				}

				if use_new == 1
					use_new = 0
					working.copy_into(current)
					if current.energy < best.energy
						current.copy_into(best)
						solution = 1
					else
						current.copy_into(working)
					end
				end
			end		
			
			f.write("#{timer} #{temperature} #{best.energy} #{accepted}\n")
			timer += 1
			puts "Best energy: #{best.energy}"
			temperature *= ALPHA	
		}
		
		if solution > 0
			best.emit_solution
		end
	end
end

if __FILE__ == $0
	Emsa.new
end
