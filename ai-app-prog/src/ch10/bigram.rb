#!/usr/local/bin/ruby

class DataFile
	def initialize(filename)
		@bigram_array = Array.new(Bigram::MAX_WORDS, 0)
		# parsefile code goes here
		
	end
end

class Bigram
	MAX_WORD_LEN=40
	MAX_WORDS=1000
	FIRST_WORD=0
	MIDDLE_WORD=1
	LAST_WORD=2
	START_SYMBOL=0
	END_SYMBOL=1
	
	def initialize(debug, datafile)
		@current_word = 2
		@word_vector = Array.new(MAX_WORDS)
		@sum_vector = Array.new(MAX_WORDS)
		
		@word_vector[0] = "<START>"
		@word_vector[1] = "<END>"
	end
end

if __FILE__ == $0
		if ARGV.length < 2 or !ARGV.include?("-f")
				puts "./bigram -f <filename> [-v]"
				exit
		end
	Bigram.new(ARGV.include?("-v"), DataFile.new(ARGV[ARGV.index("-f")+1]))
end
