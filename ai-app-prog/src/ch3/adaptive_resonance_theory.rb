#!/usr/local/bin/ruby

class Adaptive
	MAX_ITEMS = 11
	MAX_CUSTOMERS = 10
	TOTAL_PROTOTYPE_VECTORS = 5
	DATABASE = [
        [ 0,   0,   0,   0,   0,   1,   0,   0,   1,   0,   0],
        [ 0,   1,   0,   0,   0,   0,   0,   1,   0,   0,   1],
        [ 0,   0,   0,   1,   0,   0,   1,   0,   0,   1,   0],
        [ 0,   0,   0,   0,   1,   0,   0,   1,   0,   0,   1],
        [ 1,   0,   0,   1,   0,   0,   0,   0,   0,   1,   0],
        [ 0,   0,   0,   0,   1,   0,   0,   0,   0,   0,   1],
        [ 1,   0,   0,   1,   0,   0,   0,   0,   0,   0,   0],
        [ 0,   0,   1,   0,   0,   0,   0,   0,   1,   0,   0],
        [ 0,   0,   0,   0,   1,   0,   0,   1,   0,   0,   0],
        [ 0,   0,   1,   0,   0,   1,   0,   0,   1,   0,   0]	
	]
	def initialize
		@prototype_vector	= Array.new(TOTAL_PROTOTYPE_VECTORS, 0)
		@prototype_vector.each_index {|x|
			@prototype_vector[x] = Array.new(MAX_ITEMS, 0)
		}
		@sum_vector	= Array.new(TOTAL_PROTOTYPE_VECTORS, 0)
		@sum_vector.each_index {|x|
			@sum_vector[x] = Array.new(MAX_ITEMS, 0)
		}
		@members = Array.new(TOTAL_PROTOTYPE_VECTORS, 0)
		@membership = Array.new(MAX_CUSTOMERS, -1)
	end
	def perform_art1
		and_result = Array.new(MAX_ITEMS)
		exit = false
		mag_pe = mag_p = mag_e = 0
		while !exit
			exit = true
			0.upto(MAX_CUSTOMERS-1) {|index|
				0.upto(TOTAL_PROTOTYPE_VECTORS-1) {|pvec|	
					if !@members[pvec].nil?
						vector_bitwise_and(and_result, DATABASE[index], @prototype_vector[pvec])
						mag_pe = vector_magnitude(and_result)
						mag_p = vector_magnitude(@prototype_vector[pvec])
						mag_e = vector_magnitude(DATABASE[index])
					end
				}
			}
		end
	end
	def vector_magnitude(v)
		res = 0
		v.each {|x| res += x }
		res
	end
	def vector_bitwise_and(res, v, w)
		0.upto(MAX_ITEMS-1) {|i| res[i] = v[i] & w[i] }
	end
end

if __FILE__ == $0
	a = Adaptive.new	
	a.perform_art1
end
