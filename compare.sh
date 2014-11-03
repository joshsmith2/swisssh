#!/bin/bash

# Read paths from a 'roots' file, and then get info on any folders 
# located at these paths with the given subpaths.

roots_file='./roots.txt'
path=''

while getopts "r:p:h" opt; do
    case $opt in 
        r)
            roots_file=$OPTARG
            ;;
        p)
            path=$OPTARG
            ;;
        h)
            echo "This script will allow you to compare folder structures located at distinct roots."
            echo "Usage:"
            echo "    -r : roots_file : The root locations in which to look for the file"
            echo "    -p : path : Path to the file or folder you'd like information on."
    esac
done

echo "Roots file (should contain locations to search within): $roots_file" >&2
if [[ $path=='' ]]; then
    echo "Please specify a path using the '-p' flag, or run this with '-h' for help."
    exit
else
    echo "Path to search for: $path"
fi


            
