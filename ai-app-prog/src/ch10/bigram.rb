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
		
		@word_vector[0] = "<START>"
		@word_vector[1] = "<END>"

		@bigram_array = Array.new(MAX_WORDS, 0)
		@word = Array.new(MAX_WORDS+1)
		index = 0
		first = false
		file = File.open(filename, "r")
		file.each_byte {|byte|
			if file.eof
				if index > 0
					word[index]=0
					index += 1
					load_word(word, LAST_WORD)
					index = 0
				end
			elsif byte == 10 or byte == 13 or byte.chr == ' '
				if index > 0
					word[index] = 0
					index += 1
					if first
						first = false
						load_word(word, FIRST_WORD)
					else
						load_word(word, MIDDLE_WORD)
					end	
					index = 0
				end
			elsif byte.chr == '.' or byte.chr == '?'
				word[index] = 0
				index += 1
				load_word(word, MIDDLE_WORD)
				load_word(word, LAST_WORD)
				index = 0
				first = true
			else
				if byte != 10 and byte.chr != ','
					word[index] = byte.chr
				end
			end
		}
	end

	def load_word(word, order)
		word_index = 0
		
	end
end

if __FILE__ == $0
		if ARGV.length < 2 or !ARGV.include?("-f")
				puts "./bigram -f <filename> [-v]"
				exit
		end
	Bigram.new(ARGV.include?("-v"),ARGV[ARGV.index("-f")+1])
end
