#!/usr/local/bin/ruby

class Adaptive
	MAX_ITEMS = 11
	MAX_CUSTOMERS = 10
	TOTAL_PROTOTYPE_VECTORS = 5
	BETA = 1.0
	VIGILANCE = 0.0
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
		@num_prototype_vectors = 0
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
						result = mag_pe.to_f / (BETA + mag_p)
						test = mag_e.to_f / (BETA + MAX_ITEMS.to_f)
						if result > test	
							if (mag_pe.to_f / mag_e.to_f) < VIGILANCE
								old = 0
								if @membership[index] != pvec
									old = @membership[index]
									@membership[index] = pvec
									if old >= 0 
										@members[old] -= 1
										@num_prototype_vectors -= 1 if @members[old] == 0
									end
									@members[pvec] += 1
									update_prototype_vectors(old) if old >=0 && old < TOTAL_PROTOTYPE_VECTORS
								end
							end
						end
					end
				}
			}
		end
	end
	def update_prototype_vectors(cluster)
		first = true
		raise "Cluster < 0!!" if cluster < 0
		0.upto(MAX_ITEMS) {|item|
			@prototype_vector[cluster][item] = 0
			@sum_vector[cluster][item] = 0
		}
		0.upto(MAX_CUSTOMERS-1) {|customer|
			if @membership[customer] == cluster
				if first
					0.upto(MAX_ITEMS-1) {|item|
						@prototype_vector[cluster][item] = DATABASE[customer][item]
						@sum_vector[cluster][item] = DATABASE[customer][item]
					}
					first = false
				else
					0.upto(MAX_ITEMS-1) {|item|
						@prototype_vector[cluster][item] = @prototype_vector[cluster][item] & DATABASE[customer][item]
						@sum_vector[cluster][item] += DATABASE[customer][item]
					}
				end
			end
		}
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
