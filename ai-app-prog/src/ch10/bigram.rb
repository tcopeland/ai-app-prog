#!/usr/local/bin/ruby

class Bigram
	MAX_WORD_LEN=40
	MAX_WORDS=1000
	FIRST_WORD=0
	MIDDLE_WORD=1
	LAST_WORD=2
	START_SYMBOL=0
	END_SYMBOL=1
	
	def initialize(debug)
		@debug = debug
		@word_vector = []
		@occurrences = Hash.new(0)
		@@last_index = START_SYMBOL
		
		@word_vector << "<START>"
		@word_vector << "<END>"

		@bigram_array = Array.new(MAX_WORDS)
		@bigram_array.each_index {|x| @bigram_array[x] = Array.new(MAX_WORDS, 0)}
	end

	def build_sentence
		max = 0
		puts "\n"
		word = next_word(START_SYMBOL)
		while word != END_SYMBOL and max < 100
			puts "#{@word_vector[word]} "
			word = next_word(word)
			max += rand(12)
		end
		puts "\n"	
	end

	def next_word(word)
		nextwordindex = @word_vector.index(word) + 1
		lim = rand(@occurrences[word] + 1)
		while nextwordindex != @word_vector.index(word)
			# TODO
		end
	end

	def parse_corpus(filename)
		word = ""
		first = false
		file = File.open(filename, "r")
		file.each_byte {|byte|
			if file.eof
				if word.size > 0
					load_word(word, LAST_WORD)
					word = ""
				end
			elsif byte == 10 or byte == 13 or byte.chr == ' '
				if !word.empty?
					if first
						first = false
						load_word(word, FIRST_WORD)
					else
						load_word(word, MIDDLE_WORD)
					end	
					word = ""
				end
			elsif byte.chr == '.' or byte.chr == '?'
				load_word(word, MIDDLE_WORD)
				load_word(word, LAST_WORD)
				first = true
				word = ""
			else
				if byte != 10 and byte.chr != ','
					word << byte.chr
				end
			end
		}
		if @debug
			puts "#{@word_vector.size} unique words in the corpus"
		end
	end

	def load_word(word, order)
		if @word_vector.size >= MAX_WORDS
			puts "Too many words, increase MAX_WORDS!\n"
			exit(1)
		end
		if !@word_vector.include?(word)
			@word_vector << word
		end
		if order == FIRST_WORD
			@bigram_array[START_SYMBOL][@word_vector.index(word)] += 1
			@occurrences[START_SYMBOL] += 1
		elsif order == LAST_WORD
			@bigram_array[END_SYMBOL][@word_vector.index(word)] += 1
			@bigram_array[@word_vector.index(word)][END_SYMBOL] += 1
			@occurrences[END_SYMBOL] += 1
		else
			@bigram_array[@@last_index][@word_vector.index(word)] += 1
			@occurrences[@word_vector[@@last_index]] += 1
		end
		@@last_index = @word_vector.index(word)
	end
end

if __FILE__ == $0
	if ARGV.length < 2 or !ARGV.include?("-f")
		puts "./bigram -f <filename> [-v]"
		exit
	end
	b = Bigram.new(ARGV.include?("-v"))
	b.parse_corpus(ARGV[ARGV.index("-f")+1])
	#b.build_sentence
end
