#!/usr/local/bin/ruby

class Bigram
	MAX_WORD_LEN=40
	MAX_WORDS=1000
	FIRST_WORD=0
	MIDDLE_WORD=1
	LAST_WORD=2
	START_SYMBOL="<START>"
	END_SYMBOL="<END>"
	WHITESPACE = ['\n','\r',' ']
	
	def initialize(debug)
		@debug = debug
		@occurrences = Hash.new(0)
		@@last_index = 0
		@word_vector = [START_SYMBOL, END_SYMBOL]
		@bigram_array = Array.new(MAX_WORDS)
		@bigram_array.each_index {|x| @bigram_array[x] = Array.new(MAX_WORDS, 0)}
	end

	def build_sentence
		max = 0
		sentence = ""
		word = next_word(START_SYMBOL)
		while word != END_SYMBOL and max < 100
			sentence << " #{word}"
			word = next_word(word)
			max += rand(12) + 1	
		end
		return sentence << ".\n"	
	end

	def next_word(word)
		nextwordindex = @word_vector.index(word) + 1
		lim = rand(@occurrences[word] + 1)	
		sum = 0
		while nextwordindex != @word_vector.index(word)
			nextwordindex = nextwordindex % @word_vector.size
			sum += @bigram_array[@word_vector.index(word)][nextwordindex]
			if sum >= lim
				return @word_vector[nextwordindex]
			end
			nextwordindex += 1		
		end
		return @word_vector[nextwordindex]
	end

	def parse_corpus(stream)
		word = ""
		first = false
		stream.each_byte {|byte|
			if stream.eof
				if word.size > 0
					load_word(word, LAST_WORD)
				end
			elsif WHITESPACE.include?(byte.chr)
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
			@occurrences.sort {|a,b| b[1] <=> a[1] }.each {|x| puts "\"#{x[0]}\" occurred #{x[1]} times" unless x[1] < 4 }
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
			@bigram_array[0][@word_vector.index(word)] += 1
			@occurrences[START_SYMBOL] += 1
		elsif order == LAST_WORD
			@bigram_array[1][@word_vector.index(word)] += 1
			@bigram_array[@word_vector.index(word)][1] += 1
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
	File.open(ARGV[ARGV.index("-f")+1], "r") {|f| b.parse_corpus(f)}
	5.times { puts b.build_sentence}
end
