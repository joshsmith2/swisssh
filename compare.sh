#!/bin/bash

# Read paths from a 'roots' file, and then get info on any folders 
# located at these paths with the given subpaths.

roots_file='./roots.txt'
path=''
list_dir=false
tree_diff=false
full_diff=false
byte_sizes=false

while getopts "r:p:hltfb" opt; do
    case $opt in 
        r)
            roots_file=$OPTARG
            ;;
        p)
            path=$OPTARG
            ;;
        l)
            list_dir=true
            ;;
        t)
            tree_diff=true
            ;;
        f)
            full_diff=true
            ;;
        b)
            byte_sizes=true
            ;;
        h)
            echo "This script will allow you to compare folder structures located at distinct roots."
            echo "Usage:"
            echo "    -r roots_file : The root locations in which to look for the file"
            echo "    -p path : Path to the file or folder you'd like information on."
            echo "    -l : Print a directory listing of each path"
            echo "    -t : Open a vimdiff of each path's tree - WIP"
            echo "    -f : Open a vimdiff of every file within each path."
            echo "    -b : Use byte sizes, not human readable ones."
    esac
done

#Functions to call
#function get_trimmed_ls_output () {
#    ls -lAGohT ./* | tr -s ' ' | cut -d ' ' -f 3- 
#}

function get_size_due_to_dirs(){
    dirs=`./countdirs.sh $1`
    echo "found $dirs"
}

if [[ -z $path ]]; then
    echo "Error: Please specify a path using the '-p' flag, or run this with '-h' for help."
    exit
else
    echo "Path to search for: $path"
fi
echo "Roots file (should contain locations to search within): $roots_file" >&2

roots_string=''

#if $list_dir; then
#    full_source_ls=`ls -lAGoTR .`

echo "Checking paths:"
while IFS= read -r root; do
    roots_string="$roots_string $root"
    full_path=$root$path
    dirs=`get_size_due_to_dirs $full_path`
    
    
    echo $full_path
    
    
    if $byte_sizes; then
        total_size=`du -c "${full_path}" | tail -n 1`
    else
        total_size=`du -hc "${full_path}" | tail -n 1`
    fi
    echo "Size: $total_size"
    if $list_dir; then
        if $byte_sizes; then
            echo "ls -lAG:"
            ls -lAGsk"${full_path}"
        else
            echo "ls -lAGh:"
            ls -lAGhsk "${full_path}"
        fi
    fi
    echo ""
done < $roots_file



# WIP: Will be developed further if needed.
#if $tree_diff; then
#    echo "Press enter to compare trees of roots using vimdiff, or n to cancel"
#    read tree
#    if [ $tree!='n' ]; then
#        for r in $roots_string; do
#        vimdiff $tree_paths
#    fi
#fi

