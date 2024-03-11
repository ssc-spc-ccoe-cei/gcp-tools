#!/bin/bash

# get the directory of this script
SCRIPT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
file_dir="${SCRIPT_ROOT}/../common"

# Declare an indexed array
declare -a planets

# Read the file line by line and populate the array
while IFS= read -r line; do
    planets+=("$line")
done < "$file_dir/planets.txt"

# produce the number of names requested
for i in $(seq 1 "$1");
do
    # randomly pick a word from the each list
    random_planets=${planets[ $RANDOM % ${#planets[@]} ]}
    # echo and set to lowercase
    echo "$i" - "${random_planets,,}"
done