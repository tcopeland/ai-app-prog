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
	def solve
		0.upto(@pop.prog_size - 1) {|x|
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

class Genetic
	MAX_PROGRAM=6
	MAX_GENERATIONS=10
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
		@@weird_x_value = 0
		@@class_chrom = 0
	end
	def run
		generation = 0
		init_population

		# added this hack to init both parts of the array
		@current_population = 1
		init_population
		@current_population = 0
		# added this hack to init both parts of the array

		perform_fitness_check
		while generation < MAX_GENERATIONS
			@current_crossovers = @current_mutations = 0
			perform_selection
			@current_population = @current_population == 0 ? 1 : 0
			generation += 1
			if generation % 100 == 0
				puts "Generation " + (generation-1).to_s
				printf("\tMaximum fitness = %f (%g)\n", @max_fitness, Instructions::MAX_FITNESS)
				printf("\tAverage fitness = %f\n", @avg_fitness)
				printf("\tMinimum fitness = %f\n", @min_fitness)
				printf("\tCrossovers = %d\n", @current_crossovers)
				printf("\tMutation = %d\n", @current_mutations)
				printf("\tPercentage = %f\n", @avg_fitness.to_f/@max_fitness.to_f)
			end
			if generation > (MAX_GENERATIONS * 0.25) && (@avg_fitness / @max_fitness) > 0.98
				puts "Converged"
				break
			end
			if @max_fitness == Instructions::MAX_FITNESS
				puts "Found solution"
				break
			end
		end
		puts "Generation " + (generation-1).to_s
		printf("\tMaximum fitness = %f (%g)\n", @max_fitness, Instructions::MAX_FITNESS)
		printf("\tAverage fitness = %f\n", @avg_fitness)
		printf("\tMinimum fitness = %f\n", @min_fitness)
		printf("\tCrossovers = %d\n", @current_crossovers)
		printf("\tMutation = %d\n", @current_mutations)
		printf("\tPercentage = %f\n", @avg_fitness.to_f/@max_fitness.to_f)
		MAX_CHROMS.times {|i|
			if @populations[@current_population][i].fitness == @max_fitness
				printf("Program %3d : ", i)
				@populations[@current_population][i].prog_size.times {|x|
					printf("%0.2d ", @populations[@current_population][i].program[i])
				}
				printf("\n")
				printf("Fitness %f\n", @populations[@current_population][i].fitness)
				printf("ProgSize %f\n", @populations[@current_population][i].prog_size)
				break
			end
		}
	end
	def perform_selection
		0.step(MAX_CHROMS-1, 2) {|chrom|
			perform_reproduction(select_parent, select_parent, chrom, chrom+1)
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
		cross_point.times {|i|
			@populations[next_pop][childa].program[i] = mutate(@populations[next_pop][childa].program[i])
			@populations[next_pop][childb].program[i] = mutate(@populations[next_pop][childb].program[i])
		}
		cross_point.upto(MAX_PROGRAM-1) {|i|
			@populations[next_pop][childa].program[i] = mutate(@populations[@current_population][parb].program[i])
			@populations[next_pop][childb].program[i] = mutate(@populations[@current_population][para].program[i])
		}
		@populations[next_pop][childa].prog_size = @populations[@current_population][para].prog_size
		@populations[next_pop][childb].prog_size = @populations[@current_population][parb].prog_size
	end
	def mutate(gene)
		if rand > MPROB
			gene = rand(Instructions::MAX_INSTRUCTIONS)
			@current_mutations += 1
		end
		gene
	end
	def select_parent
		@@class_chrom = 0
		ret = -1
		begin
			loop do
				ret_fitness = @populations[@current_population][@@class_chrom].fitness.to_f / @max_fitness.to_f
				@@class_chrom = 0 if @@class_chrom == MAX_CHROMS - 1
				#puts "@@class_chrom == #{@@class_chrom}, @populations[@current_population][@@class_chrom].fitness = #{@populations[@current_population][@@class_chrom].fitness}, @min_fitness = #{@min_fitness}, ret_fitness = #{ret_fitness}"
				#if @populations[@current_population][@@class_chrom].fitness >= @min_fitness && rand < ret_fitness
				if @populations[@current_population][@@class_chrom].fitness >= @min_fitness && rand < 0.5
					ret = @@class_chrom
					@@class_chrom += 1
					raise "STOP"	
				end
				@@class_chrom += 1	
			end
		rescue Exception => e
		end
		return ret	
	end
	def perform_fitness_check
		@max_fitness = 0.0
		@avg_fitness = 0.0
		@min_fitness = 1000.0
		@total_fitness = 0.0
		MAX_CHROMS.times {|chrom|
			@populations[@current_population][chrom].reset_fitness
			Instructions::COUNT.times {|i|	
				args = [rand(32), rand(32), rand(32)]
				answer = args[0]**3 + args[1]**2 + args[2]
				begin 
					stm = StackMachine.new(@populations[@current_population][chrom], args)
					stm.solve
					# no stack crashes, so some points
					@populations[@current_population][chrom].fitness += Instructions::TIER1
					# only one answer, more points
					@populations[@current_population][chrom].fitness += Instructions::TIER2 if stm.stack.size == 1
					# w00t!
					@populations[@current_population][chrom].fitness += Instructions::TIER3 if stm.stack.first == answer
				rescue Exception => x
					# no points if there was an error
				end
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
