#! /usr/bin/bash

# Author:	Alex D
# Date:		2026-07-16

current_dir="$HOME"

while true
do
	echo -e "Current Directory: $current_dir \n"

	ls "$current_dir" -1

	read -p "Choose a directory: " dir
	
	if [[ "$dir" == "q" ]]
	then
		exit
	fi

	if [[ "$dir" == "b" ]]
	then
		if [[ "$current_dir" == "/" ]]
		then
			echo "cannot go out of root"
		else
			current_dir=$(dirname "$current_dir")
		fi
		continue
	fi

	if [[ -d "$current_dir/$dir" ]]
	then
		current_dir="$current_dir/$dir"
	else
		echo "'$dir' is not a valid directory"
	fi
done
