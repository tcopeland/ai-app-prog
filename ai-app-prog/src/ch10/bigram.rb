#!/usr/local/bin/ruby

class Bigram
	MAX_WORD_LEN=40
	MAX_WORDS=1000
	FIRST_WORD=0
	MIDDLE_WORD=1
	LAST_WORD=2
	START_SYMBOL=0
	END_SYMBOL=1
	
	def initialize(debug, filename)
		@current_word = 2
		@word_vector = Array.new(MAX_WORDS)
		@sum_vector = Array.new(MAX_WORDS)
		@@last_index = START_SYMBOL
		
		@word_vector << "<START>"
		@word_vector << "<END>"

		@bigram_array = Array.new(MAX_WORDS)
		@bigram_array.each {|slot| slot = Array.new(MAX_WORDS)}
		word = ""
		first = false
		file = File.open(filename, "r")
		file.each_byte {|byte|
			if file.eof
				if word.size > 0
					load_word(word, LAST_WORD)
				end
			elsif byte == 10 or byte == 13 or byte.chr == ' '
				if !word.empty?
					if first
						first = false
						load_word(word, FIRST_WORD)
					else
						load_word(word, MIDDLE_WORD)
					end	
				end
			elsif byte.chr == '.' or byte.chr == '?'
				load_word(word, MIDDLE_WORD)
				load_word(word, LAST_WORD)
				first = true
			else
				if byte != 10 and byte.chr != ','
					word << byte.chr
				end
			end
		}
	end

	def load_word(word, order)
		if @current_word == MAX_WORDS
			puts "Too many words, increase MAX_WORDS!\n"
			exit(1)
		end
		if !@word_vector.includes?(word)
			@word_vector << word
		end
		if order == FIRST_WORD
			@bigram_array[START_SYMBOL][@word_vector.index(word)] += 1
			@sum_vector[START_SYMBOL] += 1
		elsif order == LAST_WORD
			@bigram_array[END_SYMBOL][@word_vector.index(word)] += 1
			@bigram_array[@word_vector.index(word)][END_SYMBOL] += 1
			@sum_vector[END_SYMBOL] += 1
		else
			@bigram_array[@@last_index][@word_vector.index(word)] += 1
			@sum_vector[@@last_index] += 1
		end
		@@last_index = @word_vector.index(word)
	end
end

if __FILE__ == $0
		if ARGV.length < 2 or !ARGV.include?("-f")
				puts "./bigram -f <filename> [-v]"
				exit
		end
	Bigram.new(ARGV.include?("-v"),ARGV[ARGV.index("-f")+1])
end
