#!/usr/local/bin/ruby

class Vector
  def initialize(size_or_array)
    if size_or_array.kind_of?(Array)
      @a = size_or_array
    else
      @a = Array.new(size_or_array,0)
    end
  end
  def value(x)
    @a[x]
  end
  def set(x)
    @a[x] = 1
  end
  def set?(x)
    @a[x] == 1
  end
  def magnitude
    @a.collect{|x| x > 0 ? 1 : nil }.compact.size
  end
  def clear(x)
    @a[x] = 0
  end
  def add(x)
    @a.each_index{|i| @a[i] += x.value(i) }
  end
  def bitwise_and(w)
    res = Vector.new(@a.size)
    0.upto(@a.size-1) {|i|
      res.set(i) if set?(i) && w.set?(i)
    }
    res
  end
  def to_s
    @a.inspect
  end
end

class Adaptive
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
	ITEM_NAMES = [
    "Hammer", "Paper", "Snickers", "Screwdriver",
    "Pen", "Kit-Kat", "Wrench", "Pencil",
    "Heath-Bar", "Tape-Measure", "Binder"]
	
	MAX_CUSTOMERS = 10
	TOTAL_PROTOTYPE_VECTORS = 5
	BETA = 1.0
	VIGILANCE = 0.9

	def initialize
		@prototype_vector	= Array.new(TOTAL_PROTOTYPE_VECTORS, 0)
		@prototype_vector.each_index {|x| @prototype_vector[x] = Array.new(ITEM_NAMES.size, 0) }
		@sum_vector	= Array.new(TOTAL_PROTOTYPE_VECTORS, 0)
		@sum_vector.each_index {|x| @sum_vector[x] = Array.new(ITEM_NAMES.size, 0) }
		@members = Array.new(TOTAL_PROTOTYPE_VECTORS, 0)
		@membership = Array.new(MAX_CUSTOMERS, -1)
		@num_prototype_vectors = 0
	end
	def perform_art1
		and_result = Array.new(ITEM_NAMES.size)
		count = 50
		exit = false
		mag_pe = mag_p = mag_e = 0
		while !exit
			exit = true
			0.upto(MAX_CUSTOMERS-1) {|index|
				0.upto(TOTAL_PROTOTYPE_VECTORS-1) {|pvec|	
					if !@members[pvec].nil?
						mag_pe = vector_magnitude(vector_bitwise_and(DATABASE[index], @prototype_vector[pvec]))
						mag_p = vector_magnitude(@prototype_vector[pvec])
						mag_e = vector_magnitude(DATABASE[index])
						result = mag_pe.to_f / (BETA + mag_p)
						test = mag_e.to_f / (BETA + ITEM_NAMES.size.to_f)
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
									update_prototype_vectors(pvec)
									exit = false
									break
								end
							end
						end
					end
				}
				if @membership[index] == -1
					@membership[index] = create_new_prototype_vector(DATABASE[index])
					done = false
				end
			}
			count -= 1
			break if count == 0
		end
	end
	def create_new_prototype_vector(example)
		cluster = 0 
		0.upto(TOTAL_PROTOTYPE_VECTORS-1) {|x|
			if @members[x] == 0
				cluster = x
				break
			end
		}
		@num_prototype_vectors += 1
		0.upto(ITEM_NAMES.size-1) {|i| @prototype_vector[cluster][i] = example[i] }	
		@members[cluster] = 1
		cluster
	end
	def update_prototype_vectors(cluster)
		first = true
		raise "Cluster < 0!!" if cluster < 0
		0.upto(ITEM_NAMES.size) {|item|
			@prototype_vector[cluster][item] = 0
			@sum_vector[cluster][item] = 0
		}
		0.upto(MAX_CUSTOMERS-1) {|customer|
			if @membership[customer] == cluster
				if first
					0.upto(ITEM_NAMES.size-1) {|item|
						@prototype_vector[cluster][item] = DATABASE[customer][item]
						@sum_vector[cluster][item] = DATABASE[customer][item]
					}
					first = false
				else
					0.upto(ITEM_NAMES.size-1) {|item|
						@prototype_vector[cluster][item] = (@prototype_vector[cluster][item] == 1 && DATABASE[customer][item] == 1) ? 1 : 0
						@sum_vector[cluster][item] += DATABASE[customer][item]
					}
				end
			end
		}
	end
	def display_customer_database
		0.upto(TOTAL_PROTOTYPE_VECTORS-1) {|cluster|
			puts "ProtoVector: #{cluster}"
			0.upto(ITEM_NAMES.size-1) {|item|
				printf("%1d ", @prototype_vector[cluster][item])
			}
			puts "\n"
			0.upto(MAX_CUSTOMERS-1) {|customer|
				if @membership[customer] == cluster
					puts "Customer #{customer}"
					0.upto(ITEM_NAMES.size-1) {|item|
						printf("%1d ", DATABASE[customer][item])
					}
					puts " : #{@membership[customer]} :"
				end
			}
		}
	end
	def make_recommendations
		0.upto(MAX_CUSTOMERS-1) {|customer|
			best = -1
			val = 0
			0.upto(ITEM_NAMES.size-1) {|item|
				if DATABASE[customer][item] == 0 && @sum_vector[@membership[customer]][item] > val
					best = item
					val = @sum_vector[@membership[customer]][item]
				end
			}
			printf("For customer #{customer}, ")
			if best >= 0
				puts "the best recommendation is #{best} (#{ITEM_NAMES[best]})"
				puts "Owned by #{@sum_vector[@membership[customer]][best]} out of #{@members[@membership[customer]]} members of this cluster"
			else
				puts "no recommendation can be made"
			end
			printf("Already owns: ")
			0.upto(ITEM_NAMES.size-1) {|item|
				printf("%s ", ITEM_NAMES[item]) if DATABASE[customer][item] == 1
			}
			puts "\n"
		}
	end
	def vector_magnitude(v)
		v.collect{|a| a > 0 ? 1 : nil}.compact.size
	end
	def vector_bitwise_and(v, w)
		res = Array.new(v.size, 0)
		0.upto(ITEM_NAMES.size-1) {|i| 
			res[i] = (v[i]==1 && w[i]==1) ? 1 : 0 
		}
		res
	end
end

if __FILE__ == $0
	a = Adaptive.new	
	a.perform_art1
	a.display_customer_database
	a.make_recommendations
end
