#!/usr/local/bin/ruby

class Population
	attr_accessor :fitness, :prog_size, :program
	def initialize
		@fitness = 0.0
		@prog_size = Genetic::MAX_PROGRAM-1
		@program = []
	end
end

class Instructions
	DUP=0
	SWAP=1
	MUL=2
	ADD=3
	OVER=4
	NOP=5
	MAX_INSTRUCTIONS=NOP+1
end

class Genetic
	MAX_PROGRAM=6
	MAX_CHROMS=3000
	MAX_INSTRUCTIONS=6
	def initialize
		@current_population=0
		@populations = []
	end
	def run
		init_population
	end
	def init_population	
		(MAX_CHROMS-1).times {|x| init_member(x) }
	end
	def init_member(index)
		@populations[@current_population] = [] if @populations[@current_population] == nil
		@populations[@current_population][index] = Population.new
		(MAX_PROGRAM-1).times {|x| 
			@populations[@current_population][index].program[x] = rand(Instructions::MAX_INSTRUCTIONS)
		}
	end
	
end

if __FILE__ == $0
	Genetic.new.run
end
