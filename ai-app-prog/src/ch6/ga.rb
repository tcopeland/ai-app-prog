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
	DUP = 0
	SWAP = 0x01
	MUL = 0x02
	ADD = 0x03
	OVER = 0x04
	NOP = 0x05
	MAX_INSTRUCTIONS = NOP+1
	NONE = 0
	COUNT = 10
	TIER1 = 1
	TIER2 = (TIER1+1)*COUNT
	TIER3 = (TIER1+TIER2+2)*COUNT
	MAX_FITNESS = ((TIER3*COUNT) + (TIER2*COUNT) + (TIER1*COUNT)).to_f
	STACK_DEPTH = 25
end

class Genetic
	MAX_PROGRAM=6
	MAX_GENERATIONS=10000
	MAX_CHROMS=3000
	MUTATION_PROB = 0.02
	CROSSOVER_PROB = 0.8
	XPROB = 1.0 - CROSSOVER_PROB
	MPROB = 1.0 - MUTATION_PROB
	def initialize
		@current_population=0
		@current_crossovers=0
		@current_mutations=0
		@populations = []
		@stack = [] 
		@@weird_x_value = 0
		@@class_chrom = 0
	end
	def run
		generation = 0
		init_population
		perform_fitness_check
		while generation < MAX_GENERATIONS
			@current_crossovers = @current_mutations = 0
			perform_selection
			generation += 1
			if generation % 100 == 0 
				puts "Generation " + (generation-1).to_s
				printf("\tMaximum fitness = %f (%g)\n", @max_fitness, Instructions::MAX_FITNESS)
				printf("\tAverage fitness = %f\n", @avg_fitness)
				printf("\tMinimum fitness = %f\n", @min_fitness)
				printf("\tCrossovers = %d\n", @current_crossovers)
				printf("\tMutation = %d\n", @current_mutations)
				printf("\tpercentage = %f\n", @avg_fitness.to_f/@max_fitness.to_f)
			end
			if generation > (MAX_GENERATIONS * 0.25) && (@avg_fitness / @max_fitness) > 0.98
				puts "Converged"
				break
			end
			if @max_fitness == MAX_FIT
				puts "Found solution"
				break
			end
			puts "Generation " + (generation-1).to_s
			printf("\tMaximum fitness = %f (%g)\n", @max_fitness, Instructions::MAX_FITNESS)
			printf("\tAverage fitness = %f\n", @avg_fitness)
			printf("\tMinimum fitness = %f\n", @min_fitness)
			printf("\tCrossovers = %d\n", @current_crossovers)
			printf("\tMutation = %d\n", @current_mutations)
			printf("\tpercentage = %f\n", @avg_fitness.to_f/@max_fitness.to_f)
			MAX_CHROMS.times {|i|
				if @populations[@current_population][i].fitness == @max_fitness
					printf("Program %3d : ", i)
					@populations[@current_population][i].prog_size.times {|x|
						printf("%0.2d ", @populations[@current_population][i].program[index])
					}
					printf("\n")
					printf("Fitness %f\n", @populations[@current_population][i].fitness)
					printf("ProgSize %f\n", @populations[@current_population][i].prog_size)
					break
				end
			}
		end
	end
	def perform_selection
		0.step(MAX_CHROMS-1, 2) {|chrom|
			par1 = select_parent
			par2 = select_parent
			child1 = chrom
			child2 = chrom+1
			perform_reproduction(par1, par2, child1, child2)
		}
	end
	def perform_reproduction(para, parb, childa, childb)
		next_pop = @current_population == 0 ? 1 : 0
		cross_point = 0
		if rand > XPROB
			if @populations[@current_population][para].prog_size - 2 > @populations[@current_population][parb].prog_size
				cross_point = rand(@populations[@current_population][para].prog_size - 2) + 1
			else	
				cross_point = rand(@populations[@current_population][parb].prog_size - 2) + 1
			end
			@current_crossovers += 1
		else		
			cross_point = MAX_PROGRAM
		end
		CROSSPOINT.times {|i|
			@populations[next_pop][childa].program[i] = mutate(@populations[next_pop][childa].program[i])
			@populations[next_pop][childb].program[i] = mutate(@populations[next_pop][childb].program[i])
		}
		CROSSPOINT.upto(MAX_PROGRAM-1) {|i|
			@populations[next_pop][childa].program[i] = mutate(@populations[@current_population][parb].program[i])
			@populations[next_pop][childb].program[i] = mutate(@populations[@current_population][para].program[i])
		}
		@populations[next_pop][childa].prog_size = @populations[@current_population][para].prog_size
		@populations[next_pop][childb].prog_size = @populations[@current_population][parb].prog_size
	end
	def mutate(gene)
		if rand > MPROB
			gene = rand(MAX_INSTRUCTIONS)
			@current_mutations += 1
		end
		gene
	end
	def select_parent
		@@class_chrom = 0
		ret = -1
		ret_fitness = 0.0
		loop do
			ret_fitness = @populations[@current_population][@@class_chrom].fitness / @max_fitness
			@@class_chrom = 0 if @@class_chrom == MAX_CHROMS - 1
			if @populations[@current_population][@@class_chrom].fitness > @min_fitness and rand < ret_fitness
				ret = @@class_chrom
				@@class_chrom += 1
				ret_fitness = @populations[@current_population][@@class_chrom].fitness
				break
			end
			@@class_chrom += 1
		end
		return ret	
	end
	def perform_fitness_check
		@max_fitness = 0
		@min_fitness = 1000
		@total_fitness = 0
		MAX_CHROMS.times {|chrom|
			puts "chrom = " + chrom.to_s if chrom % 100 == 0
			@populations[@current_population][chrom].reset_fitness
			Instructions::COUNT.times {|i|	
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
		printf("%d %6.4f %6.4f %6.4f\n", @@weird_x_value, @min_fitness, @avg_fitness, @max_fitness)
		@@weird_x_value += 1
	end
	def interpret_stm(program, prog_length, args)
		pc = -1
		error = Instructions::NONE
		args.size.downto(0) {|x| spush(args[x])	}
		while error == Instructions::NONE && pc < prog_length
			pc += 1
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
		MAX_CHROMS.times {|x| init_member(x) }
	end
	def init_member(index)
		@populations[@current_population] = [] if @populations[@current_population] == nil
		@populations[@current_population][index] = Population.new
		MAX_PROGRAM.times {|x| 
			@populations[@current_population][index].program[x] = rand(Instructions::MAX_INSTRUCTIONS)
		}
	end
end

if __FILE__ == $0
	Genetic.new.run
end
