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
	STACK_DEPTH=25
end

class Genetic
	MAX_PROGRAM=6
	MAX_GENERATIONS=10000
	MAX_CHROMS=3000
	def initialize
		@current_population=0
		@current_crossovers=0
		@current_mutations=0
		@populations = []
		@stack = [] 
	end
	def run
		generation = 0
		init_population
		file = File.open("stats.txt", "w")
		perform_fitness_check(file)a
		while generation < MAX_GENERATIONS
			@current_crossovers = @current_mutations = 0
			perform_selection
			generation += 1
		end
		file.close
	end
	def perform_selection
		0.step(MAX_CHROMS-1, 2) {|chrom|
			par1 = select_parent
		}
	end
	def select_parent
		chrom = 0
		ret = -1
		ret_fitness = 0.0
		loop do
			ret_fitness = @populations[@current_population][chrom].fitness / @max_fitness
			chrom = 0 if chrom == MAX_CHROM
			if @populations[@current_population][chrom].fitness > @min_fitness
				if rand < ret_fitness
					ret = chrom
					chrom += 1
					ret_fitness = @populations[@current_population][chrom].fitness
					break
			end
			chrom += 1
		end	
	end
	def perform_fitness_check(file)
		@max_fitness = 0
		@min_fitness = 1000
		@total_fitness = 0
		(MAX_CHROMS-1).times {|chrom|
			@populations[@current_population][chrom].reset_fitness
			(Instructions::COUNT-1).times {|i|	
				args = [rand(32), rand(32), rand(32)]
				answer = args[0]**3 + args[1]**2 + args[2]
				result = interpret_stm(@populations[@current_population][chrom].program, @populations[@current_population][chrom].prog_size, args)
				@populations[@current_population][chrom].fitness += Instructions::TIER1 if result == Instructions::NONE
				@populations[@current_population][chrom].fitness += Instructions::TIER2 if @stack.size == 1
				@populations[@current_population][chrom].fitness += Instructions::TIER3 if @stack.first == answer
			}	
			if @populations[@current_population][chrom].fitness > @max_fitness	
				@max_fitness = @populations[@current_population][chrom].fitness
			elsif @populations[@current_population][chrom].fitness < @min_fitness
				@min_fitness = @populations[@current_population][chrom].fitness
			end
			@total_fitness += @populations[@current_population][chrom].fitness
		}
		@avg_fitness = @total_fitness.to_f / MAX_CHROMS.to_f
		printf(file, "%d %6.4f %6.4f %6.4f\n", x, @min_fitness, @avg_fitness, @max_fitness)
		x += 1
	end
	def interpret_stm(program, prog_length, args)
		pc = 0
		error = Instructions::NONE
		args.size.downto(0) {|x| spush(args[x])	}
		while error == Instructions::NONE && pc < prog_length
			begin
				case program[pc]
					when Instructions::DUP
						raise Exception.exception(STACK_VIOLATION.to_s) if assert_stack_elements(1)
						raise Exception.exception(STACK_VIOLATION.to_s) if assert_stack_not_full
						spush(speek)
					when Instructions::SWAP
						raise Exception.exception(STACK_VIOLATION.to_s) if assert_stack_elements(2)
						a = @stack.last.dup
						@stack[@stack.size-1] = @stack[@stack.size-2]
						@stack[@stack.size-2] = a
					when Instructions::MUL
						raise Exception.exception(STACK_VIOLATION.to_s) if assert_stack_elements(2)
						a = spop
						b = spop
						spush(a * b)
					when Instructions::ADD
						raise Exception.exception(STACK_VIOLATION.to_s) if assert_stack_elements(2)
						a = spop
						b = spop
						spush(a + b)
					when Instructions::OVER
						raise Exception.exception(STACK_VIOLATION.to_s) if assert_stack_elements(2)
						spush(@stack[@stack.size-2].dup)
				end
			rescue Exception => x
				error = x.message.to_i
			end
		end
		return error
	end
	def assert_stack_elements(x)
		@stack.size < x
	end
	def assert_stack_not_full
		!@stack.size == STACK_DEPTH
	end
	def spop	
		x = speek.dup
		@stack.delete_at(@stack.size - 1)
		return x
	end
	def spush(x)
		@stack << x	
	end
	def speek
		@stack.last
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
