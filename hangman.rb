require 'yaml'

class Hangman

	attr_accessor :wanted_to_save_game, :wanted_to_load_game
	attr_reader :game_over

	def initialize
		@MAX_GUESSES = 6
		@guesses = []
		@wrong_guesses = 0
		@word = get_word
		@game_over = false
		@wanted_to_save_game = false
		@wanted_to_load_game = false
		ask_to_load_saved_game
		play_game unless @wanted_to_load_game
	end

	def get_word
		word = ''
		words = File.open('words.txt').readlines
		while word.empty?
			rand_word = words.sample
			word = rand_word.downcase if is_legal_word(rand_word)
		end
		word = deletes_non_alphabet_characters(word)
	end

	def deletes_non_alphabet_characters(word)
		word = word.split('').delete_if do |char| 
			!char.match(/[a-z]/)
		end
		word.join('')
	end

	def ask_to_load_saved_game
		puts
		puts "Would you like to load a saved game? (y/n)"
		answer = gets.chomp.downcase
		while (answer != 'y' && answer != 'n')
			puts
			answer = gets.chomp.downcase
		end
		load_saved_game if answer == 'y'
	end

	def load_saved_game
		puts
		if File.exists?("saved_game.yaml")
			@wanted_to_load_game = true
		else puts "Sorry, no saved file exists. Starting new game."
		end
	end

	def is_legal_word(rand_word)
		return rand_word.length > 5 && rand_word.length < 12
	end

	def play_game
		draw_save_screen
		draw_board_and_guesses
		while (!@game_over)
			have_player_guess
			break if @wanted_to_save_game
			draw_board_and_guesses
			@game_over = test_if_game_over
		end
		draw_game_over_screen unless @wanted_to_save_game
	end

	def draw_save_screen
		puts
		puts 'Type in "save" in order to save your current game.'
		puts
	end

	def draw_board_and_guesses
		puts
		# prints the hyphens or correct words
		@word.split('').each {|char| print feedback(char)}

		print "\tWrong guesses left: #{@MAX_GUESSES - @wrong_guesses}"
		prints_letters_already_guessed
		puts
	end

	def prints_letters_already_guessed
		print "\t"
		print @guesses.join(",")
	end

	def feedback(char)
		return char + ' ' if @guesses.include?(char)
		return '_ '
	end

	def have_player_guess
		guess = ''
		while guess.empty?
			puts
			print "Place your guess: "
			given_guess = gets.chomp.downcase
			break if player_wants_to_save(given_guess)
			if is_legal_guess(given_guess)
				guess = given_guess
				@guesses.push(given_guess)
			end
		end
		@wrong_guesses += 1 unless is_a_mistake(given_guess)
	end

	def player_wants_to_save(given_guess)
		if given_guess == 'save'
			@wanted_to_save_game = true
			unless File.exists?("saved_game.yaml")
				File.new("saved_game.yaml", "w+") 
			end
			return true
		end
		false
	end

	def is_a_mistake(given_guess)
		return @word.include?(given_guess) || @wanted_to_save_game
	end

	def is_legal_guess(guess)
		return (guess.length == 1 && guess.match(/[a-z]/) &&
			!@guesses.include?(guess))
	end

	def test_if_game_over
		return (@wrong_guesses == @MAX_GUESSES ||
			player_won?)
	end

	def player_won?
		@word.split('').each do |char|
			return false unless @guesses.include?(char)
		end
		true
	end

	def draw_game_over_screen
		puts
		if @wrong_guesses != @MAX_GUESSES
			puts "Congrats, you won!"
		else puts "Sorry, you lost."
		end
		puts "The word was #{@word}"
		puts
	end
end

game = Hangman.new

while (!game.game_over)
	if game.wanted_to_load_game
		game = YAML::load_file('saved_game.yaml')
		game.play_game
	elsif game.wanted_to_save_game
		# this ensures that when the file is
		# loaded back up the game starts with false
		game.wanted_to_save_game = false
		File.open('saved_game.yaml', 'w') {|f| f.write game.to_yaml}
		abort
	end
end

# this is to ensure user can't reopen
# a game that has already ended
File.delete("saved_game.yaml") if File.exists?("saved_game.yaml")