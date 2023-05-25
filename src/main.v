module main

import os
import json
import term
import rand



struct Champion {
	name         string
	roles        []string
	lanes        []string
	release_date int
	species      string
	region       string
	range_type   []string
	portrait     string
	gender       string
	resource     string
}

const green = '\033[92m'

const yellow = '\033[93m'

const red = '\033[91m'

const end = '\033[0m'

const blue = '\033[94m'

enum GuessResult {
	registered
	already_guessed
	success
	not_found
}

struct App {
	all_champs []Champion
mut:
	to_guess Champion
	guesses  []Champion
}

fn main() {
	all_champs := load_champs()
	mut app := &App{
		all_champs: all_champs
		to_guess: rand.choose[Champion](all_champs, 1)![0]
	}

	println('Start by guessing a champion name.')
	mut guess_count := 0
	for {
		input := os.input('(${guess_count}) Your guess: ')
		result := app.guess(input)

		if input.to_lower() == 'end' {
			println('The Champion was ${app.to_guess.name}.')
			break
		}

		match result {
			.registered {
				guess_count += 1
				app.print_guessed()
			}
			.success {
				app.print_guessed()
				x, _ := term.get_terminal_size()
				println('')
				println(term.yellow('${' '.repeat((x - 9) / 2)}Congrats!'))
				println(term.yellow('${' '.repeat((x - 18 - (guess_count + 1).str().len) / 2)}It took you ${
					guess_count + 1} guesses.'))
				println('')
				break
			}
			else {
				println('Try again!')
			}
		}
	}
}

fn (a App) print_guessed() {
	term.clear()

	pr(blue, 'Name')
	pr(blue, 'Gender')
	pr(blue, 'Lanes')
	pr(blue, 'Species')
	pr(blue, 'Resource')
	pr(blue, 'Range Type')
	pr(blue, 'Region')
	pr(blue, 'Release')
	println('')

	for c in a.guesses {
		pr(blue, c.name)
		pr_sgl(c.gender, a.to_guess.gender)
		pr_arr(c.lanes, a.to_guess.lanes)
		pr_sgl(c.species, a.to_guess.species)
		pr_sgl(c.resource, a.to_guess.resource)
		pr_arr(c.range_type, a.to_guess.range_type)
		pr_sgl(c.region, a.to_guess.region)

		if c.release_date == a.to_guess.release_date {
			pr(green, '${c.release_date}')
		} else {
			if c.release_date > a.to_guess.release_date {
				pr(red, '${c.release_date} 🔽')
			} else {
				pr(red, '${c.release_date} 🔼')
			}
		}
		println('')
	}
}

fn pr_sgl(a string, b string) {
	if a == b {
		pr(green, a)
	} else {
		pr(red, a)
	}
}

fn pr(color string, field string) {
	print('${color}${field:-16}${end}')
}

fn pr_arr(guess []string, a []string) {
	if a == guess {
		pr(green, guess.join(', '))
	} else {
		if guess.any(it in a) {
			pr(yellow, guess.join(', '))
		} else {
			pr(red, guess.join(', '))
		}
	}
}

fn (mut a App) guess(input string) GuessResult {
	champ := a.find_champ(input) or { return .not_found }

	if a.to_guess.name == champ.name {
		a.guesses << champ
		return .success
	} else if champ in a.guesses {
		return .already_guessed
	}

	a.guesses << champ
	return .registered
}

fn (a App) find_champ(name string) !Champion {
	for i in a.all_champs {
		if i.name.to_lower().starts_with(name.to_lower()) {
			return i
		}
	}
	return error('No champion found')
}

fn load_champs() []Champion {
	js_str := os.read_file('/usr/local/bin/src/champs.json') or { "{}" }
	champs := json.decode([]Champion, js_str) or { [] }
	return champs
}
