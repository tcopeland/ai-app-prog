#!/usr/local/bin/ruby

class Member
	attr_accessor :energy, :solution
	def initialize
		@energy=0.0
		@solution=Array.new(Emsa::MAX_LENGTH)
		0..upto(Emsa::MAX_LENGTH-1) {|x| @solution[x] = x}
		0..upto(Emsa::MAX_LENGTH-1) {|x| tweak}
	end
	def copy_to(dest)
	end
	def tweak()
		y=0
		x = rand(Emsa::MAX_LENGTH)
		begin
			y = rand(Emsa::MAX_LENGTH)
		until x != y
		temp = solution[x]
		solution[x] = solution[y]
		solution[y] = temp
	end
end

class Emsa
	MAX_LENGTH=30
	INITIAL_TEMPERATURE=30.0
	FINAL_TEMPERATURE=0.5
	ALPHA=0.99
	STEPS_PER_CHANGE=100

	def compute_energy(member)
	end

	def emit_solution(member)
	end

	def initialize
		timer=step=solution=use_new=accepted=0
		temperature=INITIAL_TEMPERATURE
		current=Member.new
		working=Member.new
		best=Member.new

		File.open("stats.txt", "w") {|file|
			compute_energy(current)
			best.energy = 100.0	
			
			current.copy_to(working)
		
			while temperature > FINAL_TEMPERATURE
				puts "Temperature: #{temperature}"
				accepted = 0
				0..upto(STEPS_PER_CHANGE-1) {|step|
					use_new = 0	
					working.tweak
					compute_energy(working)
	
					if working.energy <= current.energy
						use_new = 1
					else
						delta = working.energy - current.energy
						calc = Math.exp(-delta/temperature)
						if calc > rand()
							accepted += 1
							use_new = 1
						end
					end
				}

				if use_new == 1
					use_new = 0
					working.copy_to(current)
					if current.energy < best.energy
						current.copy_to(best)
						solution = 1
					else
						current.copy_to(working)
					end
				end
			end		
			
			f.write("#{timer} #{temperature} #{best.energy} #{accepted}\n")
			puts "Best energy: #{best.energy}"
			temperature *= ALPHA	
		}
		
		if solution > 0
			emit_solution(best)
		end
	end
end



if __FILE__ == $0
	puts "hi"
end
