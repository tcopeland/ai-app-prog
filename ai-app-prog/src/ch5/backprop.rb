#!/usr/local/bin/ruby

class Element
	attr_reader :health, :knife, :gun, :enemy, :output_neurons
	def initialize(health, knife, gun, enemy, output_neurons)
		@health, @knife, @gun, @enemy, @output_neurons = health, knife, gun, enemy, output_neurons
	end
end

class BackProp
	INPUT_NEURONS = 4
	HIDDEN_NEURONS = 3
	OUTPUT_NEURONS = 4
	RAND_MAX = 2147483647.0
	MAX_SAMPLES = 18
	def initialize
		@wih = []
		@who = []
		@inputs = []
		@samples = [
  		Element.new(2.0, 0.0, 0.0, 0.0, [0.0, 0.0, 1.0, 0.0]),
		  Element.new(2.0, 0.0, 0.0, 1.0, [0.0, 0.0, 1.0, 0.0]),
		  Element.new(2.0, 0.0, 1.0, 1.0, [1.0, 0.0, 0.0, 0.0]),
		  Element.new(2.0, 0.0, 1.0, 2.0, [1.0, 0.0, 0.0, 0.0]),
		  Element.new(2.0, 1.0, 0.0, 2.0, [0.0, 0.0, 0.0, 1.0]),
		  Element.new(2.0, 1.0, 0.0, 1.0, [1.0, 0.0, 0.0, 0.0]),
  		Element.new(1.0, 0.0, 0.0, 0.0, [0.0, 0.0, 1.0, 0.0]),
		  Element.new(1.0, 0.0, 0.0, 1.0, [0.0, 0.0, 0.0, 1.0]),
		  Element.new(1.0, 0.0, 1.0, 1.0, [1.0, 0.0, 0.0, 0.0]),
		  Element.new(1.0, 0.0, 1.0, 2.0, [0.0, 0.0, 0.0, 1.0]),
		  Element.new(1.0, 1.0, 0.0, 2.0, [0.0, 0.0, 0.0, 1.0]),
		  Element.new(1.0, 1.0, 0.0, 1.0, [0.0, 0.0, 0.0, 1.0]),
  		Element.new(0.0, 0.0, 0.0, 0.0, [0.0, 0.0, 1.0, 0.0]),
		  Element.new(0.0, 0.0, 0.0, 1.0, [0.0, 0.0, 0.0, 1.0]),
		  Element.new(0.0, 0.0, 1.0, 1.0, [0.0, 0.0, 0.0, 1.0]),
		  Element.new(0.0, 0.0, 1.0, 2.0, [0.0, 1.0, 0.0, 0.0]),
		  Element.new(0.0, 1.0, 0.0, 2.0, [0.0, 1.0, 0.0, 0.0]),
		  Element.new(0.0, 1.0, 0.0, 1.0, [0.0, 0.0, 0.0, 1.0])
		]
	end
	def rand_weight
		(rand(RAND_MAX) / RAND_MAX) - 0.5
	end
	def run
		err=0.0
		i,iterations,sum = 0
		sample = 0
		file = File.open("stats.txt", "w")
		assign_random_weights
		while true
			if (sample + 1) == MAX_SAMPLES	
				sample = 0	
			end
			@inputs[0] = @samples[sample].health
		end
		file.close			
	end
	def assign_random_weights
		INPUT_NEURONS.times {|input|
			HIDDEN_NEURONS.times {|hidden|
				@wih[input] = [] if @wih[input] == nil
				@wih[input][hidden] = rand_weight
			}
		}
		HIDDEN_NEURONS.times {|hidden|
			OUTPUT_NEURONS.times {|output|
				@who[hidden] = [] if @who[hidden] == nil
				@who[hidden][output] = rand_weight
			}
		}
	end
end

if __FILE__ == $0
	BackProp.new.run
end
