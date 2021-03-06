#!/usr/local/bin/ruby

class Population
	attr_reader :prog_size, :program
	attr_accessor :fitness
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
	COUNT = 5
	TIER1 = 1
	TIER2 = (TIER1+1)*COUNT
	TIER3 = (TIER1+TIER2+2)*COUNT
	MAX_FITNESS = ((TIER3*COUNT) + (TIER2*COUNT) + (TIER1*COUNT)).to_f
end

class Stack
	STACK_DEPTH = 25
	STACK_VIOLATION = 1
	def initialize
		@s = []
	end
	def assert_elements(x)
		raise Exception.exception(STACK_VIOLATION.to_s) if @s.size < x
	end
	def assert_not_full
		raise Exception.exception(STACK_VIOLATION.to_s) if @s.size == STACK_DEPTH
	end
	def size
		@s.size
	end
	def first
		@s.first
	end
	def push(x)
		@s << x
	end
	def pop
		tmp = @s.last
		@s = @s[0,@s.size-1]
		return tmp
	end
	def peek
		@s.last
	end
	def swap
		a = peek
		@s[@s.size-1] = @s[@s.size-2]
		@s[@s.size-2] = a
	end
	def over
		push(@s[@s.size-2])
	end
end

class StackMachine
	attr_reader :stack
	def initialize(pop,args)
		@pop = pop
		@stack = Stack.new
		args.reverse.each {|x| @stack.push(x) }
	end
	def one_solution
		@stack.size == 1
	end
	def first
		@stack.first
	end
	def solve
		@pop.prog_size.times {|x|
			case @pop.program[x]
				when Instructions::DUP
					@stack.assert_elements(1)
					@stack.assert_not_full
					@stack.push(@stack.peek)
				when Instructions::SWAP
					@stack.assert_elements(2)
					@stack.swap
				when Instructions::MUL
					@stack.assert_elements(2)
					a = @stack.pop
					b = @stack.pop
					@stack.push(a * b)
				when Instructions::ADD
					@stack.assert_elements(2)
					a = @stack.pop
					b = @stack.pop
					@stack.push(a + b)
				when Instructions::OVER
					@stack.assert_elements(2)
					@stack.over
			end
		}
	end
end

class Generation
	attr_accessor :average_fitness
	attr_reader :id, :crossovers, :mutations, :minimum_fitness, :maximum_fitness
	@@classid = 0 
	def initialize
		@id = @@classid
		@crossovers = 0
		@mutations = 0
		@minimum_fitness = 1000.0
		@maximum_fitness = 0.0
		@average_fitness = 0.0
		@@classid += 1
	end
	def new_crossover
		@crossovers += 1
	end
	def new_mutation
		@mutations += 1
	end
	def check_minimax(x)
		if x < @minimum_fitness
			@minimum_fitness = x
		elsif x > @maximum_fitness
			@maximum_fitness = x
		end
	end
	def pctg
		@average_fitness.to_f/@maximum_fitness
	end
	def print_me
		puts "Generation #{id}"
		printf("\tMaximum fitness = %f (%g)\n", @maximum_fitness, Instructions::MAX_FITNESS)
		printf("\tAverage fitness = %f\n", @average_fitness)
		printf("\tMinimum fitness = %f\n", @minimum_fitness)
		printf("\tCrossovers = %d\n", @crossovers)
		printf("\tMutations = %d\n", @mutations)
		printf("\tPercentage = %f\n", pctg)
	end
	def converged
		(@id > (Genetic::MAX_GENERATIONS * 0.25)) && (pctg > 0.98)
	end
	def found_solution	
		@maximum_fitness == Instructions::MAX_FITNESS
	end
end

class Genetic
	MAX_PROGRAM=8
	MAX_GENERATIONS=1000
	MAX_CHROMS=3000
	MUTATION_PROB = 0.02
	CROSSOVER_PROB = 0.8
	XPROB = 1.0 - CROSSOVER_PROB
	MPROB = 1.0 - MUTATION_PROB
	def initialize
		@current_population=0
		@populations = []
	end
	def run
		g = nil
		init_population
		while g.id < MAX_GENERATIONS
			g = Generation.new
			calculate_fitness(g)
			perform_selection(g)
			@current_population = @current_population == 0 ? 1 : 0
			calculate_fitness(g)
			g.print_me
			if g.converged
				puts "Converged"
				break
			elsif g.found_solution
				puts "Found solution"
				break
			end
		end
		MAX_CHROMS.times {|i|
			if @populations[@current_population][i].fitness == g.maximum_fitness
				printf("Program %3d : ", i)
				@populations[@current_population][i].prog_size.times {|x|
					printf("%0.2d ", @populations[@current_population][i].program[x])
				}
				printf("\n")
				printf("Fitness %d\n", @populations[@current_population][i].fitness.to_i)
				break
			end
		}
	end

	def perform_selection(g)
		0.step(MAX_CHROMS-1, 2) {|c|
			perform_reproduction(g, select_parent, select_parent, c, c+1)
		}
	end

	def perform_reproduction(g, para, parb, childa, childb)
		cross_point = MAX_PROGRAM
		if rand > XPROB
			cross_point = rand(@populations[@current_population][parb].prog_size - 2) + 1
			g.new_crossover
		end
		next_pop = @current_population == 0 ? 1 : 0
		@populations[next_pop] = [] if @populations[next_pop] == nil
		@populations[next_pop][childa] = Population.new if @populations[next_pop][childa] == nil
		@populations[next_pop][childb] = Population.new if @populations[next_pop][childb] == nil
		cross_point.times {|i|
			@populations[next_pop][childa].program[i] = mutate(g, @populations[@current_population][childa].program[i])
			@populations[next_pop][childb].program[i] = mutate(g, @populations[@current_population][childb].program[i])
		}
		cross_point.upto(MAX_PROGRAM-1) {|i|
			@populations[next_pop][childa].program[i] = mutate(g, @populations[@current_population][parb].program[i])
			@populations[next_pop][childb].program[i] = mutate(g, @populations[@current_population][para].program[i])
		}		
	end

	def mutate(g, gene)
		if rand > MPROB
			gene = rand(Instructions::MAX_INSTRUCTIONS)
			g.new_mutation
		end
		gene
	end

	def select_parent
		chrom = 0
		ret_fitness = 0.0	
		fit_marker = rand * @total_fitness * 0.25
		loop do		
			ret_fitness += @populations[@current_population][chrom].fitness
			chrom += 1	
			break if ret_fitness >= fit_marker
			chrom = 0 if chrom == MAX_CHROMS
		end
		chrom - 1
	end

	def calculate_fitness(g)
		@total_fitness = 0.0
		MAX_CHROMS.times {|chrom|
			@populations[@current_population][chrom].reset_fitness
			Instructions::COUNT.times {|i|	
				args = [rand(32), rand(32), rand(32)]
				#answer = args[0]*args[1] + args[1]*args[1] + args[2]
				answer = (args[0]*args[1]) + (args[1]*2) + args[2]
				begin 
					stm = StackMachine.new(@populations[@current_population][chrom], args)
					stm.solve
					@populations[@current_population][chrom].fitness += Instructions::TIER1
					@populations[@current_population][chrom].fitness += Instructions::TIER2 if stm.one_solution
					@populations[@current_population][chrom].fitness += Instructions::TIER3 if stm.first == answer
				rescue Exception => x
					# no points if there was an error
				end
			}	
			g.check_minimax(@populations[@current_population][chrom].fitness)
			@total_fitness += @populations[@current_population][chrom].fitness
		}
		g.average_fitness = @total_fitness.to_f / MAX_CHROMS.to_f
	end

	def init_population	
		MAX_CHROMS.times {|x| 
			@populations[@current_population] = [] if @populations[@current_population] == nil
			@populations[@current_population][x] = Population.new
			MAX_PROGRAM.times { 
				@populations[@current_population][x].program << rand(Instructions::MAX_INSTRUCTIONS)
			}
		}
	end
end

if __FILE__ == $0
	Genetic.new.run
end
