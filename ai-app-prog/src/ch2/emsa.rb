#!/usr/local/bin/ruby

class Member
	def initialize
		@solution=[]
		@energy=0.0
	end
end

class Emsa
	MAX_LENGTH=30
	INITIAL_TEMPERATURE=30.0
	FINAL_TEMPERATURE=0.5
	ALPHA=0.99
	STEPS_PER_CHANGE=100
end

if __FILE__ == $0
	puts "hi"
end
