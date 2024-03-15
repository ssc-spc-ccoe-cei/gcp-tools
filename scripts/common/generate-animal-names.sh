#!/bin/bash

##############
# How to use #
##############
#
# Pass a number as an argument at the end of the command line to generate that number of names
# Example: To create 10 random names, run 'bash generate-animal-names.sh 10'
#
##############

# get the directory of this script
SCRIPT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
file_dir="${SCRIPT_ROOT}/../common"

# Declare an indexed array
declare -a animals

# Read the file line by line and populate the array
while IFS= read -r line; do
    animals+=("$line")
done < "$file_dir/animals.txt"

# produce the number of names requested
for i in $(seq 1 "$1");
do
    # randomly pick a word from the list
    random_animals=${animals[ $RANDOM % ${#animals[@]} ]}
    # echo and set to lowercase
    echo "$i" - "${random_animals,,}"
done