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
		@target = []
		@hidden = []
		@actual = []
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
		i=sample=iterations=sum=0
		file = File.open("stats.txt", "w")
		assign_random_weights
		while true
			if (sample + 1) == MAX_SAMPLES	
				sample = 0	
			else 
				sample += 1
			end
			@inputs[0] = @samples[sample].health
			@inputs[1] = @samples[sample].knife
			@inputs[2] = @samples[sample].gun
			@inputs[3] = @samples[sample].enemy

			@target[0] = @samples[sample].output_neurons[0]
			@target[1] = @samples[sample].output_neurons[1]
			@target[2] = @samples[sample].output_neurons[2]
			@target[3] = @samples[sample].output_neurons[3]

			feed_forward
	
			err = 0.0
			OUTPUT_NEURONS.times {|output|
				err += (@samples[sample].output_neurons[output] - @actual[output]) ** 2
			}
			err = 0.5 * err
			file.write("#{err}\n")
			#puts "MSE = " + err.to_s
		
			iterations += 1
			break if iterations > 100000
		end
		file.close			
	end
	def sigmoid(val)
		(1.0 / (1.0 + Math.exp(-val.to_f)))
	end
	def feed_forward
		HIDDEN_NEURONS.times {|hid|	
			sum = 0.0
			INPUT_NEURONS.times {|input|
				sum += @inputs[input] * @wih[input][hid]
			}
			@wih[INPUT_NEURONS] = [] if @wih[INPUT_NEURONS] == nil
			@wih[INPUT_NEURONS][hid] = 0.0 if @wih[INPUT_NEURONS][hid] == nil
			sum += @wih[INPUT_NEURONS][hid]
			@hidden[hid] = sigmoid(sum)
		}	
		OUTPUT_NEURONS.times {|output|
			sum = 0.0
			HIDDEN_NEURONS.times {|hid|
				sum += @hidden[hid] * @who[hid][output]
			}
			@who[HIDDEN_NEURONS] = [] if @who[HIDDEN_NEURONS] == nil
			@who[HIDDEN_NEURONS][output] = 0.0 if @who[HIDDEN_NEURONS][output] == nil
			sum += @who[HIDDEN_NEURONS][output]
			@actual[output] = sigmoid(sum)
		}
	end
	def assign_random_weights
		INPUT_NEURONS.times {|input|
			HIDDEN_NEURONS.times {|hid|
				@wih[input] = [] if @wih[input] == nil
				@wih[input][hid] = rand_weight
			}
		}
		HIDDEN_NEURONS.times {|hid|
			OUTPUT_NEURONS.times {|output|
				@who[hid] = [] if @who[hid] == nil
				@who[hid][output] = rand_weight
			}
		}
	end
end

if __FILE__ == $0
	BackProp.new.run
end
