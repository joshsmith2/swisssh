#!/bin/bash

#Calculaes the number of directories within the current directory, to any level, inluding hidden dirs.

# Read a directory to check in from the first argument - otherwise check current dir.
dir_to_check='.'
dir_to_check=$1

echo "Checking $dir_to_check"

# Get a list of all dirs 
count=`ls -FRal $dir_to_check | egrep "/$" -c`

# Account for ./ and ../ - two for in every directory, two in the root.
g=$(( $count-2 ));
echo $(( $g/3 ))
