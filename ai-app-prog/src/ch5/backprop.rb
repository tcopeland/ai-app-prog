#!/usr/local/bin/ruby

class BackProp
	INPUT_NEURONS = 4
	HIDDEN_NEURONS = 3
	OUTPUT_NEURONS = 4
	RAND_MAX = 2147483647.0
	def initialize
		@wih = []
		@who = []
	end
	def rand_weight
		(rand(RAND_MAX) / RAND_MAX) - 0.5
	end
	def run
		err=0.0
		i,sample,iterations,sum=0
		file = File.open("stats.txt", "w")
		assign_random_weights
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
