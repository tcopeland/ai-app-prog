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
	LEARN_RATE = 0.2
	MAX_ITERATIONS = 10000
	STRINGS = ["Attack", "Run", "Wander", "Hide"]
	def initialize
		@wih = []
		@who = []
		@inputs = []
		@target = []
		@hidden = []
		@actual = []
		@erro = []
		@errh = []
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
		sample=iterations=sum=0
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
			OUTPUT_NEURONS.times {|i|
				err += (@samples[sample].output_neurons[i] - @actual[i]) ** 2
			}
			err = 0.5 * err
			file.write("#{err}\n")
		
			iterations += 1
			break if iterations > MAX_ITERATIONS
			#puts iterations.to_s + " of " + MAX_ITERATIONS.to_s + " iterations" if iterations % 100 == 0

			back_propagate
		end
		MAX_SAMPLES.times {|i|
			@inputs[0] = @samples[i].health
			@inputs[1] = @samples[i].knife
			@inputs[2] = @samples[i].gun
			@inputs[3] = @samples[i].enemy
			
			@target[0] = @samples[i].output_neurons[0]
			@target[1] = @samples[i].output_neurons[1]
			@target[2] = @samples[i].output_neurons[2]
			@target[3] = @samples[i].output_neurons[3]
		
			feed_forward
			if action(@actual) != action(@target) 
				printf(file, "%2.1g:%2.1g:%2.1g:%2.1g %s (%s)\n", @inputs[0], @inputs[1], @inputs[2], @inputs[3], STRINGS[action(@actual)], STRINGS[action(@target)])
			else
				sum += 1
			end	
		}
		printf("Network is %g%% correct\n", (sum.to_f/MAX_SAMPLES.to_f)*100)

		test_inputs(2.0, 1.0, 1.0, 1.0)
		test_inputs(1.0, 1.0, 1.0, 2.0)
		test_inputs(0.0, 0.0, 0.0, 0.0)
		test_inputs(0.0, 1.0, 1.0, 1.0)
		test_inputs(2.0, 0.0, 1.0, 3.0)
		test_inputs(2.0, 1.0, 0.0, 3.0)
		test_inputs(0.0, 1.0, 0.0, 3.0)

		file.close			
	end
	def test_inputs(a, b, c, d)
		@inputs[0],@inputs[1],@inputs[2],@inputs[3] = a,b,c,d
		feed_forward
		puts a.to_i.to_s + b.to_i.to_s + c.to_i.to_s + d.to_i.to_s + " action " + STRINGS[action(@actual)]
	end
	def action(vector)
		selection = 0
		max=vector[0]
		1.upto(OUTPUT_NEURONS-1) {|index|
			if vector[index] > max
				max = vector[index]
				selection = index
			end
		}
		return selection
	end
	def back_propagate
		OUTPUT_NEURONS.times {|output|
			@erro[output] = (@target[output] - @actual[output])	 * sigmoid_derivative(@actual[output])
		}
		HIDDEN_NEURONS.times {|hid|
			@errh[hid] = 0.0
			OUTPUT_NEURONS.times {|output|
				@errh[hid] += @erro[output] * @who[hid][output]
			}
			@errh[hid] *= sigmoid_derivative(@hidden[hid])
		}
		OUTPUT_NEURONS.times {|output|
			HIDDEN_NEURONS.times {|hid|
				@who[hid][output] += (LEARN_RATE * @erro[output] * @hidden[hid])
			}
			@who[HIDDEN_NEURONS][output] += (LEARN_RATE * @erro[output])
		}
		HIDDEN_NEURONS.times {|hid|
			INPUT_NEURONS.times {|input|
				@wih[input][hid] += (LEARN_RATE * @errh[hid] * @inputs[input])		
			}
			@wih[INPUT_NEURONS][hid] += (LEARN_RATE * @errh[hid])
		}
	end
	def sigmoid_derivative(val)
		val * (1.0 - val)
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
