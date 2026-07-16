#! /usr/bin/bash

# Author:	Alex D
# Date:		2026-07-16

current_dir="$HOME"
toggle_hidden=1

display_directory() {
	echo -e "Current Directory: $current_dir \n"
	
	if [[ $toggle_hidden -lt 0 ]]
	then
		directories=($(ls -aF "$current_dir"))
	else
		directories=($(ls -F "$current_dir"))
	fi

	for i in "${!directories[@]}" 
	do
		display_num=$(($i+1))
		echo -e "$display_num. ${directories[$i]}"
	done
}

get_input() {
	read -p "Choose a directory: " input
}

handle_commands() {
	if [[ "$input" == "q" ]]
	then
		exit
	fi

	if [[ "$input" == "b" ]]
	then
		if [[ "$current_dir" == "/" ]]
		then
			echo "cannot go out of root"
		else
			current_dir=$(dirname "$current_dir")
		fi
		return 1
	fi

	if [[ "$input" == "h" ]]
	then
		(( toggle_hidden *= -1))
	fi
}

handle_dir() {
	if [[ $input =~ ^[0-9]+$ ]]
	then
		index=$(($input - 1))
		if [[ $index -ge 0 && $index -lt ${#directories[@]} ]]
		then
			current_dir=$(make_dir "${directories[$index]}")
		else
			echo "invalid index"
		fi
		return 1
	fi
	
	if [[ -d $(make_dir "input") ]]
	then
		current_dir=$(make_dir "$input")
	else
		echo "'$dir' is not a valid directory"
	fi
}

make_dir() {
	echo "$current_dir/$1"
}

while true
do
	clear
	display_directory
	get_input
	handle_commands || continue
	handle_dir || continue
done
