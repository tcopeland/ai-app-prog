#!/usr/local/bin/ruby

class Adaptive
	MAX_ITEMS = 11
	MAX_CUSTOMERS = 10
	TOTAL_PROTOTYPE_VECTORS = 5
	def initialize
		@prototype_vector	= Array.new(TOTAL_PROTOTYPE_VECTORS, 0)
		@prototype_vector.each {|x|
			x = Array.new(MAX_ITEMS, 0)
		}
		@sum_vector	= Array.new(TOTAL_PROTOTYPE_VECTORS, 0)
		@sum_vector.each {|x|
			x = Array.new(MAX_ITEMS, 0)
		}
		@members = Array.new(TOTAL_PROTOTYPE_VECTORS, 0)
		@membership = Array.new(MAX_CUSTOMERS, -1)
	end
end

if __FILE__ == $0
	a = Adaptive.new
end
