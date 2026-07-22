#! /usr/bin/bash

# Author:	Alex D
# Date:		2026-07-16

current_dir="$HOME"
selected_index=0
filter=""

toggle_hidden=0
status_message=""
home_message=""

color_reset=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
status_color=$GREEN

QUIT_KEYS="q"
BACK_KEYS=("b" $'\e[D' "a")
ENTER_KEYS=("" $'\e[C' "d")
UP_KEYS=("w" $'\e[A')
DOWN_KEYS=("s" $'\e[B')
TOGGLE_HIDDEN_COMMAND="h"
BACKSPACE=($'\177' $'\010')

toggle_filter=0
FILTER_KEY="'"
RESET_FILTER="r"

display_directory() {
	check_home_dir
	if [[ "$home_message" != "" ]]
	then
		echo "${MAGENTA}$home_message${color_reset}"
	fi

	if [[ "$status_message" != "" ]]
	then
		echo "${status_color}$status_message${color_reset}"
	fi
	
	if [[ "$filter" != "" ]]
	then
		echo "search: $filter"
	fi

	echo -e "Current Directory: $current_dir \n"
	
	if [[ $toggle_hidden -eq 1 ]]
	then
		mapfile -t directories < <(ls -aF "$current_dir")
	else
		mapfile -t directories < <(ls -F "$current_dir")
	fi
	
	filtered_directories=()

	shopt -s nocasematch
	for i in "${!directories[@]}" 
	do
		if [[ "${directories[$i]}" == *"$filter"* ]]
		then
			filtered_directories+=("${directories[$i]}")
			display_num=${#filtered_directories[@]}
			selection_index=$(($display_num - 1))
			if [[ $selected_index -eq $selection_index ]]
			then
				echo -e "> $display_num. ${directories[$i]}"
			else
				echo -e "  $display_num. ${directories[$i]}"
			fi	
		fi
	done
	shopt -u nocasematch
}

get_input() {
#	read -p "Choose a directory: " input
	IFS= read -r -s -n 1 input

	if [[ "$input" == $'\e' ]]
	then
		IFS= read -r -s -n 2 -t 0.1 next_chars
		input+="$next_chars"
	fi
	echo "$input"

	status_message=""
	home_message=""
	status_color=$GREEN
}

handle_input() {
	if check_input "$FILTER_KEY" 
	then
		f_toggle
		status_message="filter mode enabled"
		status_color=$BLUE
		return 1
	fi

	if check_input "$BACKSPACE"
	then
		if [[ "$filter" != "" ]]
		then
			backspace
			reset_selected_index
		fi
		return 1
	fi

	if [[ $toggle_filter -eq 1 ]]
	then
		status_message="filter mode enabled"
		status_color=$BLUE
		if [[ "$input" =~ ^[0-9]+$ || "$input" =~ ^[a-zA-Z]+$ ]]
		then
			filter+="$input"
			reset_selected_index
		fi

		if check_input ""
		then
			f_toggle
			status_message="filter mode disabled"
		fi

		if [[ ${#filtered_directories[@]} -eq 0 ]]
		then
			status_message="no matches found"
			status_color=$RED
		fi
	else
		if check_input "$QUIT_KEYS"
		then
			clear
			exit
		fi

		if check_input "${BACK_KEYS[@]}"
		then
			if [[ "$current_dir" == "/" ]]
			then
				status_color=$RED
				status_message="cannot go out of root"
			else
				back_dir
				status_message="Returned to $current_dir"
			fi
			reset_selected_index
			return 1
		fi

		if check_input "$TOGGLE_HIDDEN_COMMAND"
		then
			(( toggle_hidden ^= 1))
			status_color=$BLUE
			if [[ $toggle_hidden -eq 1 ]]
			then
				status_message="Hidden Files enabled"
			else
				status_message="Hidden Files disabled"
			fi
			reset_selected_index
			return 1
		fi

		if check_input "${UP_KEYS[@]}"
		then
			((selected_index--))
			check_selected_index_overflow
			return 1
		fi

		if check_input "${ENTER_KEYS[@]}"
		then
			status_message="entered ${filtered_directories[$selected_index]%?}"
			current_dir=$(make_dir "${filtered_directories[$selected_index]%?}")
			reset_selected_index
			return 1
		fi

		if check_input "${DOWN_KEYS[@]}" 
		then
			((selected_index++))
			check_selected_index_overflow
			return 1
		fi

		if check_input "$RESET_FILTER" 
		then
			reset_filter
		fi

		if [[ $input =~ ^[0-9]+$ ]]
		then
			index=$(($input - 1))
			if [[ $index -ge 0 && $index -lt ${#filtered_directories[@]} ]] 
			then
				if [[ -d $(make_dir "${filtered_directories[$index]}") ]]
				then
					status_message="entered ${filtered_directories[$index]%?}"
					current_dir=$(make_dir "${filtered_directories[$index]%?}")
				else
					status_message="cannot enter file"
					status_color=$RED
				fi
			else
				status_color=$RED
				status_message="invalid index"
			fi
			return 1
		fi
		
		if [[ -d $(make_dir "$input") ]]
		then
			if [[ "$input" == "" ]]
			then
				status_message="no input > refresh"
				return 1
			fi
			status_message="entered $input"
			current_dir=$(make_dir "$input")
		else
			status_color=$RED
			status_message="'$input' is not a valid directory"
		fi
	fi
}

backspace() {
	filter="${filter%?}"
}

f_toggle() {
	(( toggle_filter ^= 1))
}

reset_filter() {
	filter=""
}

reset_selected_index() {
	selected_index=0
}

check_input() {
	for key in "$@"
	do
		if [[ "$input" == "$key" ]]
		then
			return 0 #found
		fi
	done
	return 1 #not found
}

check_selected_index_overflow() {
	if [[ $selected_index -lt 0 ]]
	then
		selected_index=$(( ${#filtered_directories[@]} - 1 ))
	fi

	if [[ $selected_index -ge ${#filtered_directories[@]} ]]
	then
		selected_index=0
	fi
}

make_dir() {
	if [[ "$1" == "/"* ]]
	then
		echo "$input"
		return 0
	fi

	if [[ "$1" == "~" ]]
	then
		echo "$HOME"
		return 0
	fi

	echo "$current_dir/$1"
}

back_dir() {
	current_dir=$(dirname "$current_dir")
}

check_home_dir() {
	if [[ "$current_dir" == "$HOME" ]]
	then
		home_message="Welcome Home, would you like dinner, a bath or me?"
#		status_color=$MAGENTA
	fi
}

while true
do
	clear
	display_directory
	get_input
	handle_input || continue
done
