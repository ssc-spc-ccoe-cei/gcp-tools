#!/bin/bash

##############
# How to use #
##############
#
# Pass a number as an argument at the end of the command line to generate that number of names
# Example: To create 10 random names, run 'bash generate-planet-names.sh 10'
#
##############

# get the directory of this script
SCRIPT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
file_dir="${SCRIPT_ROOT}/../common"

# Check if the argument is provided and numeric
if [ -z "$1" ] || ! [[ "$1" =~ ^[0-9]+$ ]]; then
    echo "Usage: $0 <number>"
    exit 1
fi

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