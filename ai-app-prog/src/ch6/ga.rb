#!/usr/local/bin/ruby

class Population
	attr_accessor :fitness, :prog_size, :program
	def initialize
		reset_fitness
		@prog_size = Genetic::MAX_PROGRAM-1
		@program = []
	end
	def reset_fitness
		@fitness = 0.0
	end
end

class Instructions
	DUP=0
	SWAP=0x01
	MUL=0x02
	ADD=0x03
	OVER=0x04
	NOP=0x05
	MAX_INSTRUCTIONS=NOP+1
	NONE=0
	COUNT=10
	TIER1=1
	TIER2=(TIER1+1)*COUNT
	TIER3=(TIER1+TIER2+2)*COUNT
end

class Genetic
	MAX_PROGRAM=6
	MAX_CHROMS=3000
	def initialize
		@current_population=0
		@populations = []
		@stack_pointer = 0
		@stack = [] 
	end
	def run
		init_population
		file = File.open("stats.txt", "w")
		perform_fitness_check(file)

		file.close
	end
	def perform_fitness_check(file)
		args = []
		(MAX_CHROMS-1).times {|chrom|
			@populations[@current_population][chrom].reset_fitness
			(Instructions::COUNT-1).times {|i|	
				args[0], args[1], args[2] = rand(32), rand(32), rand(32)
				answer = args[0]**3 + args[1]**2 + args[2]
				result = interpret_stm(@populations[@current_population][chrom].program, @populations[@current_population][chrom].prog_size, args)
				@populations[@current_population][chrom].fitness += Instructions::TIER1 if result == Instructions::NONE
				@populations[@current_population][chrom].fitness += Instructions::TIER2 if stack_pointer == 1
			}	
		}
	end
	def interpret_stm(program, prog_length, args)
		pc = 0
		error = Instructions::NONE
		@stack_pointer = 0
		args.size.downto(0) {|x| spush(args[x])	
	end
	def spush(x)
		stack << x	
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
